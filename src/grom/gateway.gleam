import gleam/bool
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/static_supervisor
import gleam/otp/supervision
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/activity
import grom/application
import grom/channel.{type Channel}
import grom/channel/thread.{type Thread}
import grom/emoji.{type Emoji}
import grom/entitlement.{type Entitlement}
import grom/gateway/connection_pid
import grom/gateway/heartbeat
import grom/gateway/intent.{type Intent}
import grom/gateway/resuming
import grom/gateway/sequence
import grom/gateway/user_message.{
  type RequestGuildMembersMessage, type UpdatePresenceMessage,
  type UpdateVoiceStateMessage, type UserMessage,
}
import grom/guild.{type Guild}
import grom/guild/audit_log
import grom/guild/auto_moderation
import grom/guild/role.{type Role}
import grom/guild/scheduled_event.{type ScheduledEvent}
import grom/guild_member.{type GuildMember}
import grom/interaction/application_command
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/internal/time_timestamp
import grom/modification.{type Modification}
import grom/soundboard
import grom/stage_instance.{type StageInstance}
import grom/sticker.{type Sticker}
import grom/user.{type User}
import grom/voice
import operating_system
import repeatedly
import stratus

// TYPES -----------------------------------------------------------------------

pub type GatewayData {
  GatewayData(
    url: String,
    recommended_shards: Int,
    session_start_limits: SessionStartLimits,
  )
}

pub type ReadyApplication {
  ReadyApplication(id: String, flags: List(application.Flag))
}

pub type Shard {
  Shard(id: Int, num_shards: Int)
}

pub type Event {
  ReadyEvent(ReadyMessage)
  ErrorEvent(grom.Error)
  ResumedEvent
  RateLimitedEvent(RateLimitedMessage)
  ApplicationCommandPermissionsUpdatedEvent(application_command.Permissions)
  AutoModerationRuleCreatedEvent(auto_moderation.Rule)
  AutoModerationRuleUpdatedEvent(auto_moderation.Rule)
  AutoModerationRuleDeletedEvent(auto_moderation.Rule)
  AutoModerationActionExecutedEvent(AutoModerationActionExecutedMessage)
  ChannelCreatedEvent(Channel)
  ChannelUpdatedEvent(Channel)
  ChannelDeletedEvent(Channel)
  ThreadCreatedEvent(ThreadCreatedMessage)
  ThreadUpdatedEvent(Thread)
  ThreadDeletedEvent(ThreadDeletedMessage)
  ThreadListSyncedEvent(ThreadListSyncedMessage)
  ThreadMemberUpdatedEvent(ThreadMemberUpdatedMessage)
  PresenceUpdatedEvent(PresenceUpdatedMessage)
  ThreadMembersUpdatedEvent(ThreadMembersUpdatedMessage)
  ChannelPinsUpdatedEvent(ChannelPinsUpdatedMessage)
  EntitlementCreatedEvent(Entitlement)
  EntitlementUpdatedEvent(Entitlement)
  EntitlementDeletedEvent(Entitlement)
  GuildCreatedEvent(GuildCreatedMessage)
  GuildUpdatedEvent(Guild)
  /// If `!guild.unavailable`, then the user was removed from the guild.
  GuildDeletedEvent(guild.UnavailableGuild)
  AuditLogEntryCreatedEvent(AuditLogEntryCreatedMessage)
  GuildBanCreatedEvent(GuildBanMessage)
  GuildBanDeletedEvent(GuildBanMessage)
  GuildEmojisUpdatedEvent(GuildEmojisUpdatedMessage)
  GuildStickersUpdatedEvent(GuildStickersUpdatedMessage)
  GuildIntegrationsUpdatedEvent(GuildIntegrationsUpdatedMessage)
  GuildMemberCreatedEvent(GuildMemberCreatedMessage)
  GuildMemberDeletedEvent(GuildMemberDeletedMessage)
  GuildMemberUpdatedEvent(GuildMemberUpdatedMessage)
  GuildMembersChunkEvent(GuildMembersChunkMessage)
  RoleCreatedEvent(RoleCreatedMessage)
  RoleUpdatedEvent(RoleUpdatedMessage)
  RoleDeletedEvent(RoleDeletedMessage)
  ScheduledEventCreatedEvent(ScheduledEvent)
  ScheduledEventUpdatedEvent(ScheduledEvent)
  ScheduledEventDeletedEvent(ScheduledEvent)
  ScheduledEventUserCreatedEvent(ScheduledEventUserMessage)
  ScheduledEventUserDeletedEvent(ScheduledEventUserMessage)
}

pub type SessionStartLimits {
  SessionStartLimits(
    maximum_starts: Int,
    remaining_starts: Int,
    resets_after: Duration,
    max_identify_requests_per_5_seconds: Int,
  )
}

pub opaque type State {
  State(
    actor: Subject(Event),
    sequence_holder: Subject(sequence.Message),
    heartbeat_counter: Subject(heartbeat.Message),
    resuming_info_holder: Subject(resuming.Message),
    connection_pid_holder: Subject(connection_pid.Message),
    identify: IdentifyMessage,
    user_message_subject_holder: Subject(user_message.Message),
  )
}

pub type ClientStatus {
  ClientStatus(
    desktop: Option(String),
    mobile: Option(String),
    web: Option(String),
  )
}

pub type ReceivedActivity {
  ReceivedActivity(
    name: String,
    type_: activity.Type,
    url: Option(String),
    created_at: Timestamp,
    timestamps: Option(activity.Timestamps),
    application_id: Option(String),
    status_display_type: Option(activity.DisplayType),
    details: Option(String),
    details_url: Option(String),
    state: Option(String),
    state_url: Option(String),
    emoji: Option(activity.Emoji),
    party: Option(activity.Party),
    assets: Option(activity.Assets),
    secrets: Option(activity.Secrets),
    is_instance: Option(Bool),
    flags: Option(List(activity.Flag)),
    button_labels: Option(List(String)),
  )
}

// RECEIVE EVENTS --------------------------------------------------------------

pub type ReceivedMessage {
  Hello(HelloMessage)
  Dispatch(sequence: Int, message: DispatchedMessage)
  HeartbeatAcknowledged
  HeartbeatRequest
  ReconnectRequest
  InvalidSession(can_reconnect: Bool)
}

pub type HelloMessage {
  HelloMessage(heartbeat_interval: Duration)
}

// RECEIVED DISPATCH EVENTS ----------------------------------------------------

pub type DispatchedMessage {
  Ready(ReadyMessage)
  Resumed
  RateLimited(RateLimitedMessage)
  ApplicationCommandPermissionsUpdated(application_command.Permissions)
  AutoModerationRuleCreated(auto_moderation.Rule)
  AutoModerationRuleUpdated(auto_moderation.Rule)
  AutoModerationRuleDeleted(auto_moderation.Rule)
  AutoModerationActionExecuted(AutoModerationActionExecutedMessage)
  ChannelCreated(Channel)
  ChannelUpdated(Channel)
  ChannelDeleted(Channel)
  ThreadCreated(ThreadCreatedMessage)
  ThreadUpdated(Thread)
  ThreadDeleted(ThreadDeletedMessage)
  ThreadListSynced(ThreadListSyncedMessage)
  /// Fired if the current user's thread member gets updated.
  ThreadMemberUpdated(ThreadMemberUpdatedMessage)
  PresenceUpdated(PresenceUpdatedMessage)
  ThreadMembersUpdated(ThreadMembersUpdatedMessage)
  ChannelPinsUpdated(ChannelPinsUpdatedMessage)
  EntitlementCreated(Entitlement)
  EntitlementUpdated(Entitlement)
  EntitlementDeleted(Entitlement)
  GuildCreated(GuildCreatedMessage)
  GuildUpdated(Guild)
  GuildDeleted(guild.UnavailableGuild)
  AuditLogEntryCreated(AuditLogEntryCreatedMessage)
  GuildBanCreated(GuildBanMessage)
  GuildBanDeleted(GuildBanMessage)
  GuildEmojisUpdated(GuildEmojisUpdatedMessage)
  GuildStickersUpdated(GuildStickersUpdatedMessage)
  GuildIntegrationsUpdated(GuildIntegrationsUpdatedMessage)
  GuildMemberCreated(GuildMemberCreatedMessage)
  GuildMemberDeleted(GuildMemberDeletedMessage)
  GuildMemberUpdated(GuildMemberUpdatedMessage)
  GuildMembersChunk(GuildMembersChunkMessage)
  RoleCreated(RoleCreatedMessage)
  RoleUpdated(RoleUpdatedMessage)
  RoleDeleted(RoleDeletedMessage)
  ScheduledEventCreated(ScheduledEvent)
  ScheduledEventUpdated(ScheduledEvent)
  ScheduledEventDeleted(ScheduledEvent)
  ScheduledEventUserCreated(ScheduledEventUserMessage)
  ScheduledEventUserDeleted(ScheduledEventUserMessage)
}

