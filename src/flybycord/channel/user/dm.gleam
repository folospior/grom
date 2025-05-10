import flybycord/permission.{type Permission}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

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
