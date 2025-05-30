import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
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
    avatar_decoration_data: Option(AvatarDecorationData),
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
  use avatar_decoration_data <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(avatar_decoration_data_decoder()),
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
    avatar_decoration_data:,
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