pub type ReadyMessage {
  ReadyMessage(
    api_version: Int,
    user: User,
    guilds: List(guild.UnavailableGuild),
    session_id: String,
    resume_gateway_url: String,
    shard: Option(Shard),
    application: ReadyApplication,
  )
}

pub type RateLimitedMessage {
  RateLimitedMessage(
    limited_opcode: Int,
    retry_after: Duration,
    metadata: RateLimitedMetadata,
  )
}

pub type RateLimitedMetadata {
  RequestGuildMembersRateLimited(guild_id: String, nonce: Option(String))
}

pub type AutoModerationActionExecutedMessage {
  AutoModerationActionExecutedMessage(
    guild_id: String,
    action: auto_moderation.Action,
    rule_id: String,
    rule_trigger_type: auto_moderation.TriggerType,
    user_id: String,
    channel_id: Option(String),
    message_id: Option(String),
    alert_system_message_id: Option(String),
    content: Option(String),
    matched_keyword: Option(String),
    matched_content: Option(String),
  )
}

pub type ThreadCreatedMessage {
  ThreadCreatedMessage(thread: Thread, is_newly_created: Bool)
}

pub type ThreadDeletedMessage {
  ThreadDeletedMessage(
    id: String,
    guild_id: String,
    parent_id: String,
    type_: thread.Type,
  )
}

pub type ThreadListSyncedMessage {
  ThreadListSyncedMessage(
    guild_id: String,
    /// If `None`, then threads are synced for the entire guild.
    channel_ids: Option(List(String)),
    threads: List(Thread),
    /// A list of thread members for the current user.
    members: List(thread.Member),
  )
}

pub type ThreadMemberUpdatedMessage {
  ThreadMemberUpdatedMessage(thread_member: thread.Member, guild_id: String)
}

pub type PresenceUpdatedMessage {
  PresenceUpdatedMessage(
    user_id: String,
    guild_id: String,
    status: String,
    activities: List(ReceivedActivity),
    client_status: ClientStatus,
  )
}

