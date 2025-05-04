import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Type {
  Profanity
  SexualContent
  Slurs
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Profanity)
    2 -> decode.success(SexualContent)
    3 -> decode.success(Slurs)
    _ -> decode.failure(Profanity, "Type")
  }
}
