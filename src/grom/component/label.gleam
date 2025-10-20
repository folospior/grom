import gleam/option.{type Option}
import grom/component/channel_select.{type ChannelSelect}
import grom/component/mentionable_select.{type MentionableSelect}
import grom/component/role_select.{type RoleSelect}
import grom/component/string_select.{type StringSelect}
import grom/component/text_input.{type TextInput}
import grom/component/user_select.{type UserSelect}

pub type Label {
  Label(
    id: Option(Int),
    label: String,
    description: Option(String),
    component: Component,
  )
}

pub type Component {
  TextInput(TextInput)
  StringSelect(StringSelect)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
  ChannelSelect(ChannelSelect)
}
