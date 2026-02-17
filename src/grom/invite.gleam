import gleam/bit_array
import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/application.{type Application}
import grom/channel.{type Channel}
import grom/guild.{type Guild}
import grom/guild/role
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/user.{type User, User}
import multipart_form
import multipart_form/field
import splitter.{type Splitter}

// TYPES -----------------------------------------------------------------------

pub type Invite {
  InviteWithoutMetadata(WithoutMetadata)
  InviteWithMetadata(WithMetadata)
}

pub type WithoutMetadata {
  WithoutMetadata(
    type_: Type,
    code: String,
    guild: Option(Guild),
    channel: Option(Channel),
    inviter: Option(User),
    target_type: Option(TargetType),
    approximate_presence_count: Option(Int),
    approximate_member_count: Option(Int),
    expires_at: Option(Timestamp),
    flags: Option(List(Flag)),
    roles: Option(List(PartialRole)),
  )
}

pub type PartialRole {
  PartialRole(
    id: String,
    name: String,
    position: Int,
    colors: role.Colors,
    icon_hash: Option(String),
    unicode_emoji: Option(String),
  )
}

fn partial_role_decoder() -> decode.Decoder(PartialRole) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use position <- decode.field("position", decode.int)
  use colors <- decode.field("colors", role.colors_decoder())
  use icon_hash <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use unicode_emoji <- decode.optional_field(
    "unicode_emoji",
    None,
    decode.optional(decode.string),
  )
  decode.success(PartialRole(
    id:,
    name:,
    position:,
    colors:,
    icon_hash:,
    unicode_emoji:,
  ))
}

pub type WithMetadata {
  WithMetadata(
    type_: Type,
    code: String,
    guild: Option(Guild),
    channel: Option(Channel),
    inviter: Option(User),
    target_type: Option(TargetType),
    approximate_presence_count: Option(Int),
    approximate_member_count: Option(Int),
    expires_at: Option(Timestamp),
    uses: Int,
    max_uses: Int,
    max_age: Duration,
    is_temporary: Bool,
    created_at: Timestamp,
    flags: Option(List(Flag)),
    roles: Option(List(PartialRole)),
  )
}

pub type Flag {
  IsGuestInvite
}

fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 0), IsGuestInvite)]
}

pub type Create {
  Create(
    max_age: Option(Duration),
    max_uses: Option(Int),
    is_temporary: Bool,
    is_unique: Bool,
    target_type: Option(CreateTargetType),
    target_users_ids: Option(List(String)),
    /// Automatically given roles to users accepting this invite.
    role_ids: Option(List(String)),
  )
}

pub type Type {
  ToGuild
  ToGroupDm
  ToFriend
}

pub type CreateTargetType {
  CreateForStream(streaming_user_id: String)
  CreateForEmbeddedApplication(application_id: String)
}

pub type TargetType {
  ForStream(streaming_user: User)
  ForEmbeddedApplication(application: Application)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Invite) {
  let without_metadata = {
    use invite <- decode.then(without_metadata_decoder())
    decode.success(InviteWithoutMetadata(invite))
  }

  let with_metadata = {
    use invite <- decode.then(with_metadata_decoder())
    decode.success(InviteWithMetadata(invite))
  }

  decode.one_of(with_metadata, or: [without_metadata])
}

