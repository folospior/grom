import flybycord/channel/guild/forum
import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/internal/flags
import flybycord/internal/time_duration
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
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
    available_tags: List(forum.Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Option(forum.SortOrderType),
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
    decode.list(forum.tag_decoder()),
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
