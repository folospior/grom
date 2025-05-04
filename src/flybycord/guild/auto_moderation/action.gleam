import gleam/option.{type Option}
import gleam/time/duration.{type Duration}

// TYPES -----------------------------------------------------------------------

pub type Action {
  Action(type_: Type, metadata: Option(Metadata))
}

pub type Type {
  BlockMessage
  SendAlertMessage
  Timeout
  BlockMemberInteraction
}

pub type Metadata {
  ActionMetadata(
    channel_id: Option(String),
    duration: Option(Duration),
    custom_message: Option(String),
  )
}
