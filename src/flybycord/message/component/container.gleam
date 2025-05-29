import flybycord/message/component/action_row.{type ActionRow}
import flybycord/message/component/file.{type File}
import flybycord/message/component/media_gallery.{type MediaGallery}
import flybycord/message/component/section.{type Section}
import flybycord/message/component/separator.{type Separator}
import flybycord/message/component/text_display.{type TextDisplay}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Container {
  Container(
    id: Option(Int),
    components: List(Component),
    accent_color: Option(Int),
    is_spoiler: Bool,
  )
}

pub type Component {
  ActionRow(ActionRow)
  TextDisplay(TextDisplay)
  Section(Section)
  MediaGallery(MediaGallery)
  Separator(Separator)
  File(File)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Container) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(component_decoder()))
  use accent_color <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(decode.int),
  )
  use is_spoiler <- decode.optional_field("spoiler", False, decode.bool)
  decode.success(Container(id:, components:, accent_color:, is_spoiler:))
}

@internal
pub fn component_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> {
      use action_row <- decode.then(action_row.decoder())
      decode.success(ActionRow(action_row))
    }
    9 -> {
      use section <- decode.then(section.decoder())
      decode.success(Section(section))
    }
    10 -> {
      use text_display <- decode.then(text_display.decoder())
      decode.success(TextDisplay(text_display))
    }
    12 -> {
      use media_gallery <- decode.then(media_gallery.decoder())
      decode.success(MediaGallery(media_gallery))
    }
    13 -> {
      use file <- decode.then(file.decoder())
      decode.success(File(file))
    }
    14 -> {
      use separator <- decode.then(separator.decoder())
      decode.success(Separator(separator))
    }
    _ ->
      decode.failure(
        TextDisplay(text_display.TextDisplay(None, "")),
        "Component",
      )
  }
}
