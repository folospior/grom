import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Type {
  User
  Role
  Mentionable
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    5 -> decode.success(User)
    6 -> decode.success(Role)
    7 -> decode.success(Mentionable)
    _ -> decode.failure(User, "Type")
  }
}
