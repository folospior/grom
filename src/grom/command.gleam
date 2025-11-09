//// This module defines commands. Commands are the things you create and make available to your users.
//// This module will not help you with *receiving* slash commands, only with *defining* them and registering with Discord.
//// Use the `grom/interaction` and `grom/gateway` modules to receive interactions.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/function
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/application
import grom/internal/rest
import grom/modification.{type Modification, Skip}
import grom/permission.{type Permission as UserPermission}

// TYPES -----------------------------------------------------------------------

pub type Command {
  Slash(SlashCommand)
  User(UserCommand)
  Message(MessageCommand)
}

pub type SlashCommand {
  SlashCommand(
    id: String,
    application_id: String,
    guild_id: Option(String),
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    parameters: Option(List(Parameter)),
    /// None -> All members can use it.
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
    /// None -> Your application's installation contexts for the scope in which the command is ran.
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
  )
}

pub type UserCommand {
  UserCommand(
    id: String,
    application_id: String,
    guild_id: Option(String),
    name: String,
    name_localizations: Option(Dict(String, String)),
    /// None -> All members can use it.
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
    /// None -> Your application's installation contexts for the scope in which the command is ran.
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
  )
}

pub type MessageCommand {
  MessageCommand(
    id: String,
    application_id: String,
    guild_id: Option(String),
    name: String,
    name_localizations: Option(Dict(String, String)),
    /// None -> All members can use it.
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
    /// None -> Your application's installation contexts for the scope in which the command is ran.
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
  )
}

pub type Context {
  AllowedInGuilds
  AllowedInBotDms
  AllowedInPrivateChannels
}

pub type Parameter {
  SubCommandParameter(ParameterSubCommand)
  SubCommandGroupParameter(ParameterSubCommandGroup)
  TextParameter(ParameterText)
  IntegerParameter(ParameterInteger)
  BooleanParameter(ParameterBoolean)
  UserParameter(ParameterUser)
  ChannelParameter(ParameterChannel)
  RoleParameter(ParameterRole)
  MentionableParameter(ParameterMentionable)
  NumberParameter(ParameterNumber)
  AttachmentParameter(ParameterAttachment)
}

pub type ParameterSubCommand {
  ParameterSubCommand(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    parameters: Option(List(Parameter)),
  )
}

pub type ParameterSubCommandGroup {
  ParameterSubCommandGroup(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    parameters: Option(List(Parameter)),
  )
}

pub type ParameterText {
  ParameterText(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(TextChoice)),
    min_length: Option(Int),
    max_length: Option(Int),
    is_autocomplete: Bool,
  )
}

pub type TextChoice {
  TextChoice(
    name: String,
    name_localizations: Option(Dict(String, String)),
    value: String,
  )
}

pub type ParameterInteger {
  ParameterInteger(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(IntegerChoice)),
    min_value: Option(Int),
    max_value: Option(Int),
    is_autocomplete: Bool,
  )
}

pub type IntegerChoice {
  IntegerChoice(
    name: String,
    name_localizations: Option(Dict(String, String)),
    value: Int,
  )
}