pub type ThreadMembersUpdatedMessage {
  ThreadMembersUpdatedMessage(
    id: String,
    guild_id: String,
    member_count: Int,
    added_members: Option(
      List(#(thread.Member, Option(PresenceUpdatedMessage))),
    ),
    removed_member_ids: Option(List(String)),
  )
}

pub type ChannelPinsUpdatedMessage {
  ChannelPinsUpdatedMessage(
    guild_id: Option(String),
    channel_id: String,
    last_pin_timestamp: Option(Timestamp),
  )
}

pub type GuildCreatedMessage {
  GuildCreatedMessage(
    guild: Guild,
    joined_at: Timestamp,
    is_large: Bool,
    member_count: Int,
    voice_states: List(voice.State),
    /// If the guild has over 75k members, this will be only your bot and users in voice channels.
    members: List(GuildMember),
    channels: List(Channel),
    threads: List(Thread),
    /// If you don't have the `GuildPresences` intent enabled, or if the guild has over 75k members, this will only have presences for your bot and users in voice channels.
    presences: List(PresenceUpdatedMessage),
    stage_instances: List(StageInstance),
    scheduled_events: List(ScheduledEvent),
    soundboard_sounds: List(soundboard.Sound),
  )
  UnavailableGuildCreatedMessage(guild.UnavailableGuild)
}

pub type AuditLogEntryCreatedMessage {
  AuditLogEntryCreatedMessage(entry: audit_log.Entry, guild_id: String)
}

pub type GuildBanMessage {
  GuildBanMessage(guild_id: String, user: User)
}

pub type GuildEmojisUpdatedMessage {
  GuildEmojisUpdatedMessage(guild_id: String, emojis: List(Emoji))
}

pub type GuildStickersUpdatedMessage {
  GuildStickersUpdatedMessage(guild_id: String, stickers: List(Sticker))
}

pub type GuildIntegrationsUpdatedMessage {
  GuildIntegrationsUpdatedMessage(guild_id: String)
}

pub type GuildMemberCreatedMessage {
  GuildMemberCreatedMessage(guild_id: String, guild_member: GuildMember)
}

pub type GuildMemberDeletedMessage {
  GuildMemberDeletedMessage(guild_id: String, user: User)
}

pub type GuildMemberUpdatedMessage {
  GuildMemberUpdatedMessage(
    guild_id: String,
    role_ids: List(String),
    user: User,
    nick: Modification(String),
    avatar_hash: Option(String),
    banner_hash: Option(String),
    joined_at: Option(Timestamp),
    premium_since: Option(Timestamp),
    is_deaf: Option(Bool),
    is_mute: Option(Bool),
    is_pending: Option(Bool),
    communication_disabled_until: Modification(Timestamp),
    flags: Option(List(guild_member.Flag)),
    avatar_decoration_data: Modification(user.AvatarDecorationData),
  )
}

pub type GuildMembersChunkMessage {
  GuildMembersChunkMessage(
    guild_id: String,
    members: List(GuildMember),
    chunk_index: Int,
    chunk_count: Int,
    not_found_ids: Option(List(String)),
    presences: Option(List(PresenceUpdatedMessage)),
    nonce: Option(String),
  )
}

pub type RoleCreatedMessage {
  RoleCreatedMessage(guild_id: String, role: Role)
}

pub type RoleUpdatedMessage {
  RoleUpdatedMessage(guild_id: String, role: Role)
}

pub type RoleDeletedMessage {
  RoleDeletedMessage(guild_id: String, role_id: String)
}

pub type ScheduledEventUserMessage {
  ScheduledEventUserMessage(
    scheduled_event_id: String,
    user_id: String,
    guild_id: String,
  )
}

// SEND EVENTS -----------------------------------------------------------------

pub type SentMessage {
  Heartbeat(HeartbeatMessage)
  Identify(IdentifyMessage)
  Resume(ResumeMessage)
}

pub type HeartbeatMessage {
  HeartbeatMessage(last_sequence: Option(Int))
}

pub type IdentifyMessage {
  IdentifyMessage(
    token: String,
    properties: IdentifyProperties,
    supports_compression: Bool,
    max_offline_members: Option(Int),
    shard: Option(Shard),
    presence: Option(UpdatePresenceMessage),
    intents: List(Intent),
  )
}

pub type ResumeMessage {
  ResumeMessage(token: String, session_id: String, last_sequence: Int)
}

pub type IdentifyProperties {
  IdentifyProperties(os: String, browser: String, device: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn data_decoder() -> decode.Decoder(GatewayData) {
  use url <- decode.field("url", decode.string)
  use recommended_shards <- decode.field("shards", decode.int)
  use session_start_limits <- decode.field(
    "session_start_limit",
    session_start_limits_decoder(),
  )

  decode.success(GatewayData(url:, recommended_shards:, session_start_limits:))
}

@internal
pub fn session_start_limits_decoder() -> decode.Decoder(SessionStartLimits) {
  use maximum_starts <- decode.field("total", decode.int)
  use remaining_starts <- decode.field("remaining", decode.int)
  use resets_after <- decode.field(
    "reset_after",
    time_duration.from_milliseconds_decoder(),
  )

  use max_identify_requests_per_5_seconds <- decode.field(
    "max_concurrency",
    decode.int,
  )

  decode.success(SessionStartLimits(
    maximum_starts:,
    remaining_starts:,
    resets_after:,
    max_identify_requests_per_5_seconds:,
  ))
}

@internal
pub fn message_decoder() -> decode.Decoder(ReceivedMessage) {
  use opcode <- decode.field("op", decode.int)
  case opcode {
    0 -> {
      use sequence <- decode.field("s", decode.int)
      use type_ <- decode.field("t", decode.string)
      use message <- decode.field("d", dispatched_message_decoder(type_))
      decode.success(Dispatch(sequence:, message:))
    }
    1 -> decode.success(HeartbeatRequest)
    7 -> decode.success(ReconnectRequest)
    9 -> {
      use can_reconnect <- decode.then(decode.bool)
      decode.success(InvalidSession(can_reconnect:))
    }
    10 -> {
      use msg <- decode.field("d", hello_event_decoder())
      decode.success(Hello(msg))
    }
    11 -> decode.success(HeartbeatAcknowledged)
    _ ->
      decode.failure(Hello(HelloMessage(duration.seconds(0))), "ReceivedEvent")
  }
}

@internal
pub fn dispatched_message_decoder(
  type_: String,
) -> decode.Decoder(DispatchedMessage) {
  case type_ {
    "READY" -> {
      use ready <- decode.then(ready_message_decoder())
      decode.success(Ready(ready))
    }
    "RESUMED" -> decode.success(Resumed)
    "RATE_LIMITED" -> {
      use rate_limited <- decode.then(rate_limited_message_decoder())
      decode.success(RateLimited(rate_limited))
    }
    "APPLICATION_COMMAND_PERMISSIONS_UPDATE" -> {
      use perms <- decode.then(application_command.permissions_decoder())
      decode.success(ApplicationCommandPermissionsUpdated(perms))
    }
    "AUTO_MODERATION_RULE_CREATE" -> {
      use rule <- decode.then(auto_moderation.rule_decoder())
      decode.success(AutoModerationRuleCreated(rule))
    }
    "AUTO_MODERATION_RULE_UPDATE" -> {
      use rule <- decode.then(auto_moderation.rule_decoder())
      decode.success(AutoModerationRuleUpdated(rule))
    }
    "AUTO_MODERATION_RULE_DELETE" -> {
      use rule <- decode.then(auto_moderation.rule_decoder())
      decode.success(AutoModerationRuleDeleted(rule))
    }
    "AUTO_MODERATION_ACTION_EXECUTION" -> {
      use msg <- decode.then(auto_moderation_action_executed_message_decoder())
      decode.success(AutoModerationActionExecuted(msg))
    }
    "CHANNEL_CREATE" -> {
      use channel <- decode.then(channel.decoder())
      decode.success(ChannelCreated(channel))
    }
    "CHANNEL_UPDATE" -> {
      use channel <- decode.then(channel.decoder())
      decode.success(ChannelUpdated(channel))
    }
    "CHANNEL_DELETE" -> {
      use channel <- decode.then(channel.decoder())
      decode.success(ChannelDeleted(channel))
    }
    "THREAD_CREATE" -> {
      use msg <- decode.then(thread_created_message_decoder())
      decode.success(ThreadCreated(msg))
    }
    "THREAD_UPDATE" -> {
      use thread <- decode.then(thread.decoder())
      decode.success(ThreadUpdated(thread))
    }
    "THREAD_DELETE" -> {
      use msg <- decode.then(thread_deleted_message_decoder())
      decode.success(ThreadDeleted(msg))
    }
    "THREAD_LIST_SYNC" -> {
      use msg <- decode.then(thread_list_synced_message_decoder())
      decode.success(ThreadListSynced(msg))
    }
    "THREAD_MEMBER_UPDATE" -> {
      use msg <- decode.then(thread_member_updated_message_decoder())
      decode.success(ThreadMemberUpdated(msg))
    }
    "PRESENCE_UPDATE" -> {
      use msg <- decode.then(presence_updated_message_decoder())
      decode.success(PresenceUpdated(msg))
    }
    "THREAD_MEMBERS_UPDATE" -> {
      use msg <- decode.then(thread_members_updated_message_decoder())
      decode.success(ThreadMembersUpdated(msg))
    }
    "CHANNEL_PINS_UPDATE" -> {
      use msg <- decode.then(channel_pins_updated_message_decoder())
      decode.success(ChannelPinsUpdated(msg))
    }
    "ENTITLEMENT_CREATE" -> {
      use entitlement <- decode.then(entitlement.decoder())
      decode.success(EntitlementCreated(entitlement))
    }
    "ENTITLEMENT_UPDATE" -> {
      use entitlement <- decode.then(entitlement.decoder())
      decode.success(EntitlementUpdated(entitlement))
    }
    "ENTITLEMENT_DELETE" -> {
      use entitlement <- decode.then(entitlement.decoder())
      decode.success(EntitlementDeleted(entitlement))
    }
    "GUILD_CREATE" -> {
      use msg <- decode.then(guild_created_message_decoder())
      decode.success(GuildCreated(msg))
    }
    "GUILD_UPDATE" -> {
      use guild <- decode.then(guild.decoder())
      decode.success(GuildUpdated(guild))
    }
    "GUILD_DELETE" -> {
      use guild <- decode.then(guild.unavailable_guild_decoder())
      decode.success(GuildDeleted(guild))
    }
    "GUILD_AUDIT_LOG_ENTRY_CREATE" -> {
      use msg <- decode.then(audit_log_entry_created_message_decoder())
      decode.success(AuditLogEntryCreated(msg))
    }
    "GUILD_BAN_ADD" -> {
      use msg <- decode.then(guild_ban_message_decoder())
      decode.success(GuildBanCreated(msg))
    }
    "GUILD_BAN_REMOVE" -> {
      use msg <- decode.then(guild_ban_message_decoder())
      decode.success(GuildBanDeleted(msg))
    }
    "GUILD_EMOJIS_UPDATE" -> {
      use msg <- decode.then(guild_emojis_updated_message_decoder())
      decode.success(GuildEmojisUpdated(msg))
    }
    "GUILD_STICKERS_UPDATE" -> {
      use msg <- decode.then(guild_stickers_updated_message_decoder())
      decode.success(GuildStickersUpdated(msg))
    }
    "GUILD_INTEGRATIONS_UPDATE" -> {
      use msg <- decode.then(guild_integrations_updated_message_decoder())
      decode.success(GuildIntegrationsUpdated(msg))
    }
    "GUILD_MEMBER_ADD" -> {
      use msg <- decode.then(guild_member_created_message_decoder())
      decode.success(GuildMemberCreated(msg))
    }
    "GUILD_MEMBER_REMOVE" -> {
      use msg <- decode.then(guild_member_deleted_message_decoder())
      decode.success(GuildMemberDeleted(msg))
    }
    "GUILD_MEMBER_UPDATE" -> {
      use msg <- decode.then(guild_member_updated_message_decoder())
      decode.success(GuildMemberUpdated(msg))
    }
    "GUILD_MEMBERS_CHUNK" -> {
      use msg <- decode.then(guild_members_chunk_message_decoder())
      decode.success(GuildMembersChunk(msg))
    }
    "GUILD_ROLE_CREATE" -> {
      use msg <- decode.then(role_created_message_decoder())
      decode.success(RoleCreated(msg))
    }
    "GUILD_ROLE_UPDATE" -> {
      use msg <- decode.then(role_updated_message_decoder())
      decode.success(RoleUpdated(msg))
    }
    "GUILD_ROLE_DELETE" -> {
      use msg <- decode.then(role_deleted_message_decoder())
      decode.success(RoleDeleted(msg))
    }
    "GUILD_SCHEDULED_EVENT_CREATE" -> {
      use event <- decode.then(scheduled_event.decoder())
      decode.success(ScheduledEventCreated(event))
    }
    "GUILD_SCHEDULED_EVENT_UPDATE" -> {
      use event <- decode.then(scheduled_event.decoder())
      decode.success(ScheduledEventUpdated(event))
    }
    "GUILD_SCHEDULED_EVENT_DELETE" -> {
      use event <- decode.then(scheduled_event.decoder())
      decode.success(ScheduledEventDeleted(event))
    }
    "GUILD_SCHEDULED_EVENT_USER_ADD" -> {
      use msg <- decode.then(scheduled_event_user_message_decoder())
      decode.success(ScheduledEventUserCreated(msg))
    }
    "GUILD_SCHEDULED_EVENT_USER_REMOVE" -> {
      use msg <- decode.then(scheduled_event_user_message_decoder())
      decode.success(ScheduledEventUserDeleted(msg))
    }
    _ -> decode.failure(Resumed, "DispatchedMessage")
  }
}

@internal
pub fn auto_moderation_action_executed_message_decoder() -> decode.Decoder(
  AutoModerationActionExecutedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use action <- decode.field("action", auto_moderation.action_decoder())
  use rule_id <- decode.field("rule_id", decode.string)
  use rule_trigger_type <- decode.field(
    "rule_trigger_type",
    auto_moderation.trigger_type_decoder(),
  )
  use user_id <- decode.field("user_id", decode.string)
  use channel_id <- decode.optional_field(
    "channel_id",
    None,
    decode.optional(decode.string),
  )
  use message_id <- decode.optional_field(
    "message_id",
    None,
    decode.optional(decode.string),
  )
  use alert_system_message_id <- decode.optional_field(
    "alert_system_message_id",
    None,
    decode.optional(decode.string),
  )
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.string),
  )
  use matched_keyword <- decode.field(
    "matched_keyword",
    decode.optional(decode.string),
  )
  use matched_content <- decode.optional_field(
    "matched_content",
    None,
    decode.optional(decode.string),
  )

  decode.success(AutoModerationActionExecutedMessage(
    guild_id:,
    action:,
    rule_id:,
    rule_trigger_type:,
    user_id:,
    channel_id:,
    message_id:,
    alert_system_message_id:,
    content:,
    matched_keyword:,
    matched_content:,
  ))
}

@internal
pub fn thread_created_message_decoder() -> decode.Decoder(ThreadCreatedMessage) {
  use thread <- decode.then(thread.decoder())
  use is_newly_created <- decode.optional_field(
    "newly_created",
    False,
    decode.bool,
  )

  decode.success(ThreadCreatedMessage(thread:, is_newly_created:))
}

@internal
pub fn thread_deleted_message_decoder() -> decode.Decoder(ThreadDeletedMessage) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use parent_id <- decode.field("parent_id", decode.string)
  use type_ <- decode.field("type", thread.type_decoder())

  decode.success(ThreadDeletedMessage(id:, guild_id:, parent_id:, type_:))
}

