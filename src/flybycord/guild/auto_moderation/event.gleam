import gleam/dynamic/decode
import gleam/json.{type Json}

// TYPES -----------------------------------------------------------------------

pub type Type {
  MessageSend
  MemberUpdate
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(MessageSend)
    2 -> decode.success(MemberUpdate)
    _ -> decode.failure(MessageSend, "Type")
  }
}

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    MessageSend -> json.int(1)
    MemberUpdate -> json.int(2)
  }
}
