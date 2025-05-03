import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type DefaultValue {
  DefaultValue(id: String, type_: Type)
}

pub type Type {
  User
  Role
  Channel
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(DefaultValue) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())

  decode.success(DefaultValue(id:, type_:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.string)
  case variant {
    "user" -> decode.success(User)
    "role" -> decode.success(Role)
    "channel" -> decode.success(Channel)
    _ -> decode.failure(User, "Type")
  }
}
