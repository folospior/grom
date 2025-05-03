import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Style {
  Primary
  Secondary
  Success
  Danger
  Link
  Premium
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn style_decoder() -> decode.Decoder(Style) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Primary)
    2 -> decode.success(Secondary)
    3 -> decode.success(Success)
    4 -> decode.success(Danger)
    5 -> decode.success(Link)
    6 -> decode.success(Premium)
    _ -> decode.failure(Primary, "Style")
  }
}
