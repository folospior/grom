import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Sound {
  Sound(
    name: String,
    id: String,
    /// From `0.0` to `1.0`.
    volume: Float,
    emoji_id: Option(String),
    emoji_name: Option(String),
    guild_id: Option(String),
    is_available: Bool,
    creator: Option(User),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn sound_decoder() -> decode.Decoder(Sound) {
  use name <- decode.field("name", decode.string)
  use id <- decode.field("sound_id", decode.string)
  use volume <- decode.field("volume", decode.float)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use is_available <- decode.field("available", decode.bool)
  use creator <- decode.field("user", decode.optional(user.decoder()))
  decode.success(Sound(
    name:,
    id:,
    volume:,
    emoji_id:,
    emoji_name:,
    guild_id:,
    is_available:,
    creator:,
  ))
}
