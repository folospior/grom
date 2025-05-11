import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/internal/time_duration
import flybycord/internal/time_rfc3339
import flybycord/modification.{type Modification}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Channel {
  Channel(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    topic: Option(String),
    is_nsfw: Bool,
    last_message_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    last_pin_timestamp: Option(Timestamp),
    current_user_permissions: Option(List(Permission)),
    default_auto_archive_duration: Duration,
  )
}

pub type Modify {
  Modify(
    name: Option(String),
    to_announcement: Option(Bool),
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn channel_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use topic <- decode.field("topic", decode.optional(decode.string))
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use last_pin_timestamp <- decode.field(
    "last_pin_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use default_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    time_duration.from_int_seconds_decoder(),
  )
  decode.success(Channel(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_message_id:,
    rate_limit_per_user:,
    parent_id:,
    last_pin_timestamp:,
    current_user_permissions:,
    default_auto_archive_duration:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let type_ = case modify.to_announcement {
    Some(True) -> [#("type", json.int(5))]
    Some(False) -> []
    None -> []
  }

  let position =
    modify.position
    |> modification.encode("position", json.int)

  let topic =
    modify.topic
    |> modification.encode("topic", json.string)

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

  let permission_overwrites =
    modify.permission_overwrites
    |> modification.encode("permission_overwrites", fn(permissions) {
      permissions
      |> json.array(permission_overwrite.create_encode)
    })

  let parent_id =
    modify.parent_id
    |> modification.encode("parent_id", json.string)

  let default_auto_archive_duration =
    modify.default_auto_archive_duration
    |> modification.encode(
      "default_auto_archive_duration",
      time_duration.to_int_seconds_encode,
    )

  let default_thread_rate_limit_per_user = case
    modify.default_thread_rate_limit_per_user
  {
    Some(limit) -> [
      #(
        "default_thread_rate_limit_per_user",
        time_duration.to_int_seconds_encode(limit),
      ),
    ]
    None -> []
  }

  [
    name,
    type_,
    position,
    topic,
    is_nsfw,
    rate_limit_per_user,
    permission_overwrites,
    parent_id,
    default_auto_archive_duration,
    default_thread_rate_limit_per_user,
  ]
  |> list.flatten
  |> json.object
}
