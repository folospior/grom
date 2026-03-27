import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/int
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
import grom/activity.{type Activity}
import grom/application
import grom/channel.{type Channel}
import grom/channel/thread.{type Thread}
import grom/command
import grom/emoji.{type Emoji}
import grom/entitlement.{type Entitlement}
import grom/gateway/intent.{type Intent}
import grom/guild.{type Guild}
import grom/guild/audit_log
import grom/guild/auto_moderation
import grom/guild/integration.{type Integration}
import grom/guild/role.{type Role}
import grom/guild/scheduled_event.{type ScheduledEvent}
import grom/guild_member.{type GuildMember}
import grom/interaction.{type Interaction}
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/internal/time_timestamp
import grom/invite
import grom/message
import grom/message/reaction
import grom/modification.{type Modification, Skip}
import grom/soundboard
import grom/stage_instance.{type StageInstance}
import grom/sticker.{type Sticker}
import grom/subscription.{type Subscription}
import grom/user.{type User, User}
import grom/voice
import operating_system
import stratus

// TYPES -----------------------------------------------------------------------

pub type Data {
  Data(
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
  AllShardsReadyEvent(AllShardsReadyMessage)
  ErrorEvent(grom.Error)
  ResumedEvent
  RateLimitedEvent(RateLimitedMessage)
  ApplicationCommandPermissionsUpdatedEvent(command.GuildPermissions)
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
  /// Could not test decoding. Please report any attempts in issues.
  ThreadMemberUpdatedEvent(ThreadMemberUpdatedMessage)
  PresenceUpdatedEvent(PresenceUpdatedMessage)
  ThreadMembersUpdatedEvent(ThreadMembersUpdatedMessage)
  ChannelPinsUpdatedEvent(ChannelPinsUpdatedMessage)
  /// Could not test decoding. Please report any attempts in issues.
  EntitlementCreatedEvent(Entitlement)
  /// Could not test decoding. Please report any attempts in issues.
  EntitlementUpdatedEvent(Entitlement)
  /// Could not test decoding. Please report any attempts in issues.
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
  GuildSoundboardSoundCreatedEvent(soundboard.Sound)
  GuildSoundboardSoundUpdatedEvent(soundboard.Sound)
  GuildSoundboardSoundDeletedEvent(GuildSoundboardSoundDeletedMessage)
  GuildSoundboardSoundsUpdatedEvent(GuildSoundboardSoundsUpdatedMessage)
  /// Sent in response to [`request_soundboard_sounds`](#request_soundboard_sounds).
  SoundboardSoundsEvent(SoundboardSoundsMessage)
  IntegrationCreatedEvent(IntegrationCreatedMessage)
  IntegrationUpdatedEvent(IntegrationUpdatedMessage)
  IntegrationDeletedEvent(IntegrationDeletedMessage)
  InviteCreatedEvent(InviteCreatedMessage)
  InviteDeletedEvent(InviteDeletedMessage)
  MessageCreatedEvent(MessageCreatedMessage)
  MessageUpdatedEvent(MessageUpdatedMessage)
  MessageDeletedEvent(MessageDeletedMessage)
  MessagesBulkDeletedEvent(MessagesBulkDeletedMessage)
  MessageReactionCreatedEvent(MessageReactionCreatedMessage)
  MessageReactionDeletedEvent(MessageReactionDeletedMessage)
  MessageAllReactionsDeletedEvent(MessageAllReactionsDeletedMessage)
  MessageEmojiReactionsDeletedEvent(MessageEmojiReactionsDeletedMessage)
  TypingStartedEvent(TypingStartedMessage)
  CurrentUserUpdatedEvent(User)
  VoiceChannelEffectSentEvent(VoiceChannelEffectSentMessage)
  VoiceStateUpdatedEvent(voice.State)
  VoiceServerUpdatedEvent(VoiceServerUpdatedMessage)
  InteractionCreatedEvent(Interaction)
  StageInstanceCreatedEvent(StageInstance)
  StageInstanceUpdatedEvent(StageInstance)
  StageInstanceDeletedEvent(StageInstance)
  /// Could not test decoding. Please report any attempts in issues.
  SubscriptionCreatedEvent(Subscription)
  /// Could not test decoding. Please report any attempts in issues.
  SubscriptionUpdatedEvent(Subscription)
  /// Could not test decoding. Please report any attempts in issues.
  SubscriptionDeletedEvent(Subscription)
  PollVoteCreatedEvent(PollVoteCreatedMessage)
  PollVoteDeletedEvent(PollVoteDeletedMessage)
  UnknownEvent
}

pub type SessionStartLimits {
  SessionStartLimits(
    maximum_starts: Int,
    remaining_starts: Int,
    resets_after: Duration,
    max_identify_requests_per_5_seconds: Int,
  )
}

pub type ClientStatus {
  ClientStatus(
    desktop: Option(String),
    mobile: Option(String),
    web: Option(String),
  )
}

// RECEIVE EVENTS --------------------------------------------------------------

type ReceivedMessage {
  Hello(HelloMessage)
  Dispatch(sequence: Int, message: DispatchedMessage)
  HeartbeatAcknowledged
  HeartbeatRequest
  ReconnectRequest
  InvalidSession(can_reconnect: Bool)
}

type HelloMessage {
  HelloMessage(heartbeat_interval: Duration)
}

// RECEIVED DISPATCH EVENTS ----------------------------------------------------

type DispatchedMessage {
  Ready(ReadyMessage)
  Resumed
  RateLimited(RateLimitedMessage)
  ApplicationCommandPermissionsUpdated(command.GuildPermissions)
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
  GuildSoundboardSoundCreated(soundboard.Sound)
  GuildSoundboardSoundUpdated(soundboard.Sound)
  GuildSoundboardSoundDeleted(GuildSoundboardSoundDeletedMessage)
  GuildSoundboardSoundsUpdated(GuildSoundboardSoundsUpdatedMessage)
  SoundboardSounds(SoundboardSoundsMessage)
  IntegrationCreated(IntegrationCreatedMessage)
  IntegrationUpdated(IntegrationUpdatedMessage)
  IntegrationDeleted(IntegrationDeletedMessage)
  InviteCreated(InviteCreatedMessage)
  InviteDeleted(InviteDeletedMessage)
  MessageCreated(MessageCreatedMessage)
  MessageUpdated(MessageUpdatedMessage)
  MessageDeleted(MessageDeletedMessage)
  MessagesBulkDeleted(MessagesBulkDeletedMessage)
  MessageReactionCreated(MessageReactionCreatedMessage)
  MessageReactionDeleted(MessageReactionDeletedMessage)
  MessageAllReactionsDeleted(MessageAllReactionsDeletedMessage)
  MessageEmojiReactionsDeleted(MessageEmojiReactionsDeletedMessage)
  TypingStarted(TypingStartedMessage)
  CurrentUserUpdated(User)
  VoiceChannelEffectSent(VoiceChannelEffectSentMessage)
  VoiceStateUpdated(voice.State)
  VoiceServerUpdated(VoiceServerUpdatedMessage)
  InteractionCreated(Interaction)
  StageInstanceCreated(StageInstance)
  StageInstanceUpdated(StageInstance)
  StageInstanceDeleted(StageInstance)
  SubscriptionCreated(Subscription)
  SubscriptionUpdated(Subscription)
  SubscriptionDeleted(Subscription)
  PollVoteCreated(PollVoteCreatedMessage)
  PollVoteDeleted(PollVoteDeletedMessage)
  UnknownDispatchedMessage
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

pub type AllShardsReadyMessage {
  AllShardsReadyMessage(
    api_version: Int,
    user: User,
    guilds: List(guild.UnavailableGuild),
    application: ReadyApplication,
    shard_count: Int,
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
    user_id: Option(String),
    guild_id: Option(String),
    status: Option(String),
    activities: Option(List(Activity)),
    client_status: Option(ClientStatus),
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

pub type GuildSoundboardSoundDeletedMessage {
  GuildSoundboardSoundDeletedMessage(sound_id: String, guild_id: String)
}

pub type GuildSoundboardSoundsUpdatedMessage {
  GuildSoundboardSoundsUpdatedMessage(
    soundboard_sounds: List(soundboard.Sound),
    guild_id: String,
  )
}

pub type SoundboardSoundsMessage {
  SoundboardSoundsMessage(
    soundboard_sounds: List(soundboard.Sound),
    guild_id: String,
  )
}

pub type IntegrationCreatedMessage {
  IntegrationCreatedMessage(integration: Integration, guild_id: String)
}

pub type IntegrationUpdatedMessage {
  IntegrationUpdatedMessage(integration: Integration, guild_id: String)
}

pub type IntegrationDeletedMessage {
  IntegrationDeletedMessage(
    id: String,
    guild_id: String,
    application_id: Option(String),
  )
}

pub type InviteCreatedMessage {
  InviteCreatedMessage(
    channel_id: String,
    code: String,
    created_at: Timestamp,
    guild_id: Option(String),
    inviter: Option(User),
    max_age: Duration,
    max_uses: Int,
    target_type: Option(invite.TargetType),
    is_temporary: Bool,
    uses: Int,
    expires_at: Option(Timestamp),
  )
}

pub type InviteDeletedMessage {
  InviteDeletedMessage(
    channel_id: String,
    guild_id: Option(String),
    code: String,
  )
}

pub type MessageCreatedMessage {
  MessageCreatedMessage(
    message: message.Message,
    guild_id: Option(String),
    member: Option(GuildMember),
    mentions: List(User),
  )
}

pub type MessageUpdatedMessage {
  MessageUpdatedMessage(
    message: message.Message,
    guild_id: Option(String),
    member: Option(GuildMember),
    mentions: List(User),
  )
}

pub type MessageDeletedMessage {
  MessageDeletedMessage(
    id: String,
    channel_id: String,
    guild_id: Option(String),
  )
}

pub type MessagesBulkDeletedMessage {
  MessagesBulkDeletedMessage(
    ids: List(String),
    channel_id: String,
    guild_id: Option(String),
  )
}

pub type MessageReactionCreatedMessage {
  MessageReactionCreatedMessage(
    user_id: String,
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
    member: Option(GuildMember),
    emoji: Emoji,
    message_author_id: Option(String),
    is_burst: Bool,
    burst_colors: Option(List(String)),
    type_: reaction.Type,
  )
}

pub type MessageReactionDeletedMessage {
  MessageReactionDeletedMessage(
    user_id: String,
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
    emoji: Emoji,
    is_burst: Bool,
    type_: reaction.Type,
  )
}

pub type MessageAllReactionsDeletedMessage {
  MessageAllReactionsDeletedMessage(
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
  )
}

pub type MessageEmojiReactionsDeletedMessage {
  MessageEmojiReactionsDeletedMessage(
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
    emoji: Emoji,
  )
}

pub type TypingStartedMessage {
  TypingStartedMessage(
    channel_id: String,
    guild_id: Option(String),
    user_id: String,
    timestamp: Timestamp,
    member: Option(GuildMember),
  )
}

pub type VoiceChannelEffectSentMessage {
  VoiceChannelEffectSentMessage(
    channel_id: String,
    guild_id: String,
    user_id: String,
    emoji: Option(Emoji),
    animation_type: Option(voice.AnimationType),
    animation_id: Option(Int),
    sound_id: Option(soundboard.SoundId),
    sound_volume: Option(Float),
  )
}

pub type VoiceServerUpdatedMessage {
  VoiceServerUpdatedMessage(
    token: String,
    guild_id: String,
    endpoint: Option(String),
  )
}

pub type PollVoteCreatedMessage {
  PollVoteCreatedMessage(
    user_id: String,
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
    answer_id: Int,
  )
}

pub type PollVoteDeletedMessage {
  PollVoteDeletedMessage(
    user_id: String,
    channel_id: String,
    message_id: String,
    guild_id: Option(String),
    answer_id: Int,
  )
}

// USER MESSAGES ---------------------------------------------------------------

pub type UpdatePresenceMessage {
  UpdatePresenceMessage(
    /// Only for Idle.
    since: Option(Timestamp),
    activities: List(Activity),
    status: PresenceStatus,
    is_afk: Bool,
  )
}

pub type UpdateVoiceStateMessage {
  UpdateVoiceStateMessage(
    guild_id: String,
    /// Set to `None` if disconnecting.
    channel_id: Option(String),
    is_self_muted: Bool,
    is_self_deafened: Bool,
  )
}

pub type RequestGuildMembersMessage {
  RequestAllGuildMembersMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
  )
  RequestGuildMembersByIdsMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
    user_ids: List(String),
  )
  RequestGuildMembersByQueryMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
    query: String,
    limit: Int,
  )
}

pub type PresenceStatus {
  Online
  DoNotDisturb
  Idle
  Invisible
  Offline
}

// SEND EVENTS -----------------------------------------------------------------

type HeartbeatMessage {
  HeartbeatMessage(last_sequence: Option(Int))
}

pub type BaseIdentifyMessage {
  BaseIdentifyMessage(
    token: String,
    properties: IdentifyProperties,
    supports_compression: Bool,
    max_offline_members: Option(Int),
    presence: Option(UpdatePresenceMessage),
    intents: List(Intent),
  )
}

type IdentifyMessage {
  IdentifyMessage(
    shard: Shard,
    token: String,
    properties: IdentifyProperties,
    supports_compression: Bool,
    max_offline_members: Option(Int),
    presence: Option(UpdatePresenceMessage),
    intents: List(Intent),
  )
}

type ResumeMessage {
  ResumeMessage(token: String, session_id: String, last_sequence: Int)
}

pub type IdentifyProperties {
  IdentifyProperties(os: String, browser: String, device: String)
}

pub opaque type Next(state) {
  Continue(state: state)
  Stop
  StopAbnormal(reason: String)
}

pub opaque type Builder(state) {
  Builder(
    identify: BaseIdentifyMessage,
    data: Data,
    init: fn(Subject(Message)) -> Result(state, String),
    handler: fn(state, Event) -> Next(state),
    close: fn(state) -> Nil,
    shard_count: Option(Int),
  )
}

type ConnectionManagerMessage {
  UpdateWebsocket(to: Subject(stratus.InternalMessage(StratusUserMessage)))
  SendUserMessage(message: StratusUserMessage)
}

type ConnectionManagerState {
  ConnectionManagerState(
    websocket: Option(Subject(stratus.InternalMessage(StratusUserMessage))),
    queued_messages: List(StratusUserMessage),
  )
}

type Connection {
  GettingReady(
    gateway_url: String,
    manager: Subject(ConnectionManagerMessage),
    subject: Subject(Message),
    identify: IdentifyMessage,
  )
  Welcomed(
    gateway_url: String,
    manager: Subject(ConnectionManagerMessage),
    subject: Subject(Message),
    identify: IdentifyMessage,
    heartbeat_manager: Subject(HeartbeatManagerMessage),
    sequence: Option(Int),
  )
  Identified(
    gateway_url: String,
    manager: Subject(ConnectionManagerMessage),
    subject: Subject(Message),
    identify: IdentifyMessage,
    heartbeat_manager: Subject(HeartbeatManagerMessage),
    sequence: Option(Int),
    session_id: String,
    resume_gateway_url: String,
  )
}

type StratusUserMessage {
  StartSendResume(ResumingInfo)
  StartSendHeartbeat
  StartHeartbeatInequalityDisconnect
  StartIdentify(Connection)
  UserMessage(UserMessage)
}

type UserMessage {
  StartPresenceUpdate(UpdatePresenceMessage)
  StartVoiceStateUpdate(UpdateVoiceStateMessage)
  StartGuildMembersRequest(RequestGuildMembersMessage)
  StartSoundboardSoundsRequest(guild_ids: List(String))
}

type BucketedShard {
  BucketedShard(start_after: Duration, shard: Shard)
}

type ShardSpawnerMessage {
  StartConnection
}

type Gateway(user_state) {
  Gateway(
    user_state: user_state,
    identify: BaseIdentifyMessage,
    data: Data,
    shard_count: Int,
    event_handler: fn(user_state, Event) -> Next(user_state),
    shards: List(#(Shard, Subject(ConnectionManagerMessage))),
    all_ready: Option(AllShardsReadyMessage),
  )
}

// Shards do not need the user's state.
// They do however need to know whether to continue or stop
type NextForShards {
  ShardContinue
  ShardStop
  ShardStopAbnormal(reason: String)
}

pub opaque type Message {
  MessageFromUser(UserMessage)
  MessageFromDiscord(event: Event, reply_to: Subject(NextForShards))
  RegisterShard(#(Shard, Subject(ConnectionManagerMessage)))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn data_decoder() -> decode.Decoder(Data) {
  use url <- decode.field("url", decode.string)
  use recommended_shards <- decode.field("shards", decode.int)
  use session_start_limits <- decode.field(
    "session_start_limit",
    session_start_limits_decoder(),
  )

  decode.success(Data(url:, recommended_shards:, session_start_limits:))
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

fn message_decoder() -> decode.Decoder(ReceivedMessage) {
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
      use can_reconnect <- decode.field("d", decode.bool)
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

fn dispatched_message_decoder(
  type_: String,
) -> decode.Decoder(DispatchedMessage) {
  case type_ {
    "READY" -> decode.map(ready_message_decoder(), Ready)
    "RESUMED" -> decode.success(Resumed)
    "RATE_LIMITED" -> decode.map(rate_limited_message_decoder(), RateLimited)
    "APPLICATION_COMMAND_PERMISSIONS_UPDATE" ->
      decode.map(
        command.guild_permissions_decoder(),
        ApplicationCommandPermissionsUpdated,
      )
    "AUTO_MODERATION_RULE_CREATE" ->
      decode.map(auto_moderation.rule_decoder(), AutoModerationRuleCreated)
    "AUTO_MODERATION_RULE_UPDATE" ->
      decode.map(auto_moderation.rule_decoder(), AutoModerationRuleUpdated)
    "AUTO_MODERATION_RULE_DELETE" ->
      decode.map(auto_moderation.rule_decoder(), AutoModerationRuleDeleted)
    "AUTO_MODERATION_ACTION_EXECUTION" ->
      decode.map(
        auto_moderation_action_executed_message_decoder(),
        AutoModerationActionExecuted,
      )
    "CHANNEL_CREATE" -> decode.map(channel.decoder(), ChannelCreated)
    "CHANNEL_UPDATE" -> decode.map(channel.decoder(), ChannelUpdated)
    "CHANNEL_DELETE" -> decode.map(channel.decoder(), ChannelDeleted)
    "THREAD_CREATE" ->
      decode.map(thread_created_message_decoder(), ThreadCreated)
    "THREAD_UPDATE" -> decode.map(thread.decoder(), ThreadUpdated)
    "THREAD_DELETE" ->
      decode.map(thread_deleted_message_decoder(), ThreadDeleted)
    "THREAD_LIST_SYNC" ->
      decode.map(thread_list_synced_message_decoder(), ThreadListSynced)
    "THREAD_MEMBER_UPDATE" ->
      decode.map(thread_member_updated_message_decoder(), ThreadMemberUpdated)
    "PRESENCE_UPDATE" ->
      decode.map(presence_updated_message_decoder(), PresenceUpdated)
    "THREAD_MEMBERS_UPDATE" ->
      decode.map(thread_members_updated_message_decoder(), ThreadMembersUpdated)
    "CHANNEL_PINS_UPDATE" ->
      decode.map(channel_pins_updated_message_decoder(), ChannelPinsUpdated)
    "ENTITLEMENT_CREATE" ->
      decode.map(entitlement.decoder(), EntitlementCreated)
    "ENTITLEMENT_UPDATE" ->
      decode.map(entitlement.decoder(), EntitlementUpdated)
    "ENTITLEMENT_DELETE" ->
      decode.map(entitlement.decoder(), EntitlementDeleted)
    "GUILD_CREATE" -> decode.map(guild_created_message_decoder(), GuildCreated)
    "GUILD_UPDATE" -> decode.map(guild.decoder(), GuildUpdated)
    "GUILD_DELETE" ->
      decode.map(guild.unavailable_guild_decoder(), GuildDeleted)
    "GUILD_AUDIT_LOG_ENTRY_CREATE" ->
      decode.map(
        audit_log_entry_created_message_decoder(),
        AuditLogEntryCreated,
      )
    "GUILD_BAN_ADD" -> decode.map(guild_ban_message_decoder(), GuildBanCreated)
    "GUILD_BAN_REMOVE" ->
      decode.map(guild_ban_message_decoder(), GuildBanDeleted)
    "GUILD_EMOJIS_UPDATE" ->
      decode.map(guild_emojis_updated_message_decoder(), GuildEmojisUpdated)
    "GUILD_STICKERS_UPDATE" ->
      decode.map(guild_stickers_updated_message_decoder(), GuildStickersUpdated)
    "GUILD_INTEGRATIONS_UPDATE" ->
      decode.map(
        guild_integrations_updated_message_decoder(),
        GuildIntegrationsUpdated,
      )
    "GUILD_MEMBER_ADD" ->
      decode.map(guild_member_created_message_decoder(), GuildMemberCreated)
    "GUILD_MEMBER_REMOVE" ->
      decode.map(guild_member_deleted_message_decoder(), GuildMemberDeleted)
    "GUILD_MEMBER_UPDATE" ->
      decode.map(guild_member_updated_message_decoder(), GuildMemberUpdated)
    "GUILD_MEMBERS_CHUNK" ->
      decode.map(guild_members_chunk_message_decoder(), GuildMembersChunk)
    "GUILD_ROLE_CREATE" ->
      decode.map(role_created_message_decoder(), RoleCreated)
    "GUILD_ROLE_UPDATE" ->
      decode.map(role_updated_message_decoder(), RoleUpdated)
    "GUILD_ROLE_DELETE" ->
      decode.map(role_deleted_message_decoder(), RoleDeleted)
    "GUILD_SCHEDULED_EVENT_CREATE" ->
      decode.map(scheduled_event.decoder(), ScheduledEventCreated)
    "GUILD_SCHEDULED_EVENT_UPDATE" ->
      decode.map(scheduled_event.decoder(), ScheduledEventUpdated)
    "GUILD_SCHEDULED_EVENT_DELETE" ->
      decode.map(scheduled_event.decoder(), ScheduledEventDeleted)
    "GUILD_SCHEDULED_EVENT_USER_ADD" ->
      decode.map(
        scheduled_event_user_message_decoder(),
        ScheduledEventUserCreated,
      )
    "GUILD_SCHEDULED_EVENT_USER_REMOVE" ->
      decode.map(
        scheduled_event_user_message_decoder(),
        ScheduledEventUserDeleted,
      )
    "GUILD_SOUNDBOARD_SOUND_CREATE" ->
      decode.map(soundboard.sound_decoder(), GuildSoundboardSoundCreated)
    "GUILD_SOUNDBOARD_SOUND_UPDATE" ->
      decode.map(soundboard.sound_decoder(), GuildSoundboardSoundUpdated)
    "GUILD_SOUNDBOARD_SOUND_DELETE" ->
      decode.map(
        guild_soundboard_sound_deleted_message_decoder(),
        GuildSoundboardSoundDeleted,
      )
    "GUILD_SOUNDBOARD_SOUNDS_UPDATE" ->
      decode.map(
        guild_soundboard_sounds_updated_message_decoder(),
        GuildSoundboardSoundsUpdated,
      )
    "SOUNDBOARD_SOUNDS" ->
      decode.map(soundboard_sounds_message_decoder(), SoundboardSounds)
    "INTEGRATION_CREATE" ->
      decode.map(integration_created_message_decoder(), IntegrationCreated)
    "INTEGRATION_UPDATE" ->
      decode.map(integration_updated_message_decoder(), IntegrationUpdated)
    "INTEGRATION_DELETE" ->
      decode.map(integration_deleted_message_decoder(), IntegrationDeleted)
    "INVITE_CREATE" ->
      decode.map(invite_created_message_decoder(), InviteCreated)
    "INVITE_DELETE" ->
      decode.map(invite_deleted_message_decoder(), InviteDeleted)
    "MESSAGE_CREATE" ->
      decode.map(message_created_message_decoder(), MessageCreated)
    "MESSAGE_UPDATE" ->
      decode.map(message_updated_message_decoder(), MessageUpdated)
    "MESSAGE_DELETE" ->
      decode.map(message_deleted_message_decoder(), MessageDeleted)
    "MESSAGE_DELETE_BULK" ->
      decode.map(messages_bulk_deleted_message_decoder(), MessagesBulkDeleted)
    "MESSAGE_REACTION_ADD" ->
      decode.map(
        message_reaction_created_message_decoder(),
        MessageReactionCreated,
      )
    "MESSAGE_REACTION_REMOVE" ->
      decode.map(
        message_reaction_deleted_message_decoder(),
        MessageReactionDeleted,
      )
    "MESSAGE_REACTION_REMOVE_ALL" ->
      decode.map(
        message_all_reactions_deleted_message_decoder(),
        MessageAllReactionsDeleted,
      )
    "MESSAGE_REACTION_REMOVE_EMOJI" ->
      decode.map(
        message_emoji_reactions_deleted_message_decoder(),
        MessageEmojiReactionsDeleted,
      )
    "TYPING_START" ->
      decode.map(typing_started_message_decoder(), TypingStarted)
    "USER_UPDATE" -> decode.map(user.decoder(), CurrentUserUpdated)
    "VOICE_CHANNEL_EFFECT_SEND" ->
      decode.map(
        voice_channel_effect_sent_message_decoder(),
        VoiceChannelEffectSent,
      )
    "VOICE_STATE_UPDATE" -> decode.map(voice.state_decoder(), VoiceStateUpdated)
    "VOICE_SERVER_UPDATE" ->
      decode.map(voice_server_updated_message_decoder(), VoiceServerUpdated)
    "INTERACTION_CREATE" ->
      decode.map(interaction.decoder(), InteractionCreated)
    "STAGE_INSTANCE_CREATE" ->
      decode.map(stage_instance.decoder(), StageInstanceCreated)
    "STAGE_INSTANCE_UPDATE" ->
      decode.map(stage_instance.decoder(), StageInstanceUpdated)
    "STAGE_INSTANCE_DELETE" ->
      decode.map(stage_instance.decoder(), StageInstanceDeleted)
    "SUBSCRIPTION_CREATE" ->
      decode.map(subscription.decoder(), SubscriptionCreated)
    "SUBSCRIPTION_UPDATE" ->
      decode.map(subscription.decoder(), SubscriptionUpdated)
    "SUBSCRIPTION_DELETE" ->
      decode.map(subscription.decoder(), SubscriptionDeleted)
    "MESSAGE_POLL_VOTE_ADD" ->
      decode.map(poll_vote_created_message_decoder(), PollVoteCreated)
    "MESSAGE_POLL_VOTE_REMOVE" ->
      decode.map(poll_vote_deleted_message_decoder(), PollVoteDeleted)
    _ -> decode.success(UnknownDispatchedMessage)
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

fn hello_event_decoder() -> decode.Decoder(HelloMessage) {
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
  use user_id <- decode.then(decode.optionally_at(
    ["user", "id"],
    None,
    decode.optional(decode.string),
  ))
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use status <- decode.optional_field(
    "status",
    None,
    decode.optional(decode.string),
  )
  use activities <- decode.optional_field(
    "activities",
    None,
    decode.optional(decode.list(activity.decoder())),
  )
  use client_status <- decode.optional_field(
    "client_status",
    None,
    decode.optional(client_status_decoder()),
  )
  decode.success(PresenceUpdatedMessage(
    user_id:,
    guild_id:,
    status:,
    activities:,
    client_status:,
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
  use nick <- decode.optional_field(
    "nick",
    Skip,
    modification.decoder(decode.string),
  )
  use avatar_hash <- decode.field("avatar", decode.optional(decode.string))
  use banner_hash <- decode.field("banner", decode.optional(decode.string))
  use joined_at <- decode.field(
    "joined_at",
    decode.optional(time_rfc3339.decoder()),
  )
  use premium_since <- decode.optional_field(
    "premium_since",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use is_deaf <- decode.optional_field(
    "deaf",
    None,
    decode.optional(decode.bool),
  )
  use is_mute <- decode.optional_field(
    "mute",
    None,
    decode.optional(decode.bool),
  )
  use is_pending <- decode.optional_field(
    "pending",
    None,
    decode.optional(decode.bool),
  )
  use communication_disabled_until <- decode.optional_field(
    "communication_disabled_until",
    Skip,
    modification.decoder(time_rfc3339.decoder()),
  )
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(guild_member.bits_member_flags())),
  )
  use avatar_decoration_data <- decode.optional_field(
    "avatar_decoration_data",
    Skip,
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

@internal
pub fn guild_soundboard_sound_deleted_message_decoder() -> decode.Decoder(
  GuildSoundboardSoundDeletedMessage,
) {
  use sound_id <- decode.field("sound_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(GuildSoundboardSoundDeletedMessage(sound_id:, guild_id:))
}

@internal
pub fn guild_soundboard_sounds_updated_message_decoder() -> decode.Decoder(
  GuildSoundboardSoundsUpdatedMessage,
) {
  use soundboard_sounds <- decode.field(
    "soundboard_sounds",
    decode.list(soundboard.sound_decoder()),
  )
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(GuildSoundboardSoundsUpdatedMessage(
    soundboard_sounds:,
    guild_id:,
  ))
}

@internal
pub fn soundboard_sounds_message_decoder() -> decode.Decoder(
  SoundboardSoundsMessage,
) {
  use soundboard_sounds <- decode.field(
    "soundboard_sounds",
    decode.list(soundboard.sound_decoder()),
  )
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(SoundboardSoundsMessage(soundboard_sounds:, guild_id:))
}

@internal
pub fn integration_created_message_decoder() -> decode.Decoder(
  IntegrationCreatedMessage,
) {
  use integration <- decode.then(integration.decoder())
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(IntegrationCreatedMessage(integration:, guild_id:))
}

@internal
pub fn integration_updated_message_decoder() -> decode.Decoder(
  IntegrationUpdatedMessage,
) {
  use integration <- decode.then(integration.decoder())
  use guild_id <- decode.field("guild_id", decode.string)
  decode.success(IntegrationUpdatedMessage(integration:, guild_id:))
}

@internal
pub fn integration_deleted_message_decoder() -> decode.Decoder(
  IntegrationDeletedMessage,
) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use application_id <- decode.optional_field(
    "application_id",
    None,
    decode.optional(decode.string),
  )

  decode.success(IntegrationDeletedMessage(id:, guild_id:, application_id:))
}

@internal
pub fn invite_created_message_decoder() -> decode.Decoder(InviteCreatedMessage) {
  use channel_id <- decode.field("channel_id", decode.string)
  use code <- decode.field("code", decode.string)
  use created_at <- decode.field("created_at", time_rfc3339.decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use inviter <- decode.optional_field(
    "inviter",
    None,
    decode.optional(user.decoder()),
  )
  use max_age <- decode.field(
    "max_age",
    time_duration.from_int_seconds_decoder(),
  )
  use max_uses <- decode.field("max_uses", decode.int)
  use target_type <- decode.optional_field(
    "target_type",
    None,
    decode.optional(decode.int),
  )

  use target_type <- decode.then(case target_type {
    Some(1) -> {
      use streaming_user <- decode.field("target_user", user.decoder())
      decode.success(Some(invite.ForStream(streaming_user:)))
    }
    Some(2) -> {
      use application <- decode.field(
        "target_application",
        application.decoder(),
      )
      decode.success(Some(invite.ForEmbeddedApplication(application:)))
    }
    Some(_) ->
      decode.failure(
        Some(
          invite.ForStream(User(
            "",
            "",
            "",
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
            None,
          )),
        ),
        "TargetType",
      )
    None -> decode.success(None)
  })
  use is_temporary <- decode.field("temporary", decode.bool)
  use uses <- decode.field("uses", decode.int)
  use expires_at <- decode.field(
    "expires_at",
    decode.optional(time_rfc3339.decoder()),
  )
  decode.success(InviteCreatedMessage(
    channel_id:,
    code:,
    created_at:,
    guild_id:,
    inviter:,
    max_age:,
    max_uses:,
    target_type:,
    is_temporary:,
    uses:,
    expires_at:,
  ))
}

@internal
pub fn invite_deleted_message_decoder() -> decode.Decoder(InviteDeletedMessage) {
  use channel_id <- decode.field("channel_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use code <- decode.field("code", decode.string)

  decode.success(InviteDeletedMessage(channel_id:, guild_id:, code:))
}

@internal
pub fn message_created_message_decoder() -> decode.Decoder(
  MessageCreatedMessage,
) {
  use message <- decode.then(message.decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use member <- decode.optional_field(
    "member",
    None,
    decode.optional(guild_member.decoder()),
  )
  use mentions <- decode.field("mentions", decode.list(user.decoder()))

  decode.success(MessageCreatedMessage(message:, guild_id:, member:, mentions:))
}

@internal
pub fn message_updated_message_decoder() -> decode.Decoder(
  MessageUpdatedMessage,
) {
  use message <- decode.then(message.decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use member <- decode.optional_field(
    "member",
    None,
    decode.optional(guild_member.decoder()),
  )
  use mentions <- decode.field("mentions", decode.list(user.decoder()))

  decode.success(MessageUpdatedMessage(message:, guild_id:, member:, mentions:))
}

@internal
pub fn message_deleted_message_decoder() -> decode.Decoder(
  MessageDeletedMessage,
) {
  use id <- decode.field("id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )

  decode.success(MessageDeletedMessage(id:, channel_id:, guild_id:))
}

@internal
pub fn messages_bulk_deleted_message_decoder() -> decode.Decoder(
  MessagesBulkDeletedMessage,
) {
  use ids <- decode.field("ids", decode.list(decode.string))
  use channel_id <- decode.field("channel_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )

  decode.success(MessagesBulkDeletedMessage(ids:, channel_id:, guild_id:))
}

@internal
pub fn message_reaction_created_message_decoder() -> decode.Decoder(
  MessageReactionCreatedMessage,
) {
  use user_id <- decode.field("user_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use member <- decode.optional_field(
    "member",
    None,
    decode.optional(guild_member.decoder()),
  )
  use emoji <- decode.field("emoji", emoji.decoder())
  use message_author_id <- decode.optional_field(
    "message_author_id",
    None,
    decode.optional(decode.string),
  )
  use is_burst <- decode.field("burst", decode.bool)
  use burst_colors <- decode.optional_field(
    "burst_colors",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use type_ <- decode.field("type", reaction.type_decoder())
  decode.success(MessageReactionCreatedMessage(
    user_id:,
    channel_id:,
    message_id:,
    guild_id:,
    member:,
    emoji:,
    message_author_id:,
    is_burst:,
    burst_colors:,
    type_:,
  ))
}

@internal
pub fn message_reaction_deleted_message_decoder() -> decode.Decoder(
  MessageReactionDeletedMessage,
) {
  use user_id <- decode.field("user_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.field("emoji", emoji.decoder())
  use is_burst <- decode.field("burst", decode.bool)
  use type_ <- decode.field("type", reaction.type_decoder())
  decode.success(MessageReactionDeletedMessage(
    user_id:,
    channel_id:,
    message_id:,
    guild_id:,
    emoji:,
    is_burst:,
    type_:,
  ))
}

@internal
pub fn message_all_reactions_deleted_message_decoder() -> decode.Decoder(
  MessageAllReactionsDeletedMessage,
) {
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )

  decode.success(MessageAllReactionsDeletedMessage(
    channel_id:,
    message_id:,
    guild_id:,
  ))
}

@internal
pub fn message_emoji_reactions_deleted_message_decoder() -> decode.Decoder(
  MessageEmojiReactionsDeletedMessage,
) {
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.field("emoji", emoji.decoder())

  decode.success(MessageEmojiReactionsDeletedMessage(
    channel_id:,
    message_id:,
    guild_id:,
    emoji:,
  ))
}

@internal
pub fn typing_started_message_decoder() -> decode.Decoder(TypingStartedMessage) {
  use channel_id <- decode.field("channel_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use user_id <- decode.field("user_id", decode.string)
  use timestamp <- decode.field(
    "timestamp",
    time_timestamp.from_unix_seconds_decoder(),
  )
  use member <- decode.optional_field(
    "member",
    None,
    decode.optional(guild_member.decoder()),
  )

  decode.success(TypingStartedMessage(
    channel_id:,
    guild_id:,
    user_id:,
    timestamp:,
    member:,
  ))
}

@internal
pub fn voice_channel_effect_sent_message_decoder() -> decode.Decoder(
  VoiceChannelEffectSentMessage,
) {
  use channel_id <- decode.field("channel_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji.decoder()),
  )
  use animation_type <- decode.optional_field(
    "animation_type",
    None,
    decode.optional(voice.animation_type_decoder()),
  )
  use animation_id <- decode.optional_field(
    "animation_id",
    None,
    decode.optional(decode.int),
  )
  use sound_id <- decode.optional_field(
    "sound_id",
    None,
    decode.optional(soundboard.sound_id_decoder()),
  )
  use sound_volume <- decode.optional_field(
    "sound_volume",
    None,
    decode.optional(decode.float),
  )
  decode.success(VoiceChannelEffectSentMessage(
    channel_id:,
    guild_id:,
    user_id:,
    emoji:,
    animation_type:,
    animation_id:,
    sound_id:,
    sound_volume:,
  ))
}

@internal
pub fn voice_server_updated_message_decoder() -> decode.Decoder(
  VoiceServerUpdatedMessage,
) {
  use token <- decode.field("token", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use endpoint <- decode.optional_field(
    "endpoint",
    None,
    decode.optional(decode.string),
  )
  decode.success(VoiceServerUpdatedMessage(token:, guild_id:, endpoint:))
}

@internal
pub fn poll_vote_created_message_decoder() -> decode.Decoder(
  PollVoteCreatedMessage,
) {
  use user_id <- decode.field("user_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use answer_id <- decode.field("answer_id", decode.int)

  decode.success(PollVoteCreatedMessage(
    user_id:,
    channel_id:,
    message_id:,
    guild_id:,
    answer_id:,
  ))
}

@internal
pub fn poll_vote_deleted_message_decoder() -> decode.Decoder(
  PollVoteDeletedMessage,
) {
  use user_id <- decode.field("user_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use message_id <- decode.field("message_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use answer_id <- decode.field("answer_id", decode.int)

  decode.success(PollVoteDeletedMessage(
    user_id:,
    channel_id:,
    message_id:,
    guild_id:,
    answer_id:,
  ))
}

// ENCODERS --------------------------------------------------------------------

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

    let shard = [
      #("shard", json.array([msg.shard.id, msg.shard.num_shards], json.int)),
    ]

    let presence = case msg.presence {
      Some(presence) -> [
        #("presence", update_presence_to_json(presence, False)),
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

fn update_presence_to_json(
  msg: UpdatePresenceMessage,
  with_opcode: Bool,
) -> Json {
  let data = {
    let since = case msg.since, msg.status {
      Some(timestamp), Idle -> [
        #("since", json.int(time_timestamp.to_unix_milliseconds(timestamp))),
      ]
      _, _ -> [#("since", json.null())]
    }

    let activities = [
      #("activities", json.array(msg.activities, activity.to_json)),
    ]

    let status = [#("status", presence_status_to_json(msg.status))]

    let is_afk = [#("afk", json.bool(msg.is_afk))]

    [since, activities, status, is_afk]
    |> list.flatten
    |> json.object
  }

  case with_opcode {
    True -> json.object([#("op", json.int(3)), #("d", data)])
    False -> data
  }
}

fn presence_status_to_json(status: PresenceStatus) -> Json {
  case status {
    Online -> "online"
    DoNotDisturb -> "dnd"
    Idle -> "idle"
    Invisible -> "invisible"
    Offline -> "offline"
  }
  |> json.string
}

fn request_guild_members_message_to_json(
  message: RequestGuildMembersMessage,
) -> Json {
  let data = {
    let guild_id = [#("guild_id", json.string(message.guild_id))]

    let with_presences = [#("presences", json.bool(message.with_presences))]

    let nonce = case message.nonce {
      Some(nonce) -> [#("nonce", json.string(nonce))]
      None -> []
    }

    let #(query, limit, user_ids) = case message {
      RequestAllGuildMembersMessage(..) -> #(
        [#("query", json.string(""))],
        [#("limit", json.int(0))],
        [],
      )
      RequestGuildMembersByIdsMessage(..) -> #([], [], [
        #("user_ids", json.array(message.user_ids, json.string)),
      ])
      RequestGuildMembersByQueryMessage(..) -> #(
        [#("query", json.string(message.query))],
        [#("limit", json.int(message.limit))],
        [],
      )
    }

    [guild_id, with_presences, nonce, query, limit, user_ids]
    |> list.flatten
    |> json.object
  }

  json.object([#("op", json.int(8)), #("d", data)])
}

fn update_voice_state_message_to_json(message: UpdateVoiceStateMessage) -> Json {
  json.object([
    #("op", json.int(4)),
    #(
      "d",
      json.object([
        #("guild_id", json.string(message.guild_id)),
        #("channel_id", json.nullable(message.channel_id, json.string)),
        #("self_mute", json.bool(message.is_self_muted)),
        #("self_deaf", json.bool(message.is_self_deafened)),
      ]),
    ),
  ])
}

// FUNCTIONS -------------------------------------------------------------------

pub fn get_data(client: grom.Client) -> Result(Data, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/gateway/bot")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: data_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn continue(state: state) -> Next(state) {
  Continue(state)
}

pub fn stop() -> Next(state) {
  Stop
}

pub fn stop_abnormal(reason: String) -> Next(state) {
  StopAbnormal(reason:)
}

/// Only use this function if you have no intention of sending user messages, such as:
/// * `UpdatePresence`
/// * `UpdateVoiceState`
/// * `RequestGuildMembers`
/// * `RequestSoundboardSounds`
pub fn new(
  state: state,
  identify: BaseIdentifyMessage,
  data: Data,
) -> Builder(state) {
  Builder(
    identify:,
    data:,
    init: fn(_) { Ok(state) },
    handler: fn(state, _event) { continue(state) },
    close: fn(_state) { Nil },
    shard_count: None,
  )
}

/// You should hold the gateway subject in your state.
/// You'll send user messages to that subject.
pub fn new_with_initializer(
  init: fn(Subject(Message)) -> Result(user_state, String),
  identify: BaseIdentifyMessage,
  data: Data,
) -> Builder(user_state) {
  Builder(
    identify:,
    data:,
    init:,
    handler: fn(state, _event) { continue(state) },
    close: fn(_state) { Nil },
    shard_count: None,
  )
}

pub fn on_event(
  builder: Builder(state),
  do handler: fn(state, Event) -> Next(state),
) -> Builder(state) {
  Builder(..builder, handler:)
}

pub fn on_close(
  builder: Builder(state),
  do handler: fn(state) -> Nil,
) -> Builder(state) {
  Builder(..builder, close: handler)
}

/// Use this to force the amount of shards to a set number.
/// By default, grom will resort to the recommended shard count given to us from Discord.
/// Unless you have more than 150,000 guilds using your bot, you likely shouldn't use this function.
pub fn with_shards(
  builder: Builder(user_state),
  count count: Int,
) -> Builder(user_state) {
  Builder(..builder, shard_count: Some(count))
}

pub fn start(
  builder: Builder(state),
) -> Result(actor.Started(Subject(Message)), actor.StartError) {
  let shard_count = case builder.shard_count {
    Some(count) -> count
    None -> builder.data.recommended_shards
  }

  let max_concurrency =
    builder.data.session_start_limits.max_identify_requests_per_5_seconds
  let supervisor = static_supervisor.new(static_supervisor.OneForOne)

  let shard_ids =
    int.range(from: 0, to: shard_count, with: [], run: list.prepend)
    |> list.reverse

  let shards =
    shard_ids
    |> list.map(fn(id) { Shard(id, shard_count) })

  let bucketed_shards =
    shards
    |> list.sized_chunk(max_concurrency)
    |> list.index_map(fn(shards, bucket) {
      shards
      |> list.map(fn(shard) {
        BucketedShard(duration.seconds(5 * bucket), shard)
      })
    })

  actor.new_with_initialiser(1000, fn(subject) {
    use user_state <- result.try(builder.init(subject))

    let state =
      Gateway(
        user_state:,
        identify: builder.identify,
        data: builder.data,
        event_handler: builder.handler,
        shard_count:,
        shards: [],
        all_ready: None,
      )

    // i have no idea whether this is actually required
    let selector =
      process.new_selector()
      |> process.select(subject)

    let supervisor =
      bucketed_shards
      |> list.flatten
      |> list.fold(supervisor, fn(supervisor, shard) {
        supervisor
        |> static_supervisor.add(supervised_shard_spawner(
          builder,
          shard,
          subject,
        ))
      })

    use _supervisor <- result.try(
      supervisor
      |> static_supervisor.start
      |> result.map_error(string.inspect),
    )

    actor.initialised(state)
    |> actor.selecting(selector)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(on_gateway_message)
  |> actor.start
}

/// Returns the ID of the shard that will handle an event from a specified guild.
/// Some things to mind:
/// * You can get the shard count from `gateway.Data` (for the recommended amount of shards), or it could be a number you specified when you created the gateway.
/// * Events which do not have any guild (DMs, presence updates, etc.) will always be handled by shard 0.
/// * The process of distributing events to shards is automated by grom. You can, however, use this function for a health check command.
pub fn get_shard_for_guild(
  guild_id id: Int,
  shard_count shard_count: Int,
) -> Int {
  { id |> int.bitwise_shift_right(22) } % shard_count
}

fn get_guild_ids_from_user_message(
  message: UserMessage,
  failure: a,
  next: fn(List(Int)) -> a,
) -> a {
  case message {
    StartPresenceUpdate(_) -> next([0])
    StartVoiceStateUpdate(msg) ->
      case int.parse(msg.guild_id) {
        Ok(id) -> next([id])
        Error(_) -> failure
      }
    StartGuildMembersRequest(msg) ->
      case int.parse(msg.guild_id) {
        Ok(id) -> next([id])
        Error(_) -> failure
      }
    StartSoundboardSoundsRequest(guild_ids) ->
      guild_ids
      |> list.filter_map(int.parse)
      |> next
  }
}

fn on_gateway_message(
  gateway: Gateway(user_state),
  message: Message,
) -> actor.Next(Gateway(user_state), a) {
  case message {
    MessageFromUser(msg) -> {
      use guild_ids <- get_guild_ids_from_user_message(
        msg,
        actor.continue(gateway),
      )
      let shard_ids =
        list.map(guild_ids, get_shard_for_guild(_, gateway.shard_count))

      let connections =
        gateway.shards
        |> list.filter_map(fn(shard) {
          let #(shard, subject) = shard
          case list.contains(shard_ids, shard.id) {
            True -> Ok(subject)
            False -> Error(Nil)
          }
        })

      connections
      |> list.each(fn(connection) {
        connection
        |> process.send(SendUserMessage(UserMessage(msg)))
      })

      actor.continue(gateway)
    }
    MessageFromDiscord(ReadyEvent(ready), reply_to) -> {
      let all_ready = case gateway.all_ready {
        Some(old) ->
          AllShardsReadyMessage(
            ..old,
            guilds: list.append(old.guilds, ready.guilds),
            shard_count: old.shard_count + 1,
          )
        None ->
          AllShardsReadyMessage(
            api_version: ready.api_version,
            user: ready.user,
            guilds: ready.guilds,
            application: ready.application,
            shard_count: 1,
          )
      }

      let next = case all_ready.shard_count == gateway.shard_count {
        True ->
          gateway.event_handler(
            gateway.user_state,
            AllShardsReadyEvent(all_ready),
          )
        False -> gateway.event_handler(gateway.user_state, ReadyEvent(ready))
      }

      case next {
        Continue(state) -> {
          process.send(reply_to, ShardContinue)
          actor.continue(
            Gateway(..gateway, user_state: state, all_ready: Some(all_ready)),
          )
        }
        Stop -> {
          process.send(reply_to, ShardStop)
          actor.stop()
        }
        StopAbnormal(reason) -> {
          process.send(reply_to, ShardStopAbnormal(reason))
          actor.stop_abnormal(reason)
        }
      }
    }
    MessageFromDiscord(msg, reply_to) -> {
      let next = gateway.event_handler(gateway.user_state, msg)
      case next {
        Continue(state) -> {
          process.send(reply_to, ShardContinue)
          actor.continue(Gateway(..gateway, user_state: state))
        }
        Stop -> {
          process.send(reply_to, ShardStop)
          actor.stop()
        }
        StopAbnormal(reason) -> {
          process.send(reply_to, ShardStopAbnormal(reason))
          actor.stop_abnormal(reason)
        }
      }
    }
    RegisterShard(shard_subject) ->
      actor.continue(
        Gateway(..gateway, shards: [shard_subject, ..gateway.shards]),
      )
  }
}

fn supervised_shard_spawner(
  builder: Builder(user_state),
  shard: BucketedShard,
  subject: Subject(Message),
) -> supervision.ChildSpecification(Subject(ShardSpawnerMessage)) {
  supervision.supervisor(fn() { new_shard_spawner(builder, shard, subject) })
}

fn new_shard_spawner(
  builder: Builder(user_state),
  shard: BucketedShard,
  subject: Subject(Message),
) -> Result(actor.Started(Subject(ShardSpawnerMessage)), actor.StartError) {
  actor.new_with_initialiser(50, fn(subject) {
    let selector =
      process.new_selector()
      |> process.select(subject)

    let seconds_to_wait =
      shard.start_after
      |> duration.to_seconds
      |> float.multiply(1000.0)
      |> float.round

    subject
    |> process.send_after(seconds_to_wait, StartConnection)

    actor.initialised(Nil)
    |> actor.selecting(selector)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(on_shard_spawner_message(builder, shard, subject))
  |> actor.start
}

fn on_shard_spawner_message(
  builder: Builder(user_state),
  shard: BucketedShard,
  subject: Subject(Message),
) -> fn(a, ShardSpawnerMessage) -> actor.Next(Nil, b) {
  fn(_state, message: ShardSpawnerMessage) {
    case message {
      StartConnection -> {
        let result = start_connection(builder, shard, subject)
        case result {
          Ok(_) -> actor.continue(Nil)
          Error(err) -> actor.stop_abnormal(string.inspect(err))
        }
      }
    }
  }
}

fn start_connection(
  builder: Builder(user_state),
  shard: BucketedShard,
  subject: Subject(Message),
) -> Result(Nil, grom.Error) {
  let request_url =
    builder.data.url
    |> string.replace(each: "wss://", with: "https://")
    |> string.append(suffix: "?v=10&encoding=json")

  use request <- result.try(
    request.to(request_url)
    |> result.replace_error(grom.InvalidGatewayUrl(request_url)),
  )

  use connection_manager <- result.try(
    actor.new(ConnectionManagerState(None, []))
    |> actor.on_message(on_connection_manager_message)
    |> actor.start
    |> result.map_error(grom.CouldNotStartActor),
  )

  let identify =
    IdentifyMessage(
      shard: shard.shard,
      token: builder.identify.token,
      properties: builder.identify.properties,
      supports_compression: builder.identify.supports_compression,
      max_offline_members: builder.identify.max_offline_members,
      presence: builder.identify.presence,
      intents: builder.identify.intents,
    )

  let initial_connection_state =
    GettingReady(
      gateway_url: builder.data.url,
      manager: connection_manager.data,
      subject:,
      identify:,
    )

  use websocket <- result.try(
    stratus.new(request:, state: initial_connection_state)
    |> stratus.on_message(on_message)
    |> stratus.on_close(try_reconnect)
    |> stratus.start
    |> result.map_error(grom.CouldNotInitializeWebsocketConnection),
  )

  process.send(connection_manager.data, UpdateWebsocket(to: websocket.data))
  process.send(subject, RegisterShard(#(shard.shard, connection_manager.data)))

  Ok(Nil)
}

fn try_reconnect(
  connection_state: Connection,
  reason: stratus.CloseReason,
) -> Nil {
  let can_reconnect = case reason {
    stratus.NotProvided -> True
    stratus.Custom(custom_reason) -> {
      let code = stratus.get_custom_code(custom_reason)
      let allowed_codes = [4000, 4001, 4002, 4003, 4005, 4007, 4008, 4009]

      allowed_codes
      |> list.contains(code)
    }
    _ -> False
  }

  case can_reconnect, connection_state {
    True, _ -> try_resume(connection_state)
    False, Welcomed(heartbeat_manager:, ..)
    | False, Identified(heartbeat_manager:, ..)
    -> process.send(heartbeat_manager, StopHeartbeats)
    False, _ -> Nil
  }
}

type ResumingInfo {
  ResumingInfo(
    heartbeat_manager: Subject(HeartbeatManagerMessage),
    sequence: Option(Int),
    resume_gateway_url: String,
    session_id: String,
  )
}

fn try_resume(connection_state: Connection) -> Nil {
  case connection_state {
    Identified(..) ->
      resume(
        connection_state,
        ResumingInfo(
          heartbeat_manager: connection_state.heartbeat_manager,
          sequence: connection_state.sequence,
          resume_gateway_url: connection_state.resume_gateway_url,
          session_id: connection_state.session_id,
        ),
      )
    _ -> reconnect(connection_state)
  }
}

fn resume(connection_state: Connection, resuming_info: ResumingInfo) -> Nil {
  let request_url =
    resuming_info.resume_gateway_url
    |> string.replace(each: "wss://", with: "https://")
    |> string.append(suffix: "?v=10&encoding=json")

  let request_result =
    request.to(request_url)
    |> result.replace_error(grom.InvalidGatewayUrl(request_url))

  use request <-
    fn(next) {
      case request_result {
        Ok(request) -> next(request)
        Error(_) -> reconnect(connection_state)
      }
    }

  let websocket_result =
    stratus.new(request:, state: connection_state)
    |> stratus.on_message(on_message)
    |> stratus.on_close(try_reconnect)
    |> stratus.start

  // AHHHHHHHHH THIS IS SO FUCKING UGLY
  // BUT NO TYPE ANNOTATIONS KILLS MY LSP
  // HERE'S THE VERSION WITHOUT THEM
  // 
  // use websocket <-
  //   fn(next) {
  //     case websocket_result {
  //       Ok(websocket) -> next(websocket)
  //       Error(_) -> reconnect(connection_state)
  //     }
  //   }
  use
    websocket: actor.Started(
      Subject(stratus.InternalMessage(StratusUserMessage)),
    )
  <-
    fn(
      next: fn(
        actor.Started(Subject(stratus.InternalMessage(StratusUserMessage))),
      ) ->
        Nil,
    ) -> Nil {
      case websocket_result {
        Ok(websocket) -> next(websocket)
        Error(_) -> reconnect(connection_state)
      }
    }

  process.send(connection_state.manager, UpdateWebsocket(to: websocket.data))
  process.send(
    connection_state.manager,
    SendUserMessage(StartSendResume(resuming_info)),
  )
  process.send(resuming_info.heartbeat_manager, StopHeartbeats)
}

fn reconnect(connection_state: Connection) -> Nil {
  case connection_state {
    Welcomed(heartbeat_manager:, ..) | Identified(heartbeat_manager:, ..) ->
      process.send(heartbeat_manager, StopHeartbeats)
    _ -> Nil
  }

  // yes, i know this was done before in start
  // cry about it or make a PR lol, it's too late for me to do ts
  let request_result =
    request.to(connection_state.gateway_url)
    |> result.replace_error(grom.InvalidGatewayUrl(connection_state.gateway_url))

  use request <-
    fn(next) {
      case request_result {
        Ok(request) -> next(request)
        Error(_) -> Nil
      }
    }

  let start_result =
    stratus.new(
      request,
      GettingReady(
        gateway_url: connection_state.gateway_url,
        manager: connection_state.manager,
        subject: connection_state.subject,
        identify: connection_state.identify,
      ),
    )
    |> stratus.on_message(on_message)
    |> stratus.on_close(try_reconnect)
    |> stratus.start
    |> result.map_error(grom.CouldNotInitializeWebsocketConnection)

  use
    websocket: actor.Started(
      Subject(stratus.InternalMessage(StratusUserMessage)),
    )
  <-
    fn(next) {
      case start_result {
        Ok(websocket) -> next(websocket)
        Error(_) -> Nil
      }
    }

  process.send(connection_state.manager, UpdateWebsocket(to: websocket.data))
}

fn on_connection_manager_message(
  current: ConnectionManagerState,
  message: ConnectionManagerMessage,
) {
  case message {
    UpdateWebsocket(to: new) -> {
      list.each(current.queued_messages, fn(msg) {
        msg
        |> stratus.to_user_message
        |> process.send(new, _)
      })

      actor.continue(
        ConnectionManagerState(websocket: Some(new), queued_messages: []),
      )
    }
    SendUserMessage(msg) ->
      case current.websocket {
        Some(ws) -> {
          msg
          |> stratus.to_user_message
          |> process.send(ws, _)
          actor.continue(current)
        }
        None ->
          actor.continue(
            ConnectionManagerState(..current, queued_messages: [
              msg,
              ..current.queued_messages
            ]),
          )
      }
  }
}

pub fn identify(
  client: grom.Client,
  intents intents: List(Intent),
) -> BaseIdentifyMessage {
  BaseIdentifyMessage(
    token: client.token,
    properties: IdentifyProperties(
      os: operating_system.name(),
      browser: "grom",
      device: "grom",
    ),
    supports_compression: False,
    max_offline_members: None,
    presence: None,
    intents:,
  )
}

pub fn identify_with_presence(
  identify: BaseIdentifyMessage,
  presence: UpdatePresenceMessage,
) -> BaseIdentifyMessage {
  BaseIdentifyMessage(..identify, presence: Some(presence))
}

pub fn update_presence(
  gateway: Subject(Message),
  using message: UpdatePresenceMessage,
) -> Nil {
  process.send(gateway, MessageFromUser(StartPresenceUpdate(message)))
}

pub fn update_voice_state(
  gateway: Subject(Message),
  using message: UpdateVoiceStateMessage,
) -> Nil {
  process.send(gateway, MessageFromUser(StartVoiceStateUpdate(message)))
}

pub fn request_guild_members(
  gateway: Subject(Message),
  using message: RequestGuildMembersMessage,
) -> Nil {
  process.send(gateway, MessageFromUser(StartGuildMembersRequest(message)))
}

/// It's possible that this function is buggy, and I cannot test it right now.
/// If you use multiple shards, you might:
/// a) receive multiple SoundboardSounds events with the same data
/// b) receive multiple SoundboardSounds events with different data based on the guild-shard relationship
/// Please report any usage of this function with multiple shards in issues.
pub fn request_soundboard_sounds(
  gateway: Subject(Message),
  for guild_ids: List(String),
) -> Nil {
  process.send(
    gateway,
    MessageFromUser(StartSoundboardSoundsRequest(guild_ids)),
  )
}

fn on_message(
  connection_state: Connection,
  message: stratus.Message(StratusUserMessage),
  connection: stratus.Connection,
) -> stratus.Next(Connection, StratusUserMessage) {
  echo message
  case message {
    stratus.Text(text_message) ->
      on_text_message(connection_state, connection, text_message)
    stratus.Binary(_) -> stratus.continue(connection_state)
    stratus.User(StartIdentify(true_state)) ->
      on_start_identify(true_state, connection)
    stratus.User(StartSendHeartbeat) ->
      on_start_send_heartbeat(connection_state, connection)
    stratus.User(UserMessage(StartGuildMembersRequest(message))) ->
      on_start_guild_members_request(connection_state, connection, message)
    stratus.User(UserMessage(StartVoiceStateUpdate(message))) ->
      on_start_voice_state_update(connection_state, connection, message)
    stratus.User(UserMessage(StartPresenceUpdate(message))) ->
      on_start_presence_update(connection_state, connection, message)
    stratus.User(UserMessage(StartSoundboardSoundsRequest(ids))) ->
      on_start_soundboard_sounds_request(connection_state, connection, ids)
    stratus.User(StartSendResume(resuming_info)) ->
      on_start_resume(connection_state, connection, resuming_info)
    stratus.User(StartHeartbeatInequalityDisconnect) ->
      on_start_heartbeat_inequality_disconnect(connection_state, connection)
  }
}

fn on_start_heartbeat_inequality_disconnect(
  connection_state: Connection,
  connection: stratus.Connection,
) -> stratus.Next(Connection, StratusUserMessage) {
  let _ =
    connection
    |> stratus.close(because: stratus.GoingAway(body: <<>>))

  reconnect(connection_state)

  stratus.stop()
}

fn on_start_resume(
  connection_state: Connection,
  connection: stratus.Connection,
  resuming_info: ResumingInfo,
) -> stratus.Next(Connection, a) {
  let message =
    ResumeMessage(
      token: connection_state.identify.token,
      session_id: resuming_info.session_id,
      // this seems to be a crime
      last_sequence: resuming_info.sequence |> option.unwrap(0),
    )

  let send_result =
    message
    |> resume_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn on_start_guild_members_request(
  connection_state: Connection,
  connection: stratus.Connection,
  msg: RequestGuildMembersMessage,
) -> stratus.Next(Connection, a) {
  let send_result =
    msg
    |> request_guild_members_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn on_start_voice_state_update(
  connection_state: Connection,
  connection: stratus.Connection,
  msg: UpdateVoiceStateMessage,
) -> stratus.Next(Connection, a) {
  let send_result =
    msg
    |> update_voice_state_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn on_start_presence_update(
  connection_state: Connection,
  connection: stratus.Connection,
  msg: UpdatePresenceMessage,
) -> stratus.Next(Connection, a) {
  let send_result =
    msg
    |> update_presence_to_json(True)
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn on_start_soundboard_sounds_request(
  connection_state: Connection,
  connection: stratus.Connection,
  guild_ids: List(String),
) -> stratus.Next(Connection, a) {
  let json =
    json.object([
      #("op", json.int(31)),
      #("d", json.object([#("guild_ids", json.array(guild_ids, json.string))])),
    ])

  let send_result =
    json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn send_error(err: grom.Error, connection_state: Connection) {
  let next =
    process.call_forever(connection_state.subject, MessageFromDiscord(
      ErrorEvent(err),
      _,
    ))

  case next {
    ShardContinue -> stratus.continue(connection_state)
    ShardStop -> stratus.stop()
    ShardStopAbnormal(reason) -> stratus.stop_abnormal(reason)
  }
}

fn on_text_message(
  connection_state: Connection,
  connection: stratus.Connection,
  text_message: String,
) -> stratus.Next(Connection, StratusUserMessage) {
  use message <-
    fn(next) {
      case parse_message(text_message) {
        Ok(msg) -> next(msg)
        Error(err) -> send_error(err, connection_state)
      }
    }

  case message {
    Hello(event) -> on_hello_event(connection_state, event)
    Dispatch(sequence, message) ->
      on_dispatch(connection_state, sequence, message)
    HeartbeatAcknowledged -> on_heartbeat_acknowledged(connection_state)
    HeartbeatRequest -> on_heartbeat_request(connection_state)
    ReconnectRequest -> on_reconnect_request(connection_state, connection)
    InvalidSession(can_reconnect) ->
      on_invalid_session(connection_state, can_reconnect)
  }
}

fn on_invalid_session(
  connection_state: Connection,
  can_resume: Bool,
) -> stratus.Next(Connection, a) {
  case can_resume, connection_state {
    True, Identified(..) ->
      resume(
        connection_state,
        ResumingInfo(
          heartbeat_manager: connection_state.heartbeat_manager,
          sequence: connection_state.sequence,
          resume_gateway_url: connection_state.resume_gateway_url,
          session_id: connection_state.session_id,
        ),
      )
    _, _ -> reconnect(connection_state)
  }
  stratus.stop()
}

fn on_reconnect_request(
  connection_state: Connection,
  connection: stratus.Connection,
) -> stratus.Next(a, b) {
  let _ = stratus.close(connection, because: stratus.NotProvided)

  try_resume(connection_state)
  stratus.stop()
}

fn on_dispatch(
  connection_state: Connection,
  sequence: Int,
  message: DispatchedMessage,
) -> stratus.Next(Connection, a) {
  case connection_state {
    GettingReady(..) -> stratus.continue(connection_state)
    Welcomed(..) ->
      case message {
        Ready(msg) ->
          on_ready(
            connection_state,
            connection_state.heartbeat_manager,
            sequence,
            msg,
          )
        _ -> stratus.continue(connection_state)
      }
    Identified(..) -> {
      let event = case message {
        // technically impossible
        Ready(msg) -> ReadyEvent(msg)

        Resumed -> ResumedEvent
        RateLimited(msg) -> RateLimitedEvent(msg)
        ApplicationCommandPermissionsUpdated(perms) ->
          ApplicationCommandPermissionsUpdatedEvent(perms)
        AutoModerationRuleCreated(rule) -> AutoModerationRuleCreatedEvent(rule)
        AutoModerationRuleUpdated(rule) -> AutoModerationRuleUpdatedEvent(rule)
        AutoModerationRuleDeleted(rule) -> AutoModerationRuleDeletedEvent(rule)
        AutoModerationActionExecuted(msg) ->
          AutoModerationActionExecutedEvent(msg)
        ChannelCreated(channel) -> ChannelCreatedEvent(channel)
        ChannelUpdated(channel) -> ChannelUpdatedEvent(channel)
        ChannelDeleted(channel) -> ChannelDeletedEvent(channel)
        ThreadCreated(msg) -> ThreadCreatedEvent(msg)
        ThreadUpdated(thread) -> ThreadUpdatedEvent(thread)
        ThreadDeleted(msg) -> ThreadDeletedEvent(msg)
        ThreadListSynced(msg) -> ThreadListSyncedEvent(msg)
        ThreadMemberUpdated(msg) -> ThreadMemberUpdatedEvent(msg)
        PresenceUpdated(msg) -> PresenceUpdatedEvent(msg)
        ThreadMembersUpdated(msg) -> ThreadMembersUpdatedEvent(msg)
        ChannelPinsUpdated(msg) -> ChannelPinsUpdatedEvent(msg)
        EntitlementCreated(entitlement) -> EntitlementCreatedEvent(entitlement)
        EntitlementUpdated(entitlement) -> EntitlementUpdatedEvent(entitlement)
        EntitlementDeleted(entitlement) -> EntitlementDeletedEvent(entitlement)
        GuildCreated(msg) -> GuildCreatedEvent(msg)
        GuildUpdated(guild) -> GuildUpdatedEvent(guild)
        GuildDeleted(guild) -> GuildDeletedEvent(guild)
        AuditLogEntryCreated(msg) -> AuditLogEntryCreatedEvent(msg)
        GuildBanCreated(msg) -> GuildBanCreatedEvent(msg)
        GuildBanDeleted(msg) -> GuildBanDeletedEvent(msg)
        GuildEmojisUpdated(msg) -> GuildEmojisUpdatedEvent(msg)
        GuildStickersUpdated(msg) -> GuildStickersUpdatedEvent(msg)
        GuildIntegrationsUpdated(msg) -> GuildIntegrationsUpdatedEvent(msg)
        GuildMemberCreated(msg) -> GuildMemberCreatedEvent(msg)
        GuildMemberDeleted(msg) -> GuildMemberDeletedEvent(msg)
        GuildMemberUpdated(msg) -> GuildMemberUpdatedEvent(msg)
        GuildMembersChunk(msg) -> GuildMembersChunkEvent(msg)
        RoleCreated(msg) -> RoleCreatedEvent(msg)
        RoleUpdated(msg) -> RoleUpdatedEvent(msg)
        RoleDeleted(msg) -> RoleDeletedEvent(msg)
        ScheduledEventCreated(event) -> ScheduledEventCreatedEvent(event)
        ScheduledEventUpdated(event) -> ScheduledEventUpdatedEvent(event)
        ScheduledEventDeleted(event) -> ScheduledEventDeletedEvent(event)
        ScheduledEventUserCreated(msg) -> ScheduledEventUserCreatedEvent(msg)
        ScheduledEventUserDeleted(msg) -> ScheduledEventUserDeletedEvent(msg)
        GuildSoundboardSoundCreated(sound) ->
          GuildSoundboardSoundCreatedEvent(sound)
        GuildSoundboardSoundUpdated(sound) ->
          GuildSoundboardSoundUpdatedEvent(sound)
        GuildSoundboardSoundDeleted(msg) ->
          GuildSoundboardSoundDeletedEvent(msg)
        GuildSoundboardSoundsUpdated(msg) ->
          GuildSoundboardSoundsUpdatedEvent(msg)
        SoundboardSounds(msg) -> SoundboardSoundsEvent(msg)
        IntegrationCreated(msg) -> IntegrationCreatedEvent(msg)
        IntegrationUpdated(msg) -> IntegrationUpdatedEvent(msg)
        IntegrationDeleted(msg) -> IntegrationDeletedEvent(msg)
        InviteCreated(msg) -> InviteCreatedEvent(msg)
        InviteDeleted(msg) -> InviteDeletedEvent(msg)
        MessageCreated(msg) -> MessageCreatedEvent(msg)
        MessageUpdated(msg) -> MessageUpdatedEvent(msg)
        MessageDeleted(msg) -> MessageDeletedEvent(msg)
        MessagesBulkDeleted(msg) -> MessagesBulkDeletedEvent(msg)
        MessageReactionCreated(msg) -> MessageReactionCreatedEvent(msg)
        MessageReactionDeleted(msg) -> MessageReactionDeletedEvent(msg)
        MessageAllReactionsDeleted(msg) -> MessageAllReactionsDeletedEvent(msg)
        MessageEmojiReactionsDeleted(msg) ->
          MessageEmojiReactionsDeletedEvent(msg)
        TypingStarted(msg) -> TypingStartedEvent(msg)
        CurrentUserUpdated(user) -> CurrentUserUpdatedEvent(user)
        VoiceChannelEffectSent(msg) -> VoiceChannelEffectSentEvent(msg)
        VoiceStateUpdated(voice_state) -> VoiceStateUpdatedEvent(voice_state)
        VoiceServerUpdated(msg) -> VoiceServerUpdatedEvent(msg)
        InteractionCreated(interaction) -> InteractionCreatedEvent(interaction)
        StageInstanceCreated(stage_instance) ->
          StageInstanceCreatedEvent(stage_instance)
        StageInstanceUpdated(stage_instance) ->
          StageInstanceUpdatedEvent(stage_instance)
        StageInstanceDeleted(stage_instance) ->
          StageInstanceDeletedEvent(stage_instance)
        SubscriptionCreated(subscription) ->
          SubscriptionCreatedEvent(subscription)
        SubscriptionUpdated(subscription) ->
          SubscriptionUpdatedEvent(subscription)
        SubscriptionDeleted(subscription) ->
          SubscriptionDeletedEvent(subscription)
        PollVoteCreated(msg) -> PollVoteCreatedEvent(msg)
        PollVoteDeleted(msg) -> PollVoteDeletedEvent(msg)
        UnknownDispatchedMessage -> UnknownEvent
      }

      let next =
        process.call_forever(connection_state.subject, MessageFromDiscord(
          event,
          _,
        ))

      case next {
        ShardContinue ->
          stratus.continue(
            Identified(..connection_state, sequence: Some(sequence)),
          )
        ShardStop -> stratus.stop()
        ShardStopAbnormal(reason) -> stratus.stop_abnormal(reason)
      }
    }
  }
}

fn on_ready(
  connection_state: Connection,
  heartbeat_manager: Subject(HeartbeatManagerMessage),
  sequence: Int,
  message: ReadyMessage,
) -> stratus.Next(Connection, a) {
  let next =
    process.call_forever(connection_state.subject, MessageFromDiscord(
      ReadyEvent(message),
      _,
    ))

  let new_state =
    Identified(
      gateway_url: connection_state.gateway_url,
      manager: connection_state.manager,
      subject: connection_state.subject,
      identify: connection_state.identify,
      heartbeat_manager:,
      sequence: Some(sequence),
      session_id: message.session_id,
      resume_gateway_url: message.resume_gateway_url,
    )

  case next {
    ShardContinue -> stratus.continue(new_state)
    ShardStop -> stratus.stop()
    ShardStopAbnormal(reason) -> stratus.stop_abnormal(reason)
  }
}

fn on_heartbeat_request(
  connection_state: Connection,
) -> stratus.Next(Connection, a) {
  start_send_heartbeat(connection_state)
  stratus.continue(connection_state)
}

fn on_heartbeat_acknowledged(
  connection_state: Connection,
) -> stratus.Next(Connection, a) {
  case connection_state {
    GettingReady(..) -> stratus.continue(connection_state)
    Welcomed(heartbeat_manager:, ..) | Identified(heartbeat_manager:, ..) -> {
      process.send(heartbeat_manager, HeartbeatAck)
      stratus.continue(connection_state)
    }
  }
}

fn on_hello_event(
  connection_state: Connection,
  event: HelloMessage,
) -> stratus.Next(Connection, a) {
  // Stop any existing heartbeat manager before creating a new one.
  // This is necessary when reconnecting or resuming, where a heartbeat manager
  // from the previous connection may still be running.
  case connection_state {
    Welcomed(heartbeat_manager:, ..) | Identified(heartbeat_manager:, ..) ->
      process.send(heartbeat_manager, StopHeartbeats)
    GettingReady(..) -> Nil
  }

  let heartbeat_start_result =
    start_heartbeats(
      every: event.heartbeat_interval,
      send_to: connection_state.manager,
    )

  case heartbeat_start_result {
    Ok(heartbeat_manager) ->
      case connection_state {
        GettingReady(..) | Welcomed(..) -> {
          // Fresh connection: transition to Welcomed and send IDENTIFY.
          let state =
            Welcomed(
              gateway_url: connection_state.gateway_url,
              identify: connection_state.identify,
              subject: connection_state.subject,
              manager: connection_state.manager,
              heartbeat_manager: heartbeat_manager.data,
              sequence: None,
            )
          send_identify(state)
          stratus.continue(state)
        }
        Identified(..) -> {
          // Resume: keep the Identified state (preserving session_id,
          // resume_gateway_url, and sequence) and only replace the
          // heartbeat manager. The RESUME payload was already queued
          // in resume(), so we must not send IDENTIFY here.
          stratus.continue(
            Identified(
              ..connection_state,
              heartbeat_manager: heartbeat_manager.data,
            ),
          )
        }
      }
    Error(err) -> send_error(err, connection_state)
  }
}

fn send_identify(connection_state: Connection) -> Nil {
  process.send(
    connection_state.manager,
    SendUserMessage(StartIdentify(connection_state)),
  )
}

fn on_start_identify(
  connection_state: Connection,
  connection: stratus.Connection,
) -> stratus.Next(Connection, a) {
  let send_result =
    connection_state.identify
    |> identify_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> stratus.continue(connection_state)
    Error(err) -> send_error(err, connection_state)
  }
}

fn start_send_heartbeat(connection_state: Connection) -> Nil {
  process.send(connection_state.manager, SendUserMessage(StartSendHeartbeat))
}

fn on_start_send_heartbeat(
  connection_state: Connection,
  connection: stratus.Connection,
) -> stratus.Next(Connection, a) {
  use heartbeat_manager, sequence <-
    fn(next) {
      case connection_state {
        GettingReady(..) -> stratus.continue(connection_state)
        Welcomed(sequence:, heartbeat_manager:, ..)
        | Identified(sequence:, heartbeat_manager:, ..) ->
          next(heartbeat_manager, sequence)
      }
    }

  let send_result =
    sequence
    |> HeartbeatMessage
    |> heartbeat_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case send_result {
    Ok(_) -> {
      process.send(heartbeat_manager, HeartbeatSent)
      stratus.continue(connection_state)
    }
    Error(err) -> send_error(err, connection_state)
  }
}

fn parse_message(text_message: String) -> Result(ReceivedMessage, grom.Error) {
  text_message
  |> json.parse(using: message_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

// HEARTBEATS ------------------------------------------------------------------

type HeartbeatManagerMessage {
  HeartbeatSent
  HeartbeatAck
  ResetHeartbeatCount
  GetHeartbeatCount(reply_to: Subject(HeartbeatCount))
  SendHeartbeat
  StopHeartbeats
}

type HeartbeatState {
  HeartbeatState(
    interval: Duration,
    subject: Subject(HeartbeatManagerMessage),
    count: HeartbeatCount,
    connection_manager: Subject(ConnectionManagerMessage),
  )
}

type HeartbeatCount {
  HeartbeatCount(heartbeat: Int, heartbeat_ack: Int)
}

fn start_heartbeats(
  every interval: Duration,
  send_to connection_manager: Subject(ConnectionManagerMessage),
) -> Result(actor.Started(Subject(HeartbeatManagerMessage)), grom.Error) {
  let initial_wait =
    interval
    |> duration.to_seconds
    |> float.multiply(heartbeat_jitter())
    |> float.round
    |> duration.seconds

  actor.new_with_initialiser(20, fn(subject) {
    let selector =
      process.new_selector()
      |> process.select(subject)

    subject
    |> process.send_after(
      initial_wait
        |> duration.to_seconds
        |> float.multiply(1000.0)
        |> float.round,
      SendHeartbeat,
    )

    actor.initialised(HeartbeatState(
      interval:,
      subject:,
      connection_manager:,
      count: HeartbeatCount(0, 0),
    ))
    |> actor.selecting(selector)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(on_heartbeat_manager_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

fn on_heartbeat_manager_message(
  current: HeartbeatState,
  message: HeartbeatManagerMessage,
) -> actor.Next(HeartbeatState, a) {
  case message {
    HeartbeatSent ->
      actor.continue(
        HeartbeatState(
          ..current,
          count: HeartbeatCount(
            ..current.count,
            heartbeat: current.count.heartbeat + 1,
          ),
        ),
      )
    HeartbeatAck ->
      actor.continue(
        HeartbeatState(
          ..current,
          count: HeartbeatCount(
            ..current.count,
            heartbeat_ack: current.count.heartbeat_ack + 1,
          ),
        ),
      )
    SendHeartbeat -> {
      use <- check_heartbeat_equality(current)

      // tell stratus to actually send it via the websocket
      process.send(
        current.connection_manager,
        SendUserMessage(StartSendHeartbeat),
      )

      // schedule sending the next heartbeat
      process.send_after(
        current.subject,
        current.interval
          |> duration.to_seconds
          |> float.multiply(1000.0)
          |> float.round,
        SendHeartbeat,
      )

      // count will be increased when it actually sends, this just tells stratus to send it, it can fail
      actor.continue(current)
    }
    GetHeartbeatCount(reply_to: requester) -> {
      actor.send(requester, current.count)
      actor.continue(current)
    }
    ResetHeartbeatCount ->
      actor.continue(HeartbeatState(..current, count: HeartbeatCount(0, 0)))
    StopHeartbeats -> actor.stop()
  }
}

fn check_heartbeat_equality(
  current: HeartbeatState,
  next: fn() -> actor.Next(a, b),
) -> actor.Next(a, b) {
  case current.count.heartbeat == current.count.heartbeat_ack {
    True -> next()
    False -> {
      process.send(
        current.connection_manager,
        SendUserMessage(StartHeartbeatInequalityDisconnect),
      )
      actor.stop()
    }
  }
}

// sounds better
const heartbeat_jitter: fn() -> Float = float.random