@internal
pub fn thread_list_synced_message_decoder() -> decode.Decoder(
  ThreadListSyncedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use channel_ids <- decode.optional_field(
    "channel_ids",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use threads <- decode.field("threads", decode.list(thread.decoder()))
  use members <- decode.field("members", decode.list(thread.member_decoder()))

  decode.success(ThreadListSyncedMessage(
    guild_id:,
    channel_ids:,
    threads:,
    members:,
  ))
}

@internal
pub fn thread_member_updated_message_decoder() -> decode.Decoder(
  ThreadMemberUpdatedMessage,
) {
  use thread_member <- decode.then(thread.member_decoder())
  use guild_id <- decode.field("guild_id", decode.string)

  decode.success(ThreadMemberUpdatedMessage(thread_member:, guild_id:))
}

@internal
pub fn rate_limited_message_decoder() -> decode.Decoder(RateLimitedMessage) {
  use limited_opcode <- decode.field("opcode", decode.int)
  use retry_after <- decode.field(
    "retry_after",
    time_duration.from_float_seconds_decoder(),
  )
  use metadata <- decode.field("meta", case limited_opcode {
    8 -> request_guild_members_rate_limited_decoder()
    _ ->
      decode.failure(
        RequestGuildMembersRateLimited("", None),
        "RateLimitedMetadata",
      )
  })

  decode.success(RateLimitedMessage(limited_opcode:, retry_after:, metadata:))
}

@internal
pub fn request_guild_members_rate_limited_decoder() -> decode.Decoder(
  RateLimitedMetadata,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use nonce <- decode.optional_field(
    "nonce",
    None,
    decode.optional(decode.string),
  )

  decode.success(RequestGuildMembersRateLimited(guild_id:, nonce:))
}

@internal
pub fn hello_event_decoder() -> decode.Decoder(HelloMessage) {
  use heartbeat_interval <- decode.field(
    "heartbeat_interval",
    time_duration.from_milliseconds_decoder(),
  )

  decode.success(HelloMessage(heartbeat_interval:))
}

@internal
pub fn ready_message_decoder() -> decode.Decoder(ReadyMessage) {
  use api_version <- decode.field("v", decode.int)
  use user <- decode.field("user", user.decoder())
  use guilds <- decode.field(
    "guilds",
    decode.list(of: guild.unavailable_guild_decoder()),
  )
  use session_id <- decode.field("session_id", decode.string)
  use resume_gateway_url <- decode.field("resume_gateway_url", decode.string)
  use shard <- decode.optional_field(
    "shard",
    None,
    decode.optional(shard_decoder()),
  )
  use application <- decode.field("application", ready_application_decoder())

  decode.success(ReadyMessage(
    api_version:,
    user:,
    guilds:,
    session_id:,
    resume_gateway_url:,
    shard:,
    application:,
  ))
}

@internal
pub fn shard_decoder() -> decode.Decoder(Shard) {
  use id <- decode.field(0, decode.int)
  use num_shards <- decode.field(1, decode.int)
  decode.success(Shard(id:, num_shards:))
}

@internal
pub fn ready_application_decoder() -> decode.Decoder(ReadyApplication) {
  use id <- decode.field("id", decode.string)
  use flags <- decode.field("flags", flags.decoder(application.bits_flags()))
  decode.success(ReadyApplication(id:, flags:))
}

@internal
pub fn presence_updated_message_decoder() -> decode.Decoder(
  PresenceUpdatedMessage,
) {
  use user_id <- decode.field("user_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use status <- decode.field("status", decode.string)
  use activities <- decode.field(
    "activities",
    decode.list(received_activity_decoder()),
  )
  use client_status <- decode.field("client_status", client_status_decoder())
  decode.success(PresenceUpdatedMessage(
    user_id:,
    guild_id:,
    status:,
    activities:,
    client_status:,
  ))
}

pub fn received_activity_decoder() -> decode.Decoder(ReceivedActivity) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", activity.type_decoder())
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use created_at <- decode.field(
    "created_at",
    time_timestamp.from_unix_milliseconds_decoder(),
  )
  use timestamps <- decode.optional_field(
    "timestamps",
    None,
    decode.optional(activity.timestamps_decoder()),
  )
  use application_id <- decode.optional_field(
    "application_id",
    None,
    decode.optional(decode.string),
  )
  use status_display_type <- decode.optional_field(
    "status_display_type",
    None,
    decode.optional(activity.display_type_decoder()),
  )
  use details <- decode.optional_field(
    "details",
    None,
    decode.optional(decode.string),
  )
  use details_url <- decode.optional_field(
    "details_url",
    None,
    decode.optional(decode.string),
  )
  use state <- decode.optional_field(
    "state",
    None,
    decode.optional(decode.string),
  )
  use state_url <- decode.optional_field(
    "state_url",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(activity.emoji_decoder()),
  )
  use party <- decode.optional_field(
    "party",
    None,
    decode.optional(activity.party_decoder()),
  )
  use assets <- decode.optional_field(
    "assets",
    None,
    decode.optional(activity.assets_decoder()),
  )
  use secrets <- decode.optional_field(
    "secrets",
    None,
    decode.optional(activity.secrets_decoder()),
  )
  use is_instance <- decode.field("instance", decode.optional(decode.bool))
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(activity.bits_flags())),
  )
  use button_labels <- decode.optional_field(
    "buttons",
    None,
    decode.optional(decode.list(decode.string)),
  )

  decode.success(ReceivedActivity(
    name:,
    type_:,
    url:,
    created_at:,
    timestamps:,
    application_id:,
    status_display_type:,
    details:,
    details_url:,
    state:,
    state_url:,
    emoji:,
    party:,
    assets:,
    secrets:,
    is_instance:,
    flags:,
    button_labels:,
  ))
}

