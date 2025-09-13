import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import grom/guild_member

pub type State {
  State(
    guild_id: Option(String),
    channel_id: Option(String),
    user_id: String,
    member: Option(guild_member.GuildMember),
    session_id: String,
    is_deaf: Bool,
    is_mute: Bool,
    is_self_deaf: Bool,
    is_self_mute: Bool,
    is_streaming: Bool,
    is_sharing_camera: Bool,
    is_suppressed: Bool,
    request_to_speak_timestamp: Option(Timestamp),
  )
}

pub type Region {
  Region(
    id: String,
    name: String,
    is_optimal: Bool,
    is_deprecated: Bool,
    is_custom: Bool,
  )
}

@internal
pub fn region_decoder() -> decode.Decoder(Region) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_optimal <- decode.field("optimal", decode.bool)
  use is_deprecated <- decode.field("deprecated", decode.bool)
  use is_custom <- decode.field("custom", decode.bool)
  decode.success(Region(id:, name:, is_optimal:, is_deprecated:, is_custom:))
}
