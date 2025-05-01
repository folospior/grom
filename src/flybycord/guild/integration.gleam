import flybycord/internal/time_rfc3339
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES ----------------------------------------------------------------------

pub type Integration {
  Integration(
    id: String,
    name: String,
    type_: String,
    is_enabled: Bool,
    is_syncing: Option(Bool),
    role_id: Option(String),
    are_emoticons_enabled: Option(Bool),
    expire_behavior: Option(ExpireBehavior),
    expire_grace_period: Option(Int),
    user: Option(User),
    account: Account,
    synced_at: Option(Timestamp),
    subscriber_count: Option(Int),
    is_revoked: Option(Bool),
    application: Option(Application),
    scopes: Option(List(String)),
  )
}

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
pub fn decoder() -> decode.Decoder(Integration) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.string)
  use is_enabled <- decode.field("enabled", decode.bool)
  use is_syncing <- decode.optional_field(
    "syncing",
    None,
    decode.optional(decode.bool),
  )
  use role_id <- decode.optional_field(
    "role_id",
    None,
    decode.optional(decode.string),
  )
  use are_emoticons_enabled <- decode.optional_field(
    "enable_emoticons",
    None,
    decode.optional(decode.bool),
  )
  use expire_behavior <- decode.optional_field(
    "expire_behavior",
    None,
    decode.optional(expire_behavior_decoder()),
  )
  use expire_grace_period <- decode.optional_field(
    "expire_grace_period",
    None,
    decode.optional(decode.int),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use account <- decode.field("account", account_decoder())
  use synced_at <- decode.optional_field(
    "synced_at",
    None,
    decode.optional(time_rfc3339.decoder()),
  )
  use subscriber_count <- decode.optional_field(
    "subscriber_count",
    None,
    decode.optional(decode.int),
  )
  use is_revoked <- decode.optional_field(
    "revoked",
    None,
    decode.optional(decode.bool),
  )
  use application <- decode.optional_field(
    "application",
    None,
    decode.optional(application_decoder()),
  )
  use scopes <- decode.optional_field(
    "scopes",
    None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(Integration(
    id:,
    name:,
    type_:,
    is_enabled:,
    is_syncing:,
    role_id:,
    are_emoticons_enabled:,
    expire_behavior:,
    expire_grace_period:,
    user:,
    account:,
    synced_at:,
    subscriber_count:,
    is_revoked:,
    application:,
    scopes:,
  ))
}

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
