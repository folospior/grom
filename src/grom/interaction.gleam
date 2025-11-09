import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/application
import grom/channel.{type Channel}
import grom/channel/thread
import grom/entitlement.{type Entitlement}
import grom/file.{type File}
import grom/guild.{type Guild}
import grom/guild/role.{type Role}
import grom/guild_member.{type GuildMember}
import grom/interaction/application_command/choice.{type Choice}
import grom/internal/flags
import grom/internal/rest
import grom/message.{type Message}
import grom/message/allowed_mentions.{type AllowedMentions}
import grom/message/attachment.{type Attachment}
import grom/message/embed.{type Embed}
import grom/message/poll
import grom/modal
import grom/modification.{type Modification, Skip}
import grom/permission.{type Permission}
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Interaction {
  Interaction(
    id: String,
    application_id: String,
    data: Data,
    invokement_info: InvokementInfo,
    channel: Channel,
    channel_id: String,
    token: String,
    /// For modals/component interactions, the message it was triggered from.
    message: Option(Message),
    application_permissions: List(Permission),
    locale: String,
    entitlements: Option(List(Entitlement)),
    authorizing_integration_owners_ids: Dict(
      application.InstallationContext,
      String,
    ),
    context: Option(Context),
    attachment_size_limit_bytes: Int,
  )
}

pub type Data {
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
  FileUploadSubmitted(FileUploadSubmission)
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
  LabelSubmission(id: Int, component: SubmittedLabelComponent)
}

pub type SubmittedLabelComponent {
  LabelTextInputSubmitted(TextInputSubmission)
  LabelStringSelectSubmitted(StringSelectExecution)
  LabelUserSelectSubmitted(UserSelectExecution)
  LabelRoleSelectSubmitted(RoleSelectExecution)
  LabelMentionableSelectSubmitted(MentionableSelectExecution)
  LabelChannelSelectSubmitted(ChannelSelectExecution)
  LabelFileUploadSubmitted(FileUploadSubmission)
}

pub type TextDisplaySubmission {
  TextDisplaySubmission(id: Int)
}

pub type FileUploadSubmission {
  FileUploadSubmission(
    id: Int,
    custom_id: String,
    uploaded_files_ids: List(String),
  )
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
    custom_id: String,
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
  UserSlashCommandOption(
    /// Name of the option, NOT of the user.
    name: String,
    user_id: String,
    /// For autocomplete.
    is_focused: Bool,
  )
  ChannelSlashCommandOption(
    /// Name of the option, NOT of the channel.
    name: String,
    channel_id: String,
    /// For autocomplete.
    is_focused: Bool,
  )
  RoleSlashCommandOption(
    /// Name of the option, NOT of the role.
    name: String,
    role_id: String,
    /// For autocomplete.
    is_focused: Bool,
  )
  MentionableSlashCommandOption(
    /// Name of the option, NOT of the mentionable.
    name: String,
    mentionable_id: String,
    /// For autocomplete.
    is_focused: Bool,
  )
  AttachmentSlashCommandOption(
    /// Name of the option, NOT of the attachment.
    name: String,
    /// You likely want to search for this in `resolved`.
    attachment_id: String,
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
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    options: List(SlashCommandOption),
    registered_to_guild_id: Option(String),
  )
}

pub type MessageCommandExecution {
  MessageCommandExecution(
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    registered_to_guild_id: Option(String),
    message_id: String,
  )
}

pub type UserCommandExecution {
  UserCommandExecution(
    command_id: String,
    command_name: String,
    resolved: Option(Resolved),
    registered_to_guild_id: Option(String),
    user_id: String,
  )
}

pub type Context {
  TriggeredInGuild
  TriggeredInBotDms
  TriggeredInPrivateChannel
}

