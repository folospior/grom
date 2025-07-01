import gleam/dict.{type Dict}
import gleam/option.{type Option}
import grom/application
import grom/channel.{type Channel}
import grom/entitlement.{type Entitlement}
import grom/guild.{type Guild}
import grom/interaction/application_command
import grom/interaction/context_type.{type ContextType}
import grom/interaction/resolved.{type Resolved}
import grom/message.{type Message}
import grom/message/component.{type Component}
import grom/permission.{type Permission}
import grom/user.{type User}

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
    member: Option(guild.Member),
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
  StringSelectData(
    custom_id: String,
    values: List(String),
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
