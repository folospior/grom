import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}

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
  Role
  Member
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
    0 -> decode.success(Role)
    1 -> decode.success(Member)
    _ -> decode.failure(Role, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_encode(create: Create) -> Json {
  json.object([
    #("type", type_encode(create.type_)),
    #("allow", json.nullable(create.allow, permission.encode)),
    #("deny", json.nullable(create.deny, permission.encode)),
  ])
}

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    Role -> 0
    Member -> 1
  }
  |> json.int
}
