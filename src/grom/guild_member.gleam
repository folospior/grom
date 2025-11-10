import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_rfc3339
import grom/modification.{type Modification, Skip}
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type GuildMember {
  Member(
    user: Option(User),
    nick: Option(String),
    avatar_hash: Option(String),
    banner_hash: Option(String),
    roles: List(String),
    joined_at: Timestamp,
    premium_since: Option(Timestamp),
    is_deaf: Option(Bool),
    is_mute: Option(Bool),
    flags: List(Flag),
    is_pending: Option(Bool),
    permissions: Option(String),
    communication_disabled_until: Option(Timestamp),
    avatar_decoration_data: Option(user.AvatarDecorationData),
  )
}

pub type Flag {
  DidRejoin
  CompletedOnboarding
  BypassesVerification
  StartedOnboarding
  IsGuest
  StartedHomeActions
  CompletedHomeActions
  QuarantinedBecauseOfUsername
  AcknowledgedDmSettingsUpsell
}

pub type Modify {
  Modify(
    nick: Modification(String),
    role_ids: Modification(List(String)),
    is_mute: Option(Bool),
    is_deaf: Option(Bool),
    voice_channel_id: Modification(String),
    communication_disabled_until: Modification(Timestamp),
    flags: Modification(List(Flag)),
  )
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_member_flags() {
  [
    #(int.bitwise_shift_left(1, 0), DidRejoin),
    #(int.bitwise_shift_left(1, 1), CompletedOnboarding),
    #(int.bitwise_shift_left(1, 2), BypassesVerification),
    #(int.bitwise_shift_left(1, 3), StartedOnboarding),
    #(int.bitwise_shift_left(1, 4), IsGuest),
    #(int.bitwise_shift_left(1, 5), StartedHomeActions),
    #(int.bitwise_shift_left(1, 6), CompletedHomeActions),
    #(int.bitwise_shift_left(1, 7), QuarantinedBecauseOfUsername),
    #(int.bitwise_shift_left(1, 9), AcknowledgedDmSettingsUpsell),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(GuildMember) {
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use nick <- decode.optional_field(
    "nick",
    None,
    decode.optional(decode.string),
  )
  use avatar_hash <- decode.optional_field(
    "avatar",
    None,
    decode.optional(decode.string),
  )
  use banner_hash <- decode.optional_field(
    "banner",
    None,
    decode.optional(decode.string),
  )
  use roles <- decode.field("roles", decode.list(decode.string))
  use joined_at <- decode.field("joined_at", time_rfc3339.decoder())
  use premium_since <- decode.optional_field(
    "premium_since",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use is_deaf <- decode.optional_field(
    "deaf",
    None,
    decode.optional(decode.bool),
  )
  use is_mute <- decode.optional_field(
    "mute",
    None,
    decode.optional(decode.bool),
  )
  use flags <- decode.field("flags", flags.decoder(bits_member_flags()))
  use is_pending <- decode.optional_field(
    "pending",
    None,
    decode.optional(decode.bool),
  )
  use permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(decode.string),
  )
  use communication_disabled_until <- decode.optional_field(
    "communication_disabled_until",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use avatar_decoration_data <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(user.avatar_decoration_data_decoder()),
  )
  decode.success(Member(
    user:,
    nick:,
    avatar_hash:,
    banner_hash:,
    roles:,
    joined_at:,
    premium_since:,
    is_deaf:,
    is_mute:,
    flags:,
    is_pending:,
    permissions:,
    communication_disabled_until:,
    avatar_decoration_data:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  let nick =
    modify.nick
    |> modification.to_json("nick", json.string)

  let role_ids =
    modify.role_ids
    |> modification.to_json("roles", json.array(_, json.string))

  let is_mute = case modify.is_mute {
    Some(mute) -> [#("mute", json.bool(mute))]
    None -> []
  }

  let is_deaf = case modify.is_deaf {
    Some(deaf) -> [#("deaf", json.bool(deaf))]
    None -> []
  }

  let voice_channel_id =
    modify.voice_channel_id
    |> modification.to_json("channel_id", json.string)

  let communication_disabled_until =
    modify.communication_disabled_until
    |> modification.to_json(
      "communication_disabled_until",
      time_rfc3339.to_json,
    )

  let flags =
    modify.flags
    |> modification.to_json("flags", flags.to_json(_, bits_member_flags()))

  [
    nick,
    role_ids,
    is_mute,
    is_deaf,
    voice_channel_id,
    communication_disabled_until,
    flags,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: grom.Client,
  for guild_id: String,
  id user_id: String,
) -> Result(GuildMember, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/members/" <> user_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify(
  client: grom.Client,
  in guild_id: String,
  id user_id: String,
  with modify: Modify,
  because reason: Option(String),
) -> Result(GuildMember, grom.Error) {
  let json =
    modify
    |> modify_to_json
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/guilds/" <> guild_id <> "/members/" <> user_id,
    )
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn set_current_nick(
  client: grom.Client,
  in guild_id: String,
  to nick: Modification(String),
  because reason: Option(String),
) -> Result(GuildMember, grom.Error) {
  let json =
    nick
    |> modification.to_json("nick", json.string)
    |> json.object
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/guilds/" <> guild_id <> "/members/@me")
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn add_role(
  client: grom.Client,
  in guild_id: String,
  to user_id: String,
  id role_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/guilds/" <> guild_id <> "/members/" <> user_id <> "/roles/" <> role_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn remove_role(
  client: grom.Client,
  in guild_id: String,
  from user_id: String,
  id role_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/members/" <> user_id <> "/roles/" <> role_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn remove(
  client: grom.Client,
  from guild_id: String,
  id user_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/members/" <> user_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn kick(
  client: grom.Client,
  from guild_id: String,
  id user_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  remove(client, from: guild_id, id: user_id, because: reason)
}

pub fn new_modify() -> Modify {
  Modify(Skip, Skip, None, None, Skip, Skip, Skip)
}
