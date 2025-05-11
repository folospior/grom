import flybycord/application.{type Application}
import flybycord/channel.{type Channel}
import flybycord/guild.{type Guild}
import flybycord/internal/time_duration
import flybycord/internal/time_rfc3339
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

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
