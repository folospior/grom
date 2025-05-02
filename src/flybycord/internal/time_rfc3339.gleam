import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Timestamp) {
  use rfc3339 <- decode.then(decode.string)
  rfc3339
  |> timestamp.parse_rfc3339
  |> fn(timestamp) {
    case timestamp {
      Ok(time) -> decode.success(time)
      Error(_) -> decode.failure(timestamp.from_unix_seconds(0), "Timestamp")
    }
  }
}
