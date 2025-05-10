import flybycord/guild/member.{type Member as GuildMember}
import flybycord/internal/flags
import flybycord/internal/time_duration
import flybycord/internal/time_rfc3339
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Thread {
  Thread(
    id: String,
    guild_id: Option(String),
    name: String,
    last_message_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: String,
    last_pin_timestamp: Option(Timestamp),
    message_count: Int,
    member_count: Int,
    metadata: Metadata,
    current_member: Option(Member),
    current_user_permissions: Option(List(Permission)),
    flags: List(Flag),
    total_message_sent: Int,
    applied_tags_ids: Option(List(String)),
  )
}

pub type Metadata {
  Metadata(
    is_archived: Bool,
    auto_archive_duration: Int,
    archive_timestamp: Timestamp,
    is_locked: Bool,
    is_invitable: Option(Bool),
    create_timestamp: Option(Timestamp),
  )
}

pub type Member {
  Member(
    thread_id: Option(String),
    user_id: Option(String),
    join_timestamp: Timestamp,
    guild_member: GuildMember,
  )
}

pub type Flag {
  Pinned
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 1), Pinned)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Thread) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use name <- decode.field("name", decode.string)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.string)
  use last_pin_timestamp <- decode.field(
    "last_pin_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  use message_count <- decode.field("message_count", decode.int)
  use member_count <- decode.field("member_count", decode.int)
  use metadata <- decode.field("metadata", metadata_decoder())
  use current_member <- decode.optional_field(
    "current_member",
    None,
    decode.optional(member_decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use flags <- decode.field("flags", flags.decoder(bits_flags()))
  use total_message_sent <- decode.field("total_message_sent", decode.int)
  use applied_tags_ids <- decode.optional_field(
    "applied_tags_ids",
    None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(Thread(
    id:,
    guild_id:,
    name:,
    last_message_id:,
    rate_limit_per_user:,
    parent_id:,
    last_pin_timestamp:,
    message_count:,
    member_count:,
    metadata:,
    current_member:,
    current_user_permissions:,
    flags:,
    total_message_sent:,
    applied_tags_ids:,
  ))
}

@internal
pub fn metadata_decoder() -> decode.Decoder(Metadata) {
  use is_archived <- decode.field("archived", decode.bool)
  use auto_archive_duration <- decode.field("auto_archive_duration", decode.int)
  use archive_timestamp <- decode.field(
    "archive_timestamp",
    time_rfc3339.decoder(),
  )
  use is_locked <- decode.field("locked", decode.bool)
  use is_invitable <- decode.optional_field(
    "invitable",
    None,
    decode.optional(decode.bool),
  )
  use create_timestamp <- decode.optional_field(
    "create_timestamp",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  decode.success(Metadata(
    is_archived:,
    auto_archive_duration:,
    archive_timestamp:,
    is_locked:,
    is_invitable:,
    create_timestamp:,
  ))
}

@internal
pub fn member_decoder() -> decode.Decoder(Member) {
  use thread_id <- decode.optional_field(
    "id",
    None,
    decode.optional(decode.string),
  )
  use user_id <- decode.optional_field(
    "user_id",
    None,
    decode.optional(decode.string),
  )
  use join_timestamp <- decode.field("join_timestamp", time_rfc3339.decoder())
  use guild_member <- decode.field("member", member.decoder())
  decode.success(Member(thread_id:, user_id:, join_timestamp:, guild_member:))
}
