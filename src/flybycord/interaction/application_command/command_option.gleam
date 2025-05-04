//// This module has been named `command_option`, because `option` is a Gleam standard library module.
//// So has its underlying type.
//// This deviates from flybycord's naming convention.

import flybycord/channel
import flybycord/interaction/application_command/choice.{type Choice}
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type CommandOption {
  SubCommand(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    options: List(CommandOption),
  )
  SubCommmandGroup(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    options: List(CommandOption),
  )
  String(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(Choice)),
    min_length: Option(Int),
    max_length: Option(Int),
    is_autocomplete: Bool,
  )
  Integer(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(Choice)),
    min_value: Option(Int),
    max_value: Option(Int),
    is_autocomplete: Bool,
  )
  Boolean(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
  User(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
  Channel(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    channel_types: List(channel.Type),
    is_required: Bool,
  )
  Role(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
  Mentionable(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
  Number(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
    choices: Option(List(Choice)),
    min_value: Option(Float),
    max_value: Option(Float),
    is_autocomplete: Bool,
  )
  Attachment(
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
    is_required: Bool,
  )
}
