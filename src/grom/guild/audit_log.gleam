import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import gleam/set.{type Set}
import grom
import grom/channel.{type Channel}
import grom/channel/permission_overwrite
import grom/command.{type Command}
import grom/guild/auto_moderation
import grom/guild/integration
import grom/guild/scheduled_event.{type ScheduledEvent}
import grom/internal/rest
import grom/user.{type User}
import grom/webhook.{type Webhook}

// TYPES -----------------------------------------------------------------------

pub type AuditLog {
  AuditLog(
    application_commands: List(Command),
    entries: List(Entry),
    auto_moderation_rules: List(auto_moderation.Rule),
    scheduled_events: List(ScheduledEvent),
    integrations: List(PartialIntegration),
    threads: List(Channel),
    users: List(User),
    webhooks: List(Webhook),
  )
}

pub type PartialIntegration {
  PartialIntegration(
    id: String,
    name: String,
    type_: String,
    account: PartialUser,
    application_id: String,
  )
}

pub type PartialUser {
  PartialUser(name: String, id: String)
}

pub type GetQuery {
  UserId(String)
  EntryType(EntryType)
  BeforeId(String)
  AfterId(String)
  Limit(Int)
}

/// The change object describes what was changed, its old value and new value.
///
/// You will need to decode the old and new values based on what was changed
/// using [gleam/dynamic/decode](https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html)
pub type Change {
  Change(
    /// What was changed. Generally a name of a field in an object's constructor.
    /// 
    /// Some fields are _undocumented_.
    ///
    /// See [exceptions](https://discord.com/developers/docs/resources/audit-log#audit-log-change-object-audit-log-change-exceptions).
    key: String,
    old_value: Option(decode.Dynamic),
    new_value: Option(decode.Dynamic),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn change_decoder() -> decode.Decoder(Change) {
  use key <- decode.field("key", decode.string)
  use old_value <- decode.field("old_value", decode.optional(decode.dynamic))
  use new_value <- decode.field("new_value", decode.optional(decode.dynamic))
  decode.success(Change(key:, old_value:, new_value:))
}

// TYPES -----------------------------------------------------------------------

pub type Entry {
  Entry(
    target_id: Option(String),
    changes: Option(List(Change)),
    user_id: Option(String),
    id: String,
    type_: EntryType,
    info: Option(EntryInfo),
    reason: Option(String),
  )
}

pub type EntryType {
  GuildUpdate
  ChannelCreate
  ChannelUpdate
  ChannelDelete
  ChannelOverwriteCreate
  ChannelOverwriteUpdate
  ChannelOverwriteDelete
  MemberKick
  MemberPrune
  MemberBanAdd
  MemberBanRemove
  MemberUpdate
  MemberRoleUpdate
  MemberMove
  MemberDisconnect
  BotAdd
  RoleCreate
  RoleUpdate
  RoleDelete
  InviteCreate
  InviteUpdate
  InviteDelete
  WebhookCreate
  WebhookUpdate
  WebhookDelete
  EmojiCreate
  EmojiUpdate
  EmojiDelete
  MessageDelete
  MessageBulkDelete
  MessagePin
  MessageUnpin
  IntegrationCreate
  IntegrationUpdate
  IntegrationDelete
  StageInstanceCreate
  StageInstanceUpdate
  StageInstanceDelete
  StickerCreate
  StickerUpdate
  StickerDelete
  ScheduledEventCreate
  ScheduledEventUpdate
  ScheduledEventDelete
  ThreadCreate
  ThreadUpdate
  ThreadDelete
  ApplicationCommandPermissionUpdate
  SoundboardSoundCreate
  SoundboardSoundUpdate
  SoundboardSoundDelete
  AutoModerationRuleCreate
  AutoModerationRuleUpdate
  AutoModerationRuleDelete
  AutoModerationBlockMessage
  AutoModerationFlagToChannel
  AutoModerationUserCommunicationDisabled
  CreatorMonetizationRequestCreated
  CreatorMonetizationTermsAccepted
  OnboardingPromptCreate
  OnboardingPromptUpdate
  OnboardingPromptDelete
  OnboardingCreate
  OnboardingUpdate
  HomeSettingsCreate
  HomeSettingsUpdate
}

pub type EntryInfo {
  ChannelOverwriteEntry(
    id: String,
    type_: permission_overwrite.Type,
    /// Only present if `type_ == permission_overwrite.Role`.
    role_name: Option(String),
  )
  MemberKicked(
    /// Only present if an integration performed the action.
    integration_type: Option(integration.Type),
  )
  MemberRoleUpdated(
    /// Only present if an integration performed the action.
    integration_type: Option(integration.Type),
  )
  MembersPruned(delete_member_days: Int, count: Int)
  MembersMoved(channel_id: String, count: Int)
  MembersDisconnected(count: Int)
  MessagesDeleted(channel_id: String, count: Int)
  MessagesBulkDeleted(count: Int)
  MessagePinned(channel_id: String, message_id: String)
  MessageUnpinned(channel_id: String, message_id: String)
  StageInstanceEntry(channel_id: String)
  ApplicationCommandPermissionUpdated(application_id: String)
  AutoModerationTriggered(rule_name: String, channel_id: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn entry_decoder() -> decode.Decoder(Entry) {
  use target_id <- decode.field("target_id", decode.optional(decode.string))
  use changes <- decode.optional_field(
    "changes",
    None,
    decode.optional(decode.list(change_decoder())),
  )
  use user_id <- decode.field("user_id", decode.optional(decode.string))
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("action_type", entry_type_decoder())
  use info <- decode.optional_field(
    "options",
    None,
    decode.optional(entry_info_decoder(type_)),
  )
  use reason <- decode.optional_field(
    "reason",
    None,
    decode.optional(decode.string),
  )
  decode.success(Entry(
    target_id:,
    changes:,
    user_id:,
    id:,
    type_:,
    info:,
    reason:,
  ))
}

@internal
pub fn entry_type_decoder() -> decode.Decoder(EntryType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(GuildUpdate)
    10 -> decode.success(ChannelCreate)
    11 -> decode.success(ChannelUpdate)
    12 -> decode.success(ChannelDelete)
    13 -> decode.success(ChannelOverwriteCreate)
    14 -> decode.success(ChannelOverwriteUpdate)
    15 -> decode.success(ChannelOverwriteDelete)
    20 -> decode.success(MemberKick)
    21 -> decode.success(MemberPrune)
    22 -> decode.success(MemberBanAdd)
    23 -> decode.success(MemberBanRemove)
    24 -> decode.success(MemberUpdate)
    25 -> decode.success(MemberRoleUpdate)
    26 -> decode.success(MemberMove)
    27 -> decode.success(MemberDisconnect)
    28 -> decode.success(BotAdd)
    30 -> decode.success(RoleCreate)
    31 -> decode.success(RoleUpdate)
    32 -> decode.success(RoleDelete)
    40 -> decode.success(InviteCreate)
    41 -> decode.success(InviteUpdate)
    42 -> decode.success(InviteDelete)
    50 -> decode.success(WebhookCreate)
    51 -> decode.success(WebhookUpdate)
    52 -> decode.success(WebhookDelete)
    60 -> decode.success(EmojiCreate)
    61 -> decode.success(EmojiUpdate)
    62 -> decode.success(EmojiDelete)
    72 -> decode.success(MessageDelete)
    73 -> decode.success(MessageBulkDelete)
    74 -> decode.success(MessagePin)
    75 -> decode.success(MessageUnpin)
    80 -> decode.success(IntegrationCreate)
    81 -> decode.success(IntegrationUpdate)
    82 -> decode.success(IntegrationDelete)
    83 -> decode.success(StageInstanceCreate)
    84 -> decode.success(StageInstanceUpdate)
    85 -> decode.success(StageInstanceDelete)
    90 -> decode.success(StickerCreate)
    91 -> decode.success(StickerUpdate)
    92 -> decode.success(StickerDelete)
    100 -> decode.success(ScheduledEventCreate)
    101 -> decode.success(ScheduledEventUpdate)
    102 -> decode.success(ScheduledEventDelete)
    110 -> decode.success(ThreadCreate)
    111 -> decode.success(ThreadUpdate)
    112 -> decode.success(ThreadDelete)
    121 -> decode.success(ApplicationCommandPermissionUpdate)
    130 -> decode.success(SoundboardSoundCreate)
    131 -> decode.success(SoundboardSoundUpdate)
    132 -> decode.success(SoundboardSoundDelete)
    140 -> decode.success(AutoModerationRuleCreate)
    141 -> decode.success(AutoModerationRuleUpdate)
    142 -> decode.success(AutoModerationRuleDelete)
    143 -> decode.success(AutoModerationBlockMessage)
    144 -> decode.success(AutoModerationFlagToChannel)
    145 -> decode.success(AutoModerationUserCommunicationDisabled)
    150 -> decode.success(CreatorMonetizationRequestCreated)
    151 -> decode.success(CreatorMonetizationTermsAccepted)
    163 -> decode.success(OnboardingPromptCreate)
    164 -> decode.success(OnboardingPromptUpdate)
    165 -> decode.success(OnboardingPromptDelete)
    166 -> decode.success(OnboardingCreate)
    167 -> decode.success(OnboardingUpdate)
    190 -> decode.success(HomeSettingsCreate)
    191 -> decode.success(HomeSettingsUpdate)
    _ -> decode.failure(GuildUpdate, "Type")
  }
}

@internal
pub fn entry_info_decoder(entry_type: EntryType) -> decode.Decoder(EntryInfo) {
  let string_int_decoder = {
    use string <- decode.then(decode.string)
    case int.parse(string) {
      Ok(int) -> decode.success(int)
      Error(_) -> decode.failure(0, "Int")
    }
  }
  case entry_type {
    ApplicationCommandPermissionUpdate -> {
      use application_id <- decode.field("application_id", decode.string)
      decode.success(ApplicationCommandPermissionUpdated(application_id:))
    }
    AutoModerationBlockMessage
    | AutoModerationFlagToChannel
    | AutoModerationUserCommunicationDisabled -> {
      use rule_name <- decode.field("auto_moderation_rule_name", decode.string)
      use channel_id <- decode.field("channel_id", decode.string)
      decode.success(AutoModerationTriggered(rule_name:, channel_id:))
    }
    MemberMove -> {
      use channel_id <- decode.field("channel_id", decode.string)
      use count <- decode.field("count", string_int_decoder)
      decode.success(MembersMoved(channel_id:, count:))
    }
    MessagePin -> {
      use channel_id <- decode.field("channel_id", decode.string)
      use message_id <- decode.field("message_id", decode.string)
      decode.success(MessagePinned(channel_id:, message_id:))
    }
    MessageUnpin -> {
      use channel_id <- decode.field("channel_id", decode.string)
      use message_id <- decode.field("message_id", decode.string)
      decode.success(MessageUnpinned(channel_id:, message_id:))
    }
    MessageDelete -> {
      use channel_id <- decode.field("channel_id", decode.string)
      use count <- decode.field("count", string_int_decoder)
      decode.success(MessagesDeleted(channel_id:, count:))
    }
    StageInstanceCreate | StageInstanceUpdate | StageInstanceDelete -> {
      use channel_id <- decode.field("channel_id", decode.string)
      decode.success(StageInstanceEntry(channel_id:))
    }
    MessageBulkDelete -> {
      use count <- decode.field("count", string_int_decoder)
      decode.success(MessagesBulkDeleted(count:))
    }
    MemberDisconnect -> {
      use count <- decode.field("count", string_int_decoder)
      decode.success(MembersDisconnected(count:))
    }
    MemberPrune -> {
      use delete_member_days <- decode.field(
        "delete_member_days",
        string_int_decoder,
      )
      use count <- decode.field("members_removed", string_int_decoder)
      decode.success(MembersPruned(delete_member_days:, count:))
    }
    ChannelOverwriteCreate | ChannelOverwriteUpdate | ChannelOverwriteDelete -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", permission_overwrite.type_decoder())
      use role_name <- decode.optional_field(
        "role_name",
        None,
        decode.optional(decode.string),
      )
      decode.success(ChannelOverwriteEntry(id:, type_:, role_name:))
    }
    MemberKick -> {
      use integration_type <- decode.optional_field(
        "integration_type",
        None,
        decode.optional(integration.type_decoder()),
      )
      decode.success(MemberKicked(integration_type:))
    }
    MemberRoleUpdate -> {
      use integration_type <- decode.optional_field(
        "integration_type",
        None,
        decode.optional(integration.type_decoder()),
      )
      decode.success(MemberRoleUpdated(integration_type:))
    }
    _ -> decode.failure(ApplicationCommandPermissionUpdated(""), "Info")
  }
}

// INTERNAL FUNCTIONS ----------------------------------------------------------

@internal
pub fn entry_type_to_int(entry_type: EntryType) -> Int {
  case entry_type {
    GuildUpdate -> 1
    ChannelCreate -> 10
    ChannelUpdate -> 11
    ChannelDelete -> 12
    ChannelOverwriteCreate -> 13
    ChannelOverwriteUpdate -> 14
    ChannelOverwriteDelete -> 15
    MemberKick -> 20
    MemberPrune -> 21
    MemberBanAdd -> 22
    MemberBanRemove -> 23
    MemberUpdate -> 24
    MemberRoleUpdate -> 25
    MemberMove -> 26
    MemberDisconnect -> 27
    BotAdd -> 28
    RoleCreate -> 30
    RoleUpdate -> 31
    RoleDelete -> 32
    InviteCreate -> 40
    InviteUpdate -> 41
    InviteDelete -> 42
    WebhookCreate -> 50
    WebhookUpdate -> 51
    WebhookDelete -> 52
    EmojiCreate -> 60
    EmojiUpdate -> 61
    EmojiDelete -> 62
    MessageDelete -> 72
    MessageBulkDelete -> 73
    MessagePin -> 74
    MessageUnpin -> 75
    IntegrationCreate -> 80
    IntegrationUpdate -> 81
    IntegrationDelete -> 82
    StageInstanceCreate -> 83
    StageInstanceUpdate -> 84
    StageInstanceDelete -> 85
    StickerCreate -> 90
    StickerUpdate -> 91
    StickerDelete -> 92
    ScheduledEventCreate -> 100
    ScheduledEventUpdate -> 101
    ScheduledEventDelete -> 102
    ThreadCreate -> 110
    ThreadUpdate -> 111
    ThreadDelete -> 112
    ApplicationCommandPermissionUpdate -> 121
    SoundboardSoundCreate -> 130
    SoundboardSoundUpdate -> 131
    SoundboardSoundDelete -> 132
    AutoModerationRuleCreate -> 140
    AutoModerationRuleUpdate -> 141
    AutoModerationRuleDelete -> 142
    AutoModerationBlockMessage -> 143
    AutoModerationFlagToChannel -> 145
    AutoModerationUserCommunicationDisabled -> 146
    CreatorMonetizationRequestCreated -> 150
    CreatorMonetizationTermsAccepted -> 151
    OnboardingPromptCreate -> 163
    OnboardingPromptUpdate -> 164
    OnboardingPromptDelete -> 165
    OnboardingCreate -> 166
    OnboardingUpdate -> 167
    HomeSettingsCreate -> 190
    HomeSettingsUpdate -> 191
  }
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(AuditLog) {
  use application_commands <- decode.field(
    "application_commands",
    decode.list(command.decoder()),
  )
  use entries <- decode.field("entries", decode.list(entry_decoder()))
  use auto_moderation_rules <- decode.field(
    "auto_moderation_rules",
    decode.list(auto_moderation.rule_decoder()),
  )
  use scheduled_events <- decode.field(
    "scheduled_events",
    decode.list(scheduled_event.decoder()),
  )
  use integrations <- decode.field(
    "integrations",
    decode.list(partial_integration_decoder()),
  )
  use threads <- decode.field("threads", decode.list(channel.decoder()))
  use users <- decode.field("users", decode.list(user.decoder()))
  use webhooks <- decode.field("webhooks", decode.list(webhook.decoder()))
  decode.success(AuditLog(
    application_commands:,
    entries:,
    auto_moderation_rules:,
    scheduled_events:,
    integrations:,
    threads:,
    users:,
    webhooks:,
  ))
}

@internal
pub fn partial_integration_decoder() -> decode.Decoder(PartialIntegration) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.string)
  use account <- decode.field("account", partial_user_decoder())
  use application_id <- decode.field("application_id", decode.string)
  decode.success(PartialIntegration(
    id:,
    name:,
    type_:,
    account:,
    application_id:,
  ))
}

@internal
pub fn partial_user_decoder() -> decode.Decoder(PartialUser) {
  use name <- decode.field("name", decode.string)
  use id <- decode.field("id", decode.string)
  decode.success(PartialUser(name:, id:))
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: grom.Client,
  for guild_id: String,
  with query: Set(GetQuery),
) -> Result(AuditLog, grom.Error) {
  let query =
    query
    |> set.map(fn(parameter) {
      case parameter {
        UserId(id) -> #("user_id", id)
        EntryType(type_) -> #(
          "action_type",
          type_
            |> entry_type_to_int
            |> int.to_string,
        )
        BeforeId(id) -> #("before", id)
        AfterId(id) -> #("after", id)
        Limit(limit) -> #("limit", limit |> int.to_string)
      }
    })

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/audit-logs")
    |> request.set_query(query |> set.to_list)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}
