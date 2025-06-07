import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
import gleam/time/duration.{type Duration}
import grom/internal/base64
import grom/internal/flags
import grom/internal/time_duration

// TYPES -----------------------------------------------------------------------

pub type Attachment {
  Attachment(
    id: String,
    filename: String,
    title: Option(String),
    description: Option(String),
    content_type: Option(String),
    size_bytes: Int,
    url: String,
    proxy_url: String,
    height: Option(Int),
    width: Option(Int),
    is_ephemeral: Option(Bool),
    duration: Duration,
    waveform: Option(BitArray),
    flags: Option(List(Flag)),
  )
}

pub opaque type Create {
  Create(filename: String, description: Option(String))
}

pub type Flag {
  IsRemix
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 2), IsRemix)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Attachment) {
  use id <- decode.field("id", decode.string)
  use filename <- decode.field("filename", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use content_type <- decode.optional_field(
    "content_type",
    None,
    decode.optional(decode.string),
  )
  use size_bytes <- decode.field("size", decode.int)
  use url <- decode.field("url", decode.string)
  use proxy_url <- decode.field("proxy_url", decode.string)
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use is_ephemeral <- decode.optional_field(
    "ephemeral",
    None,
    decode.optional(decode.bool),
  )
  use duration <- decode.field(
    "duration",
    time_duration.from_float_seconds_decoder(),
  )
  use waveform <- decode.field("waveform", decode.optional(base64.decoder()))
  use flags <- decode.field(
    "flags",
    decode.optional(flags.decoder(bits_flags())),
  )
  decode.success(Attachment(
    id:,
    filename:,
    title:,
    description:,
    content_type:,
    size_bytes:,
    url:,
    proxy_url:,
    height:,
    width:,
    is_ephemeral:,
    duration:,
    waveform:,
    flags:,
  ))
}