pub type ParameterBoolean {
  ParameterBoolean(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}

pub type ParameterUser {
  ParameterUser(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}

pub type ParameterChannel {
  ParameterChannel(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    /// Defaults to every channel type.
    allowed_channel_types: Option(List(AllowedChannelType)),
  )
}

pub type AllowedChannelType {
  AllowTextChannels
  AllowDmChannels
  AllowVoiceChannels
  AllowCategoryChannels
  AllowAnnouncementChannels
  AllowAnnouncementThreads
  AllowPublicThreads
  AllowPrivateThreads
  AllowStageChannels
  AllowForumChannels
  AllowMediaChannels
}

pub type ParameterRole {
  ParameterRole(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}

pub type ParameterMentionable {
  ParameterMentionable(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}

pub type ParameterNumber {
  ParameterNumber(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(NumberChoice)),
    min_value: Option(Float),
    max_value: Option(Float),
    is_autocomplete: Bool,
  )
}

pub type NumberChoice {
  NumberChoice(
    name: String,
    name_localizations: Option(Dict(String, String)),
    value: Float,
  )
}

pub type ParameterAttachment {
  ParameterAttachment(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}

pub type CreateGlobal {
  CreateGlobalSlash(CreateGlobalSlashCommand)
  CreateGlobalUser(CreateGlobalUserCommand)
  CreateGlobalMessage(CreateGlobalMessageCommand)
}

pub type CreateGlobalSlashCommand {
  CreateGlobalSlashCommand(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    parameters: Option(List(Parameter)),
    default_member_permissions: Option(List(UserPermission)),
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
    is_nsfw: Bool,
  )
}

pub type CreateGlobalUserCommand {
  CreateGlobalUserCommand(
    name: String,
    name_localizations: Option(Dict(String, String)),
    default_member_permissions: Option(List(UserPermission)),
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
    is_nsfw: Bool,
  )
}

pub type CreateGlobalMessageCommand {
  CreateGlobalMessageCommand(
    name: String,
    name_localizations: Option(Dict(String, String)),
    default_member_permissions: Option(List(UserPermission)),
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
    is_nsfw: Bool,
  )
}

pub type CreateForGuild {
  CreateSlashForGuild(CreateSlashCommandForGuild)
  CreateUserForGuild(CreateUserCommandForGuild)
  CreateMessageForGuild(CreateMessageCommandForGuild)
}

pub type CreateSlashCommandForGuild {
  CreateSlashCommandForGuild(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    parameters: Option(List(Parameter)),
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
  )
}

pub type CreateUserCommandForGuild {
  CreateUserCommandForGuild(
    name: String,
    name_localizations: Option(Dict(String, String)),
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
  )
}

pub type CreateMessageCommandForGuild {
  CreateMessageCommandForGuild(
    name: String,
    name_localizations: Option(Dict(String, String)),
    default_member_permissions: Option(List(UserPermission)),
    is_nsfw: Bool,
  )
}

pub type ModifyForGuild {
  ModifySlashForGuild(ModifySlashCommandForGuild)
  ModifyUserForGuild(ModifyUserCommandForGuild)
  ModifyMessageForGuild(ModifyMessageCommandForGuild)
}

pub type ModifySlashCommandForGuild {
  ModifySlashCommandForGuild(
    name: Option(String),
    name_localizations: Modification(Dict(String, String)),
    description: Option(String),
    description_localizations: Modification(Dict(String, String)),
    parameters: Option(List(Parameter)),
    default_member_permissions: Modification(List(UserPermission)),
    is_nsfw: Option(Bool),
  )
}

pub type ModifyUserCommandForGuild {
  ModifyUserCommandForGuild(
    name: Option(String),
    name_localizations: Modification(Dict(String, String)),
    default_member_permissions: Modification(List(UserPermission)),
    is_nsfw: Option(Bool),
  )
}

pub type ModifyMessageCommandForGuild {
  ModifyMessageCommandForGuild(
    name: Option(String),
    name_localizations: Modification(Dict(String, String)),
    default_member_permissions: Modification(List(UserPermission)),
    is_nsfw: Option(Bool),
  )
}

pub type ModifyGlobal {
  ModifyGlobal(
    name: Option(String),
    name_localizations: Modification(Dict(String, String)),
    description: Option(String),
    description_localizations: Modification(Dict(String, String)),
    /// Please don't use on anything other than slash commands.
    /// I will find you and do unspeakable violence.
    parameters: Option(List(Parameter)),
    default_member_permissions: Modification(List(UserPermission)),
    integration_types: Option(List(application.InstallationContext)),
    contexts: Option(List(Context)),
    is_nsfw: Option(Bool),
  )
}

pub type GuildPermissions {
  GuildPermissions(
    command_id: String,
    application_id: String,
    guild_id: String,
    permissions: List(Permission),
  )
}

/// In this case, permission means whether a user is allowed to use a command.
/// A denied role permission means that all users with this role are not allowed to use the command.
pub type Permission {
  RolePermission(role_id: String, is_permission_granted: Bool)
  /// If `user_id == guild_id`, `@everyone` gets the permission status (granted/denied).
  UserPermission(user_id: String, is_permission_granted: Bool)
  /// If `channel_id == { guild_id - 1 }`, all channels get the permission status (granted/denied).
  ChannelPermission(channel_id: String, is_permission_granted: Bool)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Command) {
  use type_ <- decode.optional_field("type", 1, decode.int)
  case type_ {
    1 -> decode.map(slash_command_decoder(), Slash)
    _ ->
      decode.failure(
        Slash(SlashCommand(
          "",
          "",
          None,
          "",
          None,
          "",
          None,
          None,
          None,
          False,
          None,
          None,
        )),
        "Command",
      )
  }
}

@internal
pub fn slash_command_decoder() -> decode.Decoder(SlashCommand) {
  use id <- decode.field("id", decode.string)
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
  use parameters <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(of: parameter_decoder())),
  )
  use default_member_permissions <- decode.optional_field(
    "default_member_permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use is_nsfw <- decode.optional_field("nsfw", False, decode.bool)
  use integration_types <- decode.optional_field(
    "integration_types",
    None,
    decode.optional(decode.list(of: application.installation_context_decoder())),
  )
  use contexts <- decode.optional_field(
    "contexts",
    None,
    decode.optional(decode.list(of: context_decoder())),
  )

  decode.success(SlashCommand(
    id:,
    application_id:,
    guild_id:,
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    parameters:,
    default_member_permissions:,
    is_nsfw:,
    integration_types:,
    contexts:,
  ))
}

@internal
pub fn user_command_decoder() -> decode.Decoder(UserCommand) {
  use id <- decode.field("id", decode.string)
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
  use default_member_permissions <- decode.optional_field(
    "default_member_permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use is_nsfw <- decode.optional_field("nsfw", False, decode.bool)
  use integration_types <- decode.optional_field(
    "integration_types",
    None,
    decode.optional(decode.list(of: application.installation_context_decoder())),
  )
  use contexts <- decode.optional_field(
    "contexts",
    None,
    decode.optional(decode.list(of: context_decoder())),
  )

  decode.success(UserCommand(
    id:,
    application_id:,
    guild_id:,
    name:,
    name_localizations:,
    default_member_permissions:,
    is_nsfw:,
    integration_types:,
    contexts:,
  ))
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
pub fn parameter_decoder() -> decode.Decoder(Parameter) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> decode.map(parameter_sub_command_decoder(), SubCommandParameter)
    2 ->
      decode.map(
        parameter_sub_command_group_decoder(),
        SubCommandGroupParameter,
      )
    3 -> decode.map(parameter_text_decoder(), TextParameter)
    4 -> decode.map(parameter_integer_decoder(), IntegerParameter)
    5 -> decode.map(parameter_boolean_decoder(), BooleanParameter)
    6 -> decode.map(parameter_user_decoder(), UserParameter)
    7 -> decode.map(parameter_channel_decoder(), ChannelParameter)
    8 -> decode.map(parameter_role_decoder(), RoleParameter)
    9 -> decode.map(parameter_mentionable_decoder(), MentionableParameter)
    10 -> decode.map(parameter_number_decoder(), NumberParameter)
    11 -> decode.map(parameter_attachment_decoder(), AttachmentParameter)
    _ ->
      decode.failure(
        SubCommandParameter(ParameterSubCommand("", None, "", None, None)),
        "Parameter",
      )
  }
}

@internal
pub fn parameter_sub_command_decoder() -> decode.Decoder(ParameterSubCommand) {
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
  use parameters <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(of: parameter_decoder())),
  )

  decode.success(ParameterSubCommand(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    parameters:,
  ))
}

@internal
pub fn parameter_sub_command_group_decoder() -> decode.Decoder(
  ParameterSubCommandGroup,
) {
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
  use parameters <- decode.optional_field(
    "options",
    None,
    decode.optional(decode.list(of: parameter_decoder())),
  )

  decode.success(ParameterSubCommandGroup(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    parameters:,
  ))
}

@internal
pub fn parameter_text_decoder() -> decode.Decoder(ParameterText) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)
  use choices <- decode.optional_field(
    "choices",
    None,
    decode.optional(decode.list(of: text_choice_decoder())),
  )
  use min_length <- decode.optional_field(
    "min_length",
    None,
    decode.optional(decode.int),
  )
  use max_length <- decode.optional_field(
    "max_length",
    None,
    decode.optional(decode.int),
  )
  use is_autocomplete <- decode.optional_field(
    "autocomplete",
    False,
    decode.bool,
  )

  decode.success(ParameterText(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_length:,
    max_length:,
    is_autocomplete:,
  ))
}

