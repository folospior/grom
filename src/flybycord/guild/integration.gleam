import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES ----------------------------------------------------------------------

pub type Account {
  Account(id: String, name: String)
}

pub type Application {
  Application(
    id: String,
    name: String,
    icon_hash: Option(String),
    description: String,
    bot: Option(User),
  )
}

pub type ExpireBehavior {
  RemoveRole
  Kick
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn account_decoder() -> decode.Decoder(Account) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Account(id:, name:))
}

@internal
pub fn application_decoder() -> decode.Decoder(Application) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon_hash", decode.optional(decode.string))
  use description <- decode.field("description", decode.string)
  use bot <- decode.optional_field("bot", None, decode.optional(user.decoder()))
  decode.success(Application(id:, name:, icon_hash:, description:, bot:))
}

@internal
pub fn expire_behavior_decoder() {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(RemoveRole)
    1 -> decode.success(Kick)
    _ -> decode.failure(RemoveRole, "ExpireBehavior")
  }
}
