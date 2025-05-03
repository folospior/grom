import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Activity {
  Activity(type_: Type, party_id: Option(String))
}

pub type Type {
  Join
  Spectate
  Listen
  JoinRequest
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Activity) {
  use type_ <- decode.field("type", type_decoder())
  use party_id <- decode.optional_field(
    "party_id",
    None,
    decode.optional(decode.string),
  )
  decode.success(Activity(type_:, party_id:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Join)
    2 -> decode.success(Spectate)
    3 -> decode.success(Listen)
    5 -> decode.success(JoinRequest)
    _ -> decode.failure(Join, "Type")
  }
}
