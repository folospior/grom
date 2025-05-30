import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type TextInput {
  TextInput(
    id: Option(Int),
    custom_id: String,
    style: Style,
    label: String,
    min_length: Option(Int),
    max_length: Option(Int),
    is_required: Bool,
    value: Option(String),
    placeholder: Option(String),
  )
}

pub type Style {
  Short
  Paragraph
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(TextInput) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use style <- decode.field("style", style_decoder())
  use label <- decode.field("label", decode.string)
  use min_length <- decode.optional_field(
    "min_length",
    None,
    decode.optional(decode.int),
  )
  use max_length <- decode.optional_field(
    "max_length",
    None,
    decode.optional(decode.int),
  )
  use is_required <- decode.optional_field("required", True, decode.bool)
  use value <- decode.optional_field(
    "value",
    None,
    decode.optional(decode.string),
  )
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )

  decode.success(TextInput(
    id:,
    custom_id:,
    style:,
    label:,
    min_length:,
    max_length:,
    is_required:,
    value:,
    placeholder:,
  ))
}

@internal
pub fn style_decoder() -> decode.Decoder(Style) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Short)
    2 -> decode.success(Paragraph)
    _ -> decode.failure(Short, "Style")
  }
}
