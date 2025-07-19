import gleam/bool
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
import grom
import grom/channel/thread.{type Thread}
import grom/emoji.{type Emoji}
import grom/guild/auto_moderation
import grom/guild/role.{type Role}
import grom/guild_member.{type GuildMember}
import grom/image
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/modification.{type Modification, Skip}
import grom/sticker.{type Sticker}
import grom/user.{type User}

// TYPES ----------------------------------------------------------------------

pub type Guild {
  Guild(
    id: String,
    name: String,
    icon: Option(String),
    icon_hash: Option(String),
    splash: Option(String),
    discovery_splash: Option(String),
    is_current_user_owner: Option(Bool),
    owner_id: String,
    current_user_permissions: Option(String),
    afk_channel_id: Option(String),
    // TODO: Maybe make this a Duration
    afk_timeout: Int,
    is_widget_enabled: Option(Bool),
    widget_channel_id: Option(String),
    verification_level: VerificationLevel,
    default_message_notification_setting: DefaultMessageNotificationSetting,
    explicit_content_filter_setting: ExplicitContentFilterSetting,
    roles: List(Role),
    emojis: List(Emoji),
    features: List(Feature),
    mfa_level: MfaLevel,
    application_id: Option(String),
    system_channel_id: Option(String),
    system_channel_flags: List(SystemChannelFlag),
    rules_channel_id: Option(String),
    max_presences: Option(Int),
    max_members: Option(Int),
    vanity_url_code: Option(String),
    description: Option(String),
    banner_hash: Option(String),
    premium_tier: PremiumTier,
    premium_subscription_count: Option(Int),
    preferred_locale: String,
    public_updates_channel_id: Option(String),
    max_video_channel_users: Option(Int),
    max_stage_video_channel_users: Option(Int),
    approximate_member_count: Option(Int),
    approximate_presence_count: Option(Int),
    welcome_screen: Option(WelcomeScreen),
    nsfw_level: NsfwLevel,
    stickers: Option(List(Sticker)),
    is_premium_progress_bar_enabled: Bool,
    safety_alerts_channel_id: Option(String),
    incidents_data: Option(IncidentsData),
  )
}

pub type IncidentsData {
  IncidentsData(
    invites_disabled_until: Option(Timestamp),
    dms_disabled_until: Option(Timestamp),
    dms_spam_disabled_at: Option(Timestamp),
    raid_detected_at: Option(Timestamp),
  )
}

pub type DefaultMessageNotificationSetting {
  NotifyForAllMessages
  NotifyOnlyForMentions
}

pub type VerificationLevel {
  NoVerification
  LowVerification
  MediumVerification
  HighVerification
  VeryHighVerification
}

pub type ExplicitContentFilterSetting {
  ExplicitContentFilterDisabled
  ExplicitContentFilterForMembersWithoutRoles
  ExplicitContentFilterForAllMembers
}

pub type MfaLevel {
  NoMfaRequired
  MfaRequired
}

pub type Feature {
  HasAnimatedBanner
  HasAnimatedIcon
  UsesOldPermissionConfigurationBehavior
  UsesAutoModeration
  HasBanner
  IsCommunity
  EnabledMonetization
  HasRoleSubscriptionPromotionPage
  IsDeveloperSupportServer
  IsDiscoverable
  IsFeaturable
  HasInvitesDisabled
  CanSetInviteSplash
  HasMemberVerificationGateEnabled
  HasMoreSoundboardSounds
  HasMoreStickers
  CanCreateAnnouncementChannels
  IsPartnered
  CanBePreviewed
  HasRaidAlertsDisabled
  CanSetRoleIcons
  HasRoleSubscriptionsAvailableForPurchase
  HasRoleSubscriptionsEnabled
  CreatedSoundboardSounds
  HasTicketedEventsEnabled
  CanSetVanityUrl
  IsVerified
  CanSet384KbpsBitrate
  HasWelcomeScreenEnabled
  CanHaveGuestInvites
  CanSetEnhancedRoleColors
}

pub type SystemChannelFlag {
  SuppressJoinNotifications
  SuppressPremiumSubscriptionNotifications
  SuppressGuildReminderNotifications
  SuppressJoinNotificationReplies
  SuppressRoleSubscriptionPurchaseNotifications
  SuppressRoleSubscriptionPurchaseNotificationReplies
}

pub type PremiumTier {
  NoPremiumTier
  PremiumTier1
  PremiumTier2
  PremiumTier3
}

pub type NsfwLevel {
  NsfwLevelDefault
  NsfwExplicit
  NsfwSafe
  NsfwAgeRestricted
}

pub type Preview {
  Preview(
    id: String,
    name: String,
    icon_hash: Option(String),
    splash_hash: Option(String),
    discovery_splash_hash: Option(String),
    emojis: List(Emoji),
    features: List(Feature),
    approximate_member_count: Int,
    approximate_presence_count: Int,
    description: Option(String),
    stickers: List(Sticker),
  )
}

