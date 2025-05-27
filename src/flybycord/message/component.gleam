import flybycord/channel
import flybycord/emoji.{type Emoji}
import flybycord/message/component/action_row.{type ActionRow}
import flybycord/message/component/button.{type Button}
import flybycord/message/component/mentionable_select.{type MentionableSelect}
import flybycord/message/component/role_select.{type RoleSelect}
import flybycord/message/component/select/default_value.{type DefaultValue}
import flybycord/message/component/separator
import flybycord/message/component/string_select.{type StringSelect}
import flybycord/message/component/text_input.{type TextInput}
import flybycord/message/component/user_select.{type UserSelect}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Component {
  ActionRow(ActionRow)
  Button(Button)
  StringSelect(StringSelect)
  TextInput(TextInput)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
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
    1 -> {
      use action_row <- decode.then(action_row.decoder())
      decode.success(ActionRow(action_row))
    }
    2 -> {
      use button <- decode.then(button.decoder())
      decode.success(Button(button))
    }
    3 -> {
      use string_select <- decode.then(string_select.decoder())
      decode.success(StringSelect(string_select))
    }
    4 -> {
      use text_input <- decode.then(text_input.decoder())
      decode.success(TextInput(text_input))
    }
    5 -> {
      use user_select <- decode.then(user_select.decoder())
      decode.success(UserSelect(user_select))
    }
    6 -> {
      use role_select <- decode.then(role_select.decoder())
      decode.success(RoleSelect(role_select))
    }
    7 -> {
      use mentionable_select <- decode.then(mentionable_select.decoder())
      decode.success(MentionableSelect(mentionable_select))
    }
    8 -> channel_select_decoder()
    9 -> section_decoder()
    10 -> text_display_decoder()
    11 -> thumbnail_decoder()
    12 -> media_gallery_decoder()
    13 -> file_decoder()
    14 -> separator_decoder()
    17 -> container_decoder()
    _ -> decode.failure(todo, "Component")
  }
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
