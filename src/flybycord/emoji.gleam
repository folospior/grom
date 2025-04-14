import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES ----------------------------------------------------------------------

pub type Emoji {
  Emoji(
    id: Option(String),
    name: Option(String),
    roles: List(String),
    user: Option(User),
    are_colons_required: Bool,
    is_managed: Bool,
    is_animated: Bool,
    is_available: Bool,
  )
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn emoji_decoder() -> decode.Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(decode.string))
  use name <- decode.field("name", decode.optional(decode.string))
  use roles <- decode.optional_field("roles", [], decode.list(decode.string))
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.user_decoder()),
  )
  use are_colons_required <- decode.optional_field(
    "require_colons",
    False,
    decode.bool,
  )
  use is_managed <- decode.optional_field("managed", False, decode.bool)
  use is_animated <- decode.optional_field("animated", False, decode.bool)
  use is_available <- decode.optional_field("available", False, decode.bool)
  decode.success(Emoji(
    id:,
    name:,
    roles:,
    user:,
    are_colons_required:,
    is_managed:,
    is_animated:,
    is_available:,
  ))
}
