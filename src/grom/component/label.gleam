import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/component/channel_select.{type ChannelSelect}
import grom/component/checkbox.{type Checkbox}
import grom/component/checkbox_group.{type CheckboxGroup}
import grom/component/file_upload.{type FileUpload}
import grom/component/mentionable_select.{type MentionableSelect}
import grom/component/radio_group.{type RadioGroup}
import grom/component/role_select.{type RoleSelect}
import grom/component/string_select.{type StringSelect}
import grom/component/text_input.{type TextInput}
import grom/component/user_select.{type UserSelect}

// TYPES -----------------------------------------------------------------------

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
  FileUpload(FileUpload)
  RadioGroup(RadioGroup)
  CheckboxGroup(CheckboxGroup)
  Checkbox(Checkbox)
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(label: Label) -> Json {
  let type_ = [#("type", json.int(18))]

  let id = case label.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let description = case label.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let label_ = [#("label", json.string(label.label))]

  let component = [#("component", component_to_json(label.component))]

  [type_, id, description, label_, component]
  |> list.flatten
  |> json.object
}

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    TextInput(text_input) -> text_input.to_json(text_input)
    StringSelect(string_select) -> string_select.to_json(string_select)
    UserSelect(user_select) -> user_select.to_json(user_select)
    RoleSelect(role_select) -> role_select.to_json(role_select)
    MentionableSelect(mentionable_select) ->
      mentionable_select.to_json(mentionable_select)
    ChannelSelect(channel_select) -> channel_select.to_json(channel_select)
    FileUpload(file_upload) -> file_upload.to_json(file_upload)
    RadioGroup(radio_group) -> radio_group.to_json(radio_group)
    CheckboxGroup(checkbox_group) -> checkbox_group.to_json(checkbox_group)
    Checkbox(checkbox) -> checkbox.to_json(checkbox)
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(labeled label: String, containing component: Component) -> Label {
  Label(None, label, None, component)
}
