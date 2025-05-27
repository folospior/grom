import flybycord/client.{type Client}
import flybycord/error
import flybycord/guild/member.{type Member as GuildMember}
import flybycord/internal/flags
import flybycord/internal/rest
import flybycord/internal/time_duration
import flybycord/internal/time_rfc3339
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
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Thread {
  Thread(
    id: String,
    type_: Type,
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

pub opaque type Modify {
  Modify(
    name: Option(String),
    is_archived: Option(Bool),
    auto_archive_duration: Option(Duration),
    is_locked: Option(Bool),
    is_invitable: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    flags: Modification(List(Flag)),
    applied_tags_ids: Modification(List(String)),
  )
}

pub opaque type StartFromMessage {
  StartFromMessage(
    name: String,
    auto_archive_duration: Option(Duration),
    rate_limit_per_user: Option(Duration),
  )
}

pub opaque type StartWithoutMessage {
  StartWithoutMessage(
    name: String,
    auto_archive_duration: Option(Duration),
    type_: Option(Type),
    is_invitable: Option(Bool),
    rate_limit_per_user: Option(Duration),
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

pub type Type {
  Announcement
  Public
  Private
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
  use type_ <- decode.field("type", type_decoder())
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
    type_:,
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

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    10 -> decode.success(Announcement)
    11 -> decode.success(Public)
    12 -> decode.success(Private)
    _ -> decode.failure(Announcement, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    Announcement -> 10
    Public -> 11
    Private -> 12
  }
  |> json.int
}

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let is_archived = case modify.is_archived {
    Some(archived) -> [#("archived", json.bool(archived))]
    None -> []
  }

  let auto_archive_duration = case modify.auto_archive_duration {
    Some(duration) -> [
      #("auto_archive_duration", time_duration.to_int_seconds_encode(duration)),
    ]
    None -> []
  }

  let is_locked = case modify.is_locked {
    Some(locked) -> [#("locked", json.bool(locked))]
    None -> []
  }

  let is_invitable = case modify.is_invitable {
    Some(invitable) -> [#("invitable", json.bool(invitable))]
    None -> []
  }

  let rate_limit_per_user =
    modify.rate_limit_per_user
    |> modification.encode(
      "rate_limit_per_user",
      time_duration.to_int_seconds_encode,
    )

  let flags =
    modify.flags
    |> modification.encode("flags", fn(flags) {
      flags.encode(flags, bits_flags())
    })

  let applied_tags_ids =
    modify.applied_tags_ids
    |> modification.encode("applied_tags", fn(tags) {
      json.array(tags, json.string)
    })

  [
    name,
    is_archived,
    auto_archive_duration,
    is_locked,
    is_invitable,
    rate_limit_per_user,
    flags,
    applied_tags_ids,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn start_from_message_encode(start_from_message: StartFromMessage) -> Json {
  let name = [#("name", json.string(start_from_message.name))]

  let auto_archive_duration = case start_from_message.auto_archive_duration {
    Some(duration) -> [
      #("auto_archive_duration", time_duration.to_int_seconds_encode(duration)),
    ]
    None -> []
  }

  let rate_limit_per_user = case start_from_message.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  [name, auto_archive_duration, rate_limit_per_user]
  |> list.flatten
  |> json.object
}

@internal
pub fn start_without_message_encode(
  start_without_message: StartWithoutMessage,
) -> Json {
  let name = [#("name", json.string(start_without_message.name))]

  let auto_archive_duration = case start_without_message.auto_archive_duration {
    Some(duration) -> [
      #("auto_archive_duration", time_duration.to_int_seconds_encode(duration)),
    ]
    None -> []
  }

  let type_ = case start_without_message.type_ {
    Some(type_) -> [#("type", type_encode(type_))]
    None -> []
  }

  let is_invitable = case start_without_message.is_invitable {
    Some(invitable) -> [#("invitable", json.bool(invitable))]
    None -> []
  }

  let rate_limit_per_user = case start_without_message.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  [name, auto_archive_duration, type_, is_invitable, rate_limit_per_user]
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
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_modify() -> Modify {
  Modify(
    name: None,
    is_archived: None,
    auto_archive_duration: None,
    is_locked: None,
    is_invitable: None,
    rate_limit_per_user: Skip,
    flags: Skip,
    applied_tags_ids: Skip,
  )
}

pub fn modify_name(modify: Modify, new name: String) -> Modify {
  Modify(..modify, name: Some(name))
}

pub fn modify_is_archived(modify: Modify, new is_archived: Bool) -> Modify {
  Modify(..modify, is_archived: Some(is_archived))
}

pub fn modify_auto_archive_duration(
  modify: Modify,
  new duration: Duration,
) -> Modify {
  Modify(..modify, auto_archive_duration: Some(duration))
}

pub fn modify_is_locked(modify: Modify, new is_locked: Bool) -> Modify {
  Modify(..modify, is_locked: Some(is_locked))
}

pub fn modify_is_invitable(modify: Modify, new is_invitable: Bool) -> Modify {
  Modify(..modify, is_invitable: Some(is_invitable))
}

pub fn modify_rate_limit_per_user(
  modify: Modify,
  limit limit: Modification(Duration),
) -> Modify {
  Modify(..modify, rate_limit_per_user: limit)
}

pub fn modify_flags(
  modify: Modify,
  flags flags: Modification(List(Flag)),
) -> Modify {
  Modify(..modify, flags:)
}

pub fn modify_applied_tags_ids(
  modify: Modify,
  ids ids: Modification(List(String)),
) -> Modify {
  Modify(..modify, applied_tags_ids: ids)
}

pub fn start_from_message(
  client: Client,
  in channel_id: String,
  from message_id: String,
  with start_from_message: StartFromMessage,
  reason reason: Option(String),
) -> Result(Thread, error.FlybycordError) {
  let json = start_from_message |> start_from_message_encode

  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/channels/" <> channel_id <> "/messages/" <> message_id <> "/threads",
    )
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_start_from_message(name: String) -> StartFromMessage {
  StartFromMessage(
    name:,
    auto_archive_duration: None,
    rate_limit_per_user: None,
  )
}

pub fn start_from_message_with_auto_archive_duration(
  start_from_message: StartFromMessage,
  duration: Duration,
) -> StartFromMessage {
  StartFromMessage(..start_from_message, auto_archive_duration: Some(duration))
}

pub fn start_from_message_with_rate_limit_per_user(
  start_from_message: StartFromMessage,
  limit: Duration,
) -> StartFromMessage {
  StartFromMessage(..start_from_message, rate_limit_per_user: Some(limit))
}

pub fn start_without_message(
  client: Client,
  in channel_id: String,
  with start_without_message: StartWithoutMessage,
  reason reason: Option(String),
) -> Result(Thread, error.FlybycordError) {
  let json = start_without_message |> start_without_message_encode

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/threads")
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_start_without_message(name: String) -> StartWithoutMessage {
  StartWithoutMessage(
    name:,
    auto_archive_duration: None,
    type_: None,
    is_invitable: None,
    rate_limit_per_user: None,
  )
}

pub fn start_without_message_with_auto_archive_duration(
  start_without_message: StartWithoutMessage,
  duration: Duration,
) -> StartWithoutMessage {
  StartWithoutMessage(
    ..start_without_message,
    auto_archive_duration: Some(duration),
  )
}

pub fn start_without_message_with_type(
  start_without_message: StartWithoutMessage,
  type_: Type,
) -> StartWithoutMessage {
  StartWithoutMessage(..start_without_message, type_: Some(type_))
}

pub fn start_without_message_with_is_invitable(
  start_without_message: StartWithoutMessage,
  is_invitable: Bool,
) -> StartWithoutMessage {
  StartWithoutMessage(..start_without_message, is_invitable: Some(is_invitable))
}

pub fn start_without_message_with_rate_limit_per_user(
  start_without_message: StartWithoutMessage,
  limit: Duration,
) -> StartWithoutMessage {
  StartWithoutMessage(..start_without_message, rate_limit_per_user: Some(limit))
}
