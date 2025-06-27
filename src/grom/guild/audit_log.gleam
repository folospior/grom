import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import grom/channel.{type Channel}
import grom/client.{type Client}
import grom/error.{type Error}
import grom/guild/audit_log/entry.{type Entry}
import grom/guild/auto_moderation/rule.{type Rule}
import grom/guild/scheduled_event.{type ScheduledEvent}
import grom/interaction/application_command.{type ApplicationCommand}
import grom/internal/rest
import grom/user.{type User}
import grom/webhook.{type Webhook}

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

pub type GetQuery {
  UserId(String)
  EntryType(entry.Type)
  BeforeId(String)
  AfterId(String)
  Limit(Int)
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

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: Client,
  for guild_id: String,
  with query: List(GetQuery),
) -> Result(AuditLog, Error) {
  let query =
    query
    |> list.map(fn(parameter) {
      case parameter {
        UserId(id) -> #("user_id", id)
        EntryType(type_) -> #(
          "action_type",
          type_
            |> entry.type_to_int
            |> int.to_string,
        )
        BeforeId(id) -> #("before", id)
        AfterId(id) -> #("after", id)
        Limit(limit) -> #("limit", limit |> int.to_string)
      }
    })

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/audit-logs")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}
