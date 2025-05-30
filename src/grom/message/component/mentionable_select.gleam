import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type MentionableSelect {
  MentionableSelect(
    id: Option(Int),
    custom_id: String,
    placeholder: Option(String),
    default_values: Option(List(DefaultValue)),
    min_values: Int,
    max_values: Int,
    is_disabled: Bool,
  )
}

pub type DefaultValue {
  User(id: String)
  Role(id: String)
  Channel(id: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(MentionableSelect) {
  use id <- decode.field("id", decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use default_values <- decode.field(
    "default_values",
    decode.optional(decode.list(default_value_decoder())),
  )
  use min_values <- decode.optional_field("min_values", 1, decode.int)
  use max_values <- decode.optional_field("max_values", 1, decode.int)
  use is_disabled <- decode.optional_field("is_disabled", False, decode.bool)
  decode.success(MentionableSelect(
    id:,
    custom_id:,
    placeholder:,
    default_values:,
    min_values:,
    max_values:,
    is_disabled:,
  ))
}

@internal
pub fn default_value_decoder() -> decode.Decoder(DefaultValue) {
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)

  case type_ {
    "user" -> decode.success(User(id:))
    "role" -> decode.success(Role(id:))
    "channel" -> decode.success(Channel(id:))
    _ -> decode.failure(User(""), "DefaultValue")
  }
}
