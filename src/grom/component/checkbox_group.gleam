import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}

pub type CheckboxGroup {
  CheckboxGroup(
    id: option.Option(Int),
    /// 1-100 characters.
    custom_id: String,
    /// Minimum 1, maximum 10.
    options: List(Option),
    /// Defaults to 1. If set to 0, `is_required` must be set to False.
    min_values: option.Option(Int),
    /// Defaults to the count of options.
    max_values: option.Option(Int),
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
    description: option.Option(String),
    is_default_selected: Bool,
  )
}

@internal
pub fn to_json(group: CheckboxGroup) -> Json {
  let id = case group.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let custom_id = [#("custom_id", json.string(group.custom_id))]

  let options = [#("options", json.array(group.options, option_to_json))]

  let min_values = case group.min_values {
    Some(min) -> [#("min_values", json.int(min))]
    None -> []
  }

  let max_values = case group.max_values {
    Some(max) -> [#("max_values", json.int(max))]
    None -> []
  }

  let is_required = [#("required", json.bool(group.is_required))]

  [id, custom_id, options, min_values, max_values, is_required]
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
) -> CheckboxGroup {
  CheckboxGroup(None, custom_id, options, None, None, True)
}

pub fn new_option(named label: String, value value: String) -> Option {
  Option(value, label, None, False)
}
