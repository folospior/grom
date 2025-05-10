import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Channel {
  Channel(
    id: String,
    guild_id: String,
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    is_nsfw: Bool,
    bitrate: Int,
    user_limit: Int,
    parent_id: Option(String),
    rtc_region: Option(String),
    video_quality_mode: VideoQualityMode,
    current_user_permissions: Option(List(Permission)),
  )
}

pub type VideoQualityMode {
  Auto
  Full
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn video_quality_mode_decoder() -> decode.Decoder(VideoQualityMode) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Auto)
    2 -> decode.success(Full)
    _ -> decode.failure(Auto, "VoiceQualityMode")
  }
}

@internal
pub fn channel_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use bitrate <- decode.field("bitrate", decode.int)
  use user_limit <- decode.field("user_limit", decode.int)
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use rtc_region <- decode.field("rtc_region", decode.optional(decode.string))
  use video_quality_mode <- decode.optional_field(
    "video_quality_mode",
    Auto,
    video_quality_mode_decoder(),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Channel(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    is_nsfw:,
    bitrate:,
    user_limit:,
    parent_id:,
    rtc_region:,
    video_quality_mode:,
    current_user_permissions:,
  ))
}
