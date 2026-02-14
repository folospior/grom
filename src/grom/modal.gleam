import gleam/json.{type Json}
import grom/component/label.{type Label}
import grom/component/text_display.{type TextDisplay}

// TYPES -----------------------------------------------------------------------

pub type Component {
  TextDisplay(TextDisplay)
  Label(Label)
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn component_to_json(component: Component) -> Json {
  case component {
    TextDisplay(text_display) -> text_display.to_json(text_display)
    Label(label) -> label.to_json(label)
  }
}
