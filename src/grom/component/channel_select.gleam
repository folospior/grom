import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type ChannelSelect {
  ChannelSelect(
    id: Option(Int),
    custom_id: String,
    channel_types: Option(List(ChannelType)),
    placeholder: Option(String),
    default_values: Option(List(DefaultValue)),
    min_values: Int,
    max_values: Int,
    is_disabled: Bool,
  )
}

pub type ChannelType {
  Text
  Dm
  Category
  Announcement
  Forum
  Media
}

pub type DefaultValue {
  DefaultValue(id: String)
}

@internal
pub fn decoder() -> decode.Decoder(ChannelSelect) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use channel_types <- decode.optional_field(
    "channel_types",
    None,
    decode.optional(decode.list(channel_type_decoder())),
  )
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
  use is_disabled <- decode.optional_field("disabled", False, decode.bool)

  decode.success(ChannelSelect(
    id:,
    custom_id:,
    channel_types:,
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

@internal
pub fn channel_type_decoder() -> decode.Decoder(ChannelType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Text)
    1 -> decode.success(Dm)
    4 -> decode.success(Category)
    5 -> decode.success(Announcement)
    15 -> decode.success(Forum)
    16 -> decode.success(Media)
    _ -> decode.failure(Text, "ChannelType")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(channel_select: ChannelSelect) -> Json {
  let type_ = [#("type", json.int(8))]

  let id = case channel_select.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(channel_select.custom_id))]

  let channel_types = case channel_select.channel_types {
    Some(types) -> [#("channel_types", json.array(types, channel_type_to_json))]
    None -> []
  }

  let placeholder = case channel_select.placeholder {
    Some(placeholder) -> [#("placeholder", json.string(placeholder))]
    None -> []
  }

  let default_values = case channel_select.default_values {
    Some(values) -> [
      #("default_values", json.array(values, default_value_to_json)),
    ]
    None -> []
  }

  let min_values = [#("min_values", json.int(channel_select.min_values))]

  let max_values = [#("max_values", json.int(channel_select.max_values))]

  let is_disabled = [#("disabled", json.bool(channel_select.is_disabled))]

  [
    type_,
    id,
    custom_id,
    channel_types,
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
pub fn channel_type_to_json(channel_type: ChannelType) -> Json {
  case channel_type {
    Text -> 0
    Dm -> 1
    Category -> 4
    Announcement -> 5
    Forum -> 15
    Media -> 16
  }
  |> json.int
}

@internal
pub fn default_value_to_json(default_value: DefaultValue) -> Json {
  json.object([
    #("id", json.string(default_value.id)),
    #("type", json.string("channel")),
  ])
}
