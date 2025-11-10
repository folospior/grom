import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import gleam/uri
import grom
import grom/application.{type Application}
import grom/channel/thread.{type Thread}
import grom/component/action_row.{type ActionRow}
import grom/component/container.{type Container}
import grom/component/file as component_file
import grom/component/media_gallery.{type MediaGallery}
import grom/component/section.{type Section}
import grom/component/separator.{type Separator}
import grom/component/text_display.{type TextDisplay}
import grom/file.{type File}
import grom/guild/role.{type Role}
import grom/guild_member.{type GuildMember}
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/message/activity.{type Activity}
import grom/message/allowed_mentions.{type AllowedMentions}
import grom/message/attachment.{type Attachment}
import grom/message/call.{type Call}
import grom/message/embed.{type Embed}
import grom/message/interaction_metadata.{type InteractionMetadata}
import grom/message/message_reference.{type MessageReference}
import grom/message/poll.{type Poll}
import grom/message/reaction.{type Reaction}
import grom/modification.{type Modification, New, Skip}
import grom/permission.{type Permission}
import grom/sticker
import grom/user.{type User}

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
    mentions_roles: List(String),
    mentions_channels: Option(List(ChannelMention)),
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
    thread: Option(Thread),
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
    mentions_roles: List(String),
    sticker_items: Option(List(sticker.Item)),
    components: Option(List(Component)),
  )
}

pub type Resolved {
  Resolved(
    users: Option(Dict(String, User)),
    members: Option(Dict(String, GuildMember)),
    roles: Option(Dict(String, Role)),
    channels: Option(Dict(String, ResolvedChannel)),
    messages: Option(Dict(String, Message)),
    attachments: Option(Dict(String, Attachment)),
  )
}

pub type ResolvedChannel {
  ResolvedTextChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedVoiceChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedCategoryChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedAnnouncementChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedAnnouncementThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedPublicThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedPrivateThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedStageChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedForumChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedMediaChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
}

