import flybycord/message/component/unfurled_media_item.{type UnfurledMediaItem}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type MediaGallery {
  MediaGallery(id: Option(Int), items: List(Item))
}

pub type Item {
  Item(media: UnfurledMediaItem, description: Option(String), is_spoiler: Bool)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(MediaGallery) {
  use id <- decode.field("id", decode.optional(decode.int))
  use items <- decode.field("items", decode.list(item_decoder()))
  decode.success(MediaGallery(id:, items:))
}

@internal
pub fn item_decoder() -> decode.Decoder(Item) {
  use media <- decode.field("media", unfurled_media_item.decoder())
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use is_spoiler <- decode.optional_field("spoiler", False, decode.bool)
  decode.success(Item(media:, description:, is_spoiler:))
}
