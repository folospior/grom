import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/time/duration.{type Duration}
import grom/message
import grom/message/allowed_mentions.{type AllowedMentions}
import grom/message/attachment
import grom/message/component.{type Component}
import grom/message/embed.{type Embed}

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

pub opaque type StartThread {
  StartThread(
    name: String,
    auto_archive_duration: Duration,
    rate_limit_per_user: Option(Duration),
  )
}

pub opaque type StartThreadMessage {
  StartThreadMessage(
    content: Option(String),
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    components: Option(List(Component)),
    sticker_ids: Option(List(String)),
    attachments: Option(List(attachment.Create)),
    flags: Option(List(message.Flag)),
  )
}

pub type Flag {
  RequiresTag
}

pub type DefaultReaction {
  DefaultReaction(emoji_id: Option(String), emoji_name: Option(String))
}

pub type SortOrder {
  SortByLatestActivity
  SortByCreationDate
}

pub type Layout {
  LayoutNotSet
  ListLayout
  GalleryLayout
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 4), RequiresTag)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn default_reaction_decoder() -> decode.Decoder(DefaultReaction) {
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(DefaultReaction(emoji_id:, emoji_name:))
}

@internal
pub fn sort_order_type_decoder() -> decode.Decoder(SortOrder) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(SortByLatestActivity)
    1 -> decode.success(SortByCreationDate)
    _ -> decode.failure(SortByLatestActivity, "SortOrderType")
  }
}

@internal
pub fn layout_type_decoder() -> decode.Decoder(Layout) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(LayoutNotSet)
    1 -> decode.success(ListLayout)
    2 -> decode.success(GalleryLayout)
    _ -> decode.failure(LayoutNotSet, "LayoutType")
  }
}

@internal
pub fn tag_decoder() -> decode.Decoder(Tag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Tag(id:, name:, is_moderated:, emoji_id:, emoji_name:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn default_reaction_encode(default_reaction: DefaultReaction) -> Json {
  let DefaultReaction(emoji_id:, emoji_name:) = default_reaction
  json.object([
    #("emoji_id", case emoji_id {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
    #("emoji_name", case emoji_name {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
  ])
}

@internal
pub fn sort_order_type_encode(sort_order_type: SortOrder) -> Json {
  case sort_order_type {
    SortByLatestActivity -> 0
    SortByCreationDate -> 1
  }
  |> json.int
}

@internal
pub fn layout_type_encode(layout_type: Layout) -> Json {
  case layout_type {
    LayoutNotSet -> 0
    ListLayout -> 1
    GalleryLayout -> 2
  }
  |> json.int
}

@internal
pub fn tag_to_json(tag: Tag) -> Json {
  let id = #("id", json.string(tag.id))
  let name = #("name", json.string(tag.name))
  let is_moderated = #("moderated", json.bool(tag.is_moderated))
  let emoji_id = #("emoji_id", json.nullable(tag.emoji_id, json.string))
  let emoji_name = #("emoji_name", json.nullable(tag.emoji_name, json.string))

  [id, name, is_moderated, emoji_id, emoji_name]
  |> json.object
}
