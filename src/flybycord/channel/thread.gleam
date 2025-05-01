import flybycord/guild/member.{type Member as GuildMember}
import flybycord/internal/time_rfc3339
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

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
    member: GuildMember,
  )
}

pub type Flag {
  Pinned
  RequireTag
  HideMediaDownloadOptions
}

// FLAGS -----------------------------------------------------------------------

fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 1), Pinned),
    #(int.bitwise_shift_left(1, 4), RequireTag),
    #(int.bitwise_shift_left(1, 15), HideMediaDownloadOptions),
  ]
}

// DECODERS --------------------------------------------------------------------

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
  use member <- decode.field("member", member.decoder())
  decode.success(Member(thread_id:, user_id:, join_timestamp:, member:))
}

@internal
pub fn flags_decoder() -> decode.Decoder(List(Flag)) {
  use flags <- decode.then(decode.int)
  bits_flags()
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}
