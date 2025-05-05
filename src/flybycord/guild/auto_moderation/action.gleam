import flybycord/internal/time_duration
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
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
  SendAlertMessageMetadata(channel_id: String)
  TimeoutMetadata(duration: Duration)
  BlockMessageMetadata(custom_message: Option(String))
}

// TYPES -----------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Action) {
  use type_ <- decode.field("type", type_decoder())
  use metadata <- decode.field(
    "metadata",
    decode.optional(metadata_decoder(type_)),
  )
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
pub fn metadata_decoder(type_: Type) -> decode.Decoder(Metadata) {
  case type_ {
    SendAlertMessage -> send_alert_message_metadata_decoder()
    Timeout -> timeout_metadata_decoder()
    BlockMessage -> block_message_metadata_decoder()
    _ -> decode.failure(SendAlertMessageMetadata(""), "Metadata")
  }
}

fn send_alert_message_metadata_decoder() -> decode.Decoder(Metadata) {
  use channel_id <- decode.field("channel_id", decode.string)
  decode.success(SendAlertMessageMetadata(channel_id:))
}

fn timeout_metadata_decoder() -> decode.Decoder(Metadata) {
  use duration <- decode.field(
    "duration_seconds",
    time_duration.from_int_seconds_decoder(),
  )
  decode.success(TimeoutMetadata(duration:))
}

fn block_message_metadata_decoder() -> decode.Decoder(Metadata) {
  use custom_message <- decode.optional_field(
    "custom_message",
    None,
    decode.optional(decode.string),
  )
  decode.success(BlockMessageMetadata(custom_message:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn encode(action: Action) -> Json {
  let metadata = case action.metadata {
    Some(metadata) -> [#("metadata", metadata_encode(metadata))]
    None -> []
  }

  [[#("type", type_encode(action.type_))], metadata]
  |> list.flatten
  |> json.object
}

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    BlockMessage -> 1
    SendAlertMessage -> 2
    Timeout -> 3
    BlockMemberInteraction -> 4
  }
  |> json.int
}

@internal
pub fn metadata_encode(metadata: Metadata) -> Json {
  case metadata {
    SendAlertMessageMetadata(channel_id) -> [
      #("channel_id", json.string(channel_id)),
    ]
    TimeoutMetadata(duration) -> [
      #("duration_seconds", json.int(time_duration.to_int_seconds(duration))),
    ]
    BlockMessageMetadata(custom_message) ->
      case custom_message {
        Some(msg) -> [#("custom_message", json.string(msg))]
        None -> []
      }
  }
  |> json.object
}
