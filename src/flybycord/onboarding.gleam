import flybycord/emoji.{type Emoji}
import gleam/option.{type Option}

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
  InvalidMode
}

pub type PromptType {
  MultipleChoice
  Dropdown
  InvalidPromptType
}