pub type InvokementInfo {
  InvokedInGuild(
    guild: Guild,
    guild_id: String,
    member: GuildMember,
    guild_locale: String,
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

// TODO: update this, also make channels a tad bit better (kinda suck rn)
// (maybe after release?!) (seems like a bad idea) (i also don't wanna push this off)
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
  ResolvedAnnouncementChannel(
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

pub type Response {
  RespondWithChannelMessageWithSource(ResponseMessage)
  /// You should only set the `flags` property in this response.
  RespondWithDeferredChannelMessageWithSource(ResponseMessage)
  RespondWithDeferredUpdateMessage
  RespondWithUpdateMessage(ResponseMessage)
  RespondWithApplicationCommandAutocompleteResult(AutocompleteResponse)
  RespondWithModal(ModalResponse)
}

pub type ResponseMessage {
  ResponseMessage(
    is_tts: Option(Bool),
    content: Option(String),
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    /// For `RespondWithDeferredChannelMessageWithSource`s, you can only set the `EphemeralResponseMessage` flag.
    /// If you need any other flags - use them with the edited response message.
    flags: Option(List(ResponseMessageFlag)),
    components: Option(List(message.Component)),
    attachments: Option(List(attachment.Create)),
    files: Option(List(File)),
    poll: Option(poll.Create),
  )
}

pub type ResponseMessageFlag {
  ResponseMessageWithSuppressedEmbeds
  EphemeralResponseMessage
  ResponseMessageWithComponentsV2
  VoiceResponseMessage
  ResponseMessageWithSuppressedNotifications
}

pub type AutocompleteResponse {
  // TODO: revamp app command and come back
  AutocompleteResponse(choices: List(Choice))
}

pub type ModalResponse {
  ModalResponse(
    custom_id: String,
    title: String,
    components: List(modal.Component),
  )
}

pub type ModifyOriginalResponse {
  ModifyOriginalResponse(
    content: Modification(String),
    embeds: Modification(List(Embed)),
    flags: Modification(List(ModifyOriginalResponseFlag)),
    allowed_mentions: Modification(AllowedMentions),
    components: Modification(List(message.Component)),
    files: Modification(List(File)),
    attachments: Modification(List(attachment.Create)),
    poll: Modification(poll.Create),
  )
}

pub type ModifyOriginalResponseFlag {
  ModifyResponseWithSuppressedEmbeds
  ModifyResponseWithComponentsV2
}

pub type Followup {
  Followup(
    content: Option(String),
    is_tts: Bool,
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    components: Option(List(message.Component)),
    files: Option(List(File)),
    attachments: Option(List(attachment.Create)),
    flags: Option(List(FollowupFlag)),
    poll: Option(poll.Create),
  )
}

pub type FollowupFlag {
  EphemeralFollowup
  FollowupWithSuppressedEmbeds
  FollowupWithSuppressedNotifications
  FollowupWithComponentsV2
}

pub type ModifyFollowup {
  ModifyFollowup(
    content: Modification(String),
    embeds: Modification(List(Embed)),
    flags: Modification(List(ModifyFollowupFlag)),
    allowed_mentions: Modification(AllowedMentions),
    components: Modification(List(message.Component)),
    files: Modification(List(File)),
    attachments: Modification(List(attachment.Create)),
    poll: Modification(poll.Create),
  )
}

pub type ModifyFollowupFlag {
  ModifyFollowupWithSuppressedEmbeds
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_response_message_flags() -> List(#(Int, ResponseMessageFlag)) {
  [
    #(int.bitwise_shift_left(1, 2), ResponseMessageWithSuppressedEmbeds),
    #(int.bitwise_shift_left(1, 6), EphemeralResponseMessage),
    #(int.bitwise_shift_left(1, 15), ResponseMessageWithComponentsV2),
    #(int.bitwise_shift_left(1, 13), VoiceResponseMessage),
    #(int.bitwise_shift_left(1, 12), ResponseMessageWithSuppressedNotifications),
  ]
}

@internal
pub fn bits_modify_original_response_flags() -> List(
  #(Int, ModifyOriginalResponseFlag),
) {
  [
    #(int.bitwise_shift_left(1, 2), ModifyResponseWithSuppressedEmbeds),
    #(int.bitwise_shift_left(1, 15), ModifyResponseWithComponentsV2),
  ]
}

@internal
pub fn bits_followup_flags() -> List(#(Int, FollowupFlag)) {
  [
    #(int.bitwise_shift_left(1, 6), EphemeralFollowup),
    #(int.bitwise_shift_left(1, 2), FollowupWithSuppressedEmbeds),
    #(int.bitwise_shift_left(1, 12), FollowupWithSuppressedNotifications),
    #(int.bitwise_shift_left(1, 15), FollowupWithComponentsV2),
  ]
}

@internal
pub fn bits_modify_followup_flags() -> List(#(Int, ModifyFollowupFlag)) {
  [#(int.bitwise_shift_left(1, 2), ModifyFollowupWithSuppressedEmbeds)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Interaction) {
  use id <- decode.field("id", decode.string)
  use application_id <- decode.field("application_id", decode.string)
  use type_ <- decode.field("type", decode.int)
  use invokement_info <- decode.then(invokement_info_decoder())
  use channel <- decode.field("channel", channel.decoder())
  use channel_id <- decode.field("channel_id", decode.string)
  use token <- decode.field("token", decode.string)
  use data <- decode.field("data", data_decoder(type_))
  use message <- decode.optional_field(
    "message",
    None,
    decode.optional(message.decoder()),
  )
  use application_permissions <- decode.field(
    "app_permissions",
    permission.decoder(),
  )
  use locale <- decode.field("locale", decode.string)
  use entitlements <- decode.optional_field(
    "entitlements",
    None,
    decode.optional(decode.list(of: entitlement.decoder())),
  )
  use authorizing_integration_owners_ids <- decode.field(
    "authorizing_integration_owners",
    decode.dict(application.installation_context_decoder(), decode.string),
  )
  use context <- decode.optional_field(
    "context",
    None,
    decode.optional(context_decoder()),
  )
  use attachment_size_limit_bytes <- decode.field(
    "attachment_size_limit",
    decode.int,
  )

  decode.success(Interaction(
    id:,
    application_id:,
    data:,
    invokement_info:,
    channel:,
    channel_id:,
    token:,
    message:,
    application_permissions:,
    locale:,
    entitlements:,
    authorizing_integration_owners_ids:,
    context:,
    attachment_size_limit_bytes:,
  ))
}

@internal
pub fn data_decoder(type_: Int) -> decode.Decoder(Data) {
  case type_ {
    2 | 4 -> decode.map(command_execution_decoder(), CommandExecuted)
    3 ->
      decode.map(
        message_component_execution_decoder(),
        MessageComponentExecuted,
      )
    5 -> decode.map(modal_submission_decoder(), ModalSubmitted)
    _ ->
      decode.failure(
        CommandExecuted(
          SlashCommandExecuted(SlashCommandExecution("", "", None, [], None)),
        ),
        "Data",
      )
  }
}

@internal
pub fn modal_submission_decoder() -> decode.Decoder(ModalSubmission) {
  use custom_id <- decode.field("custom_id", decode.string)
  use components <- decode.field(
    "components",
    decode.list(of: submitted_modal_component_decoder()),
  )
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )

  decode.success(ModalSubmission(custom_id:, components:, resolved:))
}

@internal
pub fn submitted_modal_component_decoder() -> decode.Decoder(
  SubmittedModalComponent,
) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    3 -> decode.map(string_select_execution_decoder(), StringSelectSubmitted)
    4 -> decode.map(text_input_submission_decoder(), TextInputSubmitted)
    5 -> decode.map(user_select_execution_decoder(), UserSelectSubmitted)
    6 -> decode.map(role_select_execution_decoder(), RoleSelectSubmitted)
    7 ->
      decode.map(
        mentionable_select_execution_decoder(),
        MentionableSelectSubmitted,
      )
    8 -> decode.map(channel_select_execution_decoder(), ChannelSelectSubmitted)
    10 -> decode.map(text_display_submission_decoder(), TextDisplaySubmitted)
    18 -> decode.map(label_submission_decoder(), LabelSubmitted)
    19 -> decode.map(file_upload_submission_decoder(), FileUploadSubmitted)
    _ ->
      decode.failure(
        StringSelectSubmitted(StringSelectExecution("", [], None)),
        "SubmittedModalComponent",
      )
  }
}

@internal
pub fn text_input_submission_decoder() -> decode.Decoder(TextInputSubmission) {
  use id <- decode.field("id", decode.int)
  use custom_id <- decode.field("custom_id", decode.string)
  use value <- decode.field("value", decode.string)

  decode.success(TextInputSubmission(id:, custom_id:, value:))
}

@internal
pub fn text_display_submission_decoder() -> decode.Decoder(
  TextDisplaySubmission,
) {
  use id <- decode.field("id", decode.int)
  decode.success(TextDisplaySubmission(id:))
}

@internal
pub fn file_upload_submission_decoder() -> decode.Decoder(FileUploadSubmission) {
  use id <- decode.field("id", decode.int)
  use custom_id <- decode.field("custom_id", decode.string)
  use uploaded_files_ids <- decode.field(
    "values",
    decode.list(of: decode.string),
  )

  decode.success(FileUploadSubmission(id:, custom_id:, uploaded_files_ids:))
}

@internal
pub fn label_submission_decoder() -> decode.Decoder(LabelSubmission) {
  use id <- decode.field("id", decode.int)
  use component <- decode.field(
    "component",
    submitted_label_component_decoder(),
  )
  decode.success(LabelSubmission(id:, component:))
}

@internal
pub fn submitted_label_component_decoder() -> decode.Decoder(
  SubmittedLabelComponent,
) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    3 ->
      decode.map(string_select_execution_decoder(), LabelStringSelectSubmitted)
    4 -> decode.map(text_input_submission_decoder(), LabelTextInputSubmitted)
    5 -> decode.map(user_select_execution_decoder(), LabelUserSelectSubmitted)
    6 -> decode.map(role_select_execution_decoder(), LabelRoleSelectSubmitted)
    7 ->
      decode.map(
        mentionable_select_execution_decoder(),
        LabelMentionableSelectSubmitted,
      )
    8 ->
      decode.map(
        channel_select_execution_decoder(),
        LabelChannelSelectSubmitted,
      )
    19 -> decode.map(file_upload_submission_decoder(), LabelFileUploadSubmitted)
    _ ->
      decode.failure(
        LabelStringSelectSubmitted(StringSelectExecution("", [], None)),
        "SubmittedLabelComponent",
      )
  }
}

