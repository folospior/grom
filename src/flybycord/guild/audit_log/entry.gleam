import flybycord/channel/permission_overwrite
import flybycord/guild/audit_log/change.{type Change}
import flybycord/guild/auto_moderation/trigger
import flybycord/guild/integration
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Entry {
  Entry(
    target_id: Option(String),
    changes: Option(List(Change)),
    user_id: Option(String),
    id: String,
    type_: Type,
    info: Option(Info),
    reason: Option(String),
  )
}

pub type Type {
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

pub type Info {
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
  AutoModerationTriggered(
    rule_name: String,
    trigger_type: trigger.Type,
    channel_id: String,
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Entry) {
  use target_id <- decode.field("target_id", decode.optional(decode.string))
  use changes <- decode.optional_field(
    "changes",
    None,
    decode.optional(decode.list(change.decoder())),
  )
  use user_id <- decode.field("user_id", decode.optional(decode.string))
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("action_type", type_decoder())
  use info <- decode.optional_field(
    "options",
    None,
    decode.optional(info_decoder(type_)),
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
pub fn type_decoder() -> decode.Decoder(Type) {
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
pub fn info_decoder(type_: Type) -> decode.Decoder(Info) {
  let string_int_decoder = {
    use string <- decode.then(decode.string)
    case int.parse(string) {
      Ok(int) -> decode.success(int)
      Error(_) -> decode.failure(0, "Int")
    }
  }
  case type_ {
    ApplicationCommandPermissionUpdate -> {
      use application_id <- decode.field("application_id", decode.string)
      decode.success(ApplicationCommandPermissionUpdated(application_id:))
    }
    AutoModerationBlockMessage
    | AutoModerationFlagToChannel
    | AutoModerationUserCommunicationDisabled -> {
      use rule_name <- decode.field("auto_moderation_rule_name", decode.string)
      use trigger_type <- decode.field(
        "auto_moderation_rule_trigger_type",
        trigger.type_string_decoder(),
      )
      use channel_id <- decode.field("channel_id", decode.string)
      decode.success(AutoModerationTriggered(
        rule_name:,
        trigger_type:,
        channel_id:,
      ))
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
pub fn type_to_int(type_: Type) -> Int {
  case type_ {
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
