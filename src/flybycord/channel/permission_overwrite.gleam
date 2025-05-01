import flybycord/permission.{type Permission}
import gleam/dynamic/decode

pub type PermissionOverwrite {
  PermissionOverwrite(
    id: String,
    type_: Type,
    allow: List(Permission),
    deny: List(Permission),
  )
}

pub type Type {
  Role
  Member
}

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
    0 -> decode.success(Role)
    1 -> decode.success(Member)
    _ -> decode.failure(Role, "Type")
  }
}