@internal
pub fn command_execution_decoder() -> decode.Decoder(CommandExecution) {
  use command_type <- decode.subfield(["data", "type"], decode.int)
  case command_type {
    1 -> decode.map(slash_command_execution_decoder(), SlashCommandExecuted)
    2 -> decode.map(user_command_execution_decoder(), UserCommandExecuted)
    3 -> decode.map(message_command_execution_decoder(), MessageCommandExecuted)
    _ ->
      decode.failure(
        SlashCommandExecuted(SlashCommandExecution("", "", None, [], None)),
        "CommandExecution",
      )
  }
}

@internal
pub fn button_execution_decoder() -> decode.Decoder(ButtonExecution) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )

  decode.success(ButtonExecution(custom_id:, resolved:))
}

@internal
pub fn string_select_execution_decoder() -> decode.Decoder(
  StringSelectExecution,
) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )
  use selected_values <- decode.field("values", decode.list(decode.string))
  decode.success(StringSelectExecution(custom_id:, selected_values:, resolved:))
}

@internal
pub fn user_select_execution_decoder() -> decode.Decoder(UserSelectExecution) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )
  use selected_values <- decode.field("values", decode.list(decode.string))
  decode.success(UserSelectExecution(
    custom_id:,
    selected_users_ids: selected_values,
    resolved:,
  ))
}

