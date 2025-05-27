import flybycord/message/component/button.{type Button}
import flybycord/message/component/string_select.{type StringSelect}
import flybycord/message/component/text_input.{type TextInput}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type ActionRow {
  ActionRow(id: Option(Int), components: List(Component))
}

pub type Component {
  Button(Button)
  TextInput(TextInput)
  StringSelect(StringSelect)
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
    _ -> todo
  }
}
