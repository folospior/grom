import flybycord/emoji.{type Emoji}
import gleam/dynamic/decode
import gleam/option.{type Option as GOption, None}

// TYPES -----------------------------------------------------------------------

pub type StringSelect {
  StringSelect(
    id: GOption(Int),
    custom_id: String,
    options: List(Option),
    placeholder: GOption(String),
    min_values: Int,
    max_values: Int,
    is_disabled: Bool,
  )
}

pub type Option {
  Option(
    label: String,
    value: String,
    description: GOption(String),
    emoji: GOption(Emoji),
    is_default: GOption(Bool),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(StringSelect) {
  use id <- decode.field("id", decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use options <- decode.field("options", decode.list(option_decoder()))
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use min_values <- decode.optional_field("min_values", 1, decode.int)
  use max_values <- decode.optional_field("max_values", 1, decode.int)
  use is_disabled <- decode.optional_field("is_disabled", False, decode.bool)
  decode.success(StringSelect(
    id:,
    custom_id:,
    options:,
    placeholder:,
    min_values:,
    max_values:,
    is_disabled:,
  ))
}

@internal
pub fn option_decoder() -> decode.Decoder(Option) {
  use label <- decode.field("label", decode.string)
  use value <- decode.field("value", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use emoji <- decode.field("emoji", decode.optional(emoji.decoder()))
  use is_default <- decode.field("is_default", decode.optional(decode.bool))
  decode.success(Option(label:, value:, description:, emoji:, is_default:))
}