@internal
pub fn client_status_decoder() -> decode.Decoder(ClientStatus) {
  use desktop <- decode.optional_field(
    "desktop",
    None,
    decode.optional(decode.string),
  )
  use mobile <- decode.optional_field(
    "mobile",
    None,
    decode.optional(decode.string),
  )
  use web <- decode.optional_field("web", None, decode.optional(decode.string))

  decode.success(ClientStatus(desktop:, mobile:, web:))
}

@internal
pub fn thread_members_updated_message_decoder() -> decode.Decoder(
  ThreadMembersUpdatedMessage,
) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use member_count <- decode.field("member_count", decode.int)
  use added_members <- decode.optional_field(
    "added_members",
    None,
    decode.optional(
      decode.list({
        use thread_member <- decode.then(thread.member_decoder())
        use presence <- decode.field(
          "presence",
          decode.optional(presence_updated_message_decoder()),
        )

        decode.success(#(thread_member, presence))
      }),
    ),
  )
  use removed_member_ids <- decode.optional_field(
    "removed_member_ids",
    None,
    decode.optional(decode.list(decode.string)),
  )

  decode.success(ThreadMembersUpdatedMessage(
    id:,
    guild_id:,
    member_count:,
    added_members:,
    removed_member_ids:,
  ))
}

@internal
pub fn channel_pins_updated_message_decoder() -> decode.Decoder(
  ChannelPinsUpdatedMessage,
) {
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use channel_id <- decode.field("channel_id", decode.string)
  use last_pin_timestamp <- decode.optional_field(
    "last_pin_timestamp",
    None,
    decode.optional(time_rfc3339.decoder()),
  )

  decode.success(ChannelPinsUpdatedMessage(
    guild_id:,
    channel_id:,
    last_pin_timestamp:,
  ))
}

@internal
pub fn guild_created_message_decoder() -> decode.Decoder(GuildCreatedMessage) {
  let unavailable_guild_decoder = {
    use unavailable_guild <- decode.then(guild.unavailable_guild_decoder())
    decode.success(UnavailableGuildCreatedMessage(unavailable_guild))
  }

  let available_guild_decoder = {
    use guild <- decode.then(guild.decoder())
    use joined_at <- decode.field("joined_at", time_rfc3339.decoder())
    use is_large <- decode.field("large", decode.bool)
    use member_count <- decode.field("member_count", decode.int)
    use voice_states <- decode.field(
      "voice_states",
      decode.list(voice.state_decoder()),
    )
    use members <- decode.field("members", decode.list(guild_member.decoder()))
    use channels <- decode.field("channels", decode.list(channel.decoder()))
    use threads <- decode.field("threads", decode.list(thread.decoder()))
    use presences <- decode.field(
      "presences",
      decode.list(presence_updated_message_decoder()),
    )
    use stage_instances <- decode.field(
      "stage_instances",
      decode.list(stage_instance.decoder()),
    )
    use scheduled_events <- decode.field(
      "guild_scheduled_events",
      decode.list(scheduled_event.decoder()),
    )
    use soundboard_sounds <- decode.field(
      "soundboard_sounds",
      decode.list(soundboard.sound_decoder()),
    )

    decode.success(GuildCreatedMessage(
      guild:,
      joined_at:,
      is_large:,
      member_count:,
      voice_states:,
      members:,
      channels:,
      threads:,
      presences:,
      stage_instances:,
      scheduled_events:,
      soundboard_sounds:,
    ))
  }

  decode.one_of(available_guild_decoder, or: [unavailable_guild_decoder])
}

@internal
pub fn audit_log_entry_created_message_decoder() -> decode.Decoder(
  AuditLogEntryCreatedMessage,
) {
  use entry <- decode.then(audit_log.entry_decoder())
  use guild_id <- decode.field("guild_id", decode.string)

  decode.success(AuditLogEntryCreatedMessage(entry:, guild_id:))
}

@internal
pub fn guild_ban_message_decoder() -> decode.Decoder(GuildBanMessage) {
  use guild_id <- decode.field("guild_id", decode.string)
  use user <- decode.field("user", user.decoder())

  decode.success(GuildBanMessage(guild_id:, user:))
}

@internal
pub fn guild_emojis_updated_message_decoder() -> decode.Decoder(
  GuildEmojisUpdatedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use emojis <- decode.field("emojis", decode.list(emoji.decoder()))
  decode.success(GuildEmojisUpdatedMessage(guild_id:, emojis:))
}

@internal
pub fn guild_stickers_updated_message_decoder() -> decode.Decoder(
  GuildStickersUpdatedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use stickers <- decode.field("stickers", decode.list(sticker.decoder()))
  decode.success(GuildStickersUpdatedMessage(guild_id:, stickers:))
}

@internal
pub fn guild_integrations_updated_message_decoder() -> decode.Decoder(
  GuildIntegrationsUpdatedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(GuildIntegrationsUpdatedMessage(guild_id:))
}

@internal
pub fn guild_member_created_message_decoder() -> decode.Decoder(
  GuildMemberCreatedMessage,
) {
  use guild_member <- decode.then(guild_member.decoder())
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(GuildMemberCreatedMessage(guild_id:, guild_member:))
}

@internal
pub fn guild_member_deleted_message_decoder() -> decode.Decoder(
  GuildMemberDeletedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use user <- decode.field("user", user.decoder())
  decode.success(GuildMemberDeletedMessage(guild_id:, user:))
}

@internal
pub fn guild_member_updated_message_decoder() -> decode.Decoder(
  GuildMemberUpdatedMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use role_ids <- decode.field("roles", decode.list(decode.string))
  use user <- decode.field("user", user.decoder())
  use nick <- decode.field("nick", modification.decoder(decode.string))
  use avatar_hash <- decode.field("avatar", decode.optional(decode.string))
  use banner_hash <- decode.field("banner", decode.optional(decode.string))
  use joined_at <- decode.field(
    "joined_at",
    decode.optional(time_rfc3339.decoder()),
  )
  use premium_since <- decode.field(
    "premium_since",
    decode.optional(time_rfc3339.decoder()),
  )
  use is_deaf <- decode.field("deaf", decode.optional(decode.bool))
  use is_mute <- decode.field("mute", decode.optional(decode.bool))
  use is_pending <- decode.field("pending", decode.optional(decode.bool))
  use communication_disabled_until <- decode.field(
    "communication_disabled_until",
    modification.decoder(time_rfc3339.decoder()),
  )
  use flags <- decode.field(
    "flags",
    decode.optional(flags.decoder(guild_member.bits_member_flags())),
  )
  use avatar_decoration_data <- decode.field(
    "avatar_decoration_data",
    modification.decoder(user.avatar_decoration_data_decoder()),
  )
  decode.success(GuildMemberUpdatedMessage(
    guild_id:,
    role_ids:,
    user:,
    nick:,
    avatar_hash:,
    banner_hash:,
    joined_at:,
    premium_since:,
    is_deaf:,
    is_mute:,
    is_pending:,
    communication_disabled_until:,
    flags:,
    avatar_decoration_data:,
  ))
}

