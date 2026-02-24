import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

/// A snowflake is another name for an ID.
/// It is possible to retrieve an object's creation date from its snowflake.
pub opaque type Snowflake(a) {
  Snowflake(id: Int)
}

/// An image hash is used to download images from Discord.
/// Every non-attachment image (avatars, banners, even guild tag badges) is hashed by Discord and is able to be downloaded through a link.
pub opaque type ImageHash {
  ImageHash(hash: String)
}

/// Returns the image hash in string form.
/// Generally not needed.
pub fn image_hash_to_string(image_hash: ImageHash) -> String {
  image_hash.hash
}

fn image_hash_decoder() -> Decoder(ImageHash) {
  decode.map(decode.string, ImageHash)
}

fn snowflake_to_json(snowflake: Snowflake(a)) -> Json {
  snowflake.id
  |> int.to_string
  |> json.string
}

pub fn snowflake_to_string(snowflake: Snowflake(a)) -> String {
  snowflake.id
  |> int.to_string
}

pub fn snowflake_to_int(snowflake: Snowflake(a)) -> Int {
  snowflake.id
}

fn snowflake_decoder() -> Decoder(Snowflake(a)) {
  use id <- decode.then(decode.string)
  case int.parse(id) {
    Ok(id) -> decode.success(Snowflake(id))
    Error(_) -> decode.failure(Snowflake(0), "Snowflake")
  }
}

pub fn new_snowflake(from id: Int) -> Snowflake(a) {
  Snowflake(id)
}

fn flags_decoder(bits_flags: List(#(Int, flag))) -> Decoder(List(flag)) {
  use bits <- decode.then(decode.int)

  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

fn flags_to_int(flags: List(flag), bits_flags: List(#(Int, flag))) -> Int {
  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    let is_in_flags = list.any(flags, fn(curr) { curr == flag })
    case is_in_flags {
      True -> Ok(bit)
      False -> Error(Nil)
    }
  })
  |> int.sum
}

fn flags_to_json(flags: List(flag), bits_flags: List(#(Int, flag))) -> Json {
  json.int(flags |> flags_to_int(bits_flags))
}

pub type User {
  User(
    id: Snowflake(User),
    username: String,
    /// Mostly deprecated. Only bots have discriminators nowadays.
    /// Users will very likely have their discriminator set to `0`.
    /// Used in the past when usernames weren't user-specific.
    /// Doesn't include the `#` prefix.
    discriminator: String,
    /// Also called a display name.
    /// Is `None` when the user doesn't have a global name, and rather uses their username as their display name.
    global_name: Option(String),
    /// Is `None` when the user uses a default avatar.
    avatar_hash: Option(ImageHash),
    /// Whether the user is a bot user.
    is_bot: Bool,
    /// Whether the user is Discord's official system account.
    is_system: Bool,
    /// Is `None` if it isn't known whether the user has enabled MFA.
    /// MFA = multi-factor authentication.
    has_mfa_enabled: Option(Bool),
    /// Is `None` when the user doesn't use a custom banner.
    banner_hash: Option(ImageHash),
    /// The user's banner accent color in RGB hexadecimal format.
    /// Is `None` when the user uses a default color based on avatar.
    accent_color: Option(Int),
    /// The user's chosen locale.
    /// Full list of locales: [link](https://docs.discord.com/developers/reference#locales)
    /// Discord hasn't disclosed when this field could be `None`. 
    locale: Option(String),
    flags: List(UserFlag),
    /// Is `None` if the user's premium type isn't known.
    premium_type: Option(UserPremiumType),
    /// Publicly visible flags - aka Discord badges.
    /// Visible in the top right corner of a person's profile in the apps.
    public_flags: List(UserFlag),
    /// Is `None` when the user has no avatar decorations.
    avatar_decoration: Option(UserAvatarDecoration),
    /// Is `None` when the user has no collectibles.
    collectibles: Option(UserCollectibles),
    /// Is `None` if the user never had a primary guild.
    primary_guild: Option(UserPrimaryGuild),
  )
}

fn user_decoder() -> Decoder(User) {
  use id <- decode.field("id", snowflake_decoder())
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use global_name <- decode.field("global_name", decode.optional(decode.string))
  use avatar_hash <- decode.field(
    "avatar",
    decode.optional(image_hash_decoder()),
  )
  use is_bot <- decode.optional_field("bot", False, decode.bool)
  use is_system <- decode.optional_field("system", False, decode.bool)
  use has_mfa_enabled <- decode.optional_field(
    "mfa_enabled",
    None,
    decode.optional(decode.bool),
  )
  use banner_hash <- decode.optional_field(
    "banner",
    None,
    decode.optional(image_hash_decoder()),
  )
  use accent_color <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(decode.int),
  )
  use locale <- decode.optional_field(
    "locale",
    None,
    decode.optional(decode.string),
  )
  use flags <- decode.optional_field(
    "flags",
    [],
    flags_decoder(bits_user_flags()),
  )
  use premium_type <- decode.optional_field(
    "premium_type",
    None,
    decode.optional(user_premium_type_decoder()),
  )
  use public_flags <- decode.optional_field(
    "public_flags",
    [],
    flags_decoder(bits_user_flags()),
  )
  use avatar_decoration <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(user_avatar_decoration_decoder()),
  )
  use collectibles <- decode.optional_field(
    "collectibles",
    None,
    decode.optional(user_collectibles_decoder()),
  )
  use primary_guild <- decode.optional_field(
    "primary_guild",
    None,
    decode.optional(user_primary_guild_decoder()),
  )
  decode.success(User(
    id:,
    username:,
    discriminator:,
    global_name:,
    avatar_hash:,
    is_bot:,
    is_system:,
    has_mfa_enabled:,
    banner_hash:,
    accent_color:,
    locale:,
    flags:,
    premium_type:,
    public_flags:,
    avatar_decoration:,
    collectibles:,
    primary_guild:,
  ))
}

