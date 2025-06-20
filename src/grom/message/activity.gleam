import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Activity {
  JoinActivity(party_id: Option(String))
  SpectateActivity(party_id: Option(String))
  ListenActivity(party_id: Option(String))
  JoinRequestActivity(party_id: Option(String))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Activity) {
  use type_ <- decode.field("type", decode.int)
  use party_id <- decode.optional_field(
    "party_id",
    None,
    decode.optional(decode.string),
  )

  case type_ {
    1 -> decode.success(JoinActivity(party_id:))
    2 -> decode.success(SpectateActivity(party_id:))
    3 -> decode.success(ListenActivity(party_id:))
    5 -> decode.success(JoinRequestActivity(party_id:))
    _ -> decode.failure(JoinActivity(None), "Activity")
  }
}
