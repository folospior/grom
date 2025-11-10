import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type Button {
  Regular(
    id: Option(Int),
    is_disabled: Bool,
    style: Style,
    label: Option(String),
    emoji: Option(Emoji),
    custom_id: String,
  )
  Link(
    id: Option(Int),
    is_disabled: Bool,
    label: Option(String),
    emoji: Option(Emoji),
    url: String,
  )
  Premium(id: Option(Int), is_disabled: Bool, sku_id: String)
}

pub type Style {
  Primary
  Secondary
  Success
  Danger
}

pub type Emoji {
  Emoji(id: Option(String), name: String, is_animated: Bool)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Button) {
  use style <- decode.field("style", decode.int)
  case style {
    1 | 2 | 3 | 4 -> regular_decoder()
    5 -> link_decoder()
    6 -> premium_decoder()
    _ -> decode.failure(Regular(None, False, Primary, None, None, ""), "Button")
  }
}

fn regular_decoder() -> decode.Decoder(Button) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use style <- decode.field("style", style_decoder())
  use label <- decode.optional_field(
    "label",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji_decoder()),
  )
  use custom_id <- decode.field("custom_id", decode.string)
  use is_disabled <- decode.optional_field("disabled", False, decode.bool)

  decode.success(Regular(id:, style:, label:, emoji:, custom_id:, is_disabled:))
}

fn link_decoder() -> decode.Decoder(Button) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use label <- decode.optional_field(
    "label",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji_decoder()),
  )
  use url <- decode.field("url", decode.string)
  use is_disabled <- decode.optional_field("disabled", False, decode.bool)

  decode.success(Link(id:, label:, emoji:, url:, is_disabled:))
}

fn premium_decoder() -> decode.Decoder(Button) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use sku_id <- decode.field("sku_id", decode.string)
  use is_disabled <- decode.optional_field("disabled", False, decode.bool)

  decode.success(Premium(id:, sku_id:, is_disabled:))
}

@internal
pub fn style_decoder() -> decode.Decoder(Style) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Primary)
    2 -> decode.success(Secondary)
    3 -> decode.success(Success)
    4 -> decode.success(Danger)
    _ -> decode.failure(Primary, "Style")
  }
}

@internal
pub fn emoji_decoder() -> decode.Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(decode.string))
  use name <- decode.field("name", decode.string)
  use is_animated <- decode.optional_field("animated", False, decode.bool)

  decode.success(Emoji(id:, name:, is_animated:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(button: Button) -> Json {
  let type_ = [#("type", json.int(2))]

  let id = case button.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let style = case button {
    Regular(style:, ..) -> [#("style", style_to_json(style))]
    Link(..) -> [#("style", json.int(5))]
    Premium(..) -> [#("style", json.int(6))]
  }

  let label = case button {
    Regular(label:, ..) | Link(label:, ..) ->
      case label {
        Some(label) -> [#("label", json.string(label))]
        None -> []
      }
    _ -> []
  }

  let emoji = case button {
    Regular(emoji:, ..) | Link(emoji:, ..) ->
      case emoji {
        Some(emoji) -> [#("emoji", emoji_to_json(emoji))]
        None -> []
      }
    _ -> []
  }

  let custom_id = case button {
    Regular(custom_id:, ..) -> [#("custom_id", json.string(custom_id))]
    _ -> []
  }

  let sku_id = case button {
    Premium(sku_id:, ..) -> [#("sku_id", json.string(sku_id))]
    _ -> []
  }

  let url = case button {
    Link(url:, ..) -> [#("url", json.string(url))]
    _ -> []
  }

  let is_disabled = [#("disabled", json.bool(button.is_disabled))]

  [type_, id, style, label, emoji, custom_id, sku_id, url, is_disabled]
  |> list.flatten
  |> json.object
}

@internal
pub fn style_to_json(style: Style) -> Json {
  case style {
    Primary -> 1
    Secondary -> 2
    Success -> 3
    Danger -> 4
  }
  |> json.int
}

@internal
pub fn emoji_to_json(emoji: Emoji) -> Json {
  let id = case emoji.id {
    Some(id) -> [#("id", json.string(id))]
    None -> []
  }

  let name = [#("name", json.string(emoji.name))]

  let is_animated = [#("animated", json.bool(emoji.is_animated))]

  [id, name, is_animated]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new_regular(custom_id custom_id: String) -> Button {
  Regular(None, False, Primary, None, None, custom_id:)
}

pub fn new_link(url url: String) -> Button {
  Link(None, False, None, None, url:)
}

pub fn new_premium(sku_id sku_id: String) -> Button {
  Premium(None, False, sku_id:)
}

pub fn new_emoji(named name: String) -> Emoji {
  Emoji(None, name, False)
}
