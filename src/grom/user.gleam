import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/internal/flags

// TYPES ----------------------------------------------------------------------

pub type User {
  User(
    id: String,
    username: String,
    discriminator: String,
    global_name: Option(String),
    avatar_hash: Option(String),
    is_bot: Option(Bool),
    is_system: Option(Bool),
    is_mfa_enabled: Option(Bool),
    banner_hash: Option(String),
    accent_color: Option(Int),
    locale: Option(String),
    flags: Option(List(Flag)),
    premium_type: Option(PremiumType),
    public_flags: Option(List(Flag)),
    avatar_decoration_data: Option(AvatarDecorationData),
    collectibles: Option(Collectibles),
    primary_guild: Option(PrimaryGuild),
  )
}

pub type AvatarDecorationData {
  AvatarDecorationData(asset: String, sku_id: String)
}

pub type PremiumType {
  NoPremium
  NitroClassic
  Nitro
  NitroBasic
}

pub type Flag {
  Staff
  Partner
  Hypesquad
  BugHunterLevel1
  HypesquadBravery
  HypesquadBrilliance
  HypesquadBalance
  PremiumEarlySupporter
  TeamPseudoUser
  BugHunterLevel2
  VerifiedBot
  VerifiedDeveloper
  CertifiedModerator
  BotHttpInteractions
  ActiveDeveloper
}

pub type Collectibles {
  Collectibles(nameplate: Option(Nameplate))
}

pub type Nameplate {
  Nameplate(sku_id: String, asset: String, label: String, palette: String)
}

pub type PrimaryGuild {
  PrimaryGuild(
    id: Option(String),
    is_enabled: Option(Bool),
    tag: Option(String),
    badge_hash: Option(String),
  )
}

// CONSTANTS ------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 0), Staff),
    #(int.bitwise_shift_left(1, 1), Partner),
    #(int.bitwise_shift_left(1, 2), Hypesquad),
    #(int.bitwise_shift_left(1, 3), BugHunterLevel1),
    #(int.bitwise_shift_left(1, 6), HypesquadBravery),
    #(int.bitwise_shift_left(1, 7), HypesquadBrilliance),
    #(int.bitwise_shift_left(1, 8), HypesquadBalance),
    #(int.bitwise_shift_left(1, 9), PremiumEarlySupporter),
    #(int.bitwise_shift_left(1, 10), TeamPseudoUser),
    #(int.bitwise_shift_left(1, 14), BugHunterLevel2),
    #(int.bitwise_shift_left(1, 16), VerifiedBot),
    #(int.bitwise_shift_left(1, 17), VerifiedDeveloper),
    #(int.bitwise_shift_left(1, 18), CertifiedModerator),
    #(int.bitwise_shift_left(1, 19), BotHttpInteractions),
    #(int.bitwise_shift_left(1, 22), ActiveDeveloper),
  ]
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use global_name <- decode.field("global_name", decode.optional(decode.string))
  use avatar_hash <- decode.field("avatar", decode.optional(decode.string))
  use is_bot <- decode.optional_field("bot", None, decode.optional(decode.bool))
  use is_system <- decode.optional_field(
    "system",
    None,
    decode.optional(decode.bool),
  )
  use is_mfa_enabled <- decode.optional_field(
    "mfa_enabled",
    None,
    decode.optional(decode.bool),
  )
  use banner_hash <- decode.optional_field(
    "banner",
    None,
    decode.optional(decode.string),
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
    None,
    decode.optional(flags.decoder(bits_flags())),
  )
  use premium_type <- decode.optional_field(
    "premium_type",
    None,
    decode.optional(premium_type_decoder()),
  )
  use public_flags <- decode.optional_field(
    "public_flags",
    None,
    decode.optional(flags.decoder(bits_flags())),
  )
  use avatar_decoration_data <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(avatar_decoration_data_decoder()),
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
    username:,
    discriminator:,
    global_name:,
    avatar_hash:,
    is_bot:,
    is_system:,
    is_mfa_enabled:,
    banner_hash:,
    accent_color:,
    locale:,
    flags:,
    premium_type:,
    public_flags:,
    avatar_decoration_data:,
    collectibles:,
    primary_guild:,
  ))
}

@internal
pub fn avatar_decoration_data_decoder() -> decode.Decoder(AvatarDecorationData) {
  use asset <- decode.field("asset", decode.string)
  use sku_id <- decode.field("sku_id", decode.string)
  decode.success(AvatarDecorationData(asset:, sku_id:))
}

@internal
pub fn premium_type_decoder() -> decode.Decoder(PremiumType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoPremium)
    1 -> decode.success(NitroClassic)
    2 -> decode.success(Nitro)
    3 -> decode.success(NitroBasic)
    _ -> decode.failure(NoPremium, "PremiumType")
  }
}

@internal
pub fn collectibles_decoder() -> decode.Decoder(Collectibles) {
  use nameplate <- decode.optional_field(
    "nameplate",
    None,
    decode.optional(nameplate_decoder()),
  )

  decode.success(Collectibles(nameplate:))
}

