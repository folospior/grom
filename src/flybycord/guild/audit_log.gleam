import flybycord/channel.{type Channel}
import flybycord/guild/audit_log/entry.{type Entry}
import flybycord/guild/auto_moderation/rule.{type Rule}
import flybycord/guild/scheduled_event.{type ScheduledEvent}
import flybycord/interaction/application_command.{type ApplicationCommand}
import flybycord/user.{type User}
import flybycord/webhook.{type Webhook}
import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type AuditLog {
  AuditLog(
    application_commands: List(ApplicationCommand),
    entries: List(Entry),
    auto_moderation_rules: List(Rule),
    scheduled_events: List(ScheduledEvent),
    integrations: List(PartialIntegration),
    threads: List(Channel),
    users: List(User),
    webhooks: List(Webhook),
  )
}

pub type PartialIntegration {
  PartialIntegration(
    id: String,
    name: String,
    type_: String,
    account: PartialUser,
    application_id: String,
  )
}

pub type PartialUser {
  PartialUser(name: String, id: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(AuditLog) {
  use application_commands <- decode.field(
    "application_commands",
    decode.list(application_command.decoder()),
  )
  use entries <- decode.field("entries", decode.list(entry.decoder()))
  use auto_moderation_rules <- decode.field(
    "auto_moderation_rules",
    decode.list(rule.decoder()),
  )
  use scheduled_events <- decode.field(
    "scheduled_events",
    decode.list(scheduled_event.decoder()),
  )
  use integrations <- decode.field(
    "integrations",
    decode.list(partial_integration_decoder()),
  )
  use threads <- decode.field("threads", decode.list(channel.decoder()))
  use users <- decode.field("users", decode.list(user.decoder()))
  use webhooks <- decode.field("webhooks", decode.list(webhook.decoder()))
  decode.success(AuditLog(
    application_commands:,
    entries:,
    auto_moderation_rules:,
    scheduled_events:,
    integrations:,
    threads:,
    users:,
    webhooks:,
  ))
}

@internal
pub fn partial_integration_decoder() -> decode.Decoder(PartialIntegration) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.string)
  use account <- decode.field("account", partial_user_decoder())
  use application_id <- decode.field("application_id", decode.string)
  decode.success(PartialIntegration(
    id:,
    name:,
    type_:,
    account:,
    application_id:,
  ))
}

@internal
pub fn partial_user_decoder() -> decode.Decoder(PartialUser) {
  use name <- decode.field("name", decode.string)
  use id <- decode.field("id", decode.string)
  decode.success(PartialUser(name:, id:))
}
