import flybycord/entitlement.{type Entitlement}
import flybycord/guild.{type Guild}
import flybycord/internal/time_rfc3339
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type WebhookEvent {
  WebhookEvent(
    version: Int,
    application_id: String,
    type_: WebhookType,
    event: Option(Body),
  )
}

pub type WebhookType {
  Ping
  Event
}

pub type Type {
  ApplicationAuthorized
  EntitlementCreate
}

pub type Body {
  Body(type_: Type, timestamp: Timestamp, data: Option(Data))
}

pub type Data {
  ApplicationAuthorizedEvent(
    integration_type: Option(IntegrationType),
    user: User,
    scopes: List(String),
    guild: Option(Guild),
  )
  EntitlementCreateEvent(Entitlement)
}

pub type IntegrationType {
  GuildInstall
  UserInstall
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn webhook_event_decoder() -> decode.Decoder(WebhookEvent) {
  use version <- decode.field("version", decode.int)
  use application_id <- decode.field("application_id", decode.string)
  use type_ <- decode.field("type", webhook_type_decoder())
  use event <- decode.field("event", decode.optional(body_decoder()))
  decode.success(WebhookEvent(version:, application_id:, type_:, event:))
}

@internal
pub fn webhook_type_decoder() -> decode.Decoder(WebhookType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Ping)
    1 -> decode.success(Event)
    _ -> decode.failure(Ping, "WebhookType")
  }
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.string)
  case variant {
    "APPLICATION_AUTHORIZED" -> decode.success(ApplicationAuthorized)
    "ENTITLEMENT_CREATE" -> decode.success(EntitlementCreate)
    _ -> decode.failure(ApplicationAuthorized, "Type")
  }
}

@internal
pub fn integration_type_decoder() -> decode.Decoder(IntegrationType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildInstall)
    1 -> decode.success(UserInstall)
    _ -> decode.failure(GuildInstall, "IntegrationType")
  }
}

@internal
pub fn data_decoder() -> decode.Decoder(Data) {
  decode.one_of(
    {
      use integration_type <- decode.optional_field(
        "integration_type",
        None,
        decode.optional(integration_type_decoder()),
      )
      use user <- decode.field("user", user.decoder())
      use scopes <- decode.field("scopes", decode.list(decode.string))
      use guild <- decode.optional_field(
        "guild",
        None,
        decode.optional(guild.decoder()),
      )
      decode.success(ApplicationAuthorizedEvent(
        integration_type:,
        user:,
        scopes:,
        guild:,
      ))
    },
    or: [
      {
        use entitlement <- decode.then(entitlement.decoder())
        decode.success(EntitlementCreateEvent(entitlement))
      },
    ],
  )
}

@internal
pub fn body_decoder() -> decode.Decoder(Body) {
  use type_ <- decode.field("type", type_decoder())
  use timestamp <- decode.field("timestamp", time_rfc3339.decoder())
  use data <- decode.optional_field(
    "data",
    None,
    decode.optional(data_decoder()),
  )
  decode.success(Body(type_:, timestamp:, data:))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn type_encode(type_: Type) -> json.Json {
  case type_ {
    ApplicationAuthorized -> json.string("APPLICATION_AUTHORIZED")
    EntitlementCreate -> json.string("ENTITLEMENT_CREATE")
  }
}
