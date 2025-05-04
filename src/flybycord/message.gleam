import flybycord/application.{type Application}
import flybycord/channel.{type Channel}
import flybycord/internal/time_rfc3339
import flybycord/message/activity.{type Activity}
import flybycord/message/attachment.{type Attachment}
import flybycord/message/call.{type Call}
import flybycord/message/component.{type Component}
import flybycord/message/embed.{type Embed}
import flybycord/message/interaction_metadata.{type InteractionMetadata}
import flybycord/message/message_reference.{type MessageReference}
import flybycord/message/poll.{type Poll}
import flybycord/message/reaction.{type Reaction}
import flybycord/message/resolved.{type Resolved}
import flybycord/role.{type Role}
import flybycord/sticker
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Message {
  Message(
    id: String,
    channel_id: String,
    author: User,
    content: String,
    sent_at: Timestamp,
    last_edited_at: Option(Timestamp),
    is_tts: Bool,
    mentions_everyone: Bool,
    mentions_users: List(User),
    mentions_roles: List(Role),
    mentions_channels: Option(List(channel.Mention)),
    attachments: List(Attachment),
    embeds: List(Embed),
    reactions: Option(List(Reaction)),
    nonce: Option(Nonce),
    is_pinned: Bool,
    webhook_id: Option(String),
    type_: Type,
    activity: Option(Activity),
    application: Option(Application),
    application_id: Option(String),
    flags: Option(List(Flag)),
    reference: Option(MessageReference),
    snapshots: Option(List(Snapshot)),
    refrenced_message: Option(Message),
    interaction_metadata: Option(InteractionMetadata),
    thread: Option(Channel),
    components: Option(List(Component)),
    sticker_items: Option(List(sticker.Item)),
    position: Option(Int),
    role_subscription_data: Option(RoleSubscriptionData),
    resolved: Option(Resolved),
    poll: Option(Poll),
    call: Option(Call),
  )
}

pub type Type {
  Default
  RecipientAdd
  RecipientRemove
  Call
  ChannelNameChange
  ChannelIconChange
  ChannelPinnedMessage
  UserJoin
  GuildBoost
  GuildBoostTier1
  GuildBoostTier2
  GuildBoostTier3
  ChannelFollowAdd
  GuildDiscoveryDisqualified
  GuildDiscoveryRequalified
  GuildDiscoveryGracePeriodInitialWarning
  GuildDiscoveryGracePeriodFinalWarning
  ThreadCreated
  Reply
  ChatInputCommand
  ThreadStarterMessage
  GuildInviteReminder
  ContextMenuCommand
  AutoModerationAction
  RoleSubscriptionPurchase
  InteractionPremiumUpsell
  StageStart
  StageEnd
  StageSpeaker
  StageTopic
  GuildApplicationPremiumSubscription
  GuildIncidentAlertModeEnabled
  GuildIncidentAlertModeDisabled
  GuildIncidentReportRaid
  GuildIncidentReportFalseAlarm
  PurchaseNotification
  PollResult
}

pub type Nonce {
  IntNonce(Int)
  StringNonce(String)
}

pub type Flag {
  Crossposted
  IsCrosspost
  SuppressEmbeds
  SourceMessageDeleted
  Urgent
  HasThread
  Ephemeral
  Loading
  FailedToMentionSomeRolesInThread
  SuppressNotifications
  IsVoiceMessage
  HasSnapshot
  IsComponentsV2
}

pub type RoleSubscriptionData {
  RoleSubscriptionData(
    role_subscription_listing_id: String,
    tier_name: String,
    total_months_subscribed: Int,
    is_renewal: Bool,
  )
}

pub type Snapshot {
  Snapshot(
    type_: Type,
    content: String,
    embeds: List(Embed),
    attachments: List(Attachment),
    sent_at: Timestamp,
    last_edited_at: Option(Timestamp),
    flags: Option(List(Flag)),
    mentions_users: List(User),
    mentions_roles: List(Role),
    sticker_items: Option(List(sticker.Item)),
    components: Option(List(Component)),
  )
}

// FLAGS -----------------------------------------------------------------------

fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 0), Crossposted),
    #(int.bitwise_shift_left(1, 1), IsCrosspost),
    #(int.bitwise_shift_left(1, 2), SuppressEmbeds),
    #(int.bitwise_shift_left(1, 3), SourceMessageDeleted),
    #(int.bitwise_shift_left(1, 4), Urgent),
    #(int.bitwise_shift_left(1, 5), HasThread),
    #(int.bitwise_shift_left(1, 6), Ephemeral),
    #(int.bitwise_shift_left(1, 7), Loading),
    #(int.bitwise_shift_left(1, 8), FailedToMentionSomeRolesInThread),
    #(int.bitwise_shift_left(1, 12), SuppressNotifications),
    #(int.bitwise_shift_left(1, 13), IsVoiceMessage),
    #(int.bitwise_shift_left(1, 14), HasSnapshot),
    #(int.bitwise_shift_left(1, 15), IsComponentsV2),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn message_decoder() -> decode.Decoder(Message) {
  use id <- decode.field("id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use author <- decode.field("author", user.decoder())
  use content <- decode.field("content", decode.string)
  use sent_at <- decode.field("timestamp", time_rfc3339.decoder())
  use last_edited_at <- decode.field(
    "edited_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  use is_tts <- decode.field("tts", decode.bool)
  use mentions_everyone <- decode.field("mention_everyone", decode.bool)
  use mentions_users <- decode.field("mentions", decode.list(user.decoder()))
  use mentions_roles <- decode.field(
    "mention_roles",
    decode.list(role.decoder()),
  )
  use mentions_channels <- decode.optional_field(
    "mention_channels",
    None,
    decode.optional(decode.list(channel.mention_decoder())),
  )
  use attachments <- decode.field(
    "attachments",
    decode.list(attachment.decoder()),
  )
  use embeds <- decode.field("embeds", decode.list(embed.decoder()))
  use reactions <- decode.optional_field(
    "reactions",
    None,
    decode.optional(decode.list(reaction.decoder())),
  )
  use nonce <- decode.optional_field(
    "nonce",
    None,
    decode.optional(nonce_decoder()),
  )
  use is_pinned <- decode.field("pinned", decode.bool)
  use webhook_id <- decode.optional_field(
    "webhook_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.field("type", type_decoder())
  use activity <- decode.optional_field(
    "activity",
    None,
    decode.optional(activity.decoder()),
  )
  use application <- decode.optional_field(
    "application",
    None,
    decode.optional(application.decoder()),
  )
  use application_id <- decode.optional_field(
    "application_id",
    None,
    decode.optional(decode.string),
  )
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags_decoder()),
  )
  use reference <- decode.optional_field(
    "message_reference",
    None,
    decode.optional(message_reference.decoder()),
  )
  use snapshots <- decode.optional_field(
    "message_snapshots",
    None,
    decode.optional(decode.list(snapshot_decoder())),
  )
  use refrenced_message <- decode.optional_field(
    "refrenced_message",
    None,
    decode.optional(message_decoder()),
  )
  use interaction_metadata <- decode.optional_field(
    "interaction_metadata",
    None,
    decode.optional(interaction_metadata.decoder()),
  )
  use thread <- decode.optional_field(
    "thread",
    None,
    decode.optional(channel.decoder()),
  )
  use components <- decode.optional_field(
    "components",
    None,
    decode.optional(decode.list(component.decoder())),
  )
  use sticker_items <- decode.optional_field(
    "sticker_items",
    None,
    decode.optional(decode.list(sticker.item_decoder())),
  )
  use position <- decode.optional_field(
    "position",
    None,
    decode.optional(decode.int),
  )
  use role_subscription_data <- decode.optional_field(
    "role_subscription_data",
    None,
    decode.optional(role_subscription_data_decoder()),
  )
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved.decoder()),
  )
  use poll <- decode.optional_field(
    "poll",
    None,
    decode.optional(poll.decoder()),
  )
  use call <- decode.optional_field(
    "call",
    None,
    decode.optional(call.decoder()),
  )
  decode.success(Message(
    id:,
    channel_id:,
    author:,
    content:,
    sent_at:,
    last_edited_at:,
    is_tts:,
    mentions_everyone:,
    mentions_users:,
    mentions_roles:,
    mentions_channels:,
    attachments:,
    embeds:,
    reactions:,
    nonce:,
    is_pinned:,
    webhook_id:,
    type_:,
    activity:,
    application:,
    application_id:,
    flags:,
    reference:,
    snapshots:,
    refrenced_message:,
    interaction_metadata:,
    thread:,
    components:,
    sticker_items:,
    position:,
    role_subscription_data:,
    resolved:,
    poll:,
    call:,
  ))
}

