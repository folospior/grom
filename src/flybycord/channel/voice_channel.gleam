import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type VideoQualityMode {
  Auto
  Full
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn video_quality_mode_decoder() -> decode.Decoder(VideoQualityMode) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Auto)
    2 -> decode.success(Full)
    _ -> decode.failure(Auto, "VoiceQualityMode")
  }
}
