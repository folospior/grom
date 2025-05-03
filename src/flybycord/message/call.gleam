import flybycord/internal/time_rfc3339
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Call {
  Call(participants: List(String), ended_timestamp: Option(Timestamp))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Call) {
  use participants <- decode.field("participants", decode.list(decode.string))
  use ended_timestamp <- decode.optional_field(
    "ended_timestamp",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  decode.success(Call(participants:, ended_timestamp:))
}