fn user_primary_guild_decoder() -> Decoder(UserPrimaryGuild) {
  use is_enabled <- decode.field(
    "identity_enabled",
    decode.optional(decode.bool),
  )
  case is_enabled {
    Some(True) -> {
      use id <- decode.field("identity_guild_id", snowflake_decoder())
      use tag <- decode.field("tag", decode.string)
      use badge_hash <- decode.field("badge", image_hash_decoder())

      decode.success(ActiveUserPrimaryGuild(id:, tag:, badge_hash:))
    }
    Some(False) -> decode.success(ManuallyClearedUserPrimaryGuild)
    None -> decode.success(AutomaticallyClearedUserPrimaryGuild)
  }
}

fn user_avatar_decoration_decoder() -> Decoder(UserAvatarDecoration) {
  use hash <- decode.field("asset", image_hash_decoder())
  use sku_id <- decode.field("sku_id", snowflake_decoder())
  decode.success(UserAvatarDecoration(hash:, sku_id:))
}

fn user_premium_type_decoder() -> Decoder(UserPremiumType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(UserHasNoPremiumSubscription)
    1 -> decode.success(UserHasNitroClassic)
    2 -> decode.success(UserHasNitro)
    3 -> decode.success(UserHasNitroBasic)
    _ -> decode.failure(UserHasNoPremiumSubscription, "PremiumType")
  }
}

pub type UserPrimaryGuild {
  /// A user actively has a primary guild tag.
  ActiveUserPrimaryGuild(
    id: Snowflake(Guild),
    tag: String,
    badge_hash: ImageHash,
  )
  /// The user's primary guild was cleared by Discord because the guild became ineligible for guild tags.
  AutomaticallyClearedUserPrimaryGuild
  /// The user manually removed their guild tag.
  ManuallyClearedUserPrimaryGuild
}

// TODO: GET RID OF ME, ACTUALLY USE SKUs
pub type Sku

// TODO: GET RID OF ME, ACTUALLY USE GUILDS
pub type Guild

pub type UserAvatarDecoration {
  UserAvatarDecoration(hash: ImageHash, sku_id: Snowflake(Sku))
}

pub type UserCollectibles {
  UserCollectibles(
    /// Is `None` when the user doesn't have a nameplate.
    nameplate: Option(UserNameplate),
  )
}

/// A nameplate is a decoration around a user's Direct Messages / online member list view tab.
pub type UserNameplate {
  UserNameplate(
    sku_id: Snowflake(Sku),
    hash: ImageHash,
    /// Currently unused.
    label: String,
    palette: UserNameplatePalette,
  )
}

pub type UserNameplatePalette {
  CrimsonUserNameplate
  BerryUserNameplate
  SkyUserNameplate
  TealUserNameplate
  ForestUserNameplate
  BubbleGumUserNameplate
  VioletUserNameplate
  CobaltUserNameplate
  CloverUserNameplate
  LemonUserNameplate
  WhiteUserNameplate
}