pub type Ban {
  Ban(reason: Option(String), user: User)
}

pub type Template {
  Template(
    code: String,
    name: String,
    description: Option(String),
    usage_count: Int,
    creator_id: String,
    creator: User,
    created_at: Timestamp,
    updated_at: Timestamp,
    source_guild_id: String,
    is_dirty: Option(Bool),
  )
}

pub type WelcomeScreen {
  WelcomeScreen(
    description: Option(String),
    welcome_channels: List(WelcomeChannel),
  )
}

pub type WelcomeChannel {
  WelcomeChannel(
    channel_id: String,
    description: String,
    emoji_id: Option(String),
    emoji_name: Option(String),
  )
}

pub opaque type Modify {
  Modify(
    name: Option(String),
    verification_level: Option(VerificationLevel),
    default_message_notification_setting: Option(
      DefaultMessageNotificationSetting,
    ),
    explicit_content_filter_setting: Option(ExplicitContentFilterSetting),
    afk_channel_id: Modification(String),
    afk_timeout: Option(Int),
    icon: Modification(image.Data),
    owner_id: Option(String),
    splash: Modification(image.Data),
    discovery_splash: Modification(image.Data),
    banner: Modification(image.Data),
    system_channel_id: Modification(String),
    system_channel_flags: Option(List(SystemChannelFlag)),
    rules_channel_id: Modification(String),
    public_updates_channel_id: Modification(String),
    preferred_locale: Modification(String),
    features: Option(List(Feature)),
    description: Modification(String),
    is_premium_progress_bar_enabled: Option(Bool),
    safety_alerts_channel_id: Modification(String),
  )
}

pub type ReceivedThreads {
  ReceivedThreads(threads: List(Thread), current_members: List(thread.Member))
}

pub type BulkBanResponse {
  BulkBanResponse(
    banned_users_ids: List(String),
    failed_users_ids: List(String),
  )
}

pub type RoleToMove {
  RoleToMove(id: String, position: Option(Int))
}

// FLAGS ------------------------------------------------------------------

