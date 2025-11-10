import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/component/action_row.{type ActionRow}
import grom/component/file.{type File}
import grom/component/media_gallery.{type MediaGallery}
import grom/component/section.{type Section}
import grom/component/separator.{type Separator}
import grom/component/text_display.{type TextDisplay}

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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(container: Container) -> Json {
  let type_ = [#("type", json.int(17))]

  let id = case container.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let components = [
    #("components", json.array(container.components, component_to_json)),
  ]

  let accent_color = case container.accent_color {
    Some(color) -> [#("accent_color", json.int(color))]
    None -> []
  }

  let is_spoiler = [#("spoiler", json.bool(container.is_spoiler))]

  [type_, id, components, accent_color, is_spoiler]
  |> list.flatten
  |> json.object
}

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    ActionRow(action_row) -> action_row.to_json(action_row)
    TextDisplay(text_display) -> text_display.to_json(text_display)
    Section(section) -> section.to_json(section)
    MediaGallery(media_gallery) -> media_gallery.to_json(media_gallery)
    Separator(separator) -> separator.to_json(separator)
    File(file) -> file.to_json(file)
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(containing components: List(Component)) -> Container {
  Container(None, components, None, False)
}
