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
import grom/guild/auto_moderation/rule.{type Rule}
import grom/guild/role.{type Role}
import grom/guild/welcome_screen.{type WelcomeScreen}
import grom/image
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_rfc3339
import grom/modification.{type Modification}
import grom/sticker.{type Sticker}

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
  AllMessages
  OnlyMentions
}

pub type VerificationLevel {
  NoVerification
  Low
  Medium
  High
  VeryHigh
}

pub type ExplicitContentFilterSetting {
  Disabled
  MembersWithoutRoles
  AllMembers
}

pub type MfaLevel {
  NoMfa
  Elevated
}

pub type Feature {
  AnimatedBanner
  AnimatedIcon
  ApplicationCommandPermissionsV2
  AutoModeration
  Banner
  Community
  CreatorMonetizableProvisional
  CreatorStorePage
  DeveloperSupportServer
  Discoverable
  Featurable
  InvitesDisabled
  InviteSplash
  MemberVerificationGateEnabled
  MoreSoundboard
  MoreStickers
  News
  Partnered
  PreviewEnabled
  RaidAlertsDisabled
  RoleIcons
  RoleSubscriptionsAvailableForPurchase
  RoleSubscriptionsEnabled
  Soundboard
  TicketedEventsEnabled
  VanityUrl
  Verified
  VipRegions
  WelcomeScreenEnabled
}

pub type SystemChannelFlag {
  SuppressJoinNotifications
  SuppressPremiumSubscriptions
  SuppressGuildReminderNotifications
  SuppressJoinNotificationReplies
  SuppressRoleSubscriptionPurchaseNotifications
  SuppressRoleSubscriptionPurchaseNotificationReplies
}

pub type PremiumTier {
  NoTier
  Tier1
  Tier2
  Tier3
}

pub type NsfwLevel {
  Default
  Explicit
  Safe
  AgeRestricted
}

// FLAGS ------------------------------------------------------------------

@internal
pub fn bits_system_channel_flags() -> List(#(Int, SystemChannelFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), SuppressJoinNotifications),
    #(int.bitwise_shift_left(1, 1), SuppressPremiumSubscriptions),
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
    decode.optional(welcome_screen.decoder()),
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
    "ANIMATED_BANNER" -> decode.success(AnimatedBanner)
    "ANIMATED_ICON" -> decode.success(AnimatedIcon)
    "APPLICATION_COMMAND_PERMISSIONS_V2" ->
      decode.success(ApplicationCommandPermissionsV2)
    "AUTO_MODERATION" -> decode.success(AutoModeration)
    "BANNER" -> decode.success(Banner)
    "COMMUNITY" -> decode.success(Community)
    "CREATOR_MONETIZABLE_PROVISIONAL" ->
      decode.success(CreatorMonetizableProvisional)
    "CREATOR_STORE_PAGE" -> decode.success(CreatorStorePage)
    "DEVELOPER_SUPPORT_SERVER" -> decode.success(DeveloperSupportServer)
    "DISCOVERABLE" -> decode.success(Discoverable)
    "FEATURABLE" -> decode.success(Featurable)
    "INVITES_DISABLED" -> decode.success(InvitesDisabled)
    "INVITE_SPLASH" -> decode.success(InviteSplash)
    "MEMBER_VERIFICATION_GATE_ENABLED" ->
      decode.success(MemberVerificationGateEnabled)
    "MORE_SOUNDBOARD" -> decode.success(MoreSoundboard)
    "MORE_STICKERS" -> decode.success(MoreStickers)
    "NEWS" -> decode.success(News)
    "PARTNERED" -> decode.success(Partnered)
    "PREVIEW_ENABLED" -> decode.success(PreviewEnabled)
    "RAID_ALERTS_DISABLED" -> decode.success(RaidAlertsDisabled)
    "ROLE_ICONS" -> decode.success(RoleIcons)
    "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE" ->
      decode.success(RoleSubscriptionsAvailableForPurchase)
    "ROLE_SUBSCRIPTIONS_ENABLED" -> decode.success(RoleSubscriptionsEnabled)
    "SOUNDBOARD" -> decode.success(Soundboard)
    "TICKETED_EVENTS_ENABLED" -> decode.success(TicketedEventsEnabled)
    "VANITY_URL" -> decode.success(VanityUrl)
    "VERIFIED" -> decode.success(Verified)
    "VIP_REGIONS" -> decode.success(VipRegions)
    "WELCOME_SCREEN_ENABLED" -> decode.success(WelcomeScreenEnabled)
    _ -> decode.failure(AnimatedBanner, "Feature")
  }
}

@internal
pub fn default_message_notification_setting_decoder() -> decode.Decoder(
  DefaultMessageNotificationSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(AllMessages)
    1 -> decode.success(OnlyMentions)
    _ -> decode.failure(AllMessages, "DefaultMessageNotificationSetting")
  }
}

@internal
pub fn explicit_content_filter_setting_decoder() -> decode.Decoder(
  ExplicitContentFilterSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Disabled)
    1 -> decode.success(MembersWithoutRoles)
    2 -> decode.success(AllMembers)
    _ -> decode.failure(Disabled, "ExplicitContentFilterSetting")
  }
}

@internal
pub fn mfa_level_decoder() -> decode.Decoder(MfaLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoMfa)
    1 -> decode.success(Elevated)
    _ -> decode.failure(NoMfa, "MfaLevel")
  }
}

@internal
pub fn verification_level_decoder() -> decode.Decoder(VerificationLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoVerification)
    1 -> decode.success(Low)
    2 -> decode.success(Medium)
    3 -> decode.success(High)
    4 -> decode.success(VeryHigh)
    _ -> decode.failure(NoVerification, "VerificationLevel")
  }
}

@internal
pub fn nsfw_level_decoder() -> decode.Decoder(NsfwLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Default)
    1 -> decode.success(Explicit)
    2 -> decode.success(Safe)
    3 -> decode.success(AgeRestricted)
    _ -> decode.failure(Default, "NsfwLevel")
  }
}

@internal
pub fn premium_tier_decoder() -> decode.Decoder(PremiumTier) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoTier)
    1 -> decode.success(Tier1)
    2 -> decode.success(Tier2)
    3 -> decode.success(Tier3)
    _ -> decode.failure(NoTier, "PremiumTier")
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
) -> Result(List(Rule), Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/auto-moderation/rules",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(rule.decoder()))
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
      #("image", json.string(image)),
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