@internal
pub fn bits_system_channel_flags() -> List(#(Int, SystemChannelFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), SuppressJoinNotifications),
    #(int.bitwise_shift_left(1, 1), SuppressPremiumSubscriptionNotifications),
    #(int.bitwise_shift_left(1, 2), SuppressGuildReminderNotifications),
    #(int.bitwise_shift_left(1, 3), SuppressJoinNotificationReplies),
    #(
      int.bitwise_shift_left(1, 4),
      SuppressRoleSubscriptionPurchaseNotifications,
    ),
    #(
      int.bitwise_shift_left(1, 5),
      SuppressRoleSubscriptionPurchaseNotificationReplies,
    ),
  ]
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Guild) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon <- decode.field("icon", decode.optional(decode.string))
  use icon_hash <- decode.optional_field(
    "icon_hash",
    None,
    decode.optional(decode.string),
  )
  use splash <- decode.field("splash", decode.optional(decode.string))
  use discovery_splash <- decode.field(
    "discovery_splash",
    decode.optional(decode.string),
  )
  use is_current_user_owner <- decode.optional_field(
    "owner",
    None,
    decode.optional(decode.bool),
  )
  use owner_id <- decode.field("owner_id", decode.string)
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(decode.string),
  )
  use afk_channel_id <- decode.field(
    "afk_channel_id",
    decode.optional(decode.string),
  )
  use afk_timeout <- decode.field("afk_timeout", decode.int)
  use is_widget_enabled <- decode.optional_field(
    "widget_enabled",
    None,
    decode.optional(decode.bool),
  )
  use widget_channel_id <- decode.optional_field(
    "widget_channel_id",
    None,
    decode.optional(decode.string),
  )
  use verification_level <- decode.field(
    "verification_level",
    verification_level_decoder(),
  )
  use default_message_notification_setting <- decode.field(
    "default_message_notifications",
    default_message_notification_setting_decoder(),
  )
  use explicit_content_filter_setting <- decode.field(
    "explicit_content_filter",
    explicit_content_filter_setting_decoder(),
  )
  use roles <- decode.field("roles", decode.list(role.decoder()))
  use emojis <- decode.field("emojis", decode.list(emoji.decoder()))
  use features <- decode.field("features", decode.list(feature_decoder()))
  use mfa_level <- decode.field("mfa_level", mfa_level_decoder())
  use application_id <- decode.field(
    "application_id",
    decode.optional(decode.string),
  )
  use system_channel_id <- decode.field(
    "system_channel_id",
    decode.optional(decode.string),
  )
  use system_channel_flags <- decode.field(
    "system_channel_flags",
    flags.decoder(bits_system_channel_flags()),
  )
  use rules_channel_id <- decode.field(
    "rules_channel_id",
    decode.optional(decode.string),
  )
  use max_presences <- decode.optional_field(
    "max_presences",
    None,
    decode.optional(decode.int),
  )
  use max_members <- decode.optional_field(
    "max_members",
    None,
    decode.optional(decode.int),
  )
  use vanity_url_code <- decode.field(
    "vanity_url_code",
    decode.optional(decode.string),
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use banner_hash <- decode.field("banner", decode.optional(decode.string))
  use premium_tier <- decode.field("premium_tier", premium_tier_decoder())
  use premium_subscription_count <- decode.optional_field(
    "premium_subscription_count",
    None,
    decode.optional(decode.int),
  )
  use preferred_locale <- decode.field("preferred_locale", decode.string)
  use public_updates_channel_id <- decode.field(
    "public_updates_channel_id",
    decode.optional(decode.string),
  )
  use max_video_channel_users <- decode.optional_field(
    "max_video_channel_users",
    None,
    decode.optional(decode.int),
  )
  use max_stage_video_channel_users <- decode.optional_field(
    "max_stage_video_channel_users",
    None,
    decode.optional(decode.int),
  )
  use approximate_member_count <- decode.optional_field(
    "approximate_member_count",
    None,
    decode.optional(decode.int),
  )
  use approximate_presence_count <- decode.optional_field(
    "approximate_presence_count",
    None,
    decode.optional(decode.int),
  )
  use welcome_screen <- decode.optional_field(
    "welcome_screen",
    None,
    decode.optional(welcome_screen_decoder()),
  )
  use nsfw_level <- decode.field("nsfw_level", nsfw_level_decoder())
  use stickers <- decode.optional_field(
    "stickers",
    None,
    decode.optional(decode.list(sticker.decoder())),
  )
  use is_premium_progress_bar_enabled <- decode.field(
    "premium_progress_bar_enabled",
    decode.bool,
  )
  use safety_alerts_channel_id <- decode.field(
    "safety_alerts_channel_id",
    decode.optional(decode.string),
  )
  use incidents_data <- decode.field(
    "incidents_data",
    decode.optional(incidents_data_decoder()),
  )
  decode.success(Guild(
    id:,
    name:,
    icon:,
    icon_hash:,
    splash:,
    discovery_splash:,
    is_current_user_owner:,
    owner_id:,
    current_user_permissions:,
    afk_channel_id:,
    afk_timeout:,
    is_widget_enabled:,
    widget_channel_id:,
    verification_level:,
    default_message_notification_setting:,
    explicit_content_filter_setting:,
    roles:,
    emojis:,
    features:,
    mfa_level:,
    application_id:,
    system_channel_id:,
    system_channel_flags:,
    rules_channel_id:,
    max_presences:,
    max_members:,
    vanity_url_code:,
    description:,
    banner_hash:,
    premium_tier:,
    premium_subscription_count:,
    preferred_locale:,
    public_updates_channel_id:,
    max_video_channel_users:,
    max_stage_video_channel_users:,
    approximate_member_count:,
    approximate_presence_count:,
    welcome_screen:,
    nsfw_level:,
    stickers:,
    is_premium_progress_bar_enabled:,
    safety_alerts_channel_id:,
    incidents_data:,
  ))
}

@internal
pub fn feature_decoder() -> decode.Decoder(Feature) {
  use variant <- decode.then(decode.string)
  case variant {
    "ANIMATED_BANNER" -> decode.success(HasAnimatedBanner)
    "ANIMATED_ICON" -> decode.success(HasAnimatedIcon)
    "APPLICATION_COMMAND_PERMISSIONS_V2" ->
      decode.success(UsesOldPermissionConfigurationBehavior)
    "AUTO_MODERATION" -> decode.success(UsesAutoModeration)
    "BANNER" -> decode.success(HasBanner)
    "COMMUNITY" -> decode.success(IsCommunity)
    "CREATOR_MONETIZABLE_PROVISIONAL" -> decode.success(EnabledMonetization)
    "CREATOR_STORE_PAGE" -> decode.success(HasRoleSubscriptionPromotionPage)
    "DEVELOPER_SUPPORT_SERVER" -> decode.success(IsDeveloperSupportServer)
    "DISCOVERABLE" -> decode.success(IsDiscoverable)
    "FEATURABLE" -> decode.success(IsFeaturable)
    "INVITES_DISABLED" -> decode.success(HasInvitesDisabled)
    "INVITE_SPLASH" -> decode.success(CanSetInviteSplash)
    "MEMBER_VERIFICATION_GATE_ENABLED" ->
      decode.success(HasMemberVerificationGateEnabled)
    "MORE_SOUNDBOARD" -> decode.success(HasMoreSoundboardSounds)
    "MORE_STICKERS" -> decode.success(HasMoreStickers)
    "NEWS" -> decode.success(CanCreateAnnouncementChannels)
    "PARTNERED" -> decode.success(IsPartnered)
    "PREVIEW_ENABLED" -> decode.success(CanBePreviewed)
    "RAID_ALERTS_DISABLED" -> decode.success(HasRaidAlertsDisabled)
    "ROLE_ICONS" -> decode.success(CanSetRoleIcons)
    "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE" ->
      decode.success(HasRoleSubscriptionsAvailableForPurchase)
    "ROLE_SUBSCRIPTIONS_ENABLED" -> decode.success(HasRoleSubscriptionsEnabled)
    "SOUNDBOARD" -> decode.success(CreatedSoundboardSounds)
    "TICKETED_EVENTS_ENABLED" -> decode.success(HasTicketedEventsEnabled)
    "VANITY_URL" -> decode.success(CanSetVanityUrl)
    "VERIFIED" -> decode.success(IsVerified)
    "VIP_REGIONS" -> decode.success(CanSet384KbpsBitrate)
    "WELCOME_SCREEN_ENABLED" -> decode.success(HasWelcomeScreenEnabled)
    "GUESTS_ENABLED" -> decode.success(CanHaveGuestInvites)
    "ENHANCED_ROLE_COLORS" -> decode.success(CanSetEnhancedRoleColors)
    _ -> decode.failure(HasAnimatedBanner, "Feature")
  }
}

