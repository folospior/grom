import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/component/channel_select.{type ChannelSelect}
import grom/component/file_upload.{type FileUpload}
import grom/component/mentionable_select.{type MentionableSelect}
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
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Label) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use label <- decode.field("label", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use component <- decode.field("component", component_decoder())
  decode.success(Label(id:, label:, description:, component:))
}

@internal
pub fn component_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    3 -> decode.map(string_select.decoder(), StringSelect)
    4 -> decode.map(text_input.decoder(), TextInput)
    5 -> decode.map(user_select.decoder(), UserSelect)
    6 -> decode.map(role_select.decoder(), RoleSelect)
    7 -> decode.map(mentionable_select.decoder(), MentionableSelect)
    8 -> decode.map(channel_select.decoder(), ChannelSelect)
    19 -> decode.map(file_upload.decoder(), FileUpload)
    _ -> decode.failure(FileUpload(file_upload.new("")), "Component")
  }
}

// ENCODERS --------------------------------------------------------------------

pub fn to_json(label: Label) -> Json {
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

  [id, description, label_, component]
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
  }
}
