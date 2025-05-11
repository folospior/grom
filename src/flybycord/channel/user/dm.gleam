import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/rest
import flybycord/permission.{type Permission}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option, None}
import gleam/result

// TYPES -----------------------------------------------------------------------

pub type Channel {
  Channel(
    id: String,
    last_message_id: Option(String),
    recipients: List(User),
    current_user_permissions: Option(List(Permission)),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn channel_decoder() {
  use id <- decode.field("id", decode.string)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use recipients <- decode.field("recipients", decode.list(user.decoder()))
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Channel(
    id:,
    last_message_id:,
    recipients:,
    current_user_permissions:,
  ))
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn create(
  client: Client,
  to recipient_id: String,
) -> Result(Channel, error.FlybycordError) {
  let json = json.object([#("recipient_id", json.string(recipient_id))])

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/users/@me/channels")
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: channel_decoder())
  |> result.map_error(error.DecodeError)
}
