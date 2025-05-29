import gleam/dynamic/decode
import gleam/option.{type Option}

// TYPES -----------------------------------------------------------------------

pub type TextDisplay {
  TextDisplay(id: Option(Int), content: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(TextDisplay) {
  use id <- decode.field("id", decode.optional(decode.int))
  use content <- decode.field("content", decode.string)
  decode.success(TextDisplay(id:, content:))
}
