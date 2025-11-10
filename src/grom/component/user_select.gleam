import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type UserSelect {
  UserSelect(
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
  DefaultValue(id: String)
}

pub type InteractionResponse {
  InteractionResponse(
    id: Int,
    custom_id: String,
    selected_users_ids: List(String),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(UserSelect) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use default_values <- decode.optional_field(
    "default_values",
    None,
    decode.optional(decode.list(default_value_decoder())),
  )
  use min_values <- decode.optional_field("min_values", 1, decode.int)
  use max_values <- decode.optional_field("max_values", 1, decode.int)
  use is_disabled <- decode.optional_field("is_disabled", False, decode.bool)
  decode.success(UserSelect(
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
  use id <- decode.field("id", decode.string)
  decode.success(DefaultValue(id:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(user_select: UserSelect) -> Json {
  let type_ = [#("type", json.int(5))]

  let id = case user_select.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(user_select.custom_id))]

  let placeholder = case user_select.placeholder {
    Some(placeholder) -> [#("placeholder", json.string(placeholder))]
    None -> []
  }

  let default_values = case user_select.default_values {
    Some(values) -> [
      #("default_values", json.array(values, default_value_to_json)),
    ]
    None -> []
  }

  let min_values = [#("min_values", json.int(user_select.min_values))]

  let max_values = [#("max_values", json.int(user_select.max_values))]

  let is_disabled = [#("disabled", json.bool(user_select.is_disabled))]

  [
    type_,
    id,
    custom_id,
    placeholder,
    default_values,
    min_values,
    max_values,
    is_disabled,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn default_value_to_json(default_value: DefaultValue) {
  json.object([
    #("id", json.string(default_value.id)),
    #("type", json.string("user")),
  ])
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(custom_id custom_id: String) -> UserSelect {
  UserSelect(None, custom_id, None, None, 1, 1, False)
}
