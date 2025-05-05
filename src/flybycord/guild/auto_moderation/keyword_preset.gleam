import gleam/dynamic/decode
import gleam/json.{type Json}

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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    Profanity -> 1
    SexualContent -> 2
    Slurs -> 3
  }
  |> json.int
}
