import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

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
