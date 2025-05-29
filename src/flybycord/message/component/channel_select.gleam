import flybycord/channel
import gleam/dynamic/decode
import gleam/option.{type Option, None}

pub type ChannelSelect {
  ChannelSelect(
    id: Option(Int),
    custom_id: String,
    channel_types: Option(List(channel.Type)),
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

@internal
pub fn decoder() -> decode.Decoder(ChannelSelect) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use channel_types <- decode.optional_field(
    "channel_types",
    None,
    decode.optional(decode.list(channel.type_decoder())),
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
