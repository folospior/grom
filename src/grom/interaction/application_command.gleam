import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/application
import grom/interaction/application_command/command_option.{type CommandOption}
import grom/interaction/context_type.{type ContextType}
import grom/permission.{type Permission}

// TYPES -----------------------------------------------------------------------

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
    installation_contexts: Option(List(application.InstallationContext)),
    contexts: Option(List(ContextType)),
    version: String,
  )
}

pub type Type {
  ChatInput
  User
  Message
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(ApplicationCommand) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(type_decoder()),
  )
  use application_id <- decode.field("application_id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)
  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use options <- decode.field(
    "options",
    decode.optional(decode.list(command_option.decoder())),
  )
  use default_member_permissions <- decode.field(
    "default_member_permissions",
    decode.optional(permission.decoder()),
  )
  use is_nsfw <- decode.optional_field(
    "nsfw",
    None,
    decode.optional(decode.bool),
  )
  use installation_contexts <- decode.optional_field(
    "integration_types",
    None,
    decode.optional(decode.list(application.installation_context_decoder())),
  )
  use contexts <- decode.optional_field(
    "contexts",
    None,
    decode.optional(decode.list(context_type.decoder())),
  )
  use version <- decode.field("version", decode.string)
  decode.success(ApplicationCommand(
    id:,
    type_:,
    application_id:,
    guild_id:,
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    options:,
    default_member_permissions:,
    is_nsfw:,
    installation_contexts:,
    contexts:,
    version:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(ChatInput)
    2 -> decode.success(User)
    3 -> decode.success(Message)
    _ -> decode.failure(ChatInput, "Type")
  }
}
