import flybycord/emoji.{type Emoji}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

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

@internal
pub fn onboarding_decoder() -> decode.Decoder(Onboarding) {
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
