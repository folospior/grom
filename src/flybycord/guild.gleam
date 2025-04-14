import flybycord/channel.{type Channel}
import flybycord/emoji.{type Emoji}
import flybycord/guild/integration
import flybycord/guild/onboarding
import flybycord/internal/time_rfc3339
import flybycord/sticker.{type Sticker}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES ----------------------------------------------------------------------

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

pub type Member {
  Member(
    user: Option(User),
    nick: Option(String),
    avatar_hash: Option(String),
    banner_hash: Option(String),
    roles: List(String),
    joined_at: Timestamp,
    premium_since: Option(Timestamp),
    is_deaf: Bool,
    is_mute: Bool,
    flags: List(MemberFlag),
    is_pending: Option(Bool),
    permissions: Option(String),
    communication_disabled_until: Option(Timestamp),
    avatar_decoration_data: Option(user.AvatarDecorationData),
  )
}

pub type WidgetSettings {
  WidgetSettings(is_enabled: Bool, channel_id: Option(String))
}

pub type Widget {
  Widget(
    id: String,
    name: String,
    instant_invite: Option(String),
    channels: List(Channel),
    members: List(User),
    presence_count: Int,
  )
}

pub type Integration {
  Integration(
    id: String,
    name: String,
    type_: String,
    is_enabled: Bool,
    is_syncing: Option(Bool),
    role_id: Option(String),
    are_emoticons_enabled: Option(Bool),
    expire_behavior: Option(integration.ExpireBehavior),
    expire_grace_period: Option(Int),
    user: Option(User),
    account: integration.Account,
    synced_at: Option(Timestamp),
    subscriber_count: Option(Int),
    is_revoked: Option(Bool),
    application: Option(integration.Application),
    scopes: Option(List(String)),
  )
}

pub type Ban {
  Ban(reason: Option(String), user: User)
}

pub type WelcomeScreen {
  WelcomeScreen(
    description: Option(String),
    welcome_channels: List(WelcomeScreenChannel),
  )
}

pub type WelcomeScreenChannel {
  WelcomeScreenChannel(
    channel_id: String,
    description: String,
    emoji_id: Option(String),
    emoji_name: Option(String),
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

pub type Onboarding {
  Onboarding(
    guild_id: String,
    prompts: List(onboarding.Prompt),
    default_channel_ids: List(String),
    is_enabled: Bool,
    mode: onboarding.Mode,
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

pub type MemberFlag {
  DidRejoin
  CompletedOnboarding
  BypassesVerification
  StartedOnboarding
  IsGuest
  StartedHomeActions
  CompletedHomeActions
  AutomodQuarantinedUsername
  DmSettingsUpsellAcknowledged
}

// CONSTANTS ------------------------------------------------------------------

const bits_system_channel_flags = [
  #(1, SuppressJoinNotifications),
  #(2, SuppressPremiumSubscriptions),
  #(4, SuppressGuildReminderNotifications),
  #(8, SuppressJoinNotificationReplies),
  #(16, SuppressRoleSubscriptionPurchaseNotifications),
  #(32, SuppressRoleSubscriptionPurchaseNotificationReplies),
]

const bits_member_flags = [
  #(1, DidRejoin),
  #(2, CompletedOnboarding),
  #(4, BypassesVerification),
  #(8, StartedOnboarding),
  #(16, IsGuest),
  #(32, StartedHomeActions),
  #(64, CompletedHomeActions),
  #(128, AutomodQuarantinedUsername),
  #(512, DmSettingsUpsellAcknowledged),
]

// DECODERS -------------------------------------------------------------------

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
pub fn system_channel_flags_decoder() -> decode.Decoder(List(SystemChannelFlag)) {
  use flags <- decode.then(decode.int)
  bits_system_channel_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

@internal
pub fn welcome_screen_channel_decoder() -> decode.Decoder(WelcomeScreenChannel) {
  use channel_id <- decode.field("channel_id", decode.string)
  use description <- decode.field("description", decode.string)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(WelcomeScreenChannel(
    channel_id:,
    description:,
    emoji_id:,
    emoji_name:,
  ))
}

@internal
pub fn welcome_screen_decoder() -> decode.Decoder(WelcomeScreen) {
  use description <- decode.field("description", decode.optional(decode.string))
  use welcome_channels <- decode.field(
    "welcome_channels",
    decode.list(welcome_screen_channel_decoder()),
  )
  decode.success(WelcomeScreen(description:, welcome_channels:))
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
pub fn widget_settings_decoder() -> decode.Decoder(WidgetSettings) {
  use is_enabled <- decode.field("enabled", decode.bool)
  use channel_id <- decode.field("channel_id", decode.optional(decode.string))
  decode.success(WidgetSettings(is_enabled:, channel_id:))
}

@internal
pub fn widget_decoder() -> decode.Decoder(Widget) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use instant_invite <- decode.field(
    "instant_invite",
    decode.optional(decode.string),
  )
  use channels <- decode.field(
    "channels",
    decode.list(todo as "Decoder for Channel"),
  )
  use members <- decode.field("members", decode.list(user.decoder()))
  use presence_count <- decode.field("presence_count", decode.int)
  decode.success(Widget(
    id:,
    name:,
    instant_invite:,
    channels:,
    members:,
    presence_count:,
  ))
}

@internal
pub fn integration_decoder() -> decode.Decoder(Integration) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use is_enabled <- decode.field("enabled", decode.bool)
  use is_syncing <- decode.optional_field(
    "syncing",
    None,
    decode.optional(decode.bool),
  )
  use role_id <- decode.optional_field(
    "role_id",
    None,
    decode.optional(decode.string),
  )
  use are_emoticons_enabled <- decode.optional_field(
    "enable_emoticons",
    None,
    decode.optional(decode.bool),
  )
  use expire_behavior <- decode.optional_field(
    "expire_behavior",
    None,
    decode.optional(integration.expire_behavior_decoder()),
  )
  use expire_grace_period <- decode.optional_field(
    "expire_grace_period",
    None,
    decode.optional(decode.int),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use account <- decode.field("account", integration.account_decoder())
  use synced_at <- decode.optional_field(
    "synced_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use subscriber_count <- decode.optional_field(
    "subscriber_count",
    None,
    decode.optional(decode.int),
  )
  use is_revoked <- decode.optional_field(
    "revoked",
    None,
    decode.optional(decode.bool),
  )
  use application <- decode.optional_field(
    "application",
    None,
    decode.optional(integration.application_decoder()),
  )
  use scopes <- decode.optional_field(
    "scopes",
    None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(Integration(
    id:,
    name:,
    type_:,
    is_enabled:,
    is_syncing:,
    role_id:,
    are_emoticons_enabled:,
    expire_behavior:,
    expire_grace_period:,
    user:,
    account:,
    synced_at:,
    subscriber_count:,
    is_revoked:,
    application:,
    scopes:,
  ))
}

@internal
pub fn member_flags_decoder() -> decode.Decoder(List(MemberFlag)) {
  use flags <- decode.then(decode.int)

  bits_member_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
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
  use is_deaf <- decode.field("deaf", decode.bool)
  use is_mute <- decode.field("mute", decode.bool)
  use flags <- decode.field("flags", member_flags_decoder())
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
pub fn ban_decoder() -> decode.Decoder(Ban) {
  use reason <- decode.field("reason", decode.optional(decode.string))
  use user <- decode.field("user", user.decoder())
  decode.success(Ban(reason:, user:))
}
