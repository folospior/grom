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
    available_tags: List(Tag),
    default_reaction_emoji: Option(DefaultReaction),
    default_thread_rate_limit_per_user: Duration,
    default_sort_order: Option(SortOrderType),
    default_layout: LayoutType,
  )
}

pub type Tag {
  Tag(
    id: String,
    name: String,
    is_moderated: Bool,
    emoji_id: Option(String),
    emoji_name: Option(String),
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
    decode.list(tag_decoder()),
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
pub fn tag_decoder() -> decode.Decoder(Tag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Tag(id:, name:, is_moderated:, emoji_id:, emoji_name:))
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
