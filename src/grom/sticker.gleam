import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import grom
import grom/internal/rest
import grom/user.{type User}

// TYPES ----------------------------------------------------------------------

pub type Sticker {
  Sticker(
    id: String,
    pack_id: Option(String),
    name: String,
    description: Option(String),
    tags: String,
    type_: Type,
    format_type: ContentType,
    is_available: Option(Bool),
    guild_id: Option(String),
    user: Option(User),
    sort_value: Option(Int),
  )
}

pub type Item {
  Item(id: String, name: String, format_type: ContentType)
}

pub type Pack {
  Pack(
    id: String,
    stickers: List(Sticker),
    name: String,
    sku_id: String,
    cover_sticker_id: Option(String),
    description: String,
    banner_asset_id: Option(String),
  )
}

pub type Type {
  Standard
  Guild
}

pub type ContentType {
  Png
  Apng
  Lottie
  Gif
}

pub type File {
  File(name: String, content_type: ContentType, content: BitArray)
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Standard)
    1 -> decode.success(Guild)
    _ -> decode.failure(Standard, "Type")
  }
}

@internal
pub fn format_type_decoder() -> decode.Decoder(ContentType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Png)
    1 -> decode.success(Apng)
    2 -> decode.success(Lottie)
    3 -> decode.success(Gif)
    _ -> decode.failure(Png, "FormatType")
  }
}

@internal
pub fn decoder() -> decode.Decoder(Sticker) {
  use id <- decode.field("id", decode.string)
  use pack_id <- decode.field("pack_id", decode.optional(decode.string))
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use tags <- decode.field("tags", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use format_type <- decode.field("format_type", format_type_decoder())
  use is_available <- decode.field("available", decode.optional(decode.bool))
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use sort_value <- decode.optional_field(
    "sort_value",
    None,
    decode.optional(decode.int),
  )
  decode.success(Sticker(
    id:,
    pack_id:,
    name:,
    description:,
    tags:,
    type_:,
    format_type:,
    is_available:,
    guild_id:,
    user:,
    sort_value:,
  ))
}

@internal
pub fn pack_decoder() -> decode.Decoder(Pack) {
  use id <- decode.field("id", decode.string)
  use stickers <- decode.field("stickers", decode.list(of: decoder()))
  use name <- decode.field("name", decode.string)
  use sku_id <- decode.field("sku_id", decode.string)
  use cover_sticker_id <- decode.optional_field(
    "cover_sticker_id",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.field("description", decode.string)
  use banner_asset_id <- decode.optional_field(
    "banner_asset_id",
    None,
    decode.optional(decode.string),
  )

  decode.success(Pack(
    id:,
    stickers:,
    name:,
    sku_id:,
    cover_sticker_id:,
    description:,
    banner_asset_id:,
  ))
}

@internal
pub fn item_decoder() -> decode.Decoder(Item) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use format_type <- decode.field("format_type", format_type_decoder())
  decode.success(Item(id:, name:, format_type:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn content_type_to_string(content_type: ContentType) -> String {
  case content_type {
    Png -> "image/png"
    Apng -> "image/apng"
    Gif -> "image/gif"
    Lottie -> "video/lottie+json"
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: grom.Client,
  id sticker_id: String,
) -> Result(Sticker, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/stickers/" <> sticker_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_packs(client: grom.Client) -> Result(List(Pack), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/sticker-packs")
    |> rest.execute,
  )

  let response_decoder = {
    use packs <- decode.field("sticker_packs", decode.list(of: pack_decoder()))
    decode.success(packs)
  }

  response.body
  |> json.parse(using: response_decoder)
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_pack(
  client: grom.Client,
  id pack_id: String,
) -> Result(Pack, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/sticker-packs/" <> pack_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: pack_decoder())
  |> result.map_error(grom.CouldNotDecode)
}