@internal
pub fn guild_members_chunk_message_decoder() -> decode.Decoder(
  GuildMembersChunkMessage,
) {
  use guild_id <- decode.field("guild_id", decode.string)
  use members <- decode.field("members", decode.list(guild_member.decoder()))
  use chunk_index <- decode.field("chunk_index", decode.int)
  use chunk_count <- decode.field("chunk_count", decode.int)
  use not_found_ids <- decode.optional_field(
    "not_found",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use presences <- decode.optional_field(
    "presences",
    None,
    decode.optional(decode.list(presence_updated_message_decoder())),
  )
  use nonce <- decode.field("nonce", decode.optional(decode.string))
  decode.success(GuildMembersChunkMessage(
    guild_id:,
    members:,
    chunk_index:,
    chunk_count:,
    not_found_ids:,
    presences:,
    nonce:,
  ))
}

@internal
pub fn role_created_message_decoder() -> decode.Decoder(RoleCreatedMessage) {
  use guild_id <- decode.field("guild_id", decode.string)
  use role <- decode.field("role", role.decoder())
  decode.success(RoleCreatedMessage(guild_id:, role:))
}

@internal
pub fn role_updated_message_decoder() -> decode.Decoder(RoleUpdatedMessage) {
  use guild_id <- decode.field("guild_id", decode.string)
  use role <- decode.field("role", role.decoder())
  decode.success(RoleUpdatedMessage(guild_id:, role:))
}

@internal
pub fn role_deleted_message_decoder() -> decode.Decoder(RoleDeletedMessage) {
  use guild_id <- decode.field("guild_id", decode.string)
  use role_id <- decode.field("role_id", decode.string)
  decode.success(RoleDeletedMessage(guild_id:, role_id:))
}

@internal
pub fn scheduled_event_user_message_decoder() -> decode.Decoder(
  ScheduledEventUserMessage,
) {
  use scheduled_event_id <- decode.field(
    "guild_scheduled_event_id",
    decode.string,
  )
  use user_id <- decode.field("user_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(ScheduledEventUserMessage(
    scheduled_event_id:,
    user_id:,
    guild_id:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn message_to_json(message: SentMessage) -> Json {
  case message {
    Heartbeat(msg) -> heartbeat_to_json(msg)
    Identify(msg) -> identify_to_json(msg)
    Resume(msg) -> resume_to_json(msg)
  }
}

fn resume_to_json(message: ResumeMessage) -> Json {
  json.object([
    #("op", json.int(6)),
    #(
      "d",
      json.object([
        #("token", json.string(message.token)),
        #("session_id", json.string(message.session_id)),
        #("seq", json.int(message.last_sequence)),
      ]),
    ),
  ])
}

fn identify_to_json(msg: IdentifyMessage) -> Json {
  let data = {
    let token = [#("token", json.string(msg.token))]

    let properties = [
      #("properties", identify_properties_to_json(msg.properties)),
    ]

    let supports_compression = [
      #("compress", json.bool(msg.supports_compression)),
    ]

    let max_offline_members = case msg.max_offline_members {
      Some(threshold) -> [#("large_threshold", json.int(threshold))]
      None -> []
    }

    let shard = case msg.shard {
      Some(shard) -> [
        #("shard", json.array([shard.id, shard.num_shards], json.int)),
      ]
      None -> []
    }

    let presence = case msg.presence {
      Some(presence) -> [
        #("presence", user_message.update_presence_to_json(presence, False)),
      ]
      None -> []
    }

    let intents = [
      #("intents", flags.to_json(msg.intents, intent.bits_intents())),
    ]

    [
      token,
      properties,
      supports_compression,
      max_offline_members,
      shard,
      presence,
      intents,
    ]
    |> list.flatten
    |> json.object
  }

  json.object([#("op", json.int(2)), #("d", data)])
}

fn identify_properties_to_json(properties: IdentifyProperties) -> Json {
  [
    #("os", json.string(properties.os)),
    #("browser", json.string(properties.browser)),
    #("device", json.string(properties.device)),
  ]
  |> json.object
}

fn heartbeat_to_json(heartbeat: HeartbeatMessage) -> Json {
  json.object([
    #("op", json.int(1)),
    #("d", json.nullable(heartbeat.last_sequence, json.int)),
  ])
}

// FUNCTIONS -------------------------------------------------------------------

pub fn get_data(client: grom.Client) -> Result(GatewayData, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/gateway/bot")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: data_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn start(
  client: grom.Client,
  identify: IdentifyMessage,
  notify actor: Subject(Event),
) {
  use state <- result.try(
    init_state(actor, identify)
    |> result.replace_error(actor.InitFailed("couldn't init state")),
  )

  use _ <- result.try(
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(supervised(client, state))
    |> static_supervisor.start,
  )

  Ok(state)
}

fn supervised(client: grom.Client, state: State) {
  state.connection_pid_holder
  |> connection_pid.set(to: process.self())

  let start = case resuming.get_info(state.resuming_info_holder) {
    Some(info) -> {
      case resuming.is_possible(info) {
        True -> resume(client, state, info)
        False -> new_connection(client, state)
      }
    }
    None -> new_connection(client, state)
  }

  let restart = supervision.Permanent
  let significant = False
  let child_type = supervision.Supervisor

  supervision.ChildSpecification(start:, restart:, significant:, child_type:)
}

fn new_connection(client: grom.Client, state: State) {
  fn() {
    use gateway_data <- result.try(
      client
      |> get_data
      |> result.replace_error(actor.InitFailed("couldn't get gateway data")),
    )

    let request_url =
      string.replace(in: gateway_data.url, each: "wss://", with: "https://")
      <> "?v=10&encoding=json"

    use connection_request <- result.try(
      request.to(request_url)
      |> result.replace_error(actor.InitFailed("couldn't parse connection url")),
    )

    heartbeat.reset(state.heartbeat_counter)
    sequence.reset(state.sequence_holder)
    resuming.reset(state.resuming_info_holder)

    use subject <- result.try(
      stratus.new(connection_request, state)
      |> stratus.on_message(fn(state, message, connection) {
        on_message(client, state, message, connection)
      })
      |> stratus.on_close(on_close)
      |> stratus.start
      |> result.replace_error(actor.InitFailed(
        "couldn't start websocket connection",
      )),
    )

    state.user_message_subject_holder
    |> user_message.set_subject(subject.data)

    Ok(subject)
  }
}

fn resume(client: grom.Client, state: State, info: resuming.Info) {
  fn() {
    use connection_request <- result.try(
      request.to(info.resume_gateway_url)
      |> result.replace_error(actor.InitFailed("couldn't parse connection url")),
    )

    use subject <- result.try(
      stratus.new(connection_request, state)
      |> stratus.on_message(fn(state, message, connection) {
        on_message(client, state, message, connection)
      })
      |> stratus.on_close(on_close)
      |> stratus.start
      |> result.replace_error(actor.InitFailed(
        "couldn't start websocket connection",
      )),
    )

    state.user_message_subject_holder
    |> user_message.set_subject(subject.data)

    process.send(
      subject.data,
      stratus.to_user_message(user_message.StartResume),
    )

    Ok(subject)
  }
}

fn on_close(state: State, close_reason: stratus.CloseReason) {
  let resuming_info = resuming.get_info(state.resuming_info_holder)
  let new_resuming_info = case resuming_info {
    Some(info) ->
      Some(
        resuming.Info(..info, last_received_close_reason: Some(close_reason)),
      )
    None -> None
  }

  state.resuming_info_holder
  |> resuming.set_info(to: new_resuming_info)

  // consult on if this is a bug, no idea tbh
  // i think it's impossible state for the connection_pid to be none by the time this function gets called
  // typing requires work, impossible states defined as possible values i think
  case connection_pid.get(state.connection_pid_holder) {
    Some(pid) -> process.kill(pid)
    None -> Nil
  }
}

pub fn identify(client: grom.Client, intents: List(Intent)) -> IdentifyMessage {
  IdentifyMessage(
    token: client.token,
    properties: IdentifyProperties(
      os: operating_system.name(),
      browser: "grom",
      device: "grom",
    ),
    supports_compression: False,
    max_offline_members: None,
    shard: None,
    presence: None,
    intents:,
  )
}

pub fn identify_with_presence(
  identify: IdentifyMessage,
  presence: UpdatePresenceMessage,
) -> IdentifyMessage {
  IdentifyMessage(..identify, presence: Some(presence))
}

pub fn update_presence(state: State, using message: UpdatePresenceMessage) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartPresenceUpdate(message)),
      )
    None -> Nil
  }
}

pub fn update_voice_state(state: State, using message: UpdateVoiceStateMessage) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartVoiceStateUpdate(message)),
      )
    None -> Nil
  }
}

