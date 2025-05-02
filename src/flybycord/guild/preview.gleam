import flybycord/emoji.{type Emoji}
import flybycord/guild
import flybycord/sticker.{type Sticker}
import gleam/dynamic/decode
import gleam/option.{type Option}

// TYPES -----------------------------------------------------------------------

pub type Preview {
  Preview(
    id: String,
    name: String,
    icon_hash: Option(String),
    splash_hash: Option(String),
    discovery_splash_hash: Option(String),
    emojis: List(Emoji),
    features: List(guild.Feature),
    approximate_member_count: Int,
    approximate_presence_count: Int,
    description: Option(String),
    stickers: List(Sticker),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Preview) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(decode.string))
  use splash_hash <- decode.field("splash", decode.optional(decode.string))
  use discovery_splash_hash <- decode.field(
    "discovery_splash",
    decode.optional(decode.string),
  )
  use emojis <- decode.field("emojis", decode.list(emoji.decoder()))
  use features <- decode.field("features", decode.list(guild.feature_decoder()))
  use approximate_member_count <- decode.field(
    "approximate_member_count",
    decode.int,
  )
  use approximate_presence_count <- decode.field(
    "approximate_presence_count",
    decode.int,
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use stickers <- decode.field("stickers", decode.list(sticker.decoder()))
  decode.success(Preview(
    id:,
    name:,
    icon_hash:,
    splash_hash:,
    discovery_splash_hash:,
    emojis:,
    features:,
    approximate_member_count:,
    approximate_presence_count:,
    description:,
    stickers:,
  ))
}