@internal
pub fn role_select_execution_decoder() -> decode.Decoder(RoleSelectExecution) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )
  use selected_values <- decode.field("values", decode.list(decode.string))
  decode.success(RoleSelectExecution(
    custom_id:,
    selected_roles_ids: selected_values,
    resolved:,
  ))
}

@internal
pub fn mentionable_select_execution_decoder() -> decode.Decoder(
  MentionableSelectExecution,
) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )
  use selected_values <- decode.field("values", decode.list(decode.string))
  decode.success(MentionableSelectExecution(
    custom_id:,
    selected_mentionables_ids: selected_values,
    resolved:,
  ))
}

@internal
pub fn channel_select_execution_decoder() -> decode.Decoder(
  ChannelSelectExecution,
) {
  use custom_id <- decode.field("custom_id", decode.string)
  use resolved <- decode.optional_field(
    "resolved",
    None,
    decode.optional(resolved_decoder()),
  )
  use selected_values <- decode.field("values", decode.list(decode.string))
  decode.success(ChannelSelectExecution(
    custom_id:,
    selected_channels_ids: selected_values,
    resolved:,
  ))
}

@internal
pub fn message_component_execution_decoder() -> decode.Decoder(
  MessageComponentExecution,
) {
  use component_type <- decode.field("component_type", decode.int)

  case component_type {
    2 -> decode.map(button_execution_decoder(), ButtonExecuted)
    3 -> decode.map(string_select_execution_decoder(), StringSelectExecuted)
    5 -> decode.map(user_select_execution_decoder(), UserSelectExecuted)
    6 -> decode.map(role_select_execution_decoder(), RoleSelectExecuted)
    7 ->
      decode.map(
        mentionable_select_execution_decoder(),
        MentionableSelectExecuted,
      )
    8 -> decode.map(channel_select_execution_decoder(), ChannelSelectExecuted)
    _ ->
      decode.failure(
        ButtonExecuted(ButtonExecution("", None)),
        "MessageComponentExecution",
      )
  }
}

@internal
pub fn slash_command_execution_decoder() -> decode.Decoder(
  SlashCommandExecution,
) {
  use command_id <- decode.subfield(["data", "id"], decode.string)
  use command_name <- decode.subfield(["data", "name"], decode.string)
  use resolved <- decode.then(decode.optionally_at(
    ["data", "resolved"],
    None,
    decode.optional(resolved_decoder()),
  ))
  use options <- decode.then(decode.optionally_at(
    ["data", "options"],
    [],
    decode.list(of: slash_command_option_decoder()),
  ))
  use registered_to_guild_id <- decode.then(decode.optionally_at(
    ["data", "guild_id"],
    None,
    decode.optional(decode.string),
  ))
  decode.success(SlashCommandExecution(
    command_id:,
    command_name:,
    resolved:,
    options:,
    registered_to_guild_id:,
  ))
}

@internal
pub fn context_decoder() -> decode.Decoder(Context) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(TriggeredInGuild)
    1 -> decode.success(TriggeredInBotDms)
    2 -> decode.success(TriggeredInPrivateChannel)
    _ -> decode.failure(TriggeredInGuild, "Context")
  }
}

@internal
pub fn invokement_info_decoder() -> decode.Decoder(InvokementInfo) {
  let in_guild_decoder = {
    use guild <- decode.field("guild", guild.decoder())
    use guild_id <- decode.field("guild_id", decode.string)
    use member <- decode.field("member", guild_member.decoder())
    use guild_locale <- decode.field("guild_locale", decode.string)

    decode.success(InvokedInGuild(guild:, guild_id:, member:, guild_locale:))
  }
  let in_dm_decoder = {
    use user <- decode.field("user", user.decoder())
    decode.success(InvokedInDm(user:))
  }

  decode.one_of(in_guild_decoder, or: [in_dm_decoder])
}

