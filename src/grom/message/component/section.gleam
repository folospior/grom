import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/message/component/button.{type Button}
import grom/message/component/text_display.{type TextDisplay}
import grom/message/component/unfurled_media_item.{type UnfurledMediaItem}

// TYPES -----------------------------------------------------------------------

pub type Section {
  Section(id: Option(Int), components: List(Component), accessory: Accessory)
}

pub type Component {
  TextDisplay(TextDisplay)
}

pub type Accessory {
  Thumbnail(
    id: Option(Int),
    media: UnfurledMediaItem,
    description: Option(String),
    is_spoiler: Bool,
  )
  Button(Button)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Section) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(component_decoder()))
  use accessory <- decode.field("accessory", accessory_decoder())
  decode.success(Section(id:, components:, accessory:))
}

@internal
pub fn component_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    10 -> {
      use text_display <- decode.then(text_display.decoder())
      decode.success(TextDisplay(text_display))
    }
    _ ->
      decode.failure(
        TextDisplay(text_display.TextDisplay(None, "")),
        "Component",
      )
  }
}

@internal
pub fn accessory_decoder() {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    2 -> {
      use button <- decode.then(button.decoder())
      decode.success(Button(button))
    }
    11 -> {
      use id <- decode.optional_field("id", None, decode.optional(decode.int))
      use media <- decode.field("media", unfurled_media_item.decoder())
      use description <- decode.optional_field(
        "description",
        None,
        decode.optional(decode.string),
      )
      use is_spoiler <- decode.optional_field("spoiler", False, decode.bool)
      decode.success(Thumbnail(id:, media:, description:, is_spoiler:))
    }
    _ ->
      decode.failure(
        Button(button.Regular(None, False, button.Primary, None, None, "")),
        "Accessory",
      )
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(section: Section) -> Json {
  let type_ = [#("type", json.int(9))]

  let id = case section.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let components = [
    #("components", json.array(section.components, component_to_json)),
  ]

  let accessory = [#("accessory", accessory_to_json(section.accessory))]

  [type_, id, components, accessory]
  |> list.flatten
  |> json.object
}

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    TextDisplay(text_display) -> text_display.to_json(text_display)
  }
}

@internal
pub fn accessory_to_json(accessory: Accessory) -> Json {
  case accessory {
    Button(button) -> button.to_json(button)
    Thumbnail(..) -> {
      let type_ = [#("type", json.int(11))]

      let id = case accessory.id {
        Some(id) -> [#("id", json.int(id))]
        None -> []
      }

      let media = [#("media", unfurled_media_item.to_json(accessory.media))]

      let description = case accessory.description {
        Some(description) -> [#("description", json.string(description))]
        None -> []
      }

      let is_spoiler = [#("spoiler", json.bool(accessory.is_spoiler))]

      [type_, id, media, description, is_spoiler]
      |> list.flatten
      |> json.object
    }
  }
}
