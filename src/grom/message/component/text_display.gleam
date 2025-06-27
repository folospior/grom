import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type TextDisplay {
  TextDisplay(id: Option(Int), content: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(TextDisplay) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use content <- decode.field("content", decode.string)
  decode.success(TextDisplay(id:, content:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(text_display: TextDisplay) -> Json {
  let type_ = [#("type", json.int(10))]

  let id = case text_display.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let content = [#("content", json.string(text_display.content))]

  [type_, id, content]
  |> list.flatten
  |> json.object
}