@internal
pub fn slash_command_option_decoder() -> decode.Decoder(SlashCommandOption) {
  use name <- decode.field("name", decode.string)
  use type_ <- decode.field("type", decode.int)
  use is_focused <- decode.optional_field("focused", False, decode.bool)

  case type_ {
    1 | 2 -> {
      use options <- decode.field(
        "options",
        decode.list(of: slash_command_option_decoder()),
      )
      case type_ {
        1 -> decode.success(SubCommandSlashCommandOption(name:, options:))
        2 -> decode.success(SubCommandGroupSlashCommandOption(name:, options:))
        _ ->
          decode.failure(
            SubCommandSlashCommandOption("", []),
            "SlashCommandOption",
          )
      }
    }
    3 -> {
      use value <- decode.field("value", decode.string)
      decode.success(StringSlashCommandOption(name:, value:, is_focused:))
    }
    4 -> {
      use value <- decode.field("value", decode.int)
      decode.success(IntegerSlashCommandOption(name:, value:, is_focused:))
    }
    5 -> {
      use value <- decode.field("value", decode.bool)
      decode.success(BoolSlashCommandOption(name:, value:, is_focused:))
    }
    6 | 7 | 8 | 9 | 11 -> {
      use id <- decode.field("value", decode.string)
      case type_ {
        6 ->
          decode.success(UserSlashCommandOption(name:, user_id: id, is_focused:))
        7 ->
          decode.success(ChannelSlashCommandOption(
            name:,
            channel_id: id,
            is_focused:,
          ))
        8 ->
          decode.success(RoleSlashCommandOption(name:, role_id: id, is_focused:))
        9 ->
          decode.success(MentionableSlashCommandOption(
            name:,
            mentionable_id: id,
            is_focused:,
          ))
        11 ->
          decode.success(AttachmentSlashCommandOption(
            name:,
            attachment_id: id,
            is_focused:,
          ))
        _ ->
          decode.failure(
            SubCommandSlashCommandOption("", []),
            "SlashCommandOption",
          )
      }
    }
    10 -> {
      use value <- decode.field("value", decode.float)
      decode.success(NumberSlashCommandOption(name:, value:, is_focused:))
    }
    _ ->
      decode.failure(SubCommandSlashCommandOption("", []), "SlashCommandOption")
  }
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
  use roles <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.dict(decode.string, role.decoder())),
  )
  use channels <- decode.optional_field(
    "channels",
    None,
    decode.optional(decode.dict(decode.string, resolved_channel_decoder())),
  )
  use messages <- decode.optional_field(
    "messages",
    None,
    decode.optional(decode.dict(decode.string, message.decoder())),
  )
  use attachments <- decode.optional_field(
    "attachments",
    None,
    decode.optional(decode.dict(decode.string, attachment.decoder())),
  )

  decode.success(Resolved(
    users:,
    members:,
    roles:,
    channels:,
    messages:,
    attachments:,
  ))
}

