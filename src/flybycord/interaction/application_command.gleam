import flybycord/application
import flybycord/interaction/application_command/command_option.{
  type CommandOption,
}
import flybycord/interaction/context_type.{type InteractionContextType}
import flybycord/permission.{type Permission}
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type ApplicationCommand {
  ApplicationCommand(
    id: String,
    type_: Option(Type),
    application_id: String,
    guild_id: Option(String),
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    options: Option(List(CommandOption)),
    default_member_permissions: Option(List(Permission)),
    is_nsfw: Option(Bool),
    integration_types: Option(List(application.IntegrationType)),
    contexts: Option(List(InteractionContextType)),
    version: String,
  )
}

pub type Type {
  ChatInput
  User
  Message
}