pub type UserFlag {
  /// Given to official Discord staff.
  UserIsStaff
  /// Given to partnered guild owners.
  UserIsDiscordPartner
  /// Given to participants of Hypesquad events.
  UserIsHypesquadEventsMember
  /// Given to Discord Bug Hunters, first level of the badge.
  UserIsBugHunterLevel1
  UserBelongsToHypesquadBravery
  UserBelongsToHypesquadBrilliance
  UserBelongsToHypesquadBalance
  /// Given to "early Nitro supporters".
  UserIsPremiumEarlySupporter
  /// The user is actually a development team.
  UserIsTeamPseudoUser
  /// Given to Discord Bug Hunters, second level of the badge.
  UserIsBugHunterLevel2
  /// Given to verified bot users.
  UserIsVerifiedBot
  /// Given to early verified bot developers. No longer obtainable.
  UserIsVerifiedDeveloper
  /// Given to people who passed the Discord Certified Moderator course.
  UserIsCertifiedModerator
  /// The bot only uses HTTP webhook interaction and is shown in the online member list.
  BotUsesHttpInteractions
  /// Given to [active developers](https://support-dev.discord.com/hc/articles/10113997751447).
  /// No longer obtainable.
  UserIsActiveDeveloper
}

fn bits_user_flags() -> List(#(Int, UserFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), UserIsStaff),
    #(int.bitwise_shift_left(1, 1), UserIsDiscordPartner),
    #(int.bitwise_shift_left(1, 2), UserIsHypesquadEventsMember),
    #(int.bitwise_shift_left(1, 3), UserIsBugHunterLevel1),
    #(int.bitwise_shift_left(1, 6), UserBelongsToHypesquadBravery),
    #(int.bitwise_shift_left(1, 7), UserBelongsToHypesquadBrilliance),
    #(int.bitwise_shift_left(1, 8), UserBelongsToHypesquadBalance),
    #(int.bitwise_shift_left(1, 9), UserIsPremiumEarlySupporter),
    #(int.bitwise_shift_left(1, 10), UserIsTeamPseudoUser),
    #(int.bitwise_shift_left(1, 14), UserIsBugHunterLevel2),
    #(int.bitwise_shift_left(1, 16), UserIsVerifiedBot),
    #(int.bitwise_shift_left(1, 17), UserIsVerifiedDeveloper),
    #(int.bitwise_shift_left(1, 18), UserIsCertifiedModerator),
    #(int.bitwise_shift_left(1, 19), BotUsesHttpInteractions),
    #(int.bitwise_shift_left(1, 22), UserIsActiveDeveloper),
  ]
}

/// Describes what level of a Nitro subscription a user has.
pub type UserPremiumType {
  UserHasNoPremiumSubscription
  UserHasNitroClassic
  UserHasNitro
  UserHasNitroBasic
}

fn user_collectibles_decoder() -> Decoder(UserCollectibles) {
  use nameplate <- decode.optional_field(
    "nameplate",
    None,
    decode.optional(user_nameplate_decoder()),
  )
  decode.success(UserCollectibles(nameplate:))
}

fn user_nameplate_decoder() -> Decoder(UserNameplate) {
  use sku_id <- decode.field("sku_id", snowflake_decoder())
  use hash <- decode.field("asset", image_hash_decoder())
  use label <- decode.field("label", decode.string)
  use palette <- decode.field("palette", user_nameplate_palette_decoder())

  decode.success(UserNameplate(sku_id, hash, label, palette))
}

fn user_nameplate_palette_decoder() -> Decoder(UserNameplatePalette) {
  use variant <- decode.then(decode.string)

  case variant {
    "crimson" -> decode.success(CrimsonUserNameplate)
    "berry" -> decode.success(BerryUserNameplate)
    "sky" -> decode.success(SkyUserNameplate)
    "teal" -> decode.success(TealUserNameplate)
    "forest" -> decode.success(ForestUserNameplate)
    "bubble_gum" -> decode.success(BubbleGumUserNameplate)
    "violet" -> decode.success(VioletUserNameplate)
    "cobalt" -> decode.success(CobaltUserNameplate)
    "clover" -> decode.success(CloverUserNameplate)
    "lemon" -> decode.success(LemonUserNameplate)
    "white" -> decode.success(WhiteUserNameplate)
    _ -> decode.failure(CrimsonUserNameplate, "UserNameplatePalette")
  }
}
