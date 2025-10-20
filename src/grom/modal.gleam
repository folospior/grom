import grom/component/channel_select.{type ChannelSelect}
import grom/component/label.{type Label}
import grom/component/mentionable_select.{type MentionableSelect}
import grom/component/role_select.{type RoleSelect}
import grom/component/string_select.{type StringSelect}
import grom/component/text_display.{type TextDisplay}
import grom/component/text_input.{type TextInput}
import grom/component/user_select.{type UserSelect}

// TYPES -----------------------------------------------------------------------

pub type Component {
  StringSelect(StringSelect)
  TextInput(TextInput)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
  ChannelSelect(ChannelSelect)
  TextDisplay(TextDisplay)
  Label(Label)
}
