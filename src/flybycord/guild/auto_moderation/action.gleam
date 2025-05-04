import flybycord/internal/time_duration
import gleam/dynamic/decode
import gleam/option.{type Option, None}
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
  Metadata(
    channel_id: Option(String),
    duration: Option(Duration),
    custom_message: Option(String),
  )
}

// TYPES -----------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Action) {
  use type_ <- decode.field("type", type_decoder())
  use metadata <- decode.field("metadata", decode.optional(metadata_decoder()))
  decode.success(Action(type_:, metadata:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(BlockMessage)
    2 -> decode.success(SendAlertMessage)
    3 -> decode.success(Timeout)
    4 -> decode.success(BlockMemberInteraction)
    _ -> decode.failure(BlockMessage, "Type")
  }
}

@internal
pub fn metadata_decoder() -> decode.Decoder(Metadata) {
  use channel_id <- decode.optional_field(
    "channel_id",
    None,
    decode.optional(decode.string),
  )
  use duration <- decode.field(
    "duration",
    decode.optional(time_duration.from_int_seconds_decoder()),
  )
  use custom_message <- decode.field(
    "custom_message",
    decode.optional(decode.string),
  )
  decode.success(Metadata(channel_id:, duration:, custom_message:))
}
