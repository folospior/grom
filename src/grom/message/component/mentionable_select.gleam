import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

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
  UserValue(id: String)
  RoleValue(id: String)
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
    "user" -> decode.success(UserValue(id:))
    "role" -> decode.success(RoleValue(id:))
    _ -> decode.failure(UserValue(""), "DefaultValue")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(mentionable_select: MentionableSelect) -> Json {
  let type_ = [#("type", json.int(7))]

  let id = case mentionable_select.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(mentionable_select.custom_id))]

  let placeholder = case mentionable_select.placeholder {
    Some(placeholder) -> [#("placeholder", json.string(placeholder))]
    None -> []
  }

  let default_values = case mentionable_select.default_values {
    Some(values) -> [
      #("default_values", json.array(values, default_value_to_json)),
    ]
    None -> []
  }

  let min_values = [#("min_values", json.int(mentionable_select.min_values))]

  let max_values = [#("max_values", json.int(mentionable_select.max_values))]

  let is_disabled = [#("disabled", json.bool(mentionable_select.is_disabled))]

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
pub fn default_value_to_json(default_value: DefaultValue) -> Json {
  json.object([
    #("id", json.string(default_value.id)),
    #(
      "type",
      json.string(case default_value {
        UserValue(..) -> "user"
        RoleValue(..) -> "role"
      }),
    ),
  ])
}
