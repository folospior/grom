import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option}

pub type Ban {
  Ban(reason: Option(String), user: User)
}

@internal
pub fn decoder() -> decode.Decoder(Ban) {
  use reason <- decode.field("reason", decode.optional(decode.string))
  use user <- decode.field("user", user.decoder())
  decode.success(Ban(reason:, user:))
}
