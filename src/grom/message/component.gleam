import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{None}
import grom/message/component/action_row.{type ActionRow}
import grom/message/component/container.{type Container}
import grom/message/component/file.{type File}
import grom/message/component/media_gallery.{type MediaGallery}
import grom/message/component/section.{type Section}
import grom/message/component/separator.{type Separator}
import grom/message/component/text_display.{type TextDisplay}

// TYPES -----------------------------------------------------------------------

pub type Component {
  ActionRow(ActionRow)
  Section(Section)
  TextDisplay(TextDisplay)
  MediaGallery(MediaGallery)
  File(File)
  Separator(Separator)
  Container(Container)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Component) {
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
    17 -> {
      use container <- decode.then(container.decoder())
      decode.success(Container(container))
    }
    _ -> decode.failure(ActionRow(action_row.ActionRow(None, [])), "Component")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(component: Component) -> Json {
  case component {
    ActionRow(action_row) -> action_row.to_json(action_row)
    Section(section) -> section.to_json(section)
    TextDisplay(text_display) -> text_display.to_json(text_display)
    MediaGallery(media_gallery) -> media_gallery.to_json(media_gallery)
    File(file) -> file.to_json(file)
    Separator(separator) -> separator.to_json(separator)
    Container(container) -> container.to_json(container)
  }
}
