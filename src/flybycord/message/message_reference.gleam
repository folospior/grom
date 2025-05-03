import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type MessageReference {
  Reference(
    type_: Type,
    message_id: Option(String),
    channel_id: Option(String),
    guild_id: Option(String),
    fail_if_not_exists: Option(Bool),
  )
}

pub type Type {
  Default
  Forward
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(MessageReference) {
  use type_ <- decode.optional_field("type", Default, type_decoder())
  use message_id <- decode.optional_field(
    "message_id",
    None,
    decode.optional(decode.string),
  )
  use channel_id <- decode.optional_field(
    "channel_id",
    None,
    decode.optional(decode.string),
  )
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use fail_if_not_exists <- decode.optional_field(
    "fail_if_not_exists",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Reference(
    type_:,
    message_id:,
    channel_id:,
    guild_id:,
    fail_if_not_exists:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Default)
    2 -> decode.success(Forward)
    _ -> decode.failure(Default, "Type")
  }
}
