import flybycord/channel
import flybycord/emoji.{type Emoji}
import flybycord/message/component/button
import flybycord/message/component/mentionable_select
import flybycord/message/component/select/default_value.{type DefaultValue}
import flybycord/message/component/separator
import flybycord/message/component/text_input
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Component {
  ActionRow(id: Option(Int), components: List(Component))
  Button(
    id: Option(Int),
    style: button.Style,
    label: Option(String),
    emoji: Option(Emoji),
    custom_id: Option(String),
    sku_id: Option(String),
    url: Option(String),
    is_disabled: Option(Bool),
  )
  StringSelect(
    id: Option(Int),
    custom_id: String,
    options: List(SelectOption),
    placeholder: Option(String),
    min_values: Option(Int),
    max_values: Option(Int),
    is_disabled: Option(Bool),
  )
  TextInput(
    id: Option(Int),
    custom_id: String,
    style: text_input.Style,
    label: String,
    min_length: Option(Int),
    max_length: Option(Int),
    is_required: Option(Bool),
    value: Option(String),
    placeholder: Option(String),
  )
  MentionableSelect(
    type_: mentionable_select.Type,
    id: Option(Int),
    custom_id: String,
    placeholder: Option(String),
    default_values: Option(List(DefaultValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    is_disabled: Option(Bool),
  )
  ChannelSelect(
    id: Option(Int),
    custom_id: String,
    channel_types: Option(List(channel.Type)),
    placeholder: Option(String),
    default_values: Option(List(DefaultValue)),
    min_values: Option(Int),
    max_values: Option(Int),
    is_disabled: Option(Bool),
  )
  Section(id: Option(Int), components: List(Component), accessory: Component)
  TextDisplay(id: Option(Int), content: String)
  Thumbnail(
    id: Option(Int),
    media: UnfurledMediaItem,
    description: Option(String),
    is_spoiler: Option(Bool),
  )
  MediaGallery(id: Option(Int), items: List(MediaGalleryItem))
  File(id: Option(Int), file: UnfurledMediaItem, is_spoiler: Option(Bool))
  Separator(
    id: Option(Int),
    is_divider: Option(Bool),
    spacing: Option(separator.Spacing),
  )
  Container(
    id: Option(Int),
    components: List(Component),
    accent_color: Option(Int),
    is_spoiler: Option(Bool),
  )
}

pub type SelectOption {
  SelectOption(
    label: String,
    value: String,
    description: Option(String),
    emoji: Option(Emoji),
    is_default: Option(Bool),
  )
}

pub type MediaGalleryItem {
  MediaGalleryItem(
    media: UnfurledMediaItem,
    description: Option(String),
    is_spoiler: Option(Bool),
  )
}

pub type UnfurledMediaItem {
  UnfurledMediaItem(
    url: String,
    proxy_url: Option(String),
    height: Option(Int),
    width: Option(Int),
    content_type: Option(String),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> action_row_decoder()
    2 -> button_decoder()
    3 -> string_select_decoder()
    4 -> text_input_decoder()
    5 | 6 | 7 -> mentionable_select_decoder()
    8 -> channel_select_decoder()
    9 -> section_decoder()
    10 -> text_display_decoder()
    11 -> thumbnail_decoder()
    12 -> media_gallery_decoder()
    13 -> file_decoder()
    14 -> separator_decoder()
    17 -> container_decoder()
    _ -> decode.failure(ActionRow(None, []), "Component")
  }
}

fn action_row_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(decoder()))

  decode.success(ActionRow(id:, components:))
}

fn button_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use style <- decode.field("style", button.style_decoder())
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
  use custom_id <- decode.optional_field(
    "custom_id",
    None,
    decode.optional(decode.string),
  )
  use sku_id <- decode.optional_field(
    "sku_id",
    None,
    decode.optional(decode.string),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use is_disabled <- decode.optional_field(
    "disabled",
    None,
    decode.optional(decode.bool),
  )

  decode.success(Button(
    id:,
    style:,
    label:,
    emoji:,
    custom_id:,
    sku_id:,
    url:,
    is_disabled:,
  ))
}

fn string_select_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use options <- decode.field("options", decode.list(select_option_decoder()))
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use min_values <- decode.optional_field(
    "min_values",
    None,
    decode.optional(decode.int),
  )
  use max_values <- decode.optional_field(
    "max_values",
    None,
    decode.optional(decode.int),
  )
  use is_disabled <- decode.optional_field(
    "disabled",
    None,
    decode.optional(decode.bool),
  )

  decode.success(StringSelect(
    id:,
    custom_id:,
    options:,
    placeholder:,
    min_values:,
    max_values:,
    is_disabled:,
  ))
}

