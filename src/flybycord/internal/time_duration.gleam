import gleam/dynamic/decode
import gleam/time/duration.{type Duration}

// DECODERS --------------------------------------------------------------------

@internal
pub fn from_minutes_decoder() -> decode.Decoder(Duration) {
  use minutes <- decode.then(decode.int)
  decode.success(duration.seconds(minutes * 60))
}