@internal
pub fn without_metadata_decoder() -> decode.Decoder(WithoutMetadata) {
  use type_ <- decode.field("type", type_decoder())
  use code <- decode.field("code", decode.string)
  use guild <- decode.optional_field(
    "guild",
    None,
    decode.optional(guild.decoder()),
  )
  use channel <- decode.field("channel", decode.optional(channel.decoder()))
  use inviter <- decode.optional_field(
    "inviter",
    None,
    decode.optional(user.decoder()),
  )
  use target_type <- decode.optional_field(
    "target_type",
    None,
    decode.optional(decode.int),
  )

  use target_type <- decode.then(case target_type {
    Some(1) -> {
      use streaming_user <- decode.field("target_user", user.decoder())
      decode.success(Some(ForStream(streaming_user:)))
    }
    Some(2) -> {
      use application <- decode.field(
        "target_application",
        application.decoder(),
      )
      decode.success(Some(ForEmbeddedApplication(application:)))
    }
    Some(_) ->
      decode.failure(
        Some(
          ForStream(User(
            "",
            "",
            "",
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
          )),
        ),
        "TargetType",
      )
    None -> decode.success(None)
  })
  use approximate_presence_count <- decode.optional_field(
    "approximate_presence_count",
    None,
    decode.optional(decode.int),
  )
  use approximate_member_count <- decode.optional_field(
    "approximate_member_count",
    None,
    decode.optional(decode.int),
  )
  use expires_at <- decode.optional_field(
    "expires_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(bits_flags())),
  )
  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(of: partial_role_decoder())),
  )
  decode.success(WithoutMetadata(
    type_:,
    code:,
    guild:,
    channel:,
    inviter:,
    target_type:,
    approximate_presence_count:,
    approximate_member_count:,
    expires_at:,
    flags:,
    roles:,
  ))
}

