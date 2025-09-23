import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import grom/guild_member.{type GuildMember}
import grom/internal/time_rfc3339

pub type State {
  State(
    guild_id: Option(String),
    channel_id: Option(String),
    user_id: String,
    member: Option(GuildMember),
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

@internal
pub fn state_decoder() -> decode.Decoder(State) {
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use channel_id <- decode.field("channel_id", decode.optional(decode.string))
  use user_id <- decode.field("user_id", decode.string)
  use member <- decode.optional_field(
    "member",
    None,
    decode.optional(guild_member.decoder()),
  )
  use session_id <- decode.field("session_id", decode.string)
  use is_deaf <- decode.field("deaf", decode.bool)
  use is_mute <- decode.field("mute", decode.bool)
  use is_self_deaf <- decode.field("self_deaf", decode.bool)
  use is_self_mute <- decode.field("self_mute", decode.bool)
  use is_streaming <- decode.field("self_stream", decode.bool)
  use is_sharing_camera <- decode.field("self_video", decode.bool)
  use is_suppressed <- decode.field("suppress", decode.bool)
  use request_to_speak_timestamp <- decode.field(
    "request_to_speak_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  decode.success(State(
    guild_id:,
    channel_id:,
    user_id:,
    member:,
    session_id:,
    is_deaf:,
    is_mute:,
    is_self_deaf:,
    is_self_mute:,
    is_streaming:,
    is_sharing_camera:,
    is_suppressed:,
    request_to_speak_timestamp:,
  ))
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
