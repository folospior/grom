import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import grom/client.{type Client}
import grom/emoji.{type Emoji}
import grom/error.{type Error}
import grom/guild/auto_moderation
import grom/guild/role.{type Role}
import grom/image
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_rfc3339
import grom/modification.{type Modification}
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

pub type Member {
  Member(
    user: Option(User),
    nick: Option(String),
    avatar_hash: Option(String),
    banner_hash: Option(String),
    roles: List(String),
    joined_at: Timestamp,
    premium_since: Option(Timestamp),
    is_deaf: Option(Bool),
    is_mute: Option(Bool),
    flags: List(MemberFlag),
    is_pending: Option(Bool),
    permissions: Option(String),
    communication_disabled_until: Option(Timestamp),
    avatar_decoration_data: Option(user.AvatarDecorationData),
  )
}

pub type MemberFlag {
  MemberDidRejoin
  MemberCompletedOnboarding
  MemberBypassesVerification
  MemberStartedOnboarding
  MemberIsGuest
  MemberStartedHomeActions
  MemberCompletedHomeActions
  MemberQuarantinedBecauseOfUsername
  MemberAcknowledgedDmSettingsUpsell
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

@internal
pub fn bits_member_flags() {
  [
    #(int.bitwise_shift_left(1, 0), MemberDidRejoin),
    #(int.bitwise_shift_left(1, 1), MemberCompletedOnboarding),
    #(int.bitwise_shift_left(1, 2), MemberBypassesVerification),
    #(int.bitwise_shift_left(1, 3), MemberStartedOnboarding),
    #(int.bitwise_shift_left(1, 4), MemberIsGuest),
    #(int.bitwise_shift_left(1, 5), MemberStartedHomeActions),
    #(int.bitwise_shift_left(1, 6), MemberCompletedHomeActions),
    #(int.bitwise_shift_left(1, 7), MemberQuarantinedBecauseOfUsername),
    #(int.bitwise_shift_left(1, 9), MemberAcknowledgedDmSettingsUpsell),
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
pub fn member_decoder() -> decode.Decoder(Member) {
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use nick <- decode.optional_field(
    "nick",
    None,
    decode.optional(decode.string),
  )
  use avatar_hash <- decode.optional_field(
    "avatar",
    None,
    decode.optional(decode.string),
  )
  use banner_hash <- decode.optional_field(
    "banner",
    None,
    decode.optional(decode.string),
  )
  use roles <- decode.field("roles", decode.list(decode.string))
  use joined_at <- decode.field("joined_at", time_rfc3339.decoder())
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
  use flags <- decode.field("flags", flags.decoder(bits_member_flags()))
  use is_pending <- decode.optional_field(
    "pending",
    None,
    decode.optional(decode.bool),
  )
  use permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(decode.string),
  )
  use communication_disabled_until <- decode.optional_field(
    "communication_disabled_until",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use avatar_decoration_data <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(user.avatar_decoration_data_decoder()),
  )
  decode.success(Member(
    user:,
    nick:,
    avatar_hash:,
    banner_hash:,
    roles:,
    joined_at:,
    premium_since:,
    is_deaf:,
    is_mute:,
    flags:,
    is_pending:,
    permissions:,
    communication_disabled_until:,
    avatar_decoration_data:,
  ))
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

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn leave(client: Client, id guild_id: String) -> Result(Nil, Error) {
  use _response <- result.try(
    client
    |> rest.new_request(http.Delete, "/users/@me/guilds/" <> guild_id)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn get_auto_moderation_rules(
  client: Client,
  for guild_id: String,
) -> Result(List(auto_moderation.Rule), Error) {
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
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_emojis(
  client: Client,
  for guild_id: String,
) -> Result(List(Emoji), Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/emojis")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(emoji.decoder()))
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_emoji(
  client: Client,
  in guild_id: String,
  id emoji_id: String,
) -> Result(Emoji, Error) {
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
  |> result.map_error(error.CouldNotDecode)
}

pub fn create_emoji(
  client: Client,
  in guild_id: String,
  named name: String,
  bytes image: image.Data,
  allowed_roles roles: List(String),
  because reason: Option(String),
) -> Result(Emoji, Error) {
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
  |> result.map_error(error.CouldNotDecode)
}

pub fn modify_emoji(
  client: Client,
  in guild_id: String,
  id emoji_id: String,
  rename name: Option(String),
  allowed_roles roles: Modification(List(String)),
  because reason: Option(String),
) -> Result(Emoji, Error) {
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
  |> result.map_error(error.CouldNotDecode)
}

pub fn delete_emoji(
  client: Client,
  from guild_id: String,
  id emoji_id: String,
  because reason: Option(String),
) -> Result(Nil, Error) {
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
