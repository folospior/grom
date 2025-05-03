import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Spacing {
  SmallPadding
  LargePadding
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn spacing_decoder() -> decode.Decoder(Spacing) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(SmallPadding)
    2 -> decode.success(LargePadding)
    _ -> decode.failure(SmallPadding, "Spacing")
  }
}