@internal
pub fn with_metadata_decoder() -> decode.Decoder(WithMetadata) {
  use type_ <- decode.field("type", type_decoder())
  use code <- decode.field("code", decode.string)
  use guild <- decode.optional_field(
    "guild",
    None,
    decode.optional(guild.decoder()),
  )
  use channel <- decode.field("channel", decode.optional(channel.decoder()))
  use inviter <- decode.optional_field(
    "inviter",
    None,
    decode.optional(user.decoder()),
  )

  use target_type <- decode.optional_field(
    "target_type",
    None,
    decode.optional(decode.int),
  )

  use target_type <- decode.then(case target_type {
    Some(1) -> {
      use streaming_user <- decode.field("target_user", user.decoder())
      decode.success(Some(ForStream(streaming_user:)))
    }
    Some(2) -> {
      use application <- decode.field(
        "target_application",
        application.decoder(),
      )
      decode.success(Some(ForEmbeddedApplication(application:)))
    }
    Some(_) ->
      decode.failure(
        Some(
          ForStream(User(
            "",
            "",
            "",
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
            None,
          )),
        ),
        "TargetType",
      )
    None -> decode.success(None)
  })

  use approximate_presence_count <- decode.optional_field(
    "approximate_presence_count",
    None,
    decode.optional(decode.int),
  )
  use approximate_member_count <- decode.optional_field(
    "approximate_member_count",
    None,
    decode.optional(decode.int),
  )
  use expires_at <- decode.optional_field(
    "expires_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use uses <- decode.field("uses", decode.int)
  use max_uses <- decode.field("max_uses", decode.int)
  use max_age <- decode.field(
    "max_age",
    time_duration.from_int_seconds_decoder(),
  )
  use is_temporary <- decode.field("temporary", decode.bool)
  use created_at <- decode.field("created_at", time_rfc3339.decoder())
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(bits_flags())),
  )
  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(of: partial_role_decoder())),
  )

  decode.success(WithMetadata(
    type_:,
    code:,
    guild:,
    channel:,
    inviter:,
    target_type:,
    approximate_presence_count:,
    approximate_member_count:,
    expires_at:,
    uses:,
    max_uses:,
    max_age:,
    is_temporary:,
    created_at:,
    flags:,
    roles:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(ToGuild)
    1 -> decode.success(ToGroupDm)
    2 -> decode.success(ToFriend)
    _ -> decode.failure(ToGuild, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let max_age = case create.max_age {
    Some(age) -> [#("max_age", time_duration.to_int_seconds_json(age))]
    None -> []
  }

  let max_uses = case create.max_uses {
    Some(uses) -> [#("max_uses", json.int(uses))]
    None -> []
  }

  let is_temporary = [#("temporary", json.bool(create.is_temporary))]

  let is_unique = [#("unique", json.bool(create.is_unique))]

  let target_type = case create.target_type {
    Some(CreateForStream(streaming_user_id)) -> [
      #("target_type", json.int(1)),
      #("target_user_id", json.string(streaming_user_id)),
    ]
    Some(CreateForEmbeddedApplication(application_id)) -> [
      #("target_type", json.int(2)),
      #("target_application_id", json.string(application_id)),
    ]
    None -> []
  }

  let role_ids = case create.role_ids {
    Some(ids) -> [#("role_ids", json.array(ids, json.string))]
    None -> []
  }

  [max_age, max_uses, is_temporary, is_unique, target_type, role_ids]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_all_for_channel(
  client: grom.Client,
  with_id channel_id: String,
) -> Result(List(WithMetadata), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/channels/" <> channel_id <> "/invites")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(with_metadata_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_all_for_guild(
  client: grom.Client,
  with_id guild_id: String,
) -> Result(List(Invite), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/invites")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create(
  client: grom.Client,
  for channel_id: String,
  with create: Create,
  reason reason: Option(String),
) -> Result(WithoutMetadata, grom.Error) {
  let json = create |> create_to_json

  let path = "/channels/" <> channel_id <> "/invites"

  let request = case create.target_users_ids {
    Some(ids) -> {
      let ids_csv = ids |> string.join("\n") |> bit_array.from_string

      client
      |> rest.new_request(http.Post, path)
      |> multipart_form.to_request([
        #(
          "target_users_file",
          field.File("target_users.csv", "text/csv", ids_csv),
        ),
      ])
    }
    None -> {
      client
      |> rest.new_request(http.Post, path)
      |> request.set_body(json |> json.to_string |> bit_array.from_string)
    }
  }

  use response <- result.try(
    request
    |> rest.with_reason(reason)
    |> rest.execute_bytes,
  )

  response.body
  |> json.parse(using: without_metadata_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get(
  client: grom.Client,
  code invite_code: String,
  include_counts with_counts: Bool,
  scheduled_event_id guild_scheduled_event_id: Option(String),
) -> Result(Invite, grom.Error) {
  let query =
    [
      [#("with_counts", bool.to_string(with_counts))],
      case guild_scheduled_event_id {
        Some(id) -> [#("guild_scheduled_event_id", id)]
        None -> []
      },
    ]
    |> list.flatten

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/invites/" <> invite_code)
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete(
  client: grom.Client,
  code invite_code: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(http.Delete, "/invites/" <> invite_code)
  |> rest.with_reason(reason)
  |> rest.execute
  |> result.replace(Nil)
}

pub fn new_create() -> Create {
  Create(None, None, False, False, None, None, None)
}

pub fn get_target_users_ids(
  client: grom.Client,
  for_code code: String,
) -> Result(List(String), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/invites/" <> code <> "/target-users")
    |> rest.execute,
  )

  Ok(split_endlines(response.body))
}

// Cursed CSV handling, because this is a cursed CSV.
fn split_endlines(string: String) -> List(String) {
  let splitter = splitter.new(["\r\n", "\n"])
  split_endlines_loop(string, splitter, [])
}

fn split_endlines_loop(
  string: String,
  splitter: Splitter,
  acc: List(String),
) -> List(String) {
  case splitter.split(splitter, string) {
    #(last, "", "") ->
      [last, ..acc]
      |> list.reverse
      |> list.drop(1)
    #(id, _, rest) -> split_endlines_loop(rest, splitter, [id, ..acc])
  }
}

/// Supply the full list of users that can use the invite, not just the new users.
pub fn update_target_users(
  client: grom.Client,
  for_code code: String,
  users_ids ids: List(String),
) -> Result(Nil, grom.Error) {
  let ids_csv = ids |> string.join("\n") |> bit_array.from_string

  client
  |> rest.new_request(http.Put, "/invites/" <> code <> "/target-users")
  |> multipart_form.to_request([
    #("target_users_file", field.File("target_users.csv", "text/csv", ids_csv)),
  ])
  |> rest.execute_bytes
  |> result.replace(Nil)
}
