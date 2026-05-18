import gleam/http/response.{type Response}
import gleam/http/request.{type Request}
import gleam/http
import grom/internal/rest
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/uri.{type Uri}
import gleam_community/colour.{type Colour}
import grom/internal/decoder
import grom/snowflake.{type Snowflake}

/// A user is an entity which can be a member of a guild and participate in communication.
/// 
/// Users include:
/// - regular Discord users
/// - bots
/// - the system user, used by Discord for delivering urgent messages
/// - developer teams (pseudo-users)
pub type User {
  User(
    id: Snowflake(snowflake.UserId),
    name: String,
    discriminator: String,
    /// The display name, shown in most places of the client instead of the username, 
    /// if present.
    display_name: Option(String),
    avatar: Option(AvatarImage),
    is_bot: Bool,
    is_system: Bool,
    banner: Banner,
    flags: List(Flag),
    /// Flags which are visible on the user's profile in the Discord client.
    public_flags: List(Flag),
    avatar_decoration: Option(AvatarDecoration),
    collectibles: Option(Collectibles),
    primary_guild: Option(PrimaryGuild),
  )
}

pub opaque type AvatarImage {
  AvatarImage(hash: String)
}

pub opaque type BannerImage {
  BannerImage(hash: String)
}

pub type Banner {
  ImageBanner(image: BannerImage)
  SolidColourBanner(colour: Colour)
}

pub opaque type AvatarDecorationImage {
  AvatarDecorationImage(hash: String)
}

pub type AvatarDecoration {
  AvatarDecoration(id: Snowflake(snowflake.SkuId), image: AvatarDecorationImage)
}

/// Currently, the only collectibles a user has are [nameplates](#Nameplate).
pub type Collectibles {
  Collectibles(nameplate: Option(Nameplate))
}

/// A nameplate is shown in various Discord sidebars, such as when selecting a
/// user to direct message, or in the guild members sidebar.
pub type Nameplate {
  Nameplate(
    id: Snowflake(snowflake.SkuId),
    image_url: Uri,
    /// Currently unused.
    label: String,
    palette: NameplatePalette,
  )
}

pub type NameplatePalette {
  CrimsonNameplate
  BerryNameplate
  SkyNameplate
  TealNameplate
  ForestNameplate
  BubbleGumNameplate
  VioletNameplate
  CobaltNameplate
  CloverNameplate
  LemonNameplate
  WhiteNameplate
}

/// The user's primary guild is displayed by their name,
/// acting as an advertisement for their favourite server.
/// 
/// AKA server tags.
pub type PrimaryGuild {
  PrimaryGuild(
    id: Snowflake(snowflake.GuildId),
    is_enabled: Bool,
    text: String,
    badge_image: PrimaryGuildBadgeImage,
  )
  /// The primary guild was cleared by Discord, 
  /// e.g. when the guild loses the amount of boosts necessary to keep the tag.
  PrimaryGuildClearedByDiscord
}

pub opaque type PrimaryGuildBadgeImage {
  PrimaryGuildBadgeImage(hash: String)
}

pub type Flag {
  /// The user is a Discord employee.
  IsDiscordStaff
  /// The user is the owner of a Discord-partnered guild.
  IsDiscordPartner
  /// The user attended a real-life Hypesquad event.
  IsHypesquadEventParticipant
  IsBugHunterLevel1
  IsHypesquadBraveryMember
  IsHypesquadBrillianceMember
  IsHypesquadBalanceMember
  IsEarlyNitroSupporter
  /// The user is a developer team pseudouser.
  IsDeveloperTeam
  IsBugHunterLevel2
  IsVerifiedBot
  IsEarlyVerifiedBotDeveloper
  IsCertifiedModerator
  /// The user is a bot which uses HTTP interactions.
  IsBotWithHttpInteractions
}

/// Maps the bitfield value to the flags.
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 0), IsDiscordStaff),
    #(int.bitwise_shift_left(1, 1), IsDiscordPartner),
    #(int.bitwise_shift_left(1, 2), IsHypesquadEventParticipant),
    #(int.bitwise_shift_left(1, 3), IsBugHunterLevel1),
    #(int.bitwise_shift_left(1, 6), IsHypesquadBraveryMember),
    #(int.bitwise_shift_left(1, 7), IsHypesquadBrillianceMember),
    #(int.bitwise_shift_left(1, 8), IsHypesquadBalanceMember),
    #(int.bitwise_shift_left(1, 9), IsEarlyNitroSupporter),
    #(int.bitwise_shift_left(1, 10), IsDeveloperTeam),
    #(int.bitwise_shift_left(1, 14), IsBugHunterLevel2),
    #(int.bitwise_shift_left(1, 16), IsVerifiedBot),
    #(int.bitwise_shift_left(1, 17), IsEarlyVerifiedBotDeveloper),
    #(int.bitwise_shift_left(1, 18), IsCertifiedModerator),
    #(int.bitwise_shift_left(1, 19), IsBotWithHttpInteractions),
  ]
}