pub fn request_guild_members(
  state: State,
  using message: RequestGuildMembersMessage,
) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartGuildMembersRequest(message)),
      )
    None -> Nil
  }
}

pub fn request_soundboard_sounds(state: State, for guild_ids: List(String)) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartSoundboardSoundsRequest(
          guild_ids:,
        )),
      )
    None -> Nil
  }
}

fn init_state(actor: Subject(Event), identify: IdentifyMessage) {
  use sequence_holder <- result.try(
    sequence.holder_start() |> result.map_error(string.inspect),
  )
  let sequence_holder = sequence_holder.data

  use heartbeat_counter <- result.try(
    heartbeat.counter_start() |> result.map_error(string.inspect),
  )
  let heartbeat_counter = heartbeat_counter.data

  use resuming_info_holder <- result.try(
    resuming.info_holder_start()
    |> result.map_error(string.inspect),
  )
  let resuming_info_holder = resuming_info_holder.data

  use user_message_subject_holder <- result.try(
    user_message.new_subject_holder(None)
    |> result.map_error(string.inspect),
  )
  let user_message_subject_holder = user_message_subject_holder.data

  use connection_pid_holder <- result.try(
    connection_pid.new_holder()
    |> result.map_error(string.inspect),
  )
  let connection_pid_holder = connection_pid_holder.data

  let state =
    State(
      actor:,
      sequence_holder:,
      heartbeat_counter:,
      resuming_info_holder:,
      identify:,
      user_message_subject_holder:,
      connection_pid_holder:,
    )

  Ok(state)
}

fn on_message(
  client: grom.Client,
  state: State,
  message: stratus.Message(UserMessage),
  connection: stratus.Connection,
) {
  case message {
    stratus.Text(text_message) ->
      on_text_message(state, connection, text_message)
    stratus.User(user_message.StartResume) ->
      start_resume(client, state, connection)
    stratus.User(user_message.StartPresenceUpdate(msg)) ->
      start_presence_update(state, connection, msg)
    stratus.User(user_message.StartVoiceStateUpdate(msg)) ->
      start_voice_state_update(state, connection, msg)
    stratus.User(user_message.StartGuildMembersRequest(msg)) ->
      start_guild_members_request(state, connection, msg)
    stratus.User(user_message.StartSoundboardSoundsRequest(guild_ids)) ->
      start_soundboard_sounds_request(state, connection, guild_ids)
    _ -> stratus.continue(state)
  }
}

