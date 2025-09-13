import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/emoji.{type Emoji}
import grom/internal/rest
import grom/modification.{type Modification, Skip}

// TYPES -----------------------------------------------------------------------

pub type Onboarding {
  Onboarding(
    guild_id: String,
    prompts: List(Prompt),
    default_channel_ids: List(String),
    is_enabled: Bool,
    mode: Mode,
  )
}

pub type Prompt {
  Prompt(
    id: String,
    type_: PromptType,
    options: List(PromptOption),
    title: String,
    is_single_select: Bool,
    is_required: Bool,
    is_in_onboarding: Bool,
  )
}

pub type PromptOption {
  PromptOption(
    id: String,
    channel_ids: List(String),
    role_ids: List(String),
    emoji: Option(Emoji),
    emoji_id: Option(String),
    emoji_name: Option(String),
    is_emoji_animated: Option(Bool),
    title: String,
    description: Option(String),
  )
}

pub type Mode {
  Default
  Advanced
}

pub type PromptType {
  MultipleChoice
  Dropdown
}

pub type Modify {
  Modify(
    prompts: Modification(List(Prompt)),
    default_channel_ids: Modification(List(String)),
    is_enabled: Option(Bool),
    mode: Modification(Mode),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Onboarding) {
  use guild_id <- decode.field("guild_id", decode.string)
  use prompts <- decode.field("prompts", decode.list(prompt_decoder()))
  use default_channel_ids <- decode.field(
    "default_channel_ids",
    decode.list(decode.string),
  )
  use is_enabled <- decode.field("is_enabled", decode.bool)
  use mode <- decode.field("mode", mode_decoder())
  decode.success(Onboarding(
    guild_id:,
    prompts:,
    default_channel_ids:,
    is_enabled:,
    mode:,
  ))
}

@internal
pub fn prompt_decoder() -> decode.Decoder(Prompt) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", prompt_type_decoder())
  use options <- decode.field("options", decode.list(prompt_option_decoder()))
  use title <- decode.field("title", decode.string)
  use is_single_select <- decode.field("single_select", decode.bool)
  use is_required <- decode.field("required", decode.bool)
  use is_in_onboarding <- decode.field("in_onboarding", decode.bool)
  decode.success(Prompt(
    id:,
    type_:,
    options:,
    title:,
    is_single_select:,
    is_required:,
    is_in_onboarding:,
  ))
}

@internal
pub fn prompt_option_decoder() -> decode.Decoder(PromptOption) {
  use id <- decode.field("id", decode.string)
  use channel_ids <- decode.field("channel_ids", decode.list(decode.string))
  use role_ids <- decode.field("role_ids", decode.list(decode.string))
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji.decoder()),
  )
  use emoji_id <- decode.optional_field(
    "emoji_id",
    None,
    decode.optional(decode.string),
  )
  use emoji_name <- decode.optional_field(
    "emoji_name",
    None,
    decode.optional(decode.string),
  )
  use is_emoji_animated <- decode.optional_field(
    "emoji_animated",
    None,
    decode.optional(decode.bool),
  )
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(PromptOption(
    id:,
    channel_ids:,
    role_ids:,
    emoji:,
    emoji_id:,
    emoji_name:,
    is_emoji_animated:,
    title:,
    description:,
  ))
}

@internal
pub fn mode_decoder() -> decode.Decoder(Mode) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Default)
    1 -> decode.success(Advanced)
    _ -> decode.failure(Default, "Mode")
  }
}

@internal
pub fn prompt_type_decoder() -> decode.Decoder(PromptType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(MultipleChoice)
    1 -> decode.success(Dropdown)
    _ -> decode.failure(MultipleChoice, "PromptType")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  json.object(
    [
      modification.encode(modify.prompts, "prompts", json.array(
        _,
        prompt_to_json,
      )),
      modification.encode(
        modify.default_channel_ids,
        "default_channel_ids",
        json.array(_, json.string),
      ),
      case modify.is_enabled {
        Some(enabled) -> [#("enabled", json.bool(enabled))]
        None -> []
      },
      modification.encode(modify.mode, "mode", mode_to_json),
    ]
    |> list.flatten,
  )
}

@internal
pub fn prompt_to_json(prompt: Prompt) -> Json {
  json.object([
    #("id", json.string(prompt.id)),
    #("type", prompt_type_to_json(prompt.type_)),
    #("options", json.array(prompt.options, of: prompt_option_to_json)),
    #("title", json.string(prompt.title)),
    #("single_select", json.bool(prompt.is_single_select)),
    #("required", json.bool(prompt.is_required)),
    #("in_onboarding", json.bool(prompt.is_in_onboarding)),
  ])
}

@internal
pub fn prompt_type_to_json(prompt_type: PromptType) -> Json {
  case prompt_type {
    MultipleChoice -> 0
    Dropdown -> 1
  }
  |> json.int
}

@internal
pub fn prompt_option_to_json(prompt_option: PromptOption) -> Json {
  let id = [#("id", json.string(prompt_option.id))]

  let channel_ids = [
    #("channel_ids", json.array(prompt_option.channel_ids, json.string)),
  ]

  let role_ids = [
    #("role_ids", json.array(prompt_option.role_ids, json.string)),
  ]

  let emoji = case prompt_option.emoji {
    Some(emoji) -> [#("emoji", emoji.to_json(emoji))]
    None -> []
  }

  let emoji_id = case prompt_option.emoji_id {
    Some(id) -> [#("emoji_id", json.string(id))]
    None -> []
  }

  let emoji_name = case prompt_option.emoji_name {
    Some(name) -> [#("emoji_name", json.string(name))]
    None -> []
  }

  let is_emoji_animated = case prompt_option.is_emoji_animated {
    Some(emoji_animated) -> [#("emoji_animated", json.bool(emoji_animated))]
    None -> []
  }

  let title = [#("title", json.string(prompt_option.title))]

  let description = [
    #("description", json.nullable(prompt_option.description, json.string)),
  ]

  [
    id,
    channel_ids,
    role_ids,
    emoji,
    emoji_id,
    emoji_name,
    is_emoji_animated,
    title,
    description,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn mode_to_json(mode: Mode) -> Json {
  case mode {
    Default -> 0
    Advanced -> 1
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: grom.Client,
  for guild_id: String,
) -> Result(Onboarding, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/onboarding")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify(
  client: grom.Client,
  in guild_id: String,
  using modify: Modify,
  because reason: Option(String),
) -> Result(Onboarding, grom.Error) {
  let json = modify |> modify_to_json |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Put, "/guilds/" <> guild_id <> "/onboarding")
    |> rest.with_reason(reason)
    |> request.set_body(json)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify() -> Modify {
  Modify(Skip, Skip, None, Skip)
}
