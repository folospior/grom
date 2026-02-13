import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option as GOption, None, Some}

pub type RadioGroup {
  RadioGroup(
    id: GOption(Int),
    custom_id: String,
    options: List(Option),
    /// Defaults to True.
    is_required: Bool,
  )
}

pub type Option {
  Option(
    /// Dev facing value, max 100 characters
    value: String,
    /// User facing text, max 100 characters
    label: String,
    /// Max 100 characters
    description: GOption(String),
    is_default_selected: Bool,
  )
}

@internal
pub fn to_json(group: RadioGroup) -> Json {
  let type_ = [#("type", json.int(21))]

  let id = case group.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(group.custom_id))]

  let options = [#("options", json.array(group.options, option_to_json))]

  let is_required = [#("required", json.bool(group.is_required))]

  [type_, id, custom_id, options, is_required]
  |> list.flatten
  |> json.object
}

fn option_to_json(option: Option) -> Json {
  let value = [#("value", json.string(option.value))]

  let label = [#("label", json.string(option.label))]

  let description = case option.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let is_default_selected = [
    #("default", json.bool(option.is_default_selected)),
  ]

  [value, label, description, is_default_selected]
  |> list.flatten
  |> json.object
}

pub fn new(
  custom_id custom_id: String,
  options options: List(Option),
) -> RadioGroup {
  RadioGroup(None, custom_id, options, True)
}

pub fn new_option(named label: String, value value: String) -> Option {
  Option(value, label, None, False)
}