@internal
pub fn resolved_channel_decoder() -> decode.Decoder(ResolvedChannel) {
  use type_ <- decode.field("type", decode.int)
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use current_user_permissions <- decode.field(
    "permissions",
    permission.decoder(),
  )

  case type_ {
    0 ->
      decode.success(ResolvedTextChannel(id:, name:, current_user_permissions:))
    2 ->
      decode.success(ResolvedVoiceChannel(id:, name:, current_user_permissions:))
    4 ->
      decode.success(ResolvedCategoryChannel(
        id:,
        name:,
        current_user_permissions:,
      ))
    5 ->
      decode.success(ResolvedAnnouncementChannel(
        id:,
        name:,
        current_user_permissions:,
      ))
    10 | 11 | 12 -> {
      use metadata <- decode.field("thread_metadata", thread.metadata_decoder())
      use parent_id <- decode.field("parent_id", decode.string)
      case type_ {
        10 ->
          decode.success(ResolvedAnnouncementThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        11 ->
          decode.success(ResolvedPublicThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        12 ->
          decode.success(ResolvedPrivateThread(
            id:,
            name:,
            current_user_permissions:,
            metadata:,
            parent_id:,
          ))
        _ -> decode.failure(ResolvedTextChannel("", "", []), "ResolvedChannel")
      }
    }
    13 ->
      decode.success(ResolvedStageChannel(id:, name:, current_user_permissions:))
    15 ->
      decode.success(ResolvedForumChannel(id:, name:, current_user_permissions:))
    16 ->
      decode.success(ResolvedMediaChannel(id:, name:, current_user_permissions:))
    _ -> decode.failure(ResolvedTextChannel("", "", []), "ResolvedChannel")
  }
}

@internal
pub fn user_command_execution_decoder() -> decode.Decoder(UserCommandExecution) {
  use command_id <- decode.subfield(["data", "id"], decode.string)
  use command_name <- decode.subfield(["data", "name"], decode.string)
  use registered_to_guild_id <- decode.then(decode.optionally_at(
    ["data", "guild_id"],
    None,
    decode.optional(decode.string),
  ))
  use user_id <- decode.subfield(["data", "target_id"], decode.string)
  use resolved <- decode.then(decode.optionally_at(
    ["data", "resolved"],
    None,
    decode.optional(resolved_decoder()),
  ))

  decode.success(UserCommandExecution(
    command_id:,
    command_name:,
    resolved:,
    registered_to_guild_id:,
    user_id:,
  ))
}

@internal
pub fn message_command_execution_decoder() -> decode.Decoder(
  MessageCommandExecution,
) {
  use command_id <- decode.subfield(["data", "id"], decode.string)
  use command_name <- decode.subfield(["data", "name"], decode.string)
  use registered_to_guild_id <- decode.then(decode.optionally_at(
    ["data", "guild_id"],
    None,
    decode.optional(decode.string),
  ))
  use message_id <- decode.subfield(["data", "target_id"], decode.string)
  use resolved <- decode.then(decode.optionally_at(
    ["data", "resolved"],
    None,
    decode.optional(resolved_decoder()),
  ))
  decode.success(MessageCommandExecution(
    command_id:,
    command_name:,
    resolved:,
    registered_to_guild_id:,
    message_id:,
  ))
}

@internal
pub fn response_decoder() -> decode.Decoder(Response) {
  use type_ <- decode.field("type", decode.int)
  use data <- decode.optional_field(
    "data",
    None,
    decode.optional(case type_ {
      4 ->
        decode.map(
          response_message_decoder(),
          RespondWithChannelMessageWithSource,
        )
      5 ->
        decode.map(
          response_message_decoder(),
          RespondWithDeferredChannelMessageWithSource,
        )
      7 -> decode.map(response_message_decoder(), RespondWithUpdateMessage)
      _ -> decode.failure(RespondWithDeferredUpdateMessage, "Response")
    }),
  )

  case data {
    Some(data) -> decode.success(data)
    None ->
      case type_ {
        6 -> decode.success(RespondWithDeferredUpdateMessage)
        _ -> decode.failure(RespondWithDeferredUpdateMessage, "Response")
      }
  }
}

@internal
pub fn response_message_decoder() -> decode.Decoder(ResponseMessage) {
  use is_tts <- decode.optional_field("tts", None, decode.optional(decode.bool))
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.string),
  )
  use embeds <- decode.optional_field(
    "embed",
    None,
    decode.optional(decode.list(of: embed.decoder())),
  )
  use allowed_mentions <- decode.optional_field(
    "allowed_mentions",
    None,
    decode.optional(allowed_mentions.decoder()),
  )
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(bits_response_message_flags())),
  )
  use components <- decode.optional_field(
    "components",
    None,
    decode.optional(decode.list(of: message.component_decoder())),
  )
  use attachments <- decode.optional_field(
    "attachments",
    None,
    decode.optional(decode.list(of: attachment.create_decoder())),
  )
  use poll <- decode.optional_field(
    "poll",
    None,
    decode.optional(poll.create_decoder()),
  )

  decode.success(ResponseMessage(
    is_tts:,
    content:,
    embeds:,
    allowed_mentions:,
    flags:,
    components:,
    attachments:,
    files: None,
    poll:,
  ))
}

@internal
pub fn autocomplete_response_decoder() -> decode.Decoder(AutocompleteResponse) {
  use choices <- decode.field("choices", decode.list(of: choice.decoder()))
  decode.success(AutocompleteResponse(choices:))
}