@internal
pub fn default_message_notification_setting_decoder() -> decode.Decoder(
  DefaultMessageNotificationSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NotifyForAllMessages)
    1 -> decode.success(NotifyOnlyForMentions)
    _ ->
      decode.failure(NotifyForAllMessages, "DefaultMessageNotificationSetting")
  }
}

@internal
pub fn explicit_content_filter_setting_decoder() -> decode.Decoder(
  ExplicitContentFilterSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(ExplicitContentFilterDisabled)
    1 -> decode.success(ExplicitContentFilterForMembersWithoutRoles)
    2 -> decode.success(ExplicitContentFilterForAllMembers)
    _ ->
      decode.failure(
        ExplicitContentFilterDisabled,
        "ExplicitContentFilterSetting",
      )
  }
}

@internal
pub fn mfa_level_decoder() -> decode.Decoder(MfaLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoMfaRequired)
    1 -> decode.success(MfaRequired)
    _ -> decode.failure(NoMfaRequired, "MfaLevel")
  }
}

@internal
pub fn verification_level_decoder() -> decode.Decoder(VerificationLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoVerification)
    1 -> decode.success(LowVerification)
    2 -> decode.success(MediumVerification)
    3 -> decode.success(HighVerification)
    4 -> decode.success(VeryHighVerification)
    _ -> decode.failure(NoVerification, "VerificationLevel")
  }
}

@internal
pub fn nsfw_level_decoder() -> decode.Decoder(NsfwLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NsfwLevelDefault)
    1 -> decode.success(NsfwExplicit)
    2 -> decode.success(NsfwSafe)
    3 -> decode.success(NsfwAgeRestricted)
    _ -> decode.failure(NsfwLevelDefault, "NsfwLevel")
  }
}

@internal
pub fn premium_tier_decoder() -> decode.Decoder(PremiumTier) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoPremiumTier)
    1 -> decode.success(PremiumTier1)
    2 -> decode.success(PremiumTier2)
    3 -> decode.success(PremiumTier3)
    _ -> decode.failure(NoPremiumTier, "PremiumTier")
  }
}

@internal
pub fn incidents_data_decoder() -> decode.Decoder(IncidentsData) {
  use invites_disabled_until <- decode.field(
    "invites_disabled_until",
    decode.optional(time_rfc3339.decoder()),
  )
  use dms_disabled_until <- decode.field(
    "dms_disabled_until",
    decode.optional(time_rfc3339.decoder()),
  )
  use dms_spam_disabled_at <- decode.optional_field(
    "dms_spam_disabled_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use raid_detected_at <- decode.optional_field(
    "raid_detected_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  decode.success(IncidentsData(
    invites_disabled_until:,
    dms_disabled_until:,
    dms_spam_disabled_at:,
    raid_detected_at:,
  ))
}

@internal
pub fn welcome_screen_decoder() -> decode.Decoder(WelcomeScreen) {
  use description <- decode.field("description", decode.optional(decode.string))
  use welcome_channels <- decode.field(
    "welcome_channels",
    decode.list(welcome_channel_decoder()),
  )
  decode.success(WelcomeScreen(description:, welcome_channels:))
}

@internal
pub fn welcome_channel_decoder() -> decode.Decoder(WelcomeChannel) {
  use channel_id <- decode.field("channel_id", decode.string)
  use description <- decode.field("description", decode.string)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(WelcomeChannel(
    channel_id:,
    description:,
    emoji_id:,
    emoji_name:,
  ))
}

