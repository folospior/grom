import flybycord/message/component/button.{type Button}
import flybycord/message/component/text_display.{type TextDisplay}
import flybycord/message/component/unfurled_media_item.{type UnfurledMediaItem}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

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
        Button(button.Regular(None, button.Primary, None, None, "", False)),
        "Accessory",
      )
  }
}