@internal
pub fn nonce_decoder() -> decode.Decoder(Nonce) {
  let int_decoder = {
    use nonce <- decode.then(decode.int)
    decode.success(IntNonce(nonce))
  }
  let string_decoder = {
    use nonce <- decode.then(decode.string)
    decode.success(StringNonce(nonce))
  }

  decode.one_of(int_decoder, or: [string_decoder])
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Default)
    1 -> decode.success(RecipientAdd)
    2 -> decode.success(RecipientRemove)
    3 -> decode.success(Call)
    4 -> decode.success(ChannelNameChange)
    5 -> decode.success(ChannelIconChange)
    6 -> decode.success(ChannelPinnedMessage)
    7 -> decode.success(UserJoin)
    8 -> decode.success(GuildBoost)
    9 -> decode.success(GuildBoostTier1)
    10 -> decode.success(GuildBoostTier2)
    11 -> decode.success(GuildBoostTier3)
    12 -> decode.success(ChannelFollowAdd)
    14 -> decode.success(GuildDiscoveryDisqualified)
    15 -> decode.success(GuildDiscoveryRequalified)
    16 -> decode.success(GuildDiscoveryGracePeriodInitialWarning)
    17 -> decode.success(GuildDiscoveryGracePeriodFinalWarning)
    18 -> decode.success(ThreadCreated)
    19 -> decode.success(Reply)
    20 -> decode.success(ChatInputCommand)
    21 -> decode.success(ThreadStarterMessage)
    22 -> decode.success(GuildInviteReminder)
    23 -> decode.success(ContextMenuCommand)
    24 -> decode.success(AutoModerationAction)
    25 -> decode.success(RoleSubscriptionPurchase)
    26 -> decode.success(InteractionPremiumUpsell)
    27 -> decode.success(StageStart)
    28 -> decode.success(StageEnd)
    29 -> decode.success(StageSpeaker)
    31 -> decode.success(StageTopic)
    32 -> decode.success(GuildApplicationPremiumSubscription)
    36 -> decode.success(GuildIncidentAlertModeEnabled)
    37 -> decode.success(GuildIncidentAlertModeDisabled)
    38 -> decode.success(GuildIncidentReportRaid)
    39 -> decode.success(GuildIncidentReportFalseAlarm)
    44 -> decode.success(PurchaseNotification)
    46 -> decode.success(PollResult)
    _ -> decode.failure(Default, "Type")
  }
}

@internal
pub fn flags_decoder() -> decode.Decoder(List(Flag)) {
  use bits <- decode.then(decode.int)
  bits_flags()
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

@internal
pub fn snapshot_decoder() -> decode.Decoder(Snapshot) {
  decode.at(["message"], {
    use type_ <- decode.field("type", type_decoder())
    use content <- decode.field("content", decode.string)
    use embeds <- decode.field("embeds", decode.list(embed.decoder()))
    use attachments <- decode.field(
      "attachments",
      decode.list(attachment.decoder()),
    )
    use sent_at <- decode.field("timestamp", time_rfc3339.decoder())
    use last_edited_at <- decode.field(
      "edited_timestamp",
      decode.optional(time_rfc3339.decoder()),
    )
    use flags <- decode.optional_field(
      "flags",
      None,
      decode.optional(flags_decoder()),
    )
    use mentions_users <- decode.field("mentions", decode.list(user.decoder()))
    use mentions_roles <- decode.field(
      "mention_roles",
      decode.list(role.decoder()),
    )
    use sticker_items <- decode.optional_field(
      "sticker_items",
      None,
      decode.optional(decode.list(sticker.item_decoder())),
    )
    use components <- decode.optional_field(
      "components",
      None,
      decode.optional(decode.list(component.decoder())),
    )
    decode.success(Snapshot(
      type_:,
      content:,
      embeds:,
      attachments:,
      sent_at:,
      last_edited_at:,
      flags:,
      mentions_users:,
      mentions_roles:,
      sticker_items:,
      components:,
    ))
  })
}

@internal
pub fn role_subscription_data_decoder() -> decode.Decoder(RoleSubscriptionData) {
  use role_subscription_listing_id <- decode.field(
    "role_subscription_listing_id",
    decode.string,
  )
  use tier_name <- decode.field("tier_name", decode.string)
  use total_months_subscribed <- decode.field(
    "total_months_subscribed",
    decode.int,
  )
  use is_renewal <- decode.field("is_renewal", decode.bool)
  decode.success(RoleSubscriptionData(
    role_subscription_listing_id:,
    tier_name:,
    total_months_subscribed:,
    is_renewal:,
  ))
}
