import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/result
import grom
import grom/internal/rest
import grom/permission.{type Permission}

// TYPES -----------------------------------------------------------------------

pub type PermissionOverwrite {
  PermissionOverwrite(
    id: String,
    type_: Type,
    allow: List(Permission),
    deny: List(Permission),
  )
}

pub type Create {
  Create(
    type_: Type,
    allow: Option(List(Permission)),
    deny: Option(List(Permission)),
  )
}

pub type Type {
  ForRole
  ForMember
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(PermissionOverwrite) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use allow <- decode.field("allow", permission.decoder())
  use deny <- decode.field("deny", permission.decoder())
  decode.success(PermissionOverwrite(id:, type_:, allow:, deny:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(ForRole)
    1 -> decode.success(ForMember)
    _ -> decode.failure(ForRole, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  json.object([
    #("type", type_to_json(create.type_)),
    #("allow", json.nullable(create.allow, permission.encode)),
    #("deny", json.nullable(create.deny, permission.encode)),
  ])
}

@internal
pub fn type_to_json(type_: Type) -> Json {
  case type_ {
    ForRole -> 0
    ForMember -> 1
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn modify(
  client: grom.Client,
  for channel_id: String,
  id overwrite_id: String,
  new overwrite: Create,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  let json = overwrite |> create_to_json

  use _response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/channels/" <> channel_id <> "/permissions/" <> overwrite_id,
    )
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn delete(
  client: grom.Client,
  for channel_id: String,
  id overwrite_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/channels/" <> channel_id <> "/permissions/" <> overwrite_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}
