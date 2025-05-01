import gleam/dynamic/decode
import gleam/option.{type Option}

pub type WelcomeScreen {
  WelcomeScreen(description: Option(String), welcome_channels: List(Channel))
}

pub type Channel {
  Channel(
    channel_id: String,
    description: String,
    emoji_id: Option(String),
    emoji_name: Option(String),
  )
}

@internal
pub fn decoder() -> decode.Decoder(WelcomeScreen) {
  use description <- decode.field("description", decode.optional(decode.string))
  use welcome_channels <- decode.field(
    "welcome_channels",
    decode.list(channel_decoder()),
  )
  decode.success(WelcomeScreen(description:, welcome_channels:))
}

@internal
pub fn channel_decoder() -> decode.Decoder(Channel) {
  use channel_id <- decode.field("channel_id", decode.string)
  use description <- decode.field("description", decode.string)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Channel(channel_id:, description:, emoji_id:, emoji_name:))
}