@internal
pub fn nameplate_decoder() -> decode.Decoder(Nameplate) {
  use sku_id <- decode.field("sku_id", decode.string)
  use asset <- decode.field("asset", decode.string)
  use label <- decode.field("label", decode.string)
  use palette <- decode.field("palette", decode.string)

  decode.success(Nameplate(sku_id:, asset:, label:, palette:))
}

@internal
pub fn primary_guild_decoder() -> decode.Decoder(PrimaryGuild) {
  use id <- decode.field("identity_guild_id", decode.optional(decode.string))
  use is_enabled <- decode.field(
    "identity_enabled",
    decode.optional(decode.bool),
  )
  use tag <- decode.field("tag", decode.optional(decode.string))
  use badge_hash <- decode.field("badge", decode.optional(decode.string))

  decode.success(PrimaryGuild(id:, is_enabled:, tag:, badge_hash:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(user: User) -> Json {
  let id = [#("id", json.string(user.id))]

  let username = [#("username", json.string(user.username))]

  let discriminator = [#("discriminator", json.string(user.discriminator))]

  let global_name = [
    #("global_name", json.nullable(user.global_name, json.string)),
  ]

  let avatar_hash = [#("avatar", json.nullable(user.avatar_hash, json.string))]

  let is_bot = case user.is_bot {
    Some(bot) -> [#("bot", json.bool(bot))]
    None -> []
  }

  let is_system = case user.is_system {
    Some(system) -> [#("system", json.bool(system))]
    None -> []
  }

  let is_mfa_enabled = case user.is_mfa_enabled {
    Some(mfa_enabled) -> [#("mfa_enabled", json.bool(mfa_enabled))]
    None -> []
  }

  let banner_hash = case user.banner_hash {
    Some(banner) -> [#("banner", json.string(banner))]
    None -> []
  }

  let accent_color = case user.accent_color {
    Some(color) -> [#("accent_color", json.int(color))]
    None -> []
  }

  let locale = case user.locale {
    Some(locale) -> [#("locale", json.string(locale))]
    None -> []
  }

  let flags = case user.flags {
    Some(flags) -> [#("flags", flags.to_json(flags, bits_flags()))]
    None -> []
  }

  let premium_type = case user.premium_type {
    Some(type_) -> [#("premium_type", premium_type_to_json(type_))]
    None -> []
  }

  let public_flags = case user.public_flags {
    Some(flags) -> [#("public_flags", flags.to_json(flags, bits_flags()))]
    None -> []
  }

  let avatar_decoration_data = case user.avatar_decoration_data {
    Some(data) -> [
      #("avatar_decoration_data", avatar_decoration_data_to_json(data)),
    ]
    None -> []
  }

  let collectibles = case user.collectibles {
    Some(collectibles) -> [
      #("collectibles", collectibles_to_json(collectibles)),
    ]
    None -> []
  }

  let primary_guild = case user.primary_guild {
    Some(guild) -> [#("primary_guild", primary_guild_to_json(guild))]
    None -> []
  }

  [
    id,
    username,
    discriminator,
    global_name,
    avatar_hash,
    is_bot,
    is_system,
    is_mfa_enabled,
    banner_hash,
    accent_color,
    locale,
    flags,
    premium_type,
    public_flags,
    avatar_decoration_data,
    collectibles,
    primary_guild,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn premium_type_to_json(premium_type: PremiumType) -> Json {
  case premium_type {
    NoPremium -> 0
    NitroClassic -> 1
    Nitro -> 2
    NitroBasic -> 3
  }
  |> json.int
}

@internal
pub fn avatar_decoration_data_to_json(data: AvatarDecorationData) -> Json {
  json.object([
    #("asset", json.string(data.asset)),
    #("sku_id", json.string(data.sku_id)),
  ])
}

@internal
pub fn collectibles_to_json(collectibles: Collectibles) -> Json {
  let nameplate = case collectibles.nameplate {
    Some(nameplate) -> [#("nameplate", nameplate_to_json(nameplate))]
    None -> []
  }

  [nameplate]
  |> list.flatten
  |> json.object
}

@internal
pub fn nameplate_to_json(nameplate: Nameplate) -> Json {
  json.object([
    #("sku_id", json.string(nameplate.sku_id)),
    #("asset", json.string(nameplate.asset)),
    #("label", json.string(nameplate.label)),
    #("palette", json.string(nameplate.palette)),
  ])
}

@internal
pub fn primary_guild_to_json(primary_guild: PrimaryGuild) -> Json {
  json.object([
    #("identity_guild_id", json.nullable(primary_guild.id, json.string)),
    #("identity_enabled", json.nullable(primary_guild.is_enabled, json.bool)),
    #("tag", json.nullable(primary_guild.tag, json.string)),
    #("badge", json.nullable(primary_guild.badge_hash, json.string)),
  ])
}
