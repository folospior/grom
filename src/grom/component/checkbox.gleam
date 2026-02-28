import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type Checkbox {
  Checkbox(
    id: Option(Int),
    custom_id: String,
    /// Defaults to False.
    is_default_selected: Bool,
  )
}

@internal
pub fn to_json(checkbox: Checkbox) -> Json {
  let type_ = [#("type", json.int(23))]

  let id = case checkbox.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(checkbox.custom_id))]

  let is_default_selected = [
    #("default", json.bool(checkbox.is_default_selected)),
  ]

  [type_, id, custom_id, is_default_selected]
  |> list.flatten
  |> json.object
}

pub fn new(custom_id custom_id: String) -> Checkbox {
  Checkbox(None, custom_id, False)
}