pub type ChannelMention {
  TextChannelMention(
    // don't mind me, i'm just here for formatting ;)
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  VoiceChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  CategoryChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  AnnouncementChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  AnnouncementThreadMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  PublicThreadMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  PrivateThreadMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  StageChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  ForumChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
  MediaChannelMention(
    channel_id: String,
    guild_id: String,
    channel_name: String,
  )
}

pub type Create {
  Create(
    content: Option(String),
    nonce: Option(Nonce),
    is_tts: Option(Bool),
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    message_reference: Option(MessageReference),
    components: Option(List(Component)),
    sticker_ids: Option(List(String)),
    files: Option(List(File)),
    attachments: Option(List(attachment.Create)),
    flags: Option(List(CreateFlag)),
    enforce_nonce: Option(Bool),
    poll: Option(poll.Create),
  )
}

pub type CreateFlag {
  CreateWithSuppressedEmbeds
  CreateWithSuppressedNotifications
  CreateAsVoiceMessage
  CreateWithComponentsV2
}

pub type GetReactionsQuery {
  Type(reaction.Type)
  AfterUserId(String)
  Limit(Int)
}

pub type Modify {
  Modify(
    content: Modification(String),
    embeds: Modification(List(Embed)),
    flags: Modification(List(ModifyFlag)),
    allowed_mentions: Modification(AllowedMentions),
    components: Modification(List(Component)),
    files: Modification(List(File)),
    attachments: Modification(List(ModifyAttachment)),
  )
}

pub type ModifyFlag {
  ModifyEmbedSuppression
  ModifyUsingComponentsV2
}

pub type ModifyAttachment {
  ExistingAttachment(id: String)
  NewAttachment(attachment.Create)
}

pub type Component {
  ActionRow(ActionRow)
  Section(Section)
  TextDisplay(TextDisplay)
  MediaGallery(MediaGallery)
  File(component_file.File)
  Separator(Separator)
  Container(Container)
}

pub type StartThreadInForumOrMedia {
  StartThreadInForumOrMedia(
    name: String,
    auto_archive_duration: Option(Duration),
    rate_limit_per_user: Option(Duration),
    message: StartThreadInForumOrMediaMessage,
    applied_tags_ids: Option(List(String)),
    files: Option(List(File)),
  )
}

pub type StartThreadInForumOrMediaMessage {
  StartThreadInForumOrMediaMessage(
    content: Option(String),
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    components: Option(List(Component)),
    sticker_ids: Option(List(String)),
    attachments: Option(List(attachment.Create)),
    flags: Option(List(StartThreadInForumOrMediaMessageFlag)),
  )
}

pub type StartThreadInForumOrMediaMessageFlag {
  StartThreadInForumOrMediaMessageWithSuppressedEmbeds
  StartThreadInForumOrMediaMessageWithSuppressedNotifications
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
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

@internal
pub fn bits_create_flags() -> List(#(Int, CreateFlag)) {
  [
    #(int.bitwise_shift_left(1, 2), CreateWithSuppressedEmbeds),
    #(int.bitwise_shift_left(1, 12), CreateWithSuppressedNotifications),
    #(int.bitwise_shift_left(1, 13), CreateAsVoiceMessage),
    #(int.bitwise_shift_left(1, 15), CreateWithComponentsV2),
  ]
}

@internal
pub fn bits_modify_flags() -> List(#(Int, ModifyFlag)) {
  [
    #(int.bitwise_shift_left(1, 2), ModifyEmbedSuppression),
    #(int.bitwise_shift_left(1, 15), ModifyUsingComponentsV2),
  ]
}

@internal
pub fn bits_start_thread_in_forum_or_media_message_flags() -> List(
  #(Int, StartThreadInForumOrMediaMessageFlag),
) {
  [
    #(
      int.bitwise_shift_left(1, 2),
      StartThreadInForumOrMediaMessageWithSuppressedEmbeds,
    ),
    #(
      int.bitwise_shift_left(1, 12),
      StartThreadInForumOrMediaMessageWithSuppressedNotifications,
    ),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Message) {
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
    decode.list(decode.string),
  )
  use mentions_channels <- decode.optional_field(
    "mention_channels",
    None,
    decode.optional(decode.list(channel_mention_decoder())),
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
    decode.optional(flags.decoder(bits_flags())),
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
    decode.optional(decoder()),
  )
  use interaction_metadata <- decode.optional_field(
    "interaction_metadata",
    None,
    decode.optional(interaction_metadata.decoder()),
  )
  use thread <- decode.optional_field(
    "thread",
    None,
    decode.optional(thread.decoder()),
  )
  use components <- decode.optional_field(
    "components",
    None,
    decode.optional(decode.list(component_decoder())),
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
    decode.optional(resolved_decoder()),
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
      decode.optional(flags.decoder(bits_flags())),
    )
    use mentions_users <- decode.field("mentions", decode.list(user.decoder()))
    use mentions_roles <- decode.field(
      "mention_roles",
      decode.list(decode.string),
    )
    use sticker_items <- decode.optional_field(
      "sticker_items",
      None,
      decode.optional(decode.list(sticker.item_decoder())),
    )
    use components <- decode.optional_field(
      "components",
      None,
      decode.optional(decode.list(component_decoder())),
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

@internal
pub fn channel_mention_decoder() -> decode.Decoder(ChannelMention) {
  use type_ <- decode.field("type", decode.int)
  use channel_id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use channel_name <- decode.field("name", decode.string)

  case type_ {
    0 ->
      decode.success(TextChannelMention(channel_id:, guild_id:, channel_name:))
    2 ->
      decode.success(VoiceChannelMention(channel_id:, guild_id:, channel_name:))
    4 ->
      decode.success(CategoryChannelMention(
        channel_id:,
        guild_id:,
        channel_name:,
      ))
    5 ->
      decode.success(AnnouncementChannelMention(
        channel_id:,
        guild_id:,
        channel_name:,
      ))
    10 ->
      decode.success(AnnouncementThreadMention(
        channel_id:,
        guild_id:,
        channel_name:,
      ))
    11 ->
      decode.success(PublicThreadMention(channel_id:, guild_id:, channel_name:))
    12 ->
      decode.success(PrivateThreadMention(channel_id:, guild_id:, channel_name:))
    13 ->
      decode.success(StageChannelMention(channel_id:, guild_id:, channel_name:))
    15 ->
      decode.success(ForumChannelMention(channel_id:, guild_id:, channel_name:))
    16 ->
      decode.success(MediaChannelMention(channel_id:, guild_id:, channel_name:))
    _ -> decode.failure(TextChannelMention("", "", ""), "ChannelMention")
  }
}

@internal
pub fn resolved_channel_decoder() -> decode.Decoder(ResolvedChannel) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.int)
  use current_user_permissions <- decode.field(
    "permissions",
    permission.decoder(),
  )

  case type_ {
    0 ->
      decode.success(ResolvedTextChannel(id:, name:, current_user_permissions:))
    2 ->
      decode.success(ResolvedVoiceChannel(id:, name:, current_user_permissions:))
    4 ->
      decode.success(ResolvedCategoryChannel(
        id:,
        name:,
        current_user_permissions:,
      ))
    5 ->
      decode.success(ResolvedAnnouncementChannel(
        id:,
        name:,
        current_user_permissions:,
      ))
    10 | 11 | 12 -> {
      use metadata <- decode.field("thread_metadata", thread.metadata_decoder())
      use parent_id <- decode.field("parent_id", decode.string)
      case type_ {
        10 ->
          decode.success(ResolvedAnnouncementThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        11 ->
          decode.success(ResolvedPublicThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        12 ->
          decode.success(ResolvedPrivateThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        _ -> decode.failure(ResolvedTextChannel("", "", []), "ResolvedChannel")
      }
    }
    13 ->
      decode.success(ResolvedStageChannel(id:, name:, current_user_permissions:))
    15 ->
      decode.success(ResolvedForumChannel(id:, name:, current_user_permissions:))
    16 ->
      decode.success(ResolvedMediaChannel(id:, name:, current_user_permissions:))
    _ -> decode.failure(ResolvedTextChannel("", "", []), "ResolvedChannel")
  }
}

@internal
pub fn resolved_decoder() -> decode.Decoder(Resolved) {
  use users <- decode.optional_field(
    "users",
    None,
    decode.optional(decode.dict(decode.string, user.decoder())),
  )
  use members <- decode.optional_field(
    "members",
    None,
    decode.optional(decode.dict(decode.string, guild_member.decoder())),
  )
  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.dict(decode.string, role.decoder())),
  )
  use channels <- decode.optional_field(
    "channels",
    None,
    decode.optional(decode.dict(decode.string, resolved_channel_decoder())),
  )
  use messages <- decode.optional_field(
    "messages",
    None,
    decode.optional(decode.dict(decode.string, decoder())),
  )
  use attachments <- decode.optional_field(
    "attachments",
    None,
    decode.optional(decode.dict(decode.string, attachment.decoder())),
  )

  decode.success(Resolved(
    users:,
    members:,
    roles:,
    channels:,
    messages:,
    attachments:,
  ))
}

@internal
pub fn component_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> {
      use action_row <- decode.then(action_row.decoder())
      decode.success(ActionRow(action_row))
    }
    9 -> {
      use section <- decode.then(section.decoder())
      decode.success(Section(section))
    }
    10 -> {
      use text_display <- decode.then(text_display.decoder())
      decode.success(TextDisplay(text_display))
    }
    12 -> {
      use media_gallery <- decode.then(media_gallery.decoder())
      decode.success(MediaGallery(media_gallery))
    }
    13 -> {
      use file <- decode.then(component_file.decoder())
      decode.success(File(file))
    }
    14 -> {
      use separator <- decode.then(separator.decoder())
      decode.success(Separator(separator))
    }
    17 -> {
      use container <- decode.then(container.decoder())
      decode.success(Container(container))
    }
    _ -> decode.failure(ActionRow(action_row.ActionRow(None, [])), "Component")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let content = case create.content {
    Some(content) -> [#("content", json.string(content))]
    None -> []
  }

  let nonce = case create.nonce {
    Some(nonce) -> [#("nonce", nonce_to_json(nonce))]
    None -> []
  }

  let is_tts = case create.is_tts {
    Some(tts) -> [#("tts", json.bool(tts))]
    None -> []
  }

  let embeds = case create.embeds {
    Some(embeds) -> [#("embeds", json.array(embeds, of: embed.to_json))]
    None -> []
  }

  let allowed_mentions = case create.allowed_mentions {
    Some(allowed_mentions) -> [
      #("allowed_mentions", allowed_mentions.to_json(allowed_mentions)),
    ]
    None -> []
  }

  let message_reference = case create.message_reference {
    Some(reference) -> [
      #("message_reference", message_reference.to_json(reference)),
    ]
    None -> []
  }

  let components = case create.components {
    Some(components) -> [
      #("components", json.array(components, of: component_to_json)),
    ]
    None -> []
  }

  let sticker_ids = case create.sticker_ids {
    Some(ids) -> [#("sticker_ids", json.array(ids, json.string))]
    None -> []
  }

  let attachments = case create.attachments {
    Some(attachments) -> [
      #("attachments", json.array(attachments, of: attachment.create_to_json)),
    ]
    None -> []
  }

  let flags = case create.flags {
    Some(flags) -> [#("flags", flags.to_json(flags, bits_create_flags()))]
    None -> []
  }

  let enforce_nonce = case create.enforce_nonce {
    Some(enforce_nonce) -> [#("enforce_nonce", json.bool(enforce_nonce))]
    None -> []
  }

  let poll = case create.poll {
    Some(poll) -> [#("poll", poll.create_to_json(poll))]
    None -> []
  }

  [
    content,
    nonce,
    is_tts,
    embeds,
    allowed_mentions,
    message_reference,
    components,
    sticker_ids,
    attachments,
    flags,
    enforce_nonce,
    poll,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn nonce_to_json(nonce: Nonce) -> Json {
  case nonce {
    IntNonce(nonce) -> json.int(nonce)
    StringNonce(nonce) -> json.string(nonce)
  }
}

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  json.object(
    [
      modification.to_json(modify.content, "content", json.string),
      modification.to_json(modify.embeds, "embdeds", json.array(
        _,
        embed.to_json,
      )),
      modification.to_json(modify.flags, "flags", flags.to_json(
        _,
        bits_modify_flags(),
      )),
      modification.to_json(
        modify.allowed_mentions,
        "allowed_mentions",
        allowed_mentions.to_json,
      ),
      modification.to_json(modify.components, "components", json.array(
        _,
        component_to_json,
      )),
      modification.to_json(modify.attachments, "attachments", json.array(
        _,
        modify_attachment_to_json,
      )),
    ]
    |> list.flatten,
  )
}

@internal
pub fn modify_attachment_to_json(modify_attachment: ModifyAttachment) -> Json {
  case modify_attachment {
    ExistingAttachment(id:) -> json.object([#("id", json.string(id))])
    NewAttachment(create) -> attachment.create_to_json(create)
  }
}

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    ActionRow(action_row) -> action_row.to_json(action_row)
    Section(section) -> section.to_json(section)
    TextDisplay(text_display) -> text_display.to_json(text_display)
    MediaGallery(media_gallery) -> media_gallery.to_json(media_gallery)
    File(file) -> component_file.to_json(file)
    Separator(separator) -> separator.to_json(separator)
    Container(container) -> container.to_json(container)
  }
}

@internal
pub fn start_thread_in_forum_or_media_to_json(
  start_thread: StartThreadInForumOrMedia,
) -> Json {
  let name = [#("name", json.string(start_thread.name))]

  let auto_archive_duration = case start_thread.auto_archive_duration {
    Some(duration) -> [
      #("auto_archive_duration", time_duration.to_int_seconds_encode(duration)),
    ]
    None -> []
  }

  let rate_limit_per_user = case start_thread.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let message = [
    #(
      "message",
      start_thread_in_forum_or_media_message_to_json(start_thread.message),
    ),
  ]

  let applied_tags_ids = case start_thread.applied_tags_ids {
    Some(ids) -> [#("applied_tags", json.array(ids, json.string))]
    None -> []
  }

  [name, auto_archive_duration, rate_limit_per_user, message, applied_tags_ids]
  |> list.flatten
  |> json.object
}

@internal
pub fn start_thread_in_forum_or_media_message_to_json(
  message: StartThreadInForumOrMediaMessage,
) -> Json {
  let content = case message.content {
    Some(content) -> [#("content", json.string(content))]
    None -> []
  }

  let embeds = case message.embeds {
    Some(embeds) -> [#("embeds", json.array(embeds, embed.to_json))]
    None -> []
  }

  let allowed_mentions = case message.allowed_mentions {
    Some(allowed_mentions) -> [
      #("allowed_mentions", allowed_mentions.to_json(allowed_mentions)),
    ]
    None -> []
  }

  let components = case message.components {
    Some(components) -> [
      #("components", json.array(components, component_to_json)),
    ]
    None -> []
  }

  let sticker_ids = case message.sticker_ids {
    Some(ids) -> [#("sticker_ids", json.array(ids, json.string))]
    None -> []
  }

  let attachments = case message.attachments {
    Some(attachments) -> [
      #("attachments", json.array(attachments, attachment.create_to_json)),
    ]
    None -> []
  }

  let flags = case message.flags {
    Some(flags) -> [
      #(
        "flags",
        flags
          |> flags.to_int(bits_start_thread_in_forum_or_media_message_flags())
          |> json.int,
      ),
    ]
    None -> []
  }

  [
    content,
    embeds,
    allowed_mentions,
    components,
    sticker_ids,
    attachments,
    flags,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn pin(
  client: grom.Client,
  in channel_id: String,
  id message_id: String,
  reason reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/channels/" <> channel_id <> "/messages/pins/" <> message_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn unpin(
  client: grom.Client,
  from channel_id: String,
  id message_id: String,
  reason reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/channels/" <> channel_id <> "/messages/pins/" <> message_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn get(
  client: grom.Client,
  in channel_id: String,
  id message_id: String,
) -> Result(Message, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/" <> channel_id <> "/messages/" <> message_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create(
  client: grom.Client,
  in channel_id: String,
  using create: Create,
) -> Result(Message, grom.Error) {
  let json = create |> create_to_json

  let request = case create.files {
    Some(files) -> {
      client
      |> rest.new_multipart_request(
        http.Post,
        "/channels/" <> channel_id <> "/messages",
        json,
        files,
      )
    }
    None -> {
      client
      |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/messages")
      |> request.set_body(json |> json.to_string |> bit_array.from_string)
    }
  }

  use response <- result.try(rest.execute_bytes(request))

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create() -> Create {
  Create(
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  )
}

pub fn crosspost(
  client: grom.Client,
  from channel_id: String,
  id message_id: String,
) -> Result(Message, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/channels/" <> channel_id <> "/messages/" <> message_id <> "/crosspost",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_reactions(
  client: grom.Client,
  in channel_id: String,
  on message_id: String,
  emoji emoji_id: String,
  using query: List(GetReactionsQuery),
) -> Result(List(User), grom.Error) {
  let query =
    query
    |> list.map(fn(single_query) {
      case single_query {
        Type(type_) -> #("type", reaction.type_to_int(type_) |> int.to_string)
        AfterUserId(id) -> #("after", id)
        Limit(limit) -> #("limit", int.to_string(limit))
      }
    })

  let emoji = uri.percent_encode(emoji_id)

  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/"
        <> channel_id
        <> "/messages/"
        <> message_id
        <> "/reactions/"
        <> emoji,
    )
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: user.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete_all_reactions(
  client: grom.Client,
  in channel_id: String,
  from message_id: String,
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/channels/" <> channel_id <> "/messages/" <> message_id <> "/reactions",
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn delete_all_reactions_for_emoji(
  client: grom.Client,
  in channel_id: String,
  from message_id: String,
  emoji emoji_id: String,
) -> Result(Nil, grom.Error) {
  let emoji = uri.percent_encode(emoji_id)

  client
  |> rest.new_request(
    http.Delete,
    "/channels/"
      <> channel_id
      <> "/messages/"
      <> message_id
      <> "/reactions/"
      <> emoji,
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn modify(
  client: grom.Client,
  in channel_id: String,
  id message_id: String,
  using modify: Modify,
) -> Result(Message, grom.Error) {
  let json = modify |> modify_to_json

  let request = case modify.files {
    New(files) ->
      client
      |> rest.new_multipart_request(
        http.Patch,
        "/channels/" <> channel_id <> "/messages/" <> message_id,
        json,
        files,
      )
    _ ->
      client
      |> rest.new_request(
        http.Patch,
        "/channels/" <> channel_id <> "/messages/" <> message_id,
      )
      |> request.set_body(json |> json.to_string |> bit_array.from_string)
  }

  use response <- result.try(rest.execute_bytes(request))

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify() -> Modify {
  Modify(Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn delete(
  client: grom.Client,
  in channel_id: String,
  id message_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/channels/" <> channel_id <> "/messages/" <> message_id,
  )
  |> rest.with_reason(reason)
  |> rest.execute
  |> result.replace(Nil)
}

pub fn end_poll(
  client: grom.Client,
  in channel_id: String,
  id message_id: String,
) -> Result(Message, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/channels/" <> channel_id <> "/polls/" <> message_id <> "/expire",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn start_thread_in_forum_or_media(
  client: grom.Client,
  in channel_id: String,
  with start_thread: StartThreadInForumOrMedia,
  because reason: Option(String),
) -> Result(Thread, grom.Error) {
  use response <- result.try(case start_thread.files {
    Some(files) -> {
      client
      |> rest.new_multipart_request(
        http.Post,
        "/channels/" <> channel_id <> "/threads",
        start_thread_in_forum_or_media_to_json(start_thread),
        files,
      )
      |> rest.with_reason(reason)
      |> rest.execute_bytes
    }
    None -> {
      let json = start_thread |> start_thread_in_forum_or_media_to_json

      client
      |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/threads")
      |> request.set_body(json |> json.to_string)
      |> rest.with_reason(reason)
      |> rest.execute
    }
  })

  response.body
  |> json.parse(using: thread.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_start_thread_in_forum_or_media(
  name: String,
  message: StartThreadInForumOrMediaMessage,
) -> StartThreadInForumOrMedia {
  StartThreadInForumOrMedia(name, None, None, message, None, None)
}

pub fn new_start_thread_in_forum_or_media_message() -> StartThreadInForumOrMediaMessage {
  StartThreadInForumOrMediaMessage(None, None, None, None, None, None, None)
}
