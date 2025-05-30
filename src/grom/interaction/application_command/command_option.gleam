//// This module has been named `command_option`, because `option` is a Gleam standard library module.
//// So has its underlying type.
//// This deviates from grom's naming convention.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/channel
import grom/interaction/application_command/choice.{type Choice}

// TYPES -----------------------------------------------------------------------

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
    choices: List(Choice),
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
    choices: List(Choice),
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
    choices: List(Choice),
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

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(CommandOption) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    1 -> sub_command_decoder()
    2 -> sub_command_group_decoder()
    3 -> string_decoder()
    4 -> integer_decoder()
    5 -> boolean_decoder()
    6 -> user_decoder()
    7 -> channel_decoder()
    8 -> role_decoder()
    9 -> mentionable_decoder()
    10 -> number_decoder()
    11 -> attachment_decoder()
    _ -> decode.failure(SubCommand("", None, "", None, []), "CommandOption")
  }
}

fn sub_command_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use options <- decode.field("options", decode.list(decoder()))
  decode.success(SubCommand(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    options:,
  ))
}

fn sub_command_group_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use options <- decode.field("options", decode.list(decoder()))
  decode.success(SubCommmandGroup(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    options:,
  ))
}

fn string_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)
  use choices <- decode.field("choices", decode.list(choice.decoder()))
  use min_length <- decode.field("min_length", decode.optional(decode.int))
  use max_length <- decode.field("max_length", decode.optional(decode.int))
  use is_autocomplete <- decode.field("autocomplete", decode.bool)

  decode.success(String(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_length:,
    max_length:,
    is_autocomplete:,
  ))
}

fn integer_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)
  use choices <- decode.field("choices", decode.list(choice.decoder()))
  use min_value <- decode.field("min_value", decode.optional(decode.int))
  use max_value <- decode.field("max_value", decode.optional(decode.int))
  use is_autocomplete <- decode.field("autocomplete", decode.bool)

  decode.success(Integer(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_value:,
    max_value:,
    is_autocomplete:,
  ))
}

fn number_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)
  use choices <- decode.field("choices", decode.list(choice.decoder()))
  use min_value <- decode.field("min_value", decode.optional(decode.float))
  use max_value <- decode.field("max_value", decode.optional(decode.float))
  use is_autocomplete <- decode.field("autocomplete", decode.bool)

  decode.success(Number(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
    choices:,
    min_value:,
    max_value:,
    is_autocomplete:,
  ))
}

fn boolean_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(Boolean(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

fn user_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(User(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

fn channel_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use channel_types <- decode.field(
    "channel_types",
    decode.list(channel.type_decoder()),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(Channel(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    channel_types:,
    is_required:,
  ))
}

fn role_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(Role(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

fn mentionable_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(Mentionable(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}

fn attachment_decoder() -> decode.Decoder(CommandOption) {
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)

  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use is_required <- decode.field("required", decode.bool)

  decode.success(Attachment(
    name:,
    name_localizations:,
    description:,
    description_localizations:,
    is_required:,
  ))
}
