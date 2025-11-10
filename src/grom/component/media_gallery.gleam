import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/component/unfurled_media_item.{type UnfurledMediaItem}

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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(media_gallery: MediaGallery) -> Json {
  let type_ = [#("type", json.int(12))]

  let id = case media_gallery.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let items = [#("items", json.array(media_gallery.items, item_to_json))]

  [type_, id, items]
  |> list.flatten
  |> json.object
}

@internal
pub fn item_to_json(item: Item) -> Json {
  let media = [#("media", unfurled_media_item.to_json(item.media))]

  let description = case item.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let is_spoiler = [#("spoiler", json.bool(item.is_spoiler))]

  [media, description, is_spoiler]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(containing items: List(Item)) -> MediaGallery {
  MediaGallery(None, items)
}

pub fn new_item(showing media: UnfurledMediaItem) -> Item {
  Item(media, None, False)
}
