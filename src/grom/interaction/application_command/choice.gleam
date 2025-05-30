import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Choice {
  Choice(
    name: String,
    name_localizations: Option(Dict(String, String)),
    value: Value,
  )
}

pub type Value {
  StringValue(String)
  IntValue(Int)
  FloatValue(Float)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Choice) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use value <- decode.field("value", value_decoder())
  decode.success(Choice(name:, name_localizations:, value:))
}

@internal
pub fn value_decoder() -> decode.Decoder(Value) {
  let string_decoder = {
    use value <- decode.then(decode.string)
    decode.success(StringValue(value))
  }

  let int_decoder = {
    use value <- decode.then(decode.int)
    decode.success(IntValue(value))
  }

  let float_decoder = {
    use value <- decode.then(decode.float)
    decode.success(FloatValue(value))
  }

  decode.one_of(string_decoder, [int_decoder, float_decoder])
}
