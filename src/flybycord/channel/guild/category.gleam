import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/rest
import flybycord/modification.{type Modification, Skip}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

// TYPES -----------------------------------------------------------------------

pub type Channel {
  Channel(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    current_user_permissions: Option(List(Permission)),
  )
}

pub opaque type Modify {
  Modify(
    name: Option(String),
    position: Modification(Int),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn channel_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Channel(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    current_user_permissions:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let position =
    modify.position
    |> modification.encode("position", json.int)

  let permission_overwrites =
    modify.permission_overwrites
    |> modification.encode("permission_overwrites", fn(overwrites) {
      overwrites
      |> json.array(permission_overwrite.create_encode)
    })

  [name, position, permission_overwrites]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn modify(
  client: Client,
  id channel_id: String,
  with modify: Modify,
  reason reason: Option(String),
) {
  let json = modify |> modify_encode

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/channels/" <> channel_id)
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: channel_decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_modify() -> Modify {
  Modify(name: None, position: Skip, permission_overwrites: Skip)
}

pub fn modify_name(modify: Modify, new name: String) -> Modify {
  Modify(..modify, name: Some(name))
}

pub fn modify_position(
  modify: Modify,
  position position: Modification(Int),
) -> Modify {
  Modify(..modify, position:)
}

pub fn modify_permission_overwrites(
  modify: Modify,
  overwrites overwrites: Modification(List(permission_overwrite.Create)),
) -> Modify {
  Modify(..modify, permission_overwrites: overwrites)
}