@internal
pub fn modal_response_decoder() -> decode.Decoder(ModalResponse) {
  use custom_id <- decode.field("custom_id", decode.string)
  use title <- decode.field("title", decode.string)
  use components <- decode.field(
    "components",
    decode.list(of: modal.component_decoder()),
  )

  decode.success(ModalResponse(custom_id:, title:, components:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn response_to_json(response: Response) -> Json {
  let type_ = [
    #("type", case response {
      RespondWithChannelMessageWithSource(..) -> json.int(4)
      RespondWithDeferredChannelMessageWithSource(..) -> json.int(5)
      RespondWithDeferredUpdateMessage -> json.int(6)
      RespondWithUpdateMessage(..) -> json.int(7)
      RespondWithApplicationCommandAutocompleteResult(..) -> json.int(8)
      RespondWithModal(..) -> json.int(9)
    }),
  ]

  let data = case response {
    RespondWithChannelMessageWithSource(message) -> [
      #("data", response_message_to_json(message)),
    ]
    RespondWithDeferredChannelMessageWithSource(message) -> [
      #("data", response_message_to_json(message)),
    ]
    RespondWithDeferredUpdateMessage -> []
    RespondWithUpdateMessage(message) -> [
      #("data", response_message_to_json(message)),
    ]
    RespondWithApplicationCommandAutocompleteResult(autocomplete) -> [
      #("data", autocomplete_response_to_json(autocomplete)),
    ]
    RespondWithModal(modal) -> [#("data", modal_response_to_json(modal))]
  }

  [type_, data]
  |> list.flatten
  |> json.object
}

@internal
pub fn response_message_to_json(message: ResponseMessage) -> Json {
  let is_tts = case message.is_tts {
    Some(tts) -> [#("tts", json.bool(tts))]
    None -> []
  }

  let content = case message.content {
    Some(content) -> [#("content", json.string(content))]
    None -> []
  }

  let embeds = case message.embeds {
    Some(embeds) -> [#("embeds", json.array(embeds, embed.to_json))]
    None -> []
  }

  let allowed_mentions = case message.allowed_mentions {
    Some(allowed_mentions) -> [
      #("allowed_mentions", allowed_mentions.to_json(allowed_mentions)),
    ]
    None -> []
  }

  let flags = case message.flags {
    Some(flags) -> [
      #("flags", flags.to_json(flags, bits_response_message_flags())),
    ]
    None -> []
  }

  let components = case message.components {
    Some(components) -> [
      #("components", json.array(components, message.component_to_json)),
    ]
    None -> []
  }

  let attachment = case message.attachments {
    Some(attachments) -> [
      #("attachments", json.array(attachments, attachment.create_to_json)),
    ]
    None -> []
  }

  let poll = case message.poll {
    Some(poll) -> [#("poll", poll.create_to_json(poll))]
    None -> []
  }

  [
    is_tts,
    content,
    embeds,
    allowed_mentions,
    flags,
    components,
    attachment,
    poll,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn autocomplete_response_to_json(autocomplete: AutocompleteResponse) -> Json {
  json.object([
    #(
      "choices",
      json.array(autocomplete.choices, todo as "app command choice to json"),
    ),
  ])
}

@internal
pub fn modal_response_to_json(modal: ModalResponse) {
  json.object([
    #("custom_id", json.string(modal.custom_id)),
    #("title", json.string(modal.title)),
    #("components", json.array(modal.components, modal.component_to_json)),
  ])
}

@internal
pub fn modify_original_response_to_json(modify: ModifyOriginalResponse) {
  [
    modification.to_json(modify.content, "content", json.string),
    modification.to_json(modify.embeds, "embeds", json.array(_, embed.to_json)),
    modification.to_json(modify.flags, "flags", flags.to_json(
      _,
      bits_modify_original_response_flags(),
    )),
    modification.to_json(modify.components, "components", json.array(
      _,
      message.component_to_json,
    )),
    modification.to_json(modify.attachments, "attachments", json.array(
      _,
      attachment.create_to_json,
    )),
    modification.to_json(modify.poll, "poll", poll.create_to_json),
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn followup_to_json(followup: Followup) -> Json {
  let content = case followup.content {
    Some(content) -> [#("content", json.string(content))]
    None -> []
  }

  let is_tts = [#("tts", json.bool(followup.is_tts))]

  let embeds = case followup.embeds {
    Some(embeds) -> [#("embeds", json.array(embeds, embed.to_json))]
    None -> []
  }

  let allowed_mentions = case followup.allowed_mentions {
    Some(allowed_mentions) -> [
      #("allowed_mentions", allowed_mentions.to_json(allowed_mentions)),
    ]
    None -> []
  }

  let components = case followup.components {
    Some(components) -> [
      #("components", json.array(components, message.component_to_json)),
    ]
    None -> []
  }

  let attachments = case followup.attachments {
    Some(attachments) -> [
      #("attachments", json.array(attachments, attachment.create_to_json)),
    ]
    None -> []
  }

  let flags = case followup.flags {
    Some(flags) -> [#("flags", flags.to_json(flags, bits_followup_flags()))]
    None -> []
  }

  let poll = case followup.poll {
    Some(poll) -> [#("poll", poll.create_to_json(poll))]
    None -> []
  }

  [
    content,
    is_tts,
    embeds,
    allowed_mentions,
    components,
    attachments,
    flags,
    poll,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_followup_to_json(modify: ModifyFollowup) -> Json {
  [
    modification.to_json(modify.content, "content", json.string),
    modification.to_json(modify.embeds, "embeds", json.array(_, embed.to_json)),
    modification.to_json(modify.flags, "flags", flags.to_json(
      _,
      bits_modify_followup_flags(),
    )),
    modification.to_json(modify.components, "components", json.array(
      _,
      message.component_to_json,
    )),
    modification.to_json(modify.attachments, "attachments", json.array(
      _,
      attachment.create_to_json,
    )),
    modification.to_json(modify.poll, "poll", poll.create_to_json),
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn respond(
  client: grom.Client,
  to interaction: Interaction,
  using response: Response,
) -> Result(Nil, grom.Error) {
  let json = response |> response_to_json

  let path =
    "/interactions/"
    <> interaction.id
    <> "/"
    <> interaction.token
    <> "/callback"

  let multipart_request = rest.new_multipart_request(
    client,
    http.Post,
    path,
    json,
    _,
  )

  let non_multipart_request =
    client
    |> rest.new_request(http.Post, path)
    |> request.set_body(json |> json.to_string |> bit_array.from_string)

  let request = case response {
    RespondWithChannelMessageWithSource(message) -> {
      case message.files {
        Some(files) -> multipart_request(files)
        None -> non_multipart_request
      }
    }
    RespondWithUpdateMessage(message) -> {
      case message.files {
        Some(files) -> multipart_request(files)
        None -> non_multipart_request
      }
    }
    _ -> non_multipart_request
  }

  rest.execute_bytes(request)
  |> result.replace(Nil)
}

pub fn get_original_response(
  client: grom.Client,
  for interaction: Interaction,
) -> Result(Response, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/webhooks/"
        <> interaction.application_id
        <> "/"
        <> interaction.token
        <> "/messages/@original",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: response_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_original_response(
  client: grom.Client,
  of interaction: Interaction,
  using modify: ModifyOriginalResponse,
) -> Result(Message, grom.Error) {
  let json = modify |> modify_original_response_to_json

  let path =
    "/webhooks/"
    <> interaction.application_id
    <> "/"
    <> interaction.token
    <> "/messages/@original"

  let multipart_request = rest.new_multipart_request(
    client,
    http.Patch,
    path,
    json,
    _,
  )

  let non_multipart_request =
    rest.new_request(client, http.Patch, path)
    |> request.set_body(json |> json.to_string |> bit_array.from_string)

  let request = case modify.files {
    modification.New(files) -> multipart_request(files)
    _ -> non_multipart_request
  }

  use response <- result.try(rest.execute_bytes(request))

  response.body
  |> json.parse(using: message.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify_original_response() -> ModifyOriginalResponse {
  ModifyOriginalResponse(Skip, Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn delete_original_response(
  client: grom.Client,
  of interaction: Interaction,
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/webhooks/"
      <> interaction.application_id
      <> "/"
      <> interaction.token
      <> "/messages/@original",
  )
  |> rest.execute
  |> result.replace(Nil)
}

/// Do not use this function to send a message after deferring it.
/// Use [`modify_original_response`](#modify_original_response) instead.
pub fn followup(
  client: grom.Client,
  to interaction: Interaction,
  using followup: Followup,
) -> Result(Message, grom.Error) {
  let json = followup |> followup_to_json

  let path =
    "/webhooks/" <> interaction.application_id <> "/" <> interaction.token

  let multipart_request = rest.new_multipart_request(
    client,
    http.Post,
    path,
    json,
    _,
  )

  let non_multipart_request =
    rest.new_request(client, http.Post, path)
    |> request.set_body(json |> json.to_string |> bit_array.from_string)

  let request = case followup.files {
    Some(files) -> multipart_request(files)
    None -> non_multipart_request
  }

  use response <- result.try(rest.execute_bytes(request))

  response.body
  |> json.parse(using: message.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_followup() -> Followup {
  Followup(None, False, None, None, None, None, None, None, None)
}

pub fn get_followup(
  client: grom.Client,
  for interaction: Interaction,
  id message_id: String,
) -> Result(Message, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/webhooks/"
        <> interaction.application_id
        <> "/"
        <> interaction.token
        <> "/messages/"
        <> message_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: message.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_followup(
  client: grom.Client,
  for interaction: Interaction,
  id message_id: String,
  using modify: ModifyFollowup,
) -> Result(Message, grom.Error) {
  let json = modify |> modify_followup_to_json

  let path =
    "/webhooks/"
    <> interaction.application_id
    <> "/"
    <> interaction.token
    <> "/messages/"
    <> message_id

  let multipart_request = rest.new_multipart_request(
    client,
    http.Patch,
    path,
    json,
    _,
  )

  let non_multipart_request =
    rest.new_request(client, http.Patch, path)
    |> request.set_body(json |> json.to_string |> bit_array.from_string)

  let request = case modify.files {
    modification.New(files) -> multipart_request(files)
    _ -> non_multipart_request
  }

  use response <- result.try(rest.execute_bytes(request))

  response.body
  |> json.parse(using: message.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify_followup() -> ModifyFollowup {
  ModifyFollowup(Skip, Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn delete_followup(
  client: grom.Client,
  of interaction: Interaction,
  id message_id: String,
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(
    http.Delete,
    "/webhooks/"
      <> interaction.application_id
      <> "/"
      <> interaction.token
      <> "/messages/"
      <> message_id,
  )
  |> rest.execute
  |> result.replace(Nil)
}
