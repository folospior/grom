import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type CommandOptionChoice {
  CommandOptionChoice(
    name: String,
    name_localizations: Option(Dict(String, String)),
    value: ValueType,
  )
}

pub type ValueType {
  String
  Integer
  Float
}
