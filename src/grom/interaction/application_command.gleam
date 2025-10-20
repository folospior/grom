import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/application
import grom/interaction/application_command/command_option.{type CommandOption}
import grom/permission

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
    default_member_permissions: Option(List(permission.Permission)),
    is_nsfw: Option(Bool),
    installation_contexts: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
    version: String,
  )
}

pub type Context {
  AllowedInGuilds
  AllowedInBotDms
  AllowedInPrivateChannels
}

pub type Type {
  ChatInput
  User
  Message
}

pub type Permissions {
  Permissions(
    id: String,
    application_id: String,
    guild_id: String,
    permissions: List(Permission),
  )
}

pub type Permission {
  Permission(id: String, type_: PermissionType, is_allowed: Bool)
}

pub type PermissionType {
  RolePermission
  UserPermission
  ChannelPermission
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
    decode.optional(decode.list(context_decoder())),
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

@internal
pub fn context_decoder() -> decode.Decoder(Context) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(AllowedInGuilds)
    1 -> decode.success(AllowedInBotDms)
    2 -> decode.success(AllowedInPrivateChannels)
    _ -> decode.failure(AllowedInGuilds, "Context")
  }
}

@internal
pub fn permissions_decoder() -> decode.Decoder(Permissions) {
  use id <- decode.field("id", decode.string)
  use application_id <- decode.field("application_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use permissions <- decode.field(
    "permissions",
    decode.list(permission_decoder()),
  )
  decode.success(Permissions(id:, application_id:, guild_id:, permissions:))
}

@internal
pub fn permission_decoder() -> decode.Decoder(Permission) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", permission_type_decoder())
  use is_allowed <- decode.field("permission", decode.bool)
  decode.success(Permission(id:, type_:, is_allowed:))
}

@internal
pub fn permission_type_decoder() -> decode.Decoder(PermissionType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(RolePermission)
    2 -> decode.success(UserPermission)
    3 -> decode.success(ChannelPermission)
    _ -> decode.failure(RolePermission, "PermissionType")
  }
}
