import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import grom/component/button.{type Button}
import grom/component/channel_select.{type ChannelSelect}
import grom/component/mentionable_select.{type MentionableSelect}
import grom/component/role_select.{type RoleSelect}
import grom/component/string_select.{type StringSelect}
import grom/component/text_input.{type TextInput}
import grom/component/user_select.{type UserSelect}

// TYPES -----------------------------------------------------------------------

pub type ActionRow {
  ActionRow(id: Option(Int), components: List(Component))
}

pub type Component {
  Button(Button)
  TextInput(TextInput)
  StringSelect(StringSelect)
  UserSelect(UserSelect)
  RoleSelect(RoleSelect)
  MentionableSelect(MentionableSelect)
  ChannelSelect(ChannelSelect)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(ActionRow) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use components <- decode.field("components", decode.list(component_decoder()))

  decode.success(ActionRow(id:, components:))
}

@internal
pub fn component_decoder() -> decode.Decoder(Component) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    2 -> {
      use button <- decode.then(button.decoder())
      decode.success(Button(button))
    }
    3 -> {
      use string_select <- decode.then(string_select.decoder())
      decode.success(StringSelect(string_select))
    }
    4 -> {
      use text_input <- decode.then(text_input.decoder())
      decode.success(TextInput(text_input))
    }
    5 -> {
      use user_select <- decode.then(user_select.decoder())
      decode.success(UserSelect(user_select))
    }
    6 -> {
      use role_select <- decode.then(role_select.decoder())
      decode.success(RoleSelect(role_select))
    }
    7 -> {
      use mentionable_select <- decode.then(mentionable_select.decoder())
      decode.success(MentionableSelect(mentionable_select))
    }
    8 -> {
      use channel_select <- decode.then(channel_select.decoder())
      decode.success(ChannelSelect(channel_select))
    }
    _ ->
      decode.failure(
        Button(button.Regular(None, False, button.Primary, None, None, "")),
        "Component",
      )
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(action_row: ActionRow) -> Json {
  let type_ = [#("type", json.int(1))]

  let id = case action_row.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let components = [
    #("components", json.array(action_row.components, component_to_json)),
  ]

  [type_, id, components]
  |> list.flatten
  |> json.object
}

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    Button(button) -> button.to_json(button)
    TextInput(text_input) -> text_input.to_json(text_input)
    StringSelect(string_select) -> string_select.to_json(string_select)
    UserSelect(user_select) -> user_select.to_json(user_select)
    RoleSelect(role_select) -> role_select.to_json(role_select)
    MentionableSelect(mentionable_select) ->
      mentionable_select.to_json(mentionable_select)
    ChannelSelect(channel_select) -> channel_select.to_json(channel_select)
  }
}