fn text_input_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use style <- decode.field("style", text_input.style_decoder())
  use label <- decode.field("label", decode.string)
  use min_length <- decode.optional_field(
    "min_length",
    None,
    decode.optional(decode.int),
  )
  use max_length <- decode.optional_field(
    "max_length",
    None,
    decode.optional(decode.int),
  )
  use is_required <- decode.optional_field(
    "required",
    None,
    decode.optional(decode.bool),
  )
  use value <- decode.optional_field(
    "value",
    None,
    decode.optional(decode.string),
  )
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )

  decode.success(TextInput(
    id:,
    custom_id:,
    style:,
    label:,
    min_length:,
    max_length:,
    is_required:,
    value:,
    placeholder:,
  ))
}

fn mentionable_select_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", mentionable_select.type_decoder())
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use default_values <- decode.optional_field(
    "default_values",
    None,
    decode.optional(decode.list(default_value.decoder())),
  )

  use min_values <- decode.optional_field(
    "min_values",
    None,
    decode.optional(decode.int),
  )
  use max_values <- decode.optional_field(
    "max_values",
    None,
    decode.optional(decode.int),
  )
  use is_disabled <- decode.optional_field(
    "disabled",
    None,
    decode.optional(decode.bool),
  )

  decode.success(MentionableSelect(
    type_:,
    id:,
    custom_id:,
    placeholder:,
    default_values:,
    min_values:,
    max_values:,
    is_disabled:,
  ))
}

fn channel_select_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use channel_types <- decode.optional_field(
    "channel_types",
    None,
    decode.optional(decode.list(channel.type_decoder())),
  )
  use placeholder <- decode.optional_field(
    "placeholder",
    None,
    decode.optional(decode.string),
  )
  use default_values <- decode.optional_field(
    "default_values",
    None,
    decode.optional(decode.list(default_value.decoder())),
  )
  use min_values <- decode.optional_field(
    "min_values",
    None,
    decode.optional(decode.int),
  )
  use max_values <- decode.optional_field(
    "max_values",
    None,
    decode.optional(decode.int),
  )
  use is_disabled <- decode.optional_field(
    "disabled",
    None,
    decode.optional(decode.bool),
  )

  decode.success(ChannelSelect(
    id:,
    custom_id:,
    channel_types:,
    placeholder:,
    default_values:,
    min_values:,
    max_values:,
    is_disabled:,
  ))
}

fn section_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(decoder()))
  use accessory <- decode.field("accessory", decoder())

  decode.success(Section(id:, components:, accessory:))
}

fn text_display_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use content <- decode.field("content", decode.string)

  decode.success(TextDisplay(id:, content:))
}

fn thumbnail_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use media <- decode.field("media", unfurled_media_item_decoder())
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use is_spoiler <- decode.optional_field(
    "spoiler",
    None,
    decode.optional(decode.bool),
  )

  decode.success(Thumbnail(id:, media:, description:, is_spoiler:))
}

fn media_gallery_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use items <- decode.field("items", decode.list(media_gallery_item_decoder()))

  decode.success(MediaGallery(id:, items:))
}

fn file_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use file <- decode.field("file", unfurled_media_item_decoder())
  use is_spoiler <- decode.optional_field(
    "spoiler",
    None,
    decode.optional(decode.bool),
  )

  decode.success(File(id:, file:, is_spoiler:))
}

fn separator_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use is_divider <- decode.optional_field(
    "divider",
    None,
    decode.optional(decode.bool),
  )
  use spacing <- decode.optional_field(
    "spacing",
    None,
    decode.optional(separator.spacing_decoder()),
  )

  decode.success(Separator(id:, is_divider:, spacing:))
}

fn container_decoder() -> decode.Decoder(Component) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(decoder()))
  use accent_color <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(decode.int),
  )
  use is_spoiler <- decode.optional_field(
    "spoiler",
    None,
    decode.optional(decode.bool),
  )

  decode.success(Container(id:, components:, accent_color:, is_spoiler:))
}

@internal
pub fn select_option_decoder() -> decode.Decoder(SelectOption) {
  use label <- decode.field("label", decode.string)
  use value <- decode.field("value", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji.decoder()),
  )
  use is_default <- decode.optional_field(
    "default",
    None,
    decode.optional(decode.bool),
  )

  decode.success(SelectOption(label:, value:, description:, emoji:, is_default:))
}

@internal
pub fn unfurled_media_item_decoder() -> decode.Decoder(UnfurledMediaItem) {
  use url <- decode.field("url", decode.string)
  use proxy_url <- decode.optional_field(
    "proxy_url",
    None,
    decode.optional(decode.string),
  )
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use content_type <- decode.optional_field(
    "content_type",
    None,
    decode.optional(decode.string),
  )
  decode.success(UnfurledMediaItem(
    url:,
    proxy_url:,
    height:,
    width:,
    content_type:,
  ))
}

@internal
pub fn media_gallery_item_decoder() -> decode.Decoder(MediaGalleryItem) {
  use media <- decode.field("media", unfurled_media_item_decoder())
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use is_spoiler <- decode.optional_field(
    "spoiler",
    None,
    decode.optional(decode.bool),
  )
  decode.success(MediaGalleryItem(media:, description:, is_spoiler:))
}
