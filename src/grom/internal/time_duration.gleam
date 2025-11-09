import gleam/dynamic/decode
import gleam/float
import gleam/json.{type Json}
import gleam/time/duration.{type Duration}

// DECODERS --------------------------------------------------------------------

@internal
pub fn from_minutes_decoder() -> decode.Decoder(Duration) {
  use minutes <- decode.then(decode.int)
  decode.success(duration.seconds(minutes * 60))
}

@internal
pub fn from_milliseconds_decoder() -> decode.Decoder(Duration) {
  use milliseconds <- decode.then(decode.int)
  decode.success(duration.milliseconds(milliseconds))
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

@internal
pub fn from_int_hours_decoder() -> decode.Decoder(Duration) {
  use hours <- decode.then(decode.int)

  hours
  |> duration.hours
  |> decode.success
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_int_seconds_encode(duration: Duration) -> Json {
  duration
  |> to_int_seconds
  |> json.int
}

@internal
pub fn to_int_hours_json(duration: Duration) -> Json {
  duration
  |> to_int_hours
  |> json.int
}

// INTERNAL FUNCTIONS ----------------------------------------------------------

@internal
pub fn to_int_seconds(duration: Duration) -> Int {
  duration
  |> duration.to_seconds
  |> float.round
}

@internal
pub fn to_int_hours(duration: Duration) -> Int {
  to_int_seconds(duration) / 3600
}
