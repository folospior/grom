import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/emoji.{type Emoji}

// TYPES -----------------------------------------------------------------------

pub type Button {
  Regular(
    id: Option(Int),
    style: Style,
    label: Option(String),
    emoji: Option(Emoji),
    custom_id: String,
    is_disabled: Bool,
  )
  Link(
    id: Option(Int),
    label: Option(String),
    emoji: Option(Emoji),
    url: String,
    is_disabled: Bool,
  )
  Premium(id: Option(Int), sku_id: String, is_disabled: Bool)
}

pub type Style {
  Primary
  Secondary
  Success
  Danger
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Button) {
  use style <- decode.field("style", decode.int)
  case style {
    1 | 2 | 3 | 4 -> regular_decoder()
    5 -> link_decoder()
    6 -> premium_decoder()
    _ -> decode.failure(Regular(None, Primary, None, None, "", False), "Button")
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
    decode.optional(emoji.decoder()),
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
    decode.optional(emoji.decoder()),
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
