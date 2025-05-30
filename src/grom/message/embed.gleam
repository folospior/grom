import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/time_rfc3339

// TYPES -----------------------------------------------------------------------

pub type Embed {
  Embed(
    title: Option(String),
    type_: Option(Type),
    description: Option(String),
    url: Option(String),
    timestamp: Option(Timestamp),
    color: Option(Int),
    footer: Option(Footer),
    image: Option(Image),
    thumbnail: Option(Image),
    video: Option(Video),
    provider: Option(Provider),
    author: Option(Author),
    fields: Option(List(Field)),
  )
}

pub type Type {
  Rich
  ImageEmbed
  VideoEmbed
  Gifv
  Article
  Link
  PollResult
}

pub type Footer {
  Footer(text: String, icon_url: Option(String), proxy_icon_url: Option(String))
}

pub type Image {
  Image(
    url: String,
    proxy_url: Option(String),
    height: Option(Int),
    width: Option(Int),
  )
}

pub type Video {
  Video(
    url: Option(String),
    proxy_url: Option(String),
    height: Option(Int),
    width: Option(Int),
  )
}

pub type Provider {
  Provider(name: Option(String), url: Option(String))
}

pub type Author {
  Author(
    name: String,
    url: Option(String),
    icon_url: Option(String),
    proxy_icon_url: Option(String),
  )
}

pub type Field {
  Field(name: String, value: String, is_inline: Option(Bool))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Embed) {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(type_decoder()),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use timestamp <- decode.optional_field(
    "timestamp",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use color <- decode.optional_field("color", None, decode.optional(decode.int))
  use footer <- decode.optional_field(
    "footer",
    None,
    decode.optional(footer_decoder()),
  )
  use image <- decode.optional_field(
    "image",
    None,
    decode.optional(image_decoder()),
  )
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(image_decoder()),
  )
  use video <- decode.optional_field(
    "video",
    None,
    decode.optional(video_decoder()),
  )
  use provider <- decode.optional_field(
    "provider",
    None,
    decode.optional(provider_decoder()),
  )
  use author <- decode.optional_field(
    "author",
    None,
    decode.optional(author_decoder()),
  )
  use fields <- decode.optional_field(
    "fields",
    None,
    decode.optional(decode.list(field_decoder())),
  )
  decode.success(Embed(
    title:,
    type_:,
    description:,
    url:,
    timestamp:,
    color:,
    footer:,
    image:,
    thumbnail:,
    video:,
    provider:,
    author:,
    fields:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.string)
  case variant {
    "rich" -> decode.success(Rich)
    "image" -> decode.success(ImageEmbed)
    "video" -> decode.success(VideoEmbed)
    "gifv" -> decode.success(Gifv)
    "article" -> decode.success(Article)
    "link" -> decode.success(Link)
    "poll_result" -> decode.success(PollResult)
    _ -> decode.failure(Rich, "Type")
  }
}

@internal
pub fn footer_decoder() -> decode.Decoder(Footer) {
  use text <- decode.field("text", decode.string)
  use icon_url <- decode.optional_field(
    "icon_url",
    None,
    decode.optional(decode.string),
  )
  use proxy_icon_url <- decode.optional_field(
    "proxy_icon_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(Footer(text:, icon_url:, proxy_icon_url:))
}

@internal
pub fn image_decoder() -> decode.Decoder(Image) {
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
  decode.success(Image(url:, proxy_url:, height:, width:))
}

@internal
pub fn video_decoder() -> decode.Decoder(Video) {
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
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
  decode.success(Video(url:, proxy_url:, height:, width:))
}

@internal
pub fn provider_decoder() -> decode.Decoder(Provider) {
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(Provider(name:, url:))
}

@internal
pub fn author_decoder() -> decode.Decoder(Author) {
  use name <- decode.field("name", decode.string)
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use icon_url <- decode.optional_field(
    "icon_url",
    None,
    decode.optional(decode.string),
  )
  use proxy_icon_url <- decode.optional_field(
    "proxy_icon_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(Author(name:, url:, icon_url:, proxy_icon_url:))
}

@internal
pub fn field_decoder() -> decode.Decoder(Field) {
  use name <- decode.field("name", decode.string)
  use value <- decode.field("value", decode.string)
  use is_inline <- decode.optional_field(
    "inline",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Field(name:, value:, is_inline:))
}
