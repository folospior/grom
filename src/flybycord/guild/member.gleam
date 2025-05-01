import flybycord/internal/time_rfc3339
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

pub type Member {
  Member(
    user: Option(User),
    nick: Option(String),
    avatar_hash: Option(String),
    banner_hash: Option(String),
    roles: List(String),
    joined_at: Timestamp,
    premium_since: Option(Timestamp),
    is_deaf: Bool,
    is_mute: Bool,
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
  AutomodQuarantinedUsername
  DmSettingsUpsellAcknowledged
}

const bits_flags = [
  #(1, DidRejoin),
  #(2, CompletedOnboarding),
  #(4, BypassesVerification),
  #(8, StartedOnboarding),
  #(16, IsGuest),
  #(32, StartedHomeActions),
  #(64, CompletedHomeActions),
  #(128, AutomodQuarantinedUsername),
  #(512, DmSettingsUpsellAcknowledged),
]

@internal
pub fn decoder() -> decode.Decoder(Member) {
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
  use is_deaf <- decode.field("deaf", decode.bool)
  use is_mute <- decode.field("mute", decode.bool)
  use flags <- decode.field("flags", flags_decoder())
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

@internal
pub fn flags_decoder() -> decode.Decoder(List(Flag)) {
  use flags <- decode.then(decode.int)

  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}