@internal
pub fn text_choice_decoder() -> decode.Decoder(TextChoice) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use value <- decode.field("value", decode.string)

  decode.success(TextChoice(name:, name_localizations:, value:))
}

@internal
pub fn parameter_integer_decoder() -> decode.Decoder(ParameterInteger) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)
  use choices <- decode.optional_field(
    "choices",
    None,
    decode.optional(decode.list(of: integer_choice_decoder())),
  )
  use min_value <- decode.optional_field(
    "min_value",
    None,
    decode.optional(decode.int),
  )
  use max_value <- decode.optional_field(
    "max_value",
    None,
    decode.optional(decode.int),
  )
  use is_autocomplete <- decode.optional_field(
    "autocomplete",
    False,
    decode.bool,
  )

  decode.success(ParameterInteger(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_value:,
    max_value:,
    is_autocomplete:,
  ))
}

@internal
pub fn integer_choice_decoder() -> decode.Decoder(IntegerChoice) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use value <- decode.field("value", decode.int)

  decode.success(IntegerChoice(name:, name_localizations:, value:))
}

@internal
pub fn parameter_boolean_decoder() -> decode.Decoder(ParameterBoolean) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)

  decode.success(ParameterBoolean(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

@internal
pub fn parameter_user_decoder() -> decode.Decoder(ParameterUser) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)

  decode.success(ParameterUser(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

@internal
pub fn parameter_channel_decoder() -> decode.Decoder(ParameterChannel) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)
  use allowed_channel_types <- decode.optional_field(
    "channel_types",
    None,
    decode.optional(decode.list(allowed_channel_type_decoder())),
  )

  decode.success(ParameterChannel(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    allowed_channel_types:,
  ))
}

@internal
pub fn allowed_channel_type_decoder() -> decode.Decoder(AllowedChannelType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(AllowTextChannels)
    1 -> decode.success(AllowDmChannels)
    2 -> decode.success(AllowVoiceChannels)
    4 -> decode.success(AllowCategoryChannels)
    5 -> decode.success(AllowAnnouncementChannels)
    10 -> decode.success(AllowAnnouncementThreads)
    11 -> decode.success(AllowPublicThreads)
    12 -> decode.success(AllowPrivateThreads)
    13 -> decode.success(AllowStageChannels)
    15 -> decode.success(AllowForumChannels)
    16 -> decode.success(AllowMediaChannels)
    _ -> decode.failure(AllowTextChannels, "AllowedChannelType")
  }
}

@internal
pub fn parameter_role_decoder() -> decode.Decoder(ParameterRole) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)

  decode.success(ParameterRole(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

@internal
pub fn parameter_mentionable_decoder() -> decode.Decoder(ParameterMentionable) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)

  decode.success(ParameterMentionable(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

@internal
pub fn parameter_number_decoder() -> decode.Decoder(ParameterNumber) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)
  use choices <- decode.optional_field(
    "choices",
    None,
    decode.optional(decode.list(of: number_choice_decoder())),
  )
  use min_value <- decode.optional_field(
    "min_value",
    None,
    decode.optional(decode.float),
  )
  use max_value <- decode.optional_field(
    "max_value",
    None,
    decode.optional(decode.float),
  )
  use is_autocomplete <- decode.optional_field(
    "autocomplete",
    False,
    decode.bool,
  )

  decode.success(ParameterNumber(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_value:,
    max_value:,
    is_autocomplete:,
  ))
}

@internal
pub fn number_choice_decoder() -> decode.Decoder(NumberChoice) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use value <- decode.field("value", decode.float)

  decode.success(NumberChoice(name:, name_localizations:, value:))
}

@internal
pub fn parameter_attachment_decoder() -> decode.Decoder(ParameterAttachment) {
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
  use is_required <- decode.optional_field("required", False, decode.bool)

  decode.success(ParameterAttachment(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

@internal
pub fn guild_permissions_decoder() -> decode.Decoder(GuildPermissions) {
  use command_id <- decode.field("id", decode.string)
  use application_id <- decode.field("application_id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use permissions <- decode.field(
    "permissions",
    decode.list(of: permission_decoder()),
  )

  decode.success(GuildPermissions(
    command_id:,
    application_id:,
    guild_id:,
    permissions:,
  ))
}

@internal
pub fn permission_decoder() -> decode.Decoder(Permission) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", decode.int)
  use is_permission_granted <- decode.field("permission", decode.bool)

  case type_ {
    1 -> decode.success(RolePermission(role_id: id, is_permission_granted:))
    2 -> decode.success(UserPermission(user_id: id, is_permission_granted:))
    3 ->
      decode.success(ChannelPermission(channel_id: id, is_permission_granted:))
    _ -> decode.failure(RolePermission("", False), "Permission")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_global_to_json(create: CreateGlobal) -> Json {
  case create {
    CreateGlobalSlash(create) -> create_global_slash_command_to_json(create)
    CreateGlobalUser(create) -> create_global_user_command_to_json(create)
    CreateGlobalMessage(create) -> create_global_message_command_to_json(create)
  }
}

@internal
pub fn create_global_slash_command_to_json(
  create: CreateGlobalSlashCommand,
) -> Json {
  let type_ = [#("type", json.int(1))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(create.description))]

  let description_localizations = case create.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let parameters = case create.parameters {
    Some(parameters) -> [
      #("options", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  let integration_types = case create.integration_types {
    Some(types) -> [
      #(
        "integration_types",
        json.array(types, application.installation_context_to_json),
      ),
    ]
    None -> []
  }

  let contexts = case create.contexts {
    Some(contexts) -> [#("contexts", json.array(contexts, context_to_json))]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
    default_member_permissions,
    is_nsfw,
    integration_types,
    contexts,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_global_user_command_to_json(
  create: CreateGlobalUserCommand,
) -> Json {
  let type_ = [#("type", json.int(2))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  let integration_types = case create.integration_types {
    Some(types) -> [
      #(
        "integration_types",
        json.array(types, application.installation_context_to_json),
      ),
    ]
    None -> []
  }

  let contexts = case create.contexts {
    Some(contexts) -> [#("contexts", json.array(contexts, context_to_json))]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    default_member_permissions,
    is_nsfw,
    integration_types,
    contexts,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_global_message_command_to_json(
  create: CreateGlobalMessageCommand,
) -> Json {
  let type_ = [#("type", json.int(3))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  let integration_types = case create.integration_types {
    Some(types) -> [
      #(
        "integration_types",
        json.array(types, application.installation_context_to_json),
      ),
    ]
    None -> []
  }

  let contexts = case create.contexts {
    Some(contexts) -> [#("contexts", json.array(contexts, context_to_json))]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    default_member_permissions,
    is_nsfw,
    integration_types,
    contexts,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn context_to_json(context: Context) -> Json {
  case context {
    AllowedInGuilds -> 0
    AllowedInBotDms -> 1
    AllowedInPrivateChannels -> 2
  }
  |> json.int
}

@internal
pub fn parameter_to_json(parameter: Parameter) -> Json {
  case parameter {
    SubCommandParameter(parameter) -> parameter_sub_command_to_json(parameter)
    SubCommandGroupParameter(parameter) ->
      parameter_sub_command_group_to_json(parameter)
    TextParameter(parameter) -> parameter_text_to_json(parameter)
    IntegerParameter(parameter) -> parameter_integer_to_json(parameter)
    BooleanParameter(parameter) -> parameter_boolean_to_json(parameter)
    UserParameter(parameter) -> parameter_user_to_json(parameter)
    ChannelParameter(parameter) -> parameter_channel_to_json(parameter)
    RoleParameter(parameter) -> parameter_role_to_json(parameter)
    MentionableParameter(parameter) -> parameter_mentionable_to_json(parameter)
    NumberParameter(parameter) -> parameter_number_to_json(parameter)
    AttachmentParameter(parameter) -> parameter_attachment_to_json(parameter)
  }
}

@internal
pub fn parameter_sub_command_to_json(parameter: ParameterSubCommand) -> Json {
  let type_ = [#("type", json.int(1))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let parameters = case parameter.parameters {
    Some(parameters) -> [
      #("parameters", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
  ]
  |> list.flatten
  |> json.object
}

pub fn parameter_sub_command_group_to_json(
  parameter: ParameterSubCommandGroup,
) -> Json {
  let type_ = [#("type", json.int(2))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let parameters = case parameter.parameters {
    Some(parameters) -> [
      #("parameters", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_text_to_json(parameter: ParameterText) -> Json {
  let type_ = [#("type", json.int(3))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  let choices = case parameter.choices {
    Some(choices) -> [#("choices", json.array(choices, text_choice_to_json))]
    None -> []
  }

  let min_length = case parameter.min_length {
    Some(min_length) -> [#("min_length", json.int(min_length))]
    None -> []
  }

  let max_length = case parameter.max_length {
    Some(max_length) -> [#("max_length", json.int(max_length))]
    None -> []
  }

  let is_autocomplete = [
    #("autocomplete", json.bool(parameter.is_autocomplete)),
  ]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
    choices,
    min_length,
    max_length,
    is_autocomplete,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn text_choice_to_json(choice: TextChoice) -> Json {
  let name = [#("name", json.string(choice.name))]

  let name_localizations = case choice.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let value = [#("value", json.string(choice.value))]

  [name, name_localizations, value]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_integer_to_json(parameter: ParameterInteger) -> Json {
  let type_ = [#("type", json.int(4))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  let choices = case parameter.choices {
    Some(choices) -> [#("choices", json.array(choices, integer_choice_to_json))]
    None -> []
  }

  let min_value = case parameter.min_value {
    Some(min_value) -> [#("min_value", json.int(min_value))]
    None -> []
  }

  let max_value = case parameter.max_value {
    Some(max_value) -> [#("max_value", json.int(max_value))]
    None -> []
  }

  let is_autocomplete = [
    #("autocomplete", json.bool(parameter.is_autocomplete)),
  ]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
    choices,
    min_value,
    max_value,
    is_autocomplete,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn integer_choice_to_json(choice: IntegerChoice) -> Json {
  let name = [#("name", json.string(choice.name))]

  let name_localizations = case choice.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let value = [#("value", json.int(choice.value))]

  [name, name_localizations, value]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_boolean_to_json(parameter: ParameterBoolean) -> Json {
  let type_ = [#("type", json.int(5))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_user_to_json(parameter: ParameterUser) -> Json {
  let type_ = [#("type", json.int(6))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_channel_to_json(parameter: ParameterChannel) -> Json {
  let type_ = [#("type", json.int(7))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  let allowed_channel_types = case parameter.allowed_channel_types {
    Some(types) -> [
      #("channel_types", json.array(types, allowed_channel_type_to_json)),
    ]
    None -> []
  }

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
    allowed_channel_types,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn allowed_channel_type_to_json(type_: AllowedChannelType) -> Json {
  case type_ {
    AllowTextChannels -> 0
    AllowDmChannels -> 1
    AllowVoiceChannels -> 2
    AllowCategoryChannels -> 4
    AllowAnnouncementChannels -> 5
    AllowAnnouncementThreads -> 10
    AllowPublicThreads -> 11
    AllowPrivateThreads -> 12
    AllowStageChannels -> 13
    AllowForumChannels -> 15
    AllowMediaChannels -> 16
  }
  |> json.int
}

@internal
pub fn parameter_role_to_json(parameter: ParameterRole) -> Json {
  let type_ = [#("type", json.int(8))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_mentionable_to_json(parameter: ParameterMentionable) -> Json {
  let type_ = [#("type", json.int(9))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_number_to_json(parameter: ParameterNumber) -> Json {
  let type_ = [#("type", json.int(10))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  let choices = case parameter.choices {
    Some(choices) -> [#("choices", json.array(choices, number_choice_to_json))]
    None -> []
  }

  let min_value = case parameter.min_value {
    Some(min_value) -> [#("min_value", json.float(min_value))]
    None -> []
  }

  let max_value = case parameter.max_value {
    Some(max_value) -> [#("max_value", json.float(max_value))]
    None -> []
  }

  let is_autocomplete = [
    #("autocomplete", json.bool(parameter.is_autocomplete)),
  ]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
    choices,
    min_value,
    max_value,
    is_autocomplete,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn number_choice_to_json(choice: NumberChoice) -> Json {
  let name = [#("name", json.string(choice.name))]

  let name_localizations = case choice.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let value = [#("value", json.float(choice.value))]

  [name, name_localizations, value]
  |> list.flatten
  |> json.object
}

@internal
pub fn parameter_attachment_to_json(parameter: ParameterAttachment) -> Json {
  let type_ = [#("type", json.int(11))]

  let name = [#("name", json.string(parameter.name))]

  let name_localizations = case parameter.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(parameter.description))]

  let description_localizations = case parameter.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let is_required = [#("required", json.bool(parameter.is_required))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    is_required,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_global_to_json(modify: ModifyGlobal) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let name_localizations =
    modification.to_json(
      modify.name_localizations,
      "name_localizations",
      json.dict(_, function.identity, json.string),
    )

  let description = case modify.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let description_localizations =
    modification.to_json(
      modify.description_localizations,
      "description_localizations",
      json.dict(_, function.identity, json.string),
    )

  let parameters = case modify.parameters {
    Some(parameters) -> [
      #("options", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  let default_member_permissions =
    modification.to_json(
      modify.default_member_permissions,
      "default_member_permissions",
      permission.to_json,
    )

  let integration_types = case modify.integration_types {
    Some(types) -> [
      #(
        "integration_types",
        json.array(types, application.installation_context_to_json),
      ),
    ]
    None -> []
  }

  let contexts = case modify.contexts {
    Some(contexts) -> [#("contexts", json.array(contexts, context_to_json))]
    None -> []
  }

  let is_nsfw = case modify.is_nsfw {
    Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
    None -> []
  }

  [
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
    default_member_permissions,
    integration_types,
    contexts,
    is_nsfw,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_for_guild_to_json(create: CreateForGuild) -> Json {
  case create {
    CreateSlashForGuild(create) ->
      create_slash_command_for_guild_to_json(create)
    CreateUserForGuild(create) -> create_user_command_for_guild_to_json(create)
    CreateMessageForGuild(create) ->
      create_message_command_for_guild_to_json(create)
  }
}

@internal
pub fn create_slash_command_for_guild_to_json(
  create: CreateSlashCommandForGuild,
) -> Json {
  let type_ = [#("type", json.int(1))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description = [#("description", json.string(create.description))]

  let description_localizations = case create.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let parameters = case create.parameters {
    Some(parameters) -> [
      #("options", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  [
    type_,
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
    default_member_permissions,
    is_nsfw,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_user_command_for_guild_to_json(
  create: CreateUserCommandForGuild,
) -> Json {
  let type_ = [#("type", json.int(2))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  [type_, name, name_localizations, default_member_permissions, is_nsfw]
  |> list.flatten
  |> json.object
}

pub fn create_message_command_for_guild_to_json(
  create: CreateMessageCommandForGuild,
) -> Json {
  let type_ = [#("type", json.int(3))]

  let name = [#("name", json.string(create.name))]

  let name_localizations = case create.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let default_member_permissions = case create.default_member_permissions {
    Some(permissions) -> [
      #("default_member_permissions", permission.to_json(permissions)),
    ]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create.is_nsfw))]

  [type_, name, name_localizations, default_member_permissions, is_nsfw]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_for_guild_to_json(modify: ModifyForGuild) -> Json {
  case modify {
    ModifySlashForGuild(modify) ->
      modify_slash_command_for_guild_to_json(modify)
    ModifyUserForGuild(modify) -> modify_user_command_for_guild_to_json(modify)
    ModifyMessageForGuild(modify) ->
      modify_message_command_for_guild_to_json(modify)
  }
}

@internal
pub fn modify_slash_command_for_guild_to_json(
  modify: ModifySlashCommandForGuild,
) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let name_localizations =
    modification.to_json(
      modify.name_localizations,
      "name_localizations",
      json.dict(_, function.identity, json.string),
    )

  let description = case modify.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let description_localizations =
    modification.to_json(
      modify.description_localizations,
      "description_localizations",
      json.dict(_, function.identity, json.string),
    )

  let parameters = case modify.parameters {
    Some(parameters) -> [
      #("parameters", json.array(parameters, parameter_to_json)),
    ]
    None -> []
  }

  let default_member_permissions =
    modification.to_json(
      modify.default_member_permissions,
      "default_member_permissions",
      permission.to_json,
    )

  let is_nsfw = case modify.is_nsfw {
    Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
    None -> []
  }

  [
    name,
    name_localizations,
    description,
    description_localizations,
    parameters,
    default_member_permissions,
    is_nsfw,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_user_command_for_guild_to_json(
  modify: ModifyUserCommandForGuild,
) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let name_localizations =
    modification.to_json(
      modify.name_localizations,
      "name_localizations",
      json.dict(_, function.identity, json.string),
    )

  let default_member_permissions =
    modification.to_json(
      modify.default_member_permissions,
      "default_member_permissions",
      permission.to_json,
    )

  let is_nsfw = case modify.is_nsfw {
    Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
    None -> []
  }

  [name, name_localizations, default_member_permissions, is_nsfw]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_message_command_for_guild_to_json(
  modify: ModifyMessageCommandForGuild,
) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let name_localizations =
    modification.to_json(
      modify.name_localizations,
      "name_localizations",
      json.dict(_, function.identity, json.string),
    )

  let default_member_permissions =
    modification.to_json(
      modify.default_member_permissions,
      "default_member_permissions",
      permission.to_json,
    )

  let is_nsfw = case modify.is_nsfw {
    Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
    None -> []
  }

  [name, name_localizations, default_member_permissions, is_nsfw]
  |> list.flatten
  |> json.object
}

@internal
pub fn permission_to_json(permission: Permission) -> Json {
  let id = case permission {
    ChannelPermission(channel_id:, ..) -> channel_id
    RolePermission(role_id:, ..) -> role_id
    UserPermission(user_id:, ..) -> user_id
  }

  let type_ = case permission {
    RolePermission(..) -> 1
    UserPermission(..) -> 2
    ChannelPermission(..) -> 3
  }

  json.object([
    #("id", json.string(id)),
    #("type", json.int(type_)),
    #("permission", json.bool(permission.is_permission_granted)),
  ])
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_all_global(
  client: grom.Client,
  for application_id: String,
) -> Result(List(Command), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/commands",
    )
    |> request.set_query([#("with_localizations", "true")])
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_global(
  client: grom.Client,
  for application_id: String,
  using create: CreateGlobal,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/applications/" <> application_id <> "/commands",
    )
    |> request.set_body(create |> create_global_to_json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create_global_slash_command(
  named name: String,
  description description: String,
) -> CreateGlobalSlashCommand {
  CreateGlobalSlashCommand(
    name,
    None,
    description,
    None,
    None,
    None,
    None,
    None,
    False,
  )
}

pub fn new_create_global_user_command(named name: String) {
  CreateGlobalUserCommand(name, None, None, None, None, False)
}

pub fn new_create_global_message_command(named name: String) {
  CreateGlobalMessageCommand(name, None, None, None, None, False)
}

pub fn get_global(
  client: grom.Client,
  of application_id: String,
  id command_id: String,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/commands/" <> command_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_global(
  client: grom.Client,
  of application_id: String,
  id command_id: String,
  using modify: ModifyGlobal,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/applications/" <> application_id <> "/commands/" <> command_id,
    )
    |> request.set_body(modify |> modify_global_to_json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify_global() -> ModifyGlobal {
  ModifyGlobal(None, Skip, None, Skip, None, Skip, None, None, None)
}

pub fn delete_global(
  client: grom.Client,
  of application_id: String,
  id command_id: String,
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/applications/" <> application_id <> "/commands/" <> command_id,
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn bulk_overwrite_global(
  client: grom.Client,
  of application_id: String,
  new commands: List(CreateGlobal),
) -> Result(List(Command), grom.Error) {
  let json = json.array(commands, create_global_to_json)

  use response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/applications/" <> application_id <> "/commands",
    )
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_all_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
) -> Result(List(Command), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands",
    )
    |> request.set_query([#("with_localizations", "true")])
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
  using create: CreateForGuild,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands",
    )
    |> request.set_body(create |> create_for_guild_to_json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create_slash_command_for_guild(
  named name: String,
  description description: String,
) -> CreateSlashCommandForGuild {
  CreateSlashCommandForGuild(name, None, description, None, None, None, False)
}

pub fn new_create_user_command_for_guild(
  named name: String,
) -> CreateUserCommandForGuild {
  CreateUserCommandForGuild(name, None, None, False)
}

pub fn new_create_message_command_for_guild(
  named name: String,
) -> CreateMessageCommandForGuild {
  CreateMessageCommandForGuild(name, None, None, False)
}

pub fn get_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
  id command_id: String,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands/"
        <> command_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
  id command_id: String,
  using modify: ModifyForGuild,
) -> Result(Command, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands/"
        <> command_id,
    )
    |> request.set_body(modify |> modify_for_guild_to_json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
  id command_id: String,
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/applications/"
      <> application_id
      <> "/guilds/"
      <> guild_id
      <> "/commands/"
      <> command_id,
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn bulk_overwrite_for_guild(
  client: grom.Client,
  application application_id: String,
  guild guild_id: String,
  new commands: List(CreateForGuild),
) -> Result(List(Command), grom.Error) {
  let json = json.array(commands, create_for_guild_to_json)

  use response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands",
    )
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_all_guild_permissions(
  client: grom.Client,
  of application_id: String,
  in guild_id: String,
) -> Result(List(GuildPermissions), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands/permissions",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: guild_permissions_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_guild_permissions(
  client: grom.Client,
  of application_id: String,
  in guild_id: String,
  for command_id: String,
) -> Result(GuildPermissions, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/"
        <> application_id
        <> "/guilds/"
        <> guild_id
        <> "/commands/"
        <> command_id
        <> "/permissions",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: guild_permissions_decoder())
  |> result.map_error(grom.CouldNotDecode)
}
