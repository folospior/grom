import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/flags
import grom/internal/time_rfc3339
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
