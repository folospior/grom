import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option as GOption, None, Some}

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
    is_default: Bool,
  )
}

pub type Emoji {
  Emoji(id: GOption(String), name: String, is_animated: Bool)
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
  use is_disabled <- decode.optional_field("disabled", False, decode.bool)
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
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji_decoder()),
  )
  use is_default <- decode.optional_field("default", False, decode.bool)
  decode.success(Option(label:, value:, description:, emoji:, is_default:))
}

@internal
pub fn emoji_decoder() -> decode.Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(decode.string))
  use name <- decode.field("name", decode.string)
  use is_animated <- decode.optional_field("animated", False, decode.bool)

  decode.success(Emoji(id:, name:, is_animated:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(string_select: StringSelect) -> Json {
  let type_ = [#("type", json.int(3))]

  let id = case string_select.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(string_select.custom_id))]

  let options = [
    #("options", json.array(string_select.options, option_to_json)),
  ]

  let placeholder = case string_select.placeholder {
    Some(placeholder) -> [#("placeholder", json.string(placeholder))]
    None -> []
  }

  let min_values = [#("min_values", json.int(string_select.min_values))]

  let max_values = [#("max_values", json.int(string_select.max_values))]

  let is_disabled = [#("disabled", json.bool(string_select.is_disabled))]

  [
    type_,
    id,
    custom_id,
    options,
    placeholder,
    min_values,
    max_values,
    is_disabled,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn option_to_json(option: Option) -> Json {
  let label = [#("label", json.string(option.label))]

  let value = [#("value", json.string(option.value))]

  let description = case option.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let emoji = case option.emoji {
    Some(emoji) -> [#("emoji", emoji_to_json(emoji))]
    None -> []
  }

  let is_default = [#("default", json.bool(option.is_default))]

  [label, value, description, emoji, is_default]
  |> list.flatten
  |> json.object
}

@internal
pub fn emoji_to_json(emoji: Emoji) -> Json {
  let id = case emoji.id {
    Some(id) -> [#("id", json.string(id))]
    None -> []
  }

  let name = [#("name", json.string(emoji.name))]

  let is_animated = [#("animated", json.bool(emoji.is_animated))]

  [id, name, is_animated]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(
  custom_id custom_id: String,
  containing options: List(Option),
) -> StringSelect {
  StringSelect(None, custom_id, options, None, 1, 1, False)
}

pub fn new_option(labeled label: String, value value: String) -> Option {
  Option(label, value, None, None, False)
}
