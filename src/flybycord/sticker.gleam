import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES ----------------------------------------------------------------------

pub type Sticker {
  Sticker(
    id: String,
    pack_id: Option(String),
    name: String,
    description: Option(String),
    tags: String,
    type_: Type,
    format_type: FormatType,
    is_available: Option(Bool),
    guild_id: Option(String),
    user: Option(User),
    sort_value: Option(Int),
  )
}

pub type Type {
  Standard
  Guild
}

pub type FormatType {
  Png
  Apng
  Lottie
  Gif
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
pub fn format_type_decoder() -> decode.Decoder(FormatType) {
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