@internal
pub fn ban_decoder() -> decode.Decoder(Ban) {
  use reason <- decode.field("reason", decode.optional(decode.string))
  use user <- decode.field("user", user.decoder())
  decode.success(Ban(reason:, user:))
}

@internal
pub fn preview_decoder() -> decode.Decoder(Preview) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(decode.string))
  use splash_hash <- decode.field("splash", decode.optional(decode.string))
  use discovery_splash_hash <- decode.field(
    "discovery_splash",
    decode.optional(decode.string),
  )
  use emojis <- decode.field("emojis", decode.list(emoji.decoder()))
  use features <- decode.field("features", decode.list(feature_decoder()))
  use approximate_member_count <- decode.field(
    "approximate_member_count",
    decode.int,
  )
  use approximate_presence_count <- decode.field(
    "approximate_presence_count",
    decode.int,
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use stickers <- decode.field("stickers", decode.list(sticker.decoder()))
  decode.success(Preview(
    id:,
    name:,
    icon_hash:,
    splash_hash:,
    discovery_splash_hash:,
    emojis:,
    features:,
    approximate_member_count:,
    approximate_presence_count:,
    description:,
    stickers:,
  ))
}

@internal
pub fn template_decoder() -> decode.Decoder(Template) {
  use code <- decode.field("code", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use usage_count <- decode.field("usage_count", decode.int)
  use creator_id <- decode.field("creator_id", decode.string)
  use creator <- decode.field("creator", user.decoder())
  use created_at <- decode.field("created_at", time_rfc3339.decoder())
  use updated_at <- decode.field("updated_at", time_rfc3339.decoder())
  use source_guild_id <- decode.field("source_guild_id", decode.string)
  use is_dirty <- decode.field("is_dirty", decode.optional(decode.bool))
  decode.success(Template(
    code:,
    name:,
    description:,
    usage_count:,
    creator_id:,
    creator:,
    created_at:,
    updated_at:,
    source_guild_id:,
    is_dirty:,
  ))
}

@internal
pub fn received_threads_decoder() -> decode.Decoder(ReceivedThreads) {
  use threads <- decode.field("threads", decode.list(thread.decoder()))
  use current_members <- decode.field(
    "members",
    decode.list(thread.member_decoder()),
  )
  decode.success(ReceivedThreads(threads:, current_members:))
}

@internal
pub fn bulk_ban_response_decoder() -> decode.Decoder(BulkBanResponse) {
  use banned_users_ids <- decode.field(
    "banned_users",
    decode.list(decode.string),
  )
  use failed_users_ids <- decode.field(
    "failed_users",
    decode.list(decode.string),
  )

  decode.success(BulkBanResponse(banned_users_ids:, failed_users_ids:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let verification_level = case modify.verification_level {
    Some(level) -> [#("verification_level", verification_level_to_json(level))]
    None -> []
  }

  let default_message_notification_setting = case
    modify.default_message_notification_setting
  {
    Some(setting) -> [
      #(
        "default_message_notifications",
        default_message_notification_setting_to_json(setting),
      ),
    ]
    None -> []
  }

  let explicit_content_filter_setting = case
    modify.explicit_content_filter_setting
  {
    Some(setting) -> [
      #(
        "explicit_content_filter",
        explicit_content_filter_setting_to_json(setting),
      ),
    ]
    None -> []
  }

  let afk_channel_id =
    modify.afk_channel_id
    |> modification.encode("afk_channel_id", json.string)

  let afk_timeout = case modify.afk_timeout {
    Some(timeout) -> [#("afk_timeout", json.int(timeout))]
    None -> []
  }

  let icon =
    modify.icon
    |> modification.encode("icon", image.to_json)

  let owner_id = case modify.owner_id {
    Some(id) -> [#("owner_id", json.string(id))]
    None -> []
  }

  let splash =
    modify.splash
    |> modification.encode("splash", image.to_json)

  let discovery_splash =
    modify.discovery_splash
    |> modification.encode("discovery_splash", image.to_json)

  let banner =
    modify.banner
    |> modification.encode("banner", image.to_json)

  let system_channnel_id =
    modify.system_channel_id
    |> modification.encode("system_channel_id", json.string)

  let system_channel_flags = case modify.system_channel_flags {
    Some(flags) -> [
      #(
        "system_channel_flags",
        flags.encode(flags, bits_system_channel_flags()),
      ),
    ]
    None -> []
  }

  let rules_channel_id =
    modify.rules_channel_id
    |> modification.encode("rules_channel_id", json.string)

  let public_updates_channel_id =
    modify.public_updates_channel_id
    |> modification.encode("public_updates_channel_id", json.string)

  let preferred_locale =
    modify.preferred_locale
    |> modification.encode("preferred_locale", json.string)

  let features = case modify.features {
    Some(features) -> [#("features", json.array(features, feature_to_json))]
    None -> []
  }

  let description =
    modify.description
    |> modification.encode("description", json.string)

  let is_premium_progress_bar_enabled = case
    modify.is_premium_progress_bar_enabled
  {
    Some(premium_progress_bar_enabled) -> [
      #("premium_progress_bar_enabled", json.bool(premium_progress_bar_enabled)),
    ]
    None -> []
  }

  let safety_alerts_channel_id =
    modify.safety_alerts_channel_id
    |> modification.encode("safety_alerts_channel_id", json.string)

  [
    name,
    verification_level,
    default_message_notification_setting,
    explicit_content_filter_setting,
    afk_channel_id,
    afk_timeout,
    icon,
    owner_id,
    splash,
    discovery_splash,
    banner,
    system_channnel_id,
    system_channel_flags,
    rules_channel_id,
    public_updates_channel_id,
    preferred_locale,
    features,
    description,
    is_premium_progress_bar_enabled,
    safety_alerts_channel_id,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn verification_level_to_json(verification_level: VerificationLevel) -> Json {
  case verification_level {
    NoVerification -> 0
    LowVerification -> 1
    MediumVerification -> 2
    HighVerification -> 3
    VeryHighVerification -> 4
  }
  |> json.int
}

@internal
pub fn default_message_notification_setting_to_json(
  setting: DefaultMessageNotificationSetting,
) -> Json {
  case setting {
    NotifyForAllMessages -> 0
    NotifyOnlyForMentions -> 1
  }
  |> json.int
}

@internal
pub fn explicit_content_filter_setting_to_json(
  setting: ExplicitContentFilterSetting,
) -> Json {
  case setting {
    ExplicitContentFilterDisabled -> 0
    ExplicitContentFilterForMembersWithoutRoles -> 1
    ExplicitContentFilterForAllMembers -> 2
  }
  |> json.int
}

@internal
pub fn feature_to_json(feature: Feature) -> Json {
  case feature {
    HasAnimatedBanner -> "ANIMATED_BANNER"
    HasAnimatedIcon -> "ANIMATED_ICON"
    UsesOldPermissionConfigurationBehavior ->
      "APPLICATION_COMMAND_PERMISSIONS_V2"
    UsesAutoModeration -> "AUTO_MODERATION"
    HasBanner -> "BANNER"
    IsCommunity -> "COMMUNITY"
    EnabledMonetization -> "CREATOR_MONETIZABLE_PROVISIONAL"
    HasRoleSubscriptionPromotionPage -> "CREATOR_STORE_PAGE"
    IsDeveloperSupportServer -> "DEVELOPER_SUPPORT_SERVER"
    IsDiscoverable -> "DISCOVERABLE"
    IsFeaturable -> "FEATURABLE"
    HasInvitesDisabled -> "INVITES_DISABLED"
    CanSetInviteSplash -> "INVITE_SPLASH"
    HasMemberVerificationGateEnabled -> "MEMBER_VERIFICATION_GATE_ENABLED"
    HasMoreSoundboardSounds -> "MORE_SOUNDBOARD"
    HasMoreStickers -> "MORE_STICKERS"
    CanCreateAnnouncementChannels -> "NEWS"
    IsPartnered -> "PARTNERED"
    CanBePreviewed -> "PREVIEW_ENABLED"
    HasRaidAlertsDisabled -> "RAID_ALERTS_DISABLED"
    CanSetRoleIcons -> "ROLE_ICONS"
    HasRoleSubscriptionsAvailableForPurchase ->
      "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE"
    HasRoleSubscriptionsEnabled -> "ROLE_SUBSCRIPTIONS_ENABLED"
    CreatedSoundboardSounds -> "SOUNDBOARD"
    HasTicketedEventsEnabled -> "TICKETED_EVENTS_ENABLED"
    CanSetVanityUrl -> "VANITY_URL"
    IsVerified -> "VERIFIED"
    CanSet384KbpsBitrate -> "VIP_REGIONS"
    HasWelcomeScreenEnabled -> "WELCOME_SCREEN_ENABLED"
    CanHaveGuestInvites -> "GUESTS_ENABLED"
    CanSetEnhancedRoleColors -> "ENHANCED_ROLE_COLORS"
  }
  |> json.string
}

@internal
pub fn role_to_move_to_json(role_to_move: RoleToMove) -> Json {
  let id = [#("id", json.string(role_to_move.id))]
  let position = case role_to_move.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  [id, position]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

/// `get_counts`: Whether to get the `approximate_member_count` and `approximate_presence_count`
pub fn get(
  client: grom.Client,
  id guild_id: String,
  get_counts with_counts: Bool,
) -> Result(Guild, grom.Error) {
  let query = [#("with_counts", bool.to_string(with_counts))]

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id)
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_preview(
  client: grom.Client,
  for guild_id: String,
) -> Result(Preview, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/preview")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: preview_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify(
  client: grom.Client,
  id guild_id: String,
  with modify: Modify,
  because reason: Option(String),
) -> Result(Guild, grom.Error) {
  let json = modify |> modify_to_json

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/guilds/" <> guild_id)
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify() -> Modify {
  Modify(
    None,
    None,
    None,
    None,
    Skip,
    None,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    None,
    Skip,
    None,
    Skip,
  )
}

pub fn modify_name(modify: Modify, new name: String) -> Modify {
  Modify(..modify, name: Some(name))
}

pub fn modify_verification_level(
  modify: Modify,
  new verification_level: VerificationLevel,
) -> Modify {
  Modify(..modify, verification_level: Some(verification_level))
}

pub fn modify_default_message_notification_setting(
  modify: Modify,
  new setting: DefaultMessageNotificationSetting,
) -> Modify {
  Modify(..modify, default_message_notification_setting: Some(setting))
}

pub fn modify_explicit_content_filter_setting(
  modify: Modify,
  new setting: ExplicitContentFilterSetting,
) -> Modify {
  Modify(..modify, explicit_content_filter_setting: Some(setting))
}

pub fn modify_afk_channel_id(
  modify: Modify,
  afk_channel_id: Modification(String),
) -> Modify {
  Modify(..modify, afk_channel_id:)
}

pub fn modify_afk_timeout(modify: Modify, new afk_timeout: Int) -> Modify {
  Modify(..modify, afk_timeout: Some(afk_timeout))
}

pub fn modify_icon(modify: Modify, icon: Modification(image.Data)) -> Modify {
  Modify(..modify, icon:)
}

pub fn transfer_ownership(modify: Modify, to owner_id: String) -> Modify {
  Modify(..modify, owner_id: Some(owner_id))
}

pub fn modify_splash(modify: Modify, splash: Modification(image.Data)) -> Modify {
  Modify(..modify, splash:)
}

pub fn modify_discovery_splash(
  modify: Modify,
  discovery_splash: Modification(image.Data),
) -> Modify {
  Modify(..modify, discovery_splash:)
}

pub fn modify_banner(modify: Modify, banner: Modification(image.Data)) -> Modify {
  Modify(..modify, banner:)
}

pub fn modify_system_channel_id(
  modify: Modify,
  system_channel_id: Modification(String),
) -> Modify {
  Modify(..modify, system_channel_id:)
}

pub fn modify_system_channel_flags(
  modify: Modify,
  new system_channel_flags: List(SystemChannelFlag),
) -> Modify {
  Modify(..modify, system_channel_flags: Some(system_channel_flags))
}

pub fn modify_rules_channel_id(
  modify: Modify,
  rules_channel_id: Modification(String),
) -> Modify {
  Modify(..modify, rules_channel_id:)
}

pub fn modify_public_updates_channel_id(
  modify: Modify,
  public_updates_channel_id: Modification(String),
) -> Modify {
  Modify(..modify, public_updates_channel_id:)
}

/// If `preferred_locale == modification.Delete` then `modified_guild.preferred_locale == "en-US"`
pub fn modify_preferred_locale(
  modify: Modify,
  preferred_locale: Modification(String),
) -> Modify {
  Modify(..modify, preferred_locale:)
}

pub fn modify_features(modify: Modify, new features: List(Feature)) -> Modify {
  Modify(..modify, features: Some(features))
}

pub fn modify_description(
  modify: Modify,
  description: Modification(String),
) -> Modify {
  Modify(..modify, description:)
}

pub fn enable_premium_progress_bar(modify: Modify) -> Modify {
  Modify(..modify, is_premium_progress_bar_enabled: Some(True))
}

pub fn disable_premium_progress_bar(modify: Modify) -> Modify {
  Modify(..modify, is_premium_progress_bar_enabled: Some(False))
}

pub fn modify_safety_alerts_channel_id(
  modify: Modify,
  safety_alerts_channel_id: Modification(String),
) -> Modify {
  Modify(..modify, safety_alerts_channel_id:)
}

pub fn leave(
  client: grom.Client,
  id guild_id: String,
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(http.Delete, "/users/@me/guilds/" <> guild_id)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn get_auto_moderation_rules(
  client: grom.Client,
  for guild_id: String,
) -> Result(List(auto_moderation.Rule), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/auto-moderation/rules",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(auto_moderation.rule_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_emojis(
  client: grom.Client,
  for guild_id: String,
) -> Result(List(Emoji), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/emojis")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(emoji.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_emoji(
  client: grom.Client,
  in guild_id: String,
  id emoji_id: String,
) -> Result(Emoji, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/emojis/" <> emoji_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_emoji(
  client: grom.Client,
  in guild_id: String,
  named name: String,
  bytes image: image.Data,
  allowed_roles roles: List(String),
  because reason: Option(String),
) -> Result(Emoji, grom.Error) {
  let json =
    json.object([
      #("name", json.string(name)),
      #("image", json.string(image |> image.to_base64)),
      #("roles", json.array(roles, json.string)),
    ])

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/guilds/" <> guild_id <> "/emojis")
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_emoji(
  client: grom.Client,
  in guild_id: String,
  id emoji_id: String,
  rename name: Option(String),
  allowed_roles roles: Modification(List(String)),
  because reason: Option(String),
) -> Result(Emoji, grom.Error) {
  let json =
    [
      case name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      },
      modification.encode(roles, "roles", json.array(_, json.string)),
    ]
    |> list.flatten
    |> json.object

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/guilds/" <> guild_id <> "/emojis/" <> emoji_id,
    )
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete_emoji(
  client: grom.Client,
  from guild_id: String,
  id emoji_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/emojis/" <> emoji_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn delete(
  client: grom.Client,
  id guild_id: String,
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(http.Delete, "/guilds/" <> guild_id)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn get_active_threads(
  client: grom.Client,
  in guild_id: String,
) -> Result(ReceivedThreads, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/threads/active")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: received_threads_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

/// If `maximum` is not provided, a default of `1` will be used.
/// See: https://discord.com/developers/docs/resources/guild#list-guild-members
pub fn get_members(
  client: grom.Client,
  for guild_id: String,
  maximum limit: Option(Int),
  later_than_id after: Option(String),
) -> Result(List(GuildMember), grom.Error) {
  let query =
    [
      case limit {
        Some(limit) -> [#("limit", int.to_string(limit))]
        None -> []
      },
      case after {
        Some(id) -> [#("after", id)]
        None -> []
      },
    ]
    |> list.flatten

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/members")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(guild_member.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn search_for_members(
  client: grom.Client,
  in guild_id: String,
  named query_param: String,
  maximum limit: Option(Int),
) -> Result(List(GuildMember), grom.Error) {
  let query =
    [
      [#("query", query_param)],
      case limit {
        Some(limit) -> [#("limit", int.to_string(limit))]
        None -> []
      },
    ]
    |> list.flatten

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/members/search")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(guild_member.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

/// See: https://discord.com/developers/docs/resources/guild#get-guild-bans
pub fn get_bans(
  client: grom.Client,
  for guild_id: String,
  maximum limit: Option(Int),
  earlier_than_id before: Option(String),
  later_than_id after: Option(String),
) -> Result(List(Ban), grom.Error) {
  let query =
    [
      case limit {
        Some(limit) -> [#("limit", int.to_string(limit))]
        None -> []
      },
      case before, after {
        Some(before), _ -> [#("before", before)]
        None, Some(after) -> [#("after", after)]
        None, None -> []
      },
    ]
    |> list.flatten

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/bans")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(ban_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_ban(
  client: grom.Client,
  from guild_id: String,
  for user_id: String,
) -> Result(Ban, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/bans/" <> user_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: ban_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_ban(
  client: grom.Client,
  in guild_id: String,
  for user_id: String,
  delete_messages_since delete_message_duration: Option(Duration),
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  let json =
    case delete_message_duration {
      Some(duration) -> [
        #(
          "delete_message_seconds",
          time_duration.to_int_seconds_encode(duration),
        ),
      ]
      None -> []
    }
    |> json.object
    |> json.to_string

  use _response <- result.try(
    client
    |> rest.new_request(http.Put, "/guilds/" <> guild_id <> "/bans/" <> user_id)
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn remove_ban(
  client: grom.Client,
  in guild_id: String,
  from user_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/bans/" <> user_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn bulk_ban(
  client: grom.Client,
  in guild_id: String,
  users user_ids: List(String),
  delete_messages_since delete_message_duration: Option(Duration),
  because reason: Option(String),
) -> Result(BulkBanResponse, grom.Error) {
  let json =
    [
      [#("user_ids", json.array(user_ids, json.string))],
      case delete_message_duration {
        Some(duration) -> [
          #(
            "delete_message_seconds",
            time_duration.to_int_seconds_encode(duration),
          ),
        ]
        None -> []
      },
    ]
    |> list.flatten
    |> json.object
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/guilds/" <> guild_id <> "/bulk-ban")
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: bulk_ban_response_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_roles(
  client: grom.Client,
  for guild_id: String,
) -> Result(List(Role), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/roles")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(role.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

/// Returns a list of all of the guild's roles.
pub fn move_roles(
  client: grom.Client,
  in guild_id: String,
  roles roles: List(RoleToMove),
  because reason: Option(String),
) -> Result(List(Role), grom.Error) {
  let json =
    roles
    |> json.array(role_to_move_to_json)
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/guilds/" <> guild_id <> "/roles")
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(role.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}
