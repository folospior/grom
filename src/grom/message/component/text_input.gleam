import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type TextInput {
  TextInput(
    id: Option(Int),
    custom_id: String,
    style: Style,
    label: String,
    min_length: Int,
    max_length: Int,
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
  use min_length <- decode.optional_field("min_length", 0, decode.int)
  use max_length <- decode.optional_field("max_length", 4000, decode.int)
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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(text_input: TextInput) -> Json {
  let type_ = [#("type", json.int(4))]

  let id = case text_input.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(text_input.custom_id))]

  let style = [#("style", style_to_json(text_input.style))]

  let label = [#("label", json.string(text_input.label))]

  let min_length = [#("min_length", json.int(text_input.min_length))]

  let max_length = [#("max_length", json.int(text_input.max_length))]

  let is_required = [#("required", json.bool(text_input.is_required))]

  let value = case text_input.value {
    Some(value) -> [#("value", json.string(value))]
    None -> []
  }

  let placeholder = case text_input.placeholder {
    Some(placeholder) -> [#("placeholder", json.string(placeholder))]
    None -> []
  }

  [
    type_,
    id,
    custom_id,
    style,
    label,
    min_length,
    max_length,
    is_required,
    value,
    placeholder,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn style_to_json(style: Style) -> Json {
  case style {
    Short -> 1
    Paragraph -> 2
  }
  |> json.int
}
