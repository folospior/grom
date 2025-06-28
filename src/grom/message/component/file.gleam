import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/message/component/unfurled_media_item.{type UnfurledMediaItem}

// TYPES -----------------------------------------------------------------------

pub type File {
  File(
    id: Option(Int),
    file: UnfurledMediaItem,
    is_spoiler: Bool,
    name: String,
    size: Int,
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(File) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use file <- decode.field("file", unfurled_media_item.decoder())
  use is_spoiler <- decode.optional_field("spoiler", False, decode.bool)
  use name <- decode.field("name", decode.string)
  use size <- decode.field("size", decode.int)

  decode.success(File(id:, file:, is_spoiler:, name:, size:))
}

// ENCODERS --------------------------------------------------------------------

pub fn to_json(file: File) -> Json {
  let type_ = [#("type", json.int(13))]

  let id = case file.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let file_ = [#("file", unfurled_media_item.to_json(file.file))]

  let is_spoiler = [#("spoiler", json.bool(file.is_spoiler))]

  [type_, id, file_, is_spoiler]
  |> list.flatten
  |> json.object
}
