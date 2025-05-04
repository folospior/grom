import gleam/dynamic/decode

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