fn start_guild_members_request(
  state: State,
  connection: stratus.Connection,
  msg: RequestGuildMembersMessage,
) {
  let _ =
    msg
    |> user_message.request_guild_members_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_voice_state_update(
  state: State,
  connection: stratus.Connection,
  msg: UpdateVoiceStateMessage,
) {
  let _ =
    msg
    |> user_message.update_voice_state_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_presence_update(
  state: State,
  connection: stratus.Connection,
  msg: UpdatePresenceMessage,
) {
  let _ =
    msg
    |> user_message.update_presence_to_json(True)
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_soundboard_sounds_request(
  state: State,
  connection: stratus.Connection,
  guild_ids: List(String),
) {
  let json =
    json.object([
      #("op", json.int(31)),
      #("d", json.object([#("guild_ids", json.array(guild_ids, json.string))])),
    ])

  let _ =
    json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn on_text_message(
  state: State,
  connection: stratus.Connection,
  text_message: String,
) {
  use message <-
    fn(next) {
      case parse_message(text_message) {
        Ok(msg) -> next(msg)
        Error(err) -> {
          actor.send(state.actor, ErrorEvent(err))
          stratus.continue(state)
        }
      }
    }

  case message {
    Hello(event) -> on_hello_event(state, connection, event)
    Dispatch(sequence, message) -> on_dispatch(state, sequence, message)
    HeartbeatAcknowledged -> on_heartbeat_acknowledged(state)
    HeartbeatRequest -> on_heartbeat_request(state, connection)
    ReconnectRequest -> on_reconnect_request(state, connection)
    InvalidSession(can_reconnect) ->
      on_invalid_session(state, connection, can_reconnect)
  }

  stratus.continue(state)
}

fn on_invalid_session(
  state: State,
  connection: stratus.Connection,
  can_reconnect: Bool,
) -> Nil {
  let _ = stratus.close(connection, because: stratus.NotProvided)

  let resuming_info = resuming.get_info(state.resuming_info_holder)

  case resuming_info, can_reconnect {
    Some(info), True ->
      resuming.set_info(
        state.resuming_info_holder,
        to: Some(
          resuming.Info(
            ..info,
            last_received_close_reason: Some(stratus.NotProvided),
          ),
        ),
      )
    Some(info), False ->
      resuming.set_info(
        state.resuming_info_holder,
        to: Some(resuming.Info(..info, last_received_close_reason: None)),
      )
    _, _ -> Nil
  }

  case connection_pid.get(state.connection_pid_holder) {
    Some(pid) -> process.kill(pid)
    None -> Nil
  }
}

fn on_reconnect_request(state: State, connection: stratus.Connection) -> Nil {
  let _ = stratus.close(connection, because: stratus.NotProvided)

  let resuming_info = resuming.get_info(state.resuming_info_holder)

  case resuming_info {
    Some(info) ->
      resuming.set_info(
        state.resuming_info_holder,
        to: Some(
          resuming.Info(
            ..info,
            last_received_close_reason: Some(stratus.NotProvided),
          ),
        ),
      )
    None -> Nil
  }

  case connection_pid.get(state.connection_pid_holder) {
    Some(pid) -> process.kill(pid)
    None -> Nil
  }
}

fn start_resume(
  client: grom.Client,
  state: State,
  connection: stratus.Connection,
) {
  let resuming_info = resuming.get_info(state.resuming_info_holder)
  let last_sequence = sequence.get(state.sequence_holder)

  let _ =
    case resuming_info, last_sequence {
      Some(info), Some(sequence) ->
        ResumeMessage(client.token, info.session_id, sequence)
      // unreachable - we need to have gotten the ready event otherwise we wouldn't even get here
      // really reconsidering my typing choices
      _, _ -> ResumeMessage("", "", 0)
    }
    |> resume_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  let heartbeat_counter = heartbeat.get(state.heartbeat_counter)

  start_heartbeats(state, connection, heartbeat_counter.interval)

  stratus.continue(state)
}

fn on_dispatch(state: State, sequence: Int, message: DispatchedMessage) {
  state.sequence_holder
  |> sequence.set(to: Some(sequence))

  case message {
    Ready(msg) -> on_ready(state, msg)
    Resumed -> actor.send(state.actor, ResumedEvent)
    RateLimited(msg) -> actor.send(state.actor, RateLimitedEvent(msg))
    ApplicationCommandPermissionsUpdated(perms) ->
      actor.send(state.actor, ApplicationCommandPermissionsUpdatedEvent(perms))
    AutoModerationRuleCreated(rule) ->
      actor.send(state.actor, AutoModerationRuleCreatedEvent(rule))
    AutoModerationRuleUpdated(rule) ->
      actor.send(state.actor, AutoModerationRuleUpdatedEvent(rule))
    AutoModerationRuleDeleted(rule) ->
      actor.send(state.actor, AutoModerationRuleDeletedEvent(rule))
    AutoModerationActionExecuted(msg) ->
      actor.send(state.actor, AutoModerationActionExecutedEvent(msg))
    ChannelCreated(channel) ->
      actor.send(state.actor, ChannelCreatedEvent(channel))
    ChannelUpdated(channel) ->
      actor.send(state.actor, ChannelUpdatedEvent(channel))
    ChannelDeleted(channel) ->
      actor.send(state.actor, ChannelDeletedEvent(channel))
    ThreadCreated(msg) -> actor.send(state.actor, ThreadCreatedEvent(msg))
    ThreadUpdated(thread) -> actor.send(state.actor, ThreadUpdatedEvent(thread))
    ThreadDeleted(msg) -> actor.send(state.actor, ThreadDeletedEvent(msg))
    ThreadListSynced(msg) -> actor.send(state.actor, ThreadListSyncedEvent(msg))
    ThreadMemberUpdated(msg) ->
      actor.send(state.actor, ThreadMemberUpdatedEvent(msg))
    PresenceUpdated(msg) -> actor.send(state.actor, PresenceUpdatedEvent(msg))
    ThreadMembersUpdated(msg) ->
      actor.send(state.actor, ThreadMembersUpdatedEvent(msg))
    ChannelPinsUpdated(msg) ->
      actor.send(state.actor, ChannelPinsUpdatedEvent(msg))
    EntitlementCreated(entitlement) ->
      actor.send(state.actor, EntitlementCreatedEvent(entitlement))
    EntitlementUpdated(entitlement) ->
      actor.send(state.actor, EntitlementUpdatedEvent(entitlement))
    EntitlementDeleted(entitlement) ->
      actor.send(state.actor, EntitlementDeletedEvent(entitlement))
    GuildCreated(msg) -> actor.send(state.actor, GuildCreatedEvent(msg))
    GuildUpdated(guild) -> actor.send(state.actor, GuildUpdatedEvent(guild))
    GuildDeleted(guild) -> actor.send(state.actor, GuildDeletedEvent(guild))
    AuditLogEntryCreated(msg) ->
      actor.send(state.actor, AuditLogEntryCreatedEvent(msg))
    GuildBanCreated(msg) -> actor.send(state.actor, GuildBanCreatedEvent(msg))
    GuildBanDeleted(msg) -> actor.send(state.actor, GuildBanDeletedEvent(msg))
    GuildEmojisUpdated(msg) ->
      actor.send(state.actor, GuildEmojisUpdatedEvent(msg))
    GuildStickersUpdated(msg) ->
      actor.send(state.actor, GuildStickersUpdatedEvent(msg))
    GuildIntegrationsUpdated(msg) ->
      actor.send(state.actor, GuildIntegrationsUpdatedEvent(msg))
    GuildMemberCreated(msg) ->
      actor.send(state.actor, GuildMemberCreatedEvent(msg))
    GuildMemberDeleted(msg) ->
      actor.send(state.actor, GuildMemberDeletedEvent(msg))
    GuildMemberUpdated(msg) ->
      actor.send(state.actor, GuildMemberUpdatedEvent(msg))
    GuildMembersChunk(msg) ->
      actor.send(state.actor, GuildMembersChunkEvent(msg))
    RoleCreated(msg) -> actor.send(state.actor, RoleCreatedEvent(msg))
    RoleUpdated(msg) -> actor.send(state.actor, RoleUpdatedEvent(msg))
    RoleDeleted(msg) -> actor.send(state.actor, RoleDeletedEvent(msg))
    ScheduledEventCreated(event) ->
      actor.send(state.actor, ScheduledEventCreatedEvent(event))
    ScheduledEventUpdated(event) ->
      actor.send(state.actor, ScheduledEventUpdatedEvent(event))
    ScheduledEventDeleted(event) ->
      actor.send(state.actor, ScheduledEventDeletedEvent(event))
    ScheduledEventUserCreated(msg) ->
      actor.send(state.actor, ScheduledEventUserCreatedEvent(msg))
    ScheduledEventUserDeleted(msg) ->
      actor.send(state.actor, ScheduledEventUserDeletedEvent(msg))
  }
}

fn on_ready(state: State, message: ReadyMessage) {
  state.resuming_info_holder
  |> resuming.set_info(
    to: Some(resuming.Info(
      session_id: message.session_id,
      resume_gateway_url: message.resume_gateway_url,
      last_received_close_reason: Some(stratus.NotProvided),
    )),
  )

  state.actor
  |> actor.send(ReadyEvent(message))
}

fn on_heartbeat_request(state: State, connection: stratus.Connection) -> Nil {
  case send_heartbeat(state, connection) {
    Ok(_) -> Nil
    Error(err) -> {
      state.actor
      |> actor.send(ErrorEvent(err))
    }
  }
}

fn on_heartbeat_acknowledged(state: State) -> Nil {
  state.heartbeat_counter
  |> heartbeat.acknoweledged
}

fn on_hello_event(
  state: State,
  connection: stratus.Connection,
  event: HelloMessage,
) {
  start_heartbeats(state, connection, event.heartbeat_interval)
  send_identify(state, connection)
}

fn send_identify(state: State, connection: stratus.Connection) {
  let result =
    state.identify
    |> identify_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case result {
    Ok(_) -> Nil
    Error(error) -> actor.send(state.actor, ErrorEvent(error))
  }
}

/// returns the pid of the process taking care of the heartbeat loop
fn start_heartbeats(
  state: State,
  connection: stratus.Connection,
  interval: Duration,
) {
  state.heartbeat_counter
  |> heartbeat.interval(interval)

  let regular_wait_duration =
    interval
    |> duration.to_seconds
    |> float.multiply(1000.0)
    |> float.round

  let initial_wait_duration =
    interval
    |> duration.to_seconds
    |> float.multiply(1000.0)
    |> float.multiply(jitter())
    |> float.round

  process.spawn(fn() {
    process.sleep(initial_wait_duration)

    use <-
      fn(next) {
        case
          send_heartbeat(state, connection)
          |> result.map_error(grom.CouldNotStartHeartbeatCycle)
        {
          Ok(_) -> next()
          Error(error) -> actor.send(state.actor, ErrorEvent(error))
        }
      }

    repeatedly.call(regular_wait_duration, Nil, fn(_state, _i) {
      case send_heartbeat(state, connection) {
        Ok(_) -> Nil
        Error(error) -> actor.send(state.actor, ErrorEvent(error))
      }
    })
    Nil
  })
}

fn send_heartbeat(
  state: State,
  connection: stratus.Connection,
) -> Result(Nil, grom.Error) {
  let last_sequence = sequence.get(state.sequence_holder)

  let counter = heartbeat.get(state.heartbeat_counter)
  use <- bool.guard(
    when: counter.heartbeat != counter.heartbeat_ack,
    return: stratus.close(connection, stratus.UnexpectedCondition(<<>>))
      |> result.map_error(grom.CouldNotCloseWebsocketConnection),
  )

  use _nil <- result.try(
    last_sequence
    |> HeartbeatMessage
    |> heartbeat_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent),
  )

  Ok(heartbeat.sent(state.heartbeat_counter))
}

fn parse_message(text_message: String) -> Result(ReceivedMessage, grom.Error) {
  text_message
  |> json.parse(using: message_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

fn jitter() -> Float {
  case float.random() {
    0.0 -> jitter()
    jitter -> jitter
  }
}

pub fn receive_opcode(event: ReceivedMessage) -> Int {
  case event {
    Dispatch(..) -> 0
    Hello(..) -> 10
    HeartbeatAcknowledged -> 11
    HeartbeatRequest -> 1
    ReconnectRequest -> 7
    InvalidSession(..) -> 9
  }
}
