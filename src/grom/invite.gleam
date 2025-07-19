import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import gleam/result
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/application.{type Application}
import grom/channel.{type Channel}
import grom/error.{type Error}
import grom/guild.{type Guild}
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type WithoutMetadata {
  WithoutMetadata(
    type_: Type,
    code: String,
    guild: Option(Guild),
    channel: Option(Channel),
    inviter: Option(User),
    target_type: Option(TargetType),
    target_user: Option(User),
    target_application: Option(Application),
    approximate_presence_count: Option(Int),
    approximate_member_count: Option(Int),
    expires_at: Option(Timestamp),
  )
}

pub type WithMetadata {
  WithMetadata(
    type_: Type,
    code: String,
    guild: Option(Guild),
    channel: Option(Channel),
    inviter: Option(User),
    target_type: Option(TargetType),
    target_user: Option(User),
    target_application: Option(Application),
    approximate_presence_count: Option(Int),
    approximate_member_count: Option(Int),
    expires_at: Option(Timestamp),
    uses: Int,
    max_uses: Int,
    max_age: Duration,
    is_temporary: Bool,
    created_at: Timestamp,
  )
}

pub type Create {
  Create(
    max_age: Option(Duration),
    max_uses: Option(Int),
    is_temporary: Option(Bool),
    target_type: Option(TargetType),
    target_user_id: Option(String),
    target_application_id: Option(String),
  )
}

pub type Type {
  Guild
  GroupDm
  Friend
}

pub type TargetType {
  Stream
  EmbeddedApplication
}

// DECODERS --------------------------------------------------------------------

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
    decode.optional(target_type_decoder()),
  )
  use target_user <- decode.optional_field(
    "target_user",
    None,
    decode.optional(user.decoder()),
  )
  use target_application <- decode.optional_field(
    "target_application",
    None,
    decode.optional(application.decoder()),
  )
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
  decode.success(WithoutMetadata(
    type_:,
    code:,
    guild:,
    channel:,
    inviter:,
    target_type:,
    target_user:,
    target_application:,
    approximate_presence_count:,
    approximate_member_count:,
    expires_at:,
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
    decode.optional(target_type_decoder()),
  )
  use target_user <- decode.optional_field(
    "target_user",
    None,
    decode.optional(user.decoder()),
  )
  use target_application <- decode.optional_field(
    "target_application",
    None,
    decode.optional(application.decoder()),
  )
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

  decode.success(WithMetadata(
    type_:,
    code:,
    guild:,
    channel:,
    inviter:,
    target_type:,
    target_user:,
    target_application:,
    approximate_presence_count:,
    approximate_member_count:,
    expires_at:,
    uses:,
    max_uses:,
    max_age:,
    is_temporary:,
    created_at:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Guild)
    1 -> decode.success(GroupDm)
    2 -> decode.success(Friend)
    _ -> decode.failure(Guild, "Type")
  }
}

@internal
pub fn target_type_decoder() -> decode.Decoder(TargetType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Stream)
    2 -> decode.success(EmbeddedApplication)
    _ -> decode.failure(Stream, "TargetType")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn target_type_encode(target_type: TargetType) -> Json {
  case target_type {
    Stream -> 1
    EmbeddedApplication -> 2
  }
  |> json.int
}

@internal
pub fn create_encode(create: Create) -> Json {
  let Create(
    max_age:,
    max_uses:,
    is_temporary:,
    target_type:,
    target_user_id:,
    target_application_id:,
  ) = create
  json.object([
    #("max_age", case max_age {
      None -> json.null()
      option.Some(value) -> time_duration.to_int_seconds_encode(value)
    }),
    #("max_uses", case max_uses {
      None -> json.null()
      option.Some(value) -> json.int(value)
    }),
    #("is_temporary", case is_temporary {
      None -> json.null()
      option.Some(value) -> json.bool(value)
    }),
    #("target_type", case target_type {
      None -> json.null()
      option.Some(value) -> target_type_encode(value)
    }),
    #("target_user_id", case target_user_id {
      None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("target_application_id", case target_application_id {
      None -> json.null()
      option.Some(value) -> json.string(value)
    }),
  ])
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_many(
  client: grom.Client,
  for channel_id: String,
) -> Result(List(WithMetadata), Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/channels/" <> channel_id <> "/invites")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(with_metadata_decoder()))
  |> result.map_error(error.CouldNotDecode)
}

pub fn create(
  client: grom.Client,
  for channel_id: String,
  with create: Create,
  reason reason: Option(String),
) -> Result(WithoutMetadata, Error) {
  let json = create |> create_encode

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/invites")
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: without_metadata_decoder())
  |> result.map_error(error.CouldNotDecode)
}
