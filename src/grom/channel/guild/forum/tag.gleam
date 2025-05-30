import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

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

pub type Create {
  Create(
    name: String,
    is_moderated: Bool,
    emoji_id: Option(String),
    emoji_name: Option(String),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Tag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Tag(id:, name:, is_moderated:, emoji_id:, emoji_name:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_encode(create: Create) -> Json {
  let Create(name:, is_moderated:, emoji_id:, emoji_name:) = create
  json.object([
    #("name", json.string(name)),
    #("is_moderated", json.bool(is_moderated)),
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
