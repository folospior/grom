import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type UnfurledMediaItem {
  UnfurledMediaItem(
    url: String,
    proxy_url: Option(String),
    height: Option(Int),
    width: Option(Int),
    content_type: Option(String),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(UnfurledMediaItem) {
  use url <- decode.field("url", decode.string)
  use proxy_url <- decode.optional_field(
    "proxy_url",
    None,
    decode.optional(decode.string),
  )
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use content_type <- decode.optional_field(
    "content_type",
    None,
    decode.optional(decode.string),
  )
  decode.success(UnfurledMediaItem(
    url:,
    proxy_url:,
    height:,
    width:,
    content_type:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(unfurled_media_item: UnfurledMediaItem) -> Json {
  json.object([#("url", json.string(unfurled_media_item.url))])
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(url url: String) -> UnfurledMediaItem {
  UnfurledMediaItem(url, None, None, None, None)
}
