import gleam/dynamic/decode
import gleam/option.{type Option}
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Ban {
  Ban(reason: Option(String), user: User)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Ban) {
  use reason <- decode.field("reason", decode.optional(decode.string))
  use user <- decode.field("user", user.decoder())
  decode.success(Ban(reason:, user:))
}
