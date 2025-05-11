import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/rest
import flybycord/internal/time_duration
import flybycord/modification.{type Modification, Skip}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}

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
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    rtc_region: Option(String),
    video_quality_mode: VideoQualityMode,
    current_user_permissions: Option(List(Permission)),
  )
}

pub opaque type Modify {
  Modify(
    name: Option(String),
    position: Modification(Int),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    bitrate: Modification(Int),
    user_limit: Modification(Int),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    rtc_region: Modification(String),
    video_quality_mode: Modification(VideoQualityMode),
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
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_int_seconds_decoder(),
  )
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
    rate_limit_per_user:,
    parent_id:,
    rtc_region:,
    video_quality_mode:,
    current_user_permissions:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let position =
    modify.position
    |> modification.encode("position", json.int)

  let is_nsfw = case modify.is_nsfw {
    Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
    None -> []
  }

  let rate_limit_per_user =
    modify.rate_limit_per_user
    |> modification.encode(
      "rate_limit_per_user",
      time_duration.to_int_seconds_encode,
    )

  let bitrate =
    modify.bitrate
    |> modification.encode("bitrate", json.int)

  let user_limit =
    modify.user_limit
    |> modification.encode("user_limit", json.int)

  let permission_overwrites =
    modify.permission_overwrites
    |> modification.encode("permission_overwrites", fn(overwrites) {
      overwrites
      |> json.array(permission_overwrite.create_encode)
    })

  let parent_id =
    modify.parent_id
    |> modification.encode("parent_id", json.string)

  let rtc_region =
    modify.rtc_region
    |> modification.encode("rtc_region", json.string)

  let video_quality_mode =
    modify.video_quality_mode
    |> modification.encode("video_quality_mode", video_quality_mode_encode)

  [
    name,
    position,
    is_nsfw,
    rate_limit_per_user,
    bitrate,
    user_limit,
    permission_overwrites,
    parent_id,
    rtc_region,
    video_quality_mode,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn video_quality_mode_encode(video_quality_mode: VideoQualityMode) -> Json {
  case video_quality_mode {
    Auto -> 1
    Full -> 2
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn modify(
  client: Client,
  id channel_id: String,
  with modify: Modify,
  reason reason: Option(String),
) {
  let json = modify |> modify_encode

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/channels/" <> channel_id)
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: channel_decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_modify() -> Modify {
  Modify(
    name: None,
    position: Skip,
    is_nsfw: None,
    rate_limit_per_user: Skip,
    bitrate: Skip,
    user_limit: Skip,
    permission_overwrites: Skip,
    parent_id: Skip,
    rtc_region: Skip,
    video_quality_mode: Skip,
  )
}

pub fn modify_name(modify: Modify, new name: String) -> Modify {
  Modify(..modify, name: Some(name))
}

pub fn modify_position(
  modify: Modify,
  position position: Modification(Int),
) -> Modify {
  Modify(..modify, position:)
}

pub fn modify_is_nsfw(modify: Modify, new is_nsfw: Bool) -> Modify {
  Modify(..modify, is_nsfw: Some(is_nsfw))
}

pub fn modify_bitrate(
  modify: Modify,
  bitrate bitrate: Modification(Int),
) -> Modify {
  Modify(..modify, bitrate:)
}

pub fn modify_user_limit(
  modify: Modify,
  limit user_limit: Modification(Int),
) -> Modify {
  Modify(..modify, user_limit:)
}

pub fn modify_permission_overwrites(
  modify: Modify,
  overwrites overwrites: Modification(List(permission_overwrite.Create)),
) -> Modify {
  Modify(..modify, permission_overwrites: overwrites)
}

pub fn modify_parent_id(
  modify: Modify,
  id parent_id: Modification(String),
) -> Modify {
  Modify(..modify, parent_id:)
}

pub fn modify_rtc_region(
  modify: Modify,
  region rtc_region: Modification(String),
) -> Modify {
  Modify(..modify, rtc_region:)
}

pub fn modify_video_quality_mode(
  modify: Modify,
  mode video_quality_mode: Modification(VideoQualityMode),
) -> Modify {
  Modify(..modify, video_quality_mode:)
}
