import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/user.{type User}

// TYPES ----------------------------------------------------------------------

pub type Emoji {
  Emoji(
    id: Option(String),
    name: Option(String),
    role_ids: Option(List(String)),
    user: Option(User),
    requires_colons: Bool,
    is_managed: Bool,
    is_animated: Bool,
    is_available: Bool,
  )
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(decode.string))
  use name <- decode.field("name", decode.optional(decode.string))
  use role_ids <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use requires_colons <- decode.optional_field(
    "require_colons",
    False,
    decode.bool,
  )
  use is_managed <- decode.optional_field("managed", False, decode.bool)
  use is_animated <- decode.optional_field("animated", False, decode.bool)
  use is_available <- decode.optional_field("available", False, decode.bool)
  decode.success(Emoji(
    id:,
    name:,
    role_ids:,
    user:,
    requires_colons:,
    is_managed:,
    is_animated:,
    is_available:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(emoji: Emoji) -> Json {
  let id = [#("id", json.nullable(emoji.id, json.string))]

  let name = [#("name", json.nullable(emoji.name, json.string))]

  let role_ids = case emoji.role_ids {
    Some(ids) -> [#("roles", json.array(ids, json.string))]
    None -> []
  }

  let user = case emoji.user {
    Some(user) -> [#("user", user.to_json(user))]
    None -> []
  }

  let requires_colons = [
    #("require_colons", json.bool(emoji.requires_colons)),
  ]

  let is_managed = [#("managed", json.bool(emoji.is_managed))]

  let is_animated = [#("animated", json.bool(emoji.is_animated))]

  let is_available = [#("available", json.bool(emoji.is_available))]

  [
    id,
    name,
    role_ids,
    user,
    requires_colons,
    is_managed,
    is_animated,
    is_available,
  ]
  |> list.flatten
  |> json.object
}
