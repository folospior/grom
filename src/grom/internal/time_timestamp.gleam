import gleam/dynamic/decode
import gleam/float
import gleam/time/timestamp.{type Timestamp}

@internal
pub fn from_unix_milliseconds_decoder() -> decode.Decoder(Timestamp) {
  use milliseconds <- decode.then(decode.int)
  decode.success(timestamp.from_unix_seconds(milliseconds / 1000))
}

@internal
pub fn from_unix_seconds_decoder() -> decode.Decoder(Timestamp) {
  decode.map(decode.int, timestamp.from_unix_seconds)
}

@internal
pub fn to_unix_milliseconds(timestamp: Timestamp) -> Int {
  timestamp
  |> timestamp.to_unix_seconds
  |> float.multiply(1000.0)
  |> float.round
}
