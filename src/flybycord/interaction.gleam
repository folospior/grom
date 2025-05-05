import flybycord/application
import flybycord/channel.{type Channel}
import flybycord/entitlement.{type Entitlement}
import flybycord/guild.{type Guild}
import flybycord/guild/member.{type Member}
import flybycord/interaction/application_command
import flybycord/interaction/context_type.{type ContextType}
import flybycord/interaction/resolved.{type Resolved}
import flybycord/message.{type Message}
import flybycord/message/component.{type Component}
import flybycord/message/component/select
import flybycord/permission.{type Permission}
import flybycord/user.{type User}
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type Interaction {
  Interaction(
    id: String,
    application_id: String,
    type_: Type,
    data: Option(Data),
    guild: Option(Guild),
    guild_id: Option(String),
    channel: Option(Channel),
    channel_id: Option(String),
    member: Option(Member),
    user: Option(User),
    token: String,
    version: Int,
    message: Option(Message),
    app_permissions: List(Permission),
    locale: Option(String),
    guild_locale: Option(String),
    entitlements: List(Entitlement),
    authorizing_integration_owners: Dict(
      application.InstallationContext,
      String,
    ),
    context: Option(ContextType),
    attachment_size_limit_bytes: Int,
  )
}

pub type Type {
  Ping
  ApplicationCommand
  MessageComponent
  ApplicationCommandAutocomplete
  ModalSubmit
}

pub type Data {
  ApplicationCommandData(
    id: String,
    name: String,
    type_: application_command.Type,
    resolved: Option(Resolved),
    options: Option(List(ApplicationCommandDataOption)),
    guild_id: Option(String),
    target_id: Option(String),
  )
  MessageComponentData(
    custom_id: String,
    component_type: MessageComponentDataComponentType,
    values: List(select.Value),
    resolved: Option(Resolved),
  )
  ModalSubmitData(custom_id: String, components: List(Component))
}

pub type ApplicationCommandDataOption {
  ApplicationCommandDataOption(
    name: String,
    type_: ApplicationCommandDataOptionType,
    value: Option(ApplicationCommandDataOptionValue),
    options: Option(ApplicationCommandDataOption),
    is_focused: Bool,
  )
}

pub type ApplicationCommandDataOptionType {
  SubCommand
  SubCommandGroup
  String
  Integer
  Boolean
  User
  Channel
  Role
  Mentionable
  Number
  Attachment
}

pub type ApplicationCommandDataOptionValue {
  StringValue(String)
  IntValue(Int)
  FloatValue(Float)
  BoolValue(Bool)
}

pub type MessageComponentDataComponentType {
  ActionRow
  Button
  StringSelect
  TextInput
  UserSelect
  RoleSelect
  MentionableSelect
  ChannelSelect
  Section
  TextDisplay
  Thumbnail
  MediaGallery
  File
  Separator
  Container
}
