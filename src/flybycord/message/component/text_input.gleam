import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Style {
  Short
  Paragraph
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn style_decoder() -> decode.Decoder(Style) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Short)
    2 -> decode.success(Paragraph)
    _ -> decode.failure(Short, "Style")
  }
}
