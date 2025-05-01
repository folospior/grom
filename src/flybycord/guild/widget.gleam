import flybycord/channel.{type Channel}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option}

pub type Settings {
  WidgetSettings(is_enabled: Bool, channel_id: Option(String))
}

pub type Widget {
  Widget(
    id: String,
    name: String,
    instant_invite: Option(String),
    channels: List(Channel),
    members: List(User),
    presence_count: Int,
  )
}

@internal
pub fn settings_decoder() -> decode.Decoder(Settings) {
  use is_enabled <- decode.field("enabled", decode.bool)
  use channel_id <- decode.field("channel_id", decode.optional(decode.string))
  decode.success(WidgetSettings(is_enabled:, channel_id:))
}

@internal
pub fn decoder() -> decode.Decoder(Widget) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use instant_invite <- decode.field(
    "instant_invite",
    decode.optional(decode.string),
  )
  use channels <- decode.field("channels", decode.list(channel.decoder()))
  use members <- decode.field("members", decode.list(user.decoder()))
  use presence_count <- decode.field("presence_count", decode.int)
  decode.success(Widget(
    id:,
    name:,
    instant_invite:,
    channels:,
    members:,
    presence_count:,
  ))
}
