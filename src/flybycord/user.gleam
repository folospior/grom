import flybycord/client
import flybycord/internal/error
import flybycord/internal/requests
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result

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
    flags: Option(Int),
    premium_type: Option(PremiumType),
    public_flags: Option(List(PublicFlag)),
    avatar_decoration_data: Option(AvatarDecorationData),
  )
}

pub type AvatarDecorationData {
  AvatarDecorationData(asset: String, sku_id: String)
}

pub type PremiumType {
  None
  NitroClassic
  Nitro
  NitroBasic
  Invalid
}

pub type PublicFlag {
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

const bits_flags = [
  #(1, Staff),
  #(2, Partner),
  #(4, Hypesquad),
  #(8, BugHunterLevel1),
  #(64, HypesquadBravery),
  #(128, HypesquadBrilliance),
  #(256, HypesquadBalance),
  #(512, PremiumEarlySupporter),
  #(1024, TeamPseudoUser),
  #(16_384, BugHunterLevel2),
  #(65_536, VerifiedBot),
  #(131_072, VerifiedDeveloper),
  #(262_144, CertifiedModerator),
  #(524_288, BotHttpInteractions),
  #(4_194_304, ActiveDeveloper),
]

// DECODERS -------------------------------------------------------------------

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use global_name <- decode.field("global_name", decode.optional(decode.string))
  use avatar_hash <- decode.field("avatar", decode.optional(decode.string))
  use is_bot <- decode.field("bot", decode.optional(decode.bool))
  use is_system <- decode.field("system", decode.optional(decode.bool))
  use is_mfa_enabled <- decode.field(
    "mfa_enabled",
    decode.optional(decode.bool),
  )
  use banner_hash <- decode.field("banner", decode.optional(decode.string))
  use accent_color <- decode.field("accent_color", decode.optional(decode.int))
  use locale <- decode.field("locale", decode.optional(decode.string))
  use flags <- decode.field("flags", decode.optional(decode.int))
  use premium_type <- decode.field(
    "premium_type",
    decode.optional(premium_type_decoder()),
  )
  use public_flags <- decode.field(
    "public_flags",
    decode.optional(public_flags_decoder()),
  )
  use avatar_decoration_data <- decode.field(
    "avatar_decoration_data",
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
    public_flags:,
    avatar_decoration_data:,
  ))
}

fn avatar_decoration_data_decoder() -> decode.Decoder(AvatarDecorationData) {
  use asset <- decode.field("asset", decode.string)
  use sku_id <- decode.field("sku_id", decode.string)
  decode.success(AvatarDecorationData(asset:, sku_id:))
}

fn premium_type_decoder() -> decode.Decoder(PremiumType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(None)
    1 -> decode.success(NitroClassic)
    2 -> decode.success(Nitro)
    3 -> decode.success(NitroBasic)
    _ -> decode.success(Invalid)
  }
}

fn public_flags_decoder() -> decode.Decoder(List(PublicFlag)) {
  use flags <- decode.then(decode.int)

  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

// PUBLIC FUNCTIONS -----------------------------------------------------------

pub fn get_user(
  client: client.Client,
  id: String,
) -> Result(User, error.FlybycordError) {
  use response <- result.try(
    client
    |> requests.get("/users/" <> id),
  )

  response.body
  |> json.parse(using: user_decoder())
  |> result.map_error(error.DecodeError)
}
