import flybycord/channel/guild/forum
import flybycord/channel/guild/forum/tag.{type Tag}
import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/flags
import flybycord/internal/rest
import flybycord/internal/time_duration
import flybycord/modification.{type Modification, Skip}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}

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
    last_thread_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    default_auto_archive_duration: Option(Duration),
    current_user_permissions: Option(List(Permission)),
    flags: List(Flag),
    available_tags: List(Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Option(forum.SortOrderType),
  )
}

pub type Modify {
  Modify(
    name: Option(String),
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
    flags: Option(List(Flag)),
    available_tags: Option(List(tag.Create)),
    default_reaction_emoji: Modification(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Modification(forum.SortOrderType),
  )
}

pub type Flag {
  RequiresTag
  HideMediaDownloadOptions
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 4), RequiresTag),
    #(int.bitwise_shift_left(1, 15), HideMediaDownloadOptions),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn channel_decoder() {
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
  use is_nsfw <- decode.field("is_nsfw", decode.bool)
  use last_thread_id <- decode.field(
    "last_thread_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use default_auto_archive_duration <- decode.optional_field(
    "default_auto_archive_duration",
    None,
    decode.optional(time_duration.from_minutes_decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use flags <- decode.field("flags", flags.decoder(bits_flags()))
  use available_tags <- decode.field(
    "available_tags",
    decode.list(tag.decoder()),
  )
  use default_reaction_emoji <- decode.field(
    "default_reaction_emoji",
    decode.optional(forum.default_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.optional_field(
    "default_thread_rate_limit_per_user",
    None,
    decode.optional(time_duration.from_minutes_decoder()),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    decode.optional(forum.sort_order_type_decoder()),
  )
  decode.success(Channel(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_thread_id:,
    rate_limit_per_user:,
    parent_id:,
    default_auto_archive_duration:,
    current_user_permissions:,
    flags:,
    available_tags:,
    default_reaction_emoji:,
    default_thread_rate_limit_per_user:,
    default_sort_order:,
  ))
}

// ENCODERS --------------------------------------------------------------------

pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
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
    |> modification.encode("permission_overwrites", fn(overwrites) {
      overwrites
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

  let flags = case modify.flags {
    Some(flags) -> [#("flags", flags.encode(flags, bits_flags()))]
    None -> []
  }

  let available_tags = case modify.available_tags {
    Some(tags) -> [#("available_tags", json.array(tags, tag.create_encode))]
    None -> []
  }

  let default_reaction_emoji =
    modify.default_reaction_emoji
    |> modification.encode(
      "default_reaction_emoji",
      forum.default_reaction_encode,
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

  let default_sort_order =
    modify.default_sort_order
    |> modification.encode("default_sort_order", forum.sort_order_type_encode)

  [
    name,
    position,
    topic,
    is_nsfw,
    rate_limit_per_user,
    permission_overwrites,
    parent_id,
    default_auto_archive_duration,
    flags,
    available_tags,
    default_reaction_emoji,
    default_thread_rate_limit_per_user,
    default_sort_order,
  ]
  |> list.flatten
  |> json.object
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
    topic: Skip,
    is_nsfw: None,
    rate_limit_per_user: Skip,
    permission_overwrites: Skip,
    parent_id: Skip,
    default_auto_archive_duration: Skip,
    flags: None,
    available_tags: None,
    default_reaction_emoji: Skip,
    default_thread_rate_limit_per_user: None,
    default_sort_order: Skip,
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

pub fn modify_topic(modify: Modify, topic topic: Modification(String)) -> Modify {
  Modify(..modify, topic:)
}

pub fn modify_is_nsfw(modify: Modify, new is_nsfw: Bool) -> Modify {
  Modify(..modify, is_nsfw: Some(is_nsfw))
}

pub fn modify_rate_limit_per_user(
  modify: Modify,
  limit limit: Modification(Duration),
) -> Modify {
  Modify(..modify, rate_limit_per_user: limit)
}

pub fn modify_permission_overwrites(
  modify: Modify,
  overwrites overwrites: Modification(List(permission_overwrite.Create)),
) -> Modify {
  Modify(..modify, permission_overwrites: overwrites)
}

pub fn modify_parent_id(modify: Modify, id id: Modification(String)) -> Modify {
  Modify(..modify, parent_id: id)
}

pub fn modify_default_auto_archive_duration(
  modify: Modify,
  duration duration: Modification(Duration),
) -> Modify {
  Modify(..modify, default_auto_archive_duration: duration)
}

pub fn modify_flags(modify: Modify, new flags: List(Flag)) -> Modify {
  Modify(..modify, flags: Some(flags))
}

pub fn modify_available_tags(
  modify: Modify,
  new tags: List(tag.Create),
) -> Modify {
  Modify(..modify, available_tags: Some(tags))
}

pub fn modify_default_reaction_emoji(
  modify: Modify,
  reaction reaction: Modification(forum.DefaultReaction),
) -> Modify {
  Modify(..modify, default_reaction_emoji: reaction)
}

pub fn modify_default_thread_rate_limit_per_user(
  modify: Modify,
  new limit: Duration,
) -> Modify {
  Modify(..modify, default_thread_rate_limit_per_user: Some(limit))
}

pub fn modify_default_sort_order(
  modify: Modify,
  sort_order order: Modification(forum.SortOrderType),
) -> Modify {
  Modify(..modify, default_sort_order: order)
}
