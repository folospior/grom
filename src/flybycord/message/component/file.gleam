import flybycord/message/component/unfurled_media_item.{type UnfurledMediaItem}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type File {
  File(id: Option(Int), file: UnfurledMediaItem, is_spoiler: Bool)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(File) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use file <- decode.field("file", unfurled_media_item.decoder())
  use is_spoiler <- decode.optional_field("spoiler", False, decode.bool)
  decode.success(File(id:, file:, is_spoiler:))
}
