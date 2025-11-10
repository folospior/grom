import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type AllowedMentions {
  AllowedMentions(
    types: Option(List(Type)),
    roles_ids: Option(List(String)),
    users_ids: Option(List(String)),
    replied_user: Option(Bool),
  )
}

pub type Type {
  Roles
  Users
  Everyone
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(AllowedMentions) {
  use types <- decode.optional_field(
    "parse",
    None,
    decode.optional(decode.list(type_decoder())),
  )
  use roles_ids <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(decode.string)),
  )

  use users_ids <- decode.optional_field(
    "users",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use replied_user <- decode.optional_field(
    "replied_user",
    None,
    decode.optional(decode.bool),
  )

  decode.success(AllowedMentions(types:, roles_ids:, users_ids:, replied_user:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.string)
  case variant {
    "roles" -> decode.success(Roles)
    "users" -> decode.success(Users)
    "everyone" -> decode.success(Everyone)
    _ -> decode.failure(Roles, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(allowed_mentions: AllowedMentions) -> Json {
  let types = case allowed_mentions.types {
    Some(types) -> [#("parse", json.array(types, type_to_json))]
    None -> []
  }

  let roles_ids = case allowed_mentions.roles_ids {
    Some(ids) -> [#("roles", json.array(ids, json.string))]
    None -> []
  }

  let users_ids = case allowed_mentions.users_ids {
    Some(ids) -> [#("users", json.array(ids, json.string))]
    None -> []
  }

  let replied_user = case allowed_mentions.replied_user {
    Some(allowed) -> [#("replied_user", json.bool(allowed))]
    None -> []
  }

  [types, roles_ids, users_ids, replied_user]
  |> list.flatten
  |> json.object
}

@internal
pub fn type_to_json(type_: Type) -> Json {
  case type_ {
    Users -> "users"
    Roles -> "roles"
    Everyone -> "everyone"
  }
  |> json.string
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new() -> AllowedMentions {
  AllowedMentions(None, None, None, None)
}
