import gleam/dynamic/decode
import gleam/float
import gleam/time/duration.{type Duration}

// DECODERS --------------------------------------------------------------------

@internal
pub fn from_minutes_decoder() -> decode.Decoder(Duration) {
  use minutes <- decode.then(decode.int)
  decode.success(duration.seconds(minutes * 60))
}

@internal
pub fn from_float_seconds_decoder() -> decode.Decoder(Duration) {
  use seconds <- decode.then(decode.float)

  seconds
  |> float.round
  |> duration.seconds
  |> decode.success
}

@internal
pub fn from_int_seconds_decoder() -> decode.Decoder(Duration) {
  use seconds <- decode.then(decode.int)

  seconds
  |> duration.seconds
  |> decode.success
}

// ENCODERS --------------------------------------------------------------------

pub fn to_int_seconds(duration: Duration) -> Int {
  duration
  |> duration.to_seconds
  |> float.round
}
