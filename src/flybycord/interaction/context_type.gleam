import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type ContextType {
  Guild
  BotDm
  PrivateChannel
}

// DECODERS --------------------------------------------------------------------

pub fn decoder() -> decode.Decoder(ContextType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Guild)
    1 -> decode.success(BotDm)
    2 -> decode.success(PrivateChannel)
    _ -> decode.failure(Guild, "ContextType")
  }
}