pub fn decoder() -> Decoder(User) {
  use id <- decode.field("id", snowflake.decoder())
  use name <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use display_name <- decode.field(
    "global_name",
    decode.optional(decode.string),
  )
  use avatar <- decode.field(
    "avatar",
    decode.optional(decode.map(decode.string, AvatarImage)),
  )
  use is_bot <- decode.optional_field("bot", False, decode.bool)
  use is_system <- decode.optional_field("system", False, decode.bool)
  use banner <- decode.then(banner_decoder())
  use flags <- decode.optional_field(
    "flags",
    [],
    decoder.for_int_flags(bits_flags()),
  )
  use public_flags <- decode.optional_field(
    "public_flags",
    [],
    decoder.for_int_flags(bits_flags()),
  )
  use avatar_decoration <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(avatar_decoration_decoder()),
  )
  use collectibles <- decode.optional_field(
    "collectibles",
    None,
    decode.optional(collectibles_decoder()),
  )
  use primary_guild <- decode.optional_field(
    "primary_guild",
    None,
    decode.optional(primary_guild_decoder()),
  )

  decode.success(User(
    id:,
    name:,
    discriminator:,
    display_name:,
    avatar:,
    is_bot:,
    is_system:,
    banner:,
    flags:,
    public_flags:,
    avatar_decoration:,
    collectibles:,
    primary_guild:,
  ))
}

pub fn primary_guild_decoder() -> Decoder(PrimaryGuild) {
  use is_enabled <- decode.field(
    "identity_enabled",
    decode.optional(decode.bool),
  )

  case is_enabled {
    None -> decode.success(PrimaryGuildClearedByDiscord)
    Some(is_enabled) -> {
      use id <- decode.field("identity_guild_id", snowflake.decoder())
      use text <- decode.field("tag", decode.string)
      use badge_image <- decode.field(
        "badge",
        decode.map(decode.string, PrimaryGuildBadgeImage),
      )
      decode.success(PrimaryGuild(id:, is_enabled:, text:, badge_image:))
    }
  }
}

pub fn banner_decoder() -> Decoder(Banner) {
  let image_decoder = {
    use image <- decode.field("banner", decode.map(decode.string, BannerImage))
    decode.success(ImageBanner(image:))
  }

  let colour_decoder = {
    use colour <- decode.field("accent_color", decoder.for_hex_colour())
    decode.success(SolidColourBanner(colour:))
  }

  decode.one_of(image_decoder, or: [colour_decoder])
}

pub fn avatar_decoration_decoder() -> Decoder(AvatarDecoration) {
  use id <- decode.field("sku_id", snowflake.decoder())
  use image <- decode.field(
    "asset",
    decode.map(decode.string, AvatarDecorationImage),
  )
  decode.success(AvatarDecoration(id:, image:))
}

pub fn collectibles_decoder() -> Decoder(Collectibles) {
  use nameplate <- decode.optional_field(
    "nameplate",
    None,
    decode.optional(nameplate_decoder()),
  )
  decode.success(Collectibles(nameplate:))
}

pub fn nameplate_decoder() -> Decoder(Nameplate) {
  use id <- decode.field("sku_id", snowflake.decoder())
  use image_url <- decode.field("asset", decoder.for_uri())
  use label <- decode.field("label", decode.string)
  use background <- decode.field("palette", nameplate_background_decoder())
  decode.success(Nameplate(id:, image_url:, label:, background:))
}

pub fn nameplate_background_decoder() -> Decoder(NameplatePalette) {
  use variant <- decode.then(decode.string)
  case variant {
    "crimson" -> decode.success(CrimsonNameplate)
    "berry" -> decode.success(BerryNameplate)
    "sky" -> decode.success(SkyNameplate)
    "teal" -> decode.success(TealNameplate)
    "forest" -> decode.success(ForestNameplate)
    "bubble_gum" -> decode.success(BubbleGumNameplate)
    "violet" -> decode.success(VioletNameplate)
    "cobalt" -> decode.success(CobaltNameplate)
    "clover" -> decode.success(CloverNameplate)
    "lemon" -> decode.success(LemonNameplate)
    "white" -> decode.success(WhiteNameplate)
    _ -> decode.failure(CrimsonNameplate, "NameplateBackground")
  }
}

pub fn get_current_user_request(token token: String) -> Request(String) {
  rest.new_request(http.Get, "/users/@me", token:)
}

pub fn get_current_user_response(response: Response(String))