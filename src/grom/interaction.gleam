import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/application
import grom/channel.{type Channel}
import grom/channel/thread
import grom/entitlement.{type Entitlement}
import grom/guild.{type Guild}
import grom/guild/role.{type Role}
import grom/guild_member.{type GuildMember}
import grom/interaction/application_command
import grom/message.{type Message}
import grom/message/attachment.{type Attachment}
import grom/permission.{type Permission}
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Interaction {
  CommandExecuted(CommandExecution)
  MessageComponentExecuted(MessageComponentExecution)
  ModalSubmitted(ModalSubmission)
}

pub type CommandExecution {
  SlashCommandExecuted(SlashCommandExecution)
  MessageCommandExecuted(MessageCommandExecution)
  UserCommandExecuted(UserCommandExecution)
}

pub type MessageComponentExecution {
  ButtonExecuted(ButtonExecution)
  StringSelectExecuted(StringSelectExecution)
  UserSelectExecuted(UserSelectExecution)
  RoleSelectExecuted(RoleSelectExecution)
  MentionableSelectExecuted(MentionableSelectExecution)
  ChannelSelectExecuted(ChannelSelectExecution)
}

pub type ModalSubmission {
  ModalSubmission(
    custom_id: String,
    components: List(SubmittedModalComponent),
    resolved: Option(Resolved),
  )
}

pub type SubmittedModalComponent {
  StringSelectSubmitted(StringSelectExecution)
  TextInputSubmitted(TextInputSubmission)
  UserSelectSubmitted(UserSelectExecution)
  RoleSelectSubmitted(RoleSelectExecution)
  MentionableSelectSubmitted(MentionableSelectExecution)
  ChannelSelectSubmitted(ChannelSelectExecution)
  TextDisplaySubmitted(TextDisplaySubmission)
  LabelSubmitted(LabelSubmission)
}

@internal
pub type ComponentExecutionType {
  ExecutedInMessage
  SubmittedInModal
}

pub type ButtonExecution {
  ButtonExecution(custom_id: String, resolved: Option(Resolved))
}

pub type StringSelectExecution {
  StringSelectExecution(
    custom_id: String,
    selected_values: List(String),
    resolved: Option(Resolved),
  )
}

pub type TextInputSubmission {
  TextInputSubmission(id: Int, custom_id: String, value: String)
}

pub type LabelSubmission {
  LabelSubmission(id: Int, component: LabelComponentSubmission)
}

pub type LabelComponentSubmission {
  LabelTextInputSubmission(TextInputSubmission)
  LabelStringSelectSubmission(StringSelectExecution)
  LabelUserSelectSubmission(UserSelectExecution)
  LabelRoleSelectSubmission(RoleSelectExecution)
  LabelMentionableSelectSubmission(MentionableSelectExecution)
  LabelChannelSelectSubmission(ChannelSelectExecution)
}

pub type TextDisplaySubmission {
  TextDisplaySubmission(id: Int)
}

pub type UserSelectExecution {
  UserSelectExecution(
    custom_id: String,
    selected_users_ids: List(String),
    resolved: Option(Resolved),
  )
}

pub type RoleSelectExecution {
  RoleSelectExecution(
    custom_id: String,
    selected_roles_ids: List(String),
    resolved: Option(Resolved),
  )
}

pub type MentionableSelectExecution {
  MentionableSelectExecution(
    custom_id: String,
    selected_mentionables_ids: List(String),
    resolved: Option(Resolved),
  )
}

pub type ChannelSelectExecution {
  ChannelSelectExecution(
    channel_id: String,
    selected_channels_ids: List(String),
    resolved: Option(Resolved),
  )
}

pub type SlashCommandOption {
  StringSlashCommandOption(
    name: String,
    value: String,
    /// For autocomplete.
    is_focused: Bool,
  )
  IntegerSlashCommandOption(
    name: String,
    value: Int,
    /// For autocomplete.
    is_focused: Bool,
  )
  NumberSlashCommandOption(
    name: String,
    value: Float,
    /// For autocomplete.
    is_focused: Bool,
  )
  BoolSlashCommandOption(
    name: String,
    value: Bool,
    /// For autocomplete.
    is_focused: Bool,
  )
  SubCommandSlashCommandOption(name: String, options: List(SlashCommandOption))
  SubCommandGroupSlashCommandOption(
    name: String,
    options: List(SlashCommandOption),
  )
}

pub type SlashCommandExecution {
  SlashCommandExecution(
    id: String,
    application_id: String,
    invokement_info: InvokementInfo,
    channel: Channel,
    channel_id: String,
    token: String,
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    options: List(SlashCommandOption),
    registered_to_guild_id: Option(String),
    application_permissions: List(Permission),
    locale: String,
    entitlements: List(Entitlement),
    /// See: https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-authorizing-integration-owners-object
    authorizing_integration_owners_ids: Dict(
      application.InstallationContext,
      String,
    ),
    context: Option(Context),
    /// In bytes.
    attachment_size_limit: Int,
  )
}

pub type MessageCommandExecution {
  MessageCommandExecution(
    id: String,
    application_id: String,
    invokement_info: InvokementInfo,
    channel: Channel,
    channel_id: String,
    token: String,
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    registered_to_guild_id: Option(String),
    user_id: String,
    application_permissions: List(Permission),
    locale: String,
    entitlements: List(Entitlement),
    /// See: https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-authorizing-integration-owners-object
    authorizing_integration_owners_ids: Dict(
      application.InstallationContext,
      String,
    ),
    context: Option(Context),
    /// In bytes.
    attachment_size_limit: Int,
  )
}

pub type UserCommandExecution {
  UserCommmandExecution(
    id: String,
    application_id: String,
    invokement_info: InvokementInfo,
    channel: Channel,
    channel_id: String,
    token: String,
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    registered_to_guild_id: Option(String),
    message_id: String,
    application_permissions: List(Permission),
    locale: String,
    entitlements: List(Entitlement),
    /// See: https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-authorizing-integration-owners-object
    authorizing_integration_owners_ids: Dict(
      application.InstallationContext,
      String,
    ),
    context: Option(Context),
    /// In bytes.
    attachment_size_limit: Int,
  )
}

pub type Context {
  TriggeredInGuild
  TriggeredInBotDms
  TrigerredInPrivateChannel
}

pub type InvokementInfo {
  InvokedInGuild(
    guild: Guild,
    guild_id: String,
    member: GuildMember,
    locale: String,
  )
  InvokedInDm(user: User)
}

pub type Resolved {
  Resolved(
    users: Option(Dict(String, User)),
    members: Option(Dict(String, GuildMember)),
    roles: Option(Dict(String, Role)),
    channels: Option(Dict(String, ResolvedChannel)),
    messages: Option(Dict(String, Message)),
    attachments: Option(Dict(String, Attachment)),
  )
}

pub type ResolvedChannel {
  ResolvedTextChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedVoiceChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedCategoryChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedannouncementChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedAnnouncementThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedPublicThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedPrivateThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  ResolvedStageChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedForumChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ResolvedMediaChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Interaction) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    2 -> decode.map(command_execution_decoder(), CommandExecuted)
    _ -> todo as "interaction types"
  }
}

@internal
pub fn command_execution_decoder() -> decode.Decoder(CommandExecution) {
  use command_type <- decode.subfield(["data", "type"], decode.int)
  case command_type {
    1 -> decode.map(slash_command_execution_decoder(), SlashCommandExecuted)
  }
}

@internal
pub fn slash_command_execution_decoder() -> decode.Decoder(
  SlashCommandExecution,
) {
  use id <- decode.field("id", decode.string)
  use application_id <- decode.field("application_id", decode.string)
  use command_id <- decode.subfield(["data", "id"], decode.string)
  use command_name <- decode.subfield(["data", "name"], decode.string)
  use resolved <- decode.map(decode.optionally_at(
    ["data", "resolved"],
    None,
    decode.optional(resolved_decoder()),
  ))
  todo
}

@internal
pub fn slash_command_option_decoder() -> decode.Decoder(SlashCommandOption) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.int)
  use is_focused <- decode.optional_field("focused", False, decode.bool)
  todo
}

@internal
pub fn resolved_decoder() -> decode.Decoder(Resolved) {
  use users <- decode.optional_field(
    "users",
    None,
    decode.optional(decode.dict(decode.string, user.decoder())),
  )
  use members <- decode.optional_field(
    "members",
    None,
    decode.optional(decode.dict(decode.string, guild_member.decoder())),
  )
  use roles <- decode.optional_field("roles", None, decod:)

  todo
}
