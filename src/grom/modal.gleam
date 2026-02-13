import gleam/json.{type Json}
import grom/component/channel_select.{type ChannelSelect}
import grom/component/file_upload.{type FileUpload}
import grom/component/label.{type Label}
import grom/component/mentionable_select.{type MentionableSelect}
import grom/component/radio_group.{type RadioGroup}
import grom/component/role_select.{type RoleSelect}
import grom/component/string_select.{type StringSelect}
import grom/component/text_display.{type TextDisplay}
import grom/component/text_input.{type TextInput}
import grom/component/user_select.{type UserSelect}

// TYPES -----------------------------------------------------------------------

/// It is suggested that you wrap all components in Labels.
/// (except for TextDisplays and Labels)
pub type Component {
  StringSelect(StringSelect)
  TextInput(TextInput)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
  ChannelSelect(ChannelSelect)
  FileUpload(FileUpload)
  TextDisplay(TextDisplay)
  Label(Label)
  RadioGroup(RadioGroup)
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    StringSelect(string_select) -> string_select.to_json(string_select)
    TextInput(text_input) -> text_input.to_json(text_input)
    UserSelect(user_select) -> user_select.to_json(user_select)
    RoleSelect(role_select) -> role_select.to_json(role_select)
    MentionableSelect(mentionable_select) ->
      mentionable_select.to_json(mentionable_select)
    ChannelSelect(channel_select) -> channel_select.to_json(channel_select)
    FileUpload(file_upload) -> file_upload.to_json(file_upload)
    TextDisplay(text_display) -> text_display.to_json(text_display)
    Label(label) -> label.to_json(label)
    RadioGroup(radio_group) -> radio_group.to_json(radio_group)
  }
}
