import flybycord/channel/guild/forum/tag.{type Tag}
import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/internal/flags
import flybycord/internal/time_duration
import flybycord/modification.{type Modification}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
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
    default_reaction_emoji: Option(DefaultReaction),
    default_thread_rate_limit_per_user: Duration,
    default_sort_order: Option(SortOrderType),
    default_layout: LayoutType,
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
    default_reaction_emoji: Modification(DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Modification(SortOrderType),
    default_layout: Option(LayoutType),
  )
}

pub type Flag {
  RequiresTag
}

pub type DefaultReaction {
  DefaultReaction(emoji_id: Option(String), emoji_name: Option(String))
}

pub type SortOrderType {
  LatestActivity
  CreationDate
}

pub type LayoutType {
  NotSet
  ListView
  GalleryView
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 4), RequiresTag)]
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
    decode.optional(default_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.field(
    "default_thread_rate_limit_per_user",
    time_duration.from_int_seconds_decoder(),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    decode.optional(sort_order_type_decoder()),
  )
  use default_layout <- decode.field("default_layout", layout_type_decoder())
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
    default_layout:,
  ))
}

@internal
pub fn default_reaction_decoder() -> decode.Decoder(DefaultReaction) {
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(DefaultReaction(emoji_id:, emoji_name:))
}

@internal
pub fn sort_order_type_decoder() -> decode.Decoder(SortOrderType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(LatestActivity)
    1 -> decode.success(CreationDate)
    _ -> decode.failure(LatestActivity, "SortOrderType")
  }
}

@internal
pub fn layout_type_decoder() -> decode.Decoder(LayoutType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NotSet)
    1 -> decode.success(ListView)
    2 -> decode.success(GalleryView)
    _ -> decode.failure(NotSet, "LayoutType")
  }
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
    |> modification.encode("default_reaction_emoji", default_reaction_encode)

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
    |> modification.encode("default_sort_order", sort_order_type_encode)

  let default_layout = case modify.default_layout {
    Some(layout) -> [#("default_forum_layout", layout_type_encode(layout))]
    None -> []
  }

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
    default_layout,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn default_reaction_encode(default_reaction: DefaultReaction) -> Json {
  let DefaultReaction(emoji_id:, emoji_name:) = default_reaction
  json.object([
    #("emoji_id", case emoji_id {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
    #("emoji_name", case emoji_name {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
  ])
}

@internal
pub fn sort_order_type_encode(sort_order_type: SortOrderType) -> Json {
  case sort_order_type {
    LatestActivity -> 0
    CreationDate -> 1
  }
  |> json.int
}

@internal
pub fn layout_type_encode(layout_type: LayoutType) -> Json {
  case layout_type {
    NotSet -> 0
    ListView -> 1
    GalleryView -> 2
  }
  |> json.int
}
