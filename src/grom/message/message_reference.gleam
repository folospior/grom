import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type MessageReference {
  MessageReference(
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
  decode.success(MessageReference(
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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(reference: MessageReference) -> Json {
  let type_ = [#("type", type_to_json(reference.type_))]

  let message_id = case reference.message_id {
    Some(id) -> [#("message_id", json.string(id))]
    None -> []
  }

  let channel_id = case reference.channel_id {
    Some(id) -> [#("channel_id", json.string(id))]
    None -> []
  }

  let guild_id = case reference.guild_id {
    Some(id) -> [#("guild_id", json.string(id))]
    None -> []
  }

  let fail_if_not_exists = case reference.fail_if_not_exists {
    Some(fail) -> [#("fail_if_not_exists", json.bool(fail))]
    None -> []
  }

  [type_, message_id, channel_id, guild_id, fail_if_not_exists]
  |> list.flatten
  |> json.object
}

@internal
pub fn type_to_json(type_: Type) -> Json {
  case type_ {
    Default -> 0
    Forward -> 1
  }
  |> json.int
}
