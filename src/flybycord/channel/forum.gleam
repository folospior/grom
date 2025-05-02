import gleam/dynamic/decode
import gleam/option.{type Option}

// TYPES -----------------------------------------------------------------------

pub type Tag {
  Tag(
    id: String,
    name: String,
    is_moderated: Bool,
    emoji_id: Option(String),
    emoji_name: Option(String),
  )
}

pub type DefaultReaction {
  DefaultReaction(emoji_id: Option(String), emoji_name: Option(String))
}

pub type SortOrderType {
  LatestActivity
  CreationDate
}

pub type LayoutType {
  NotSet
  ListView
  GalleryView
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn tag_decoder() -> decode.Decoder(Tag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Tag(id:, name:, is_moderated:, emoji_id:, emoji_name:))
}

@internal
pub fn default_reaction_decoder() -> decode.Decoder(DefaultReaction) {
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(DefaultReaction(emoji_id:, emoji_name:))
}

@internal
pub fn sort_order_type_decoder() -> decode.Decoder(SortOrderType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(LatestActivity)
    1 -> decode.success(CreationDate)
    _ -> decode.failure(LatestActivity, "SortOrderType")
  }
}

@internal
pub fn layout_type_decoder() -> decode.Decoder(LayoutType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NotSet)
    1 -> decode.success(ListView)
    2 -> decode.success(GalleryView)
    _ -> decode.failure(NotSet, "LayoutType")
  }
}
