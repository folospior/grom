import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/internal/rest

// TYPES -----------------------------------------------------------------------

pub type StageInstance {
  StageInstance(
    id: String,
    guild_id: String,
    channel_id: String,
    topic: String,
    privacy_level: PrivacyLevel,
    scheduled_event_id: Option(String),
  )
}

pub type PrivacyLevel {
  GuildOnly
}

pub type Create {
  Create(
    channel_id: String,
    topic: String,
    privacy_level: PrivacyLevel,
    send_start_notification: Bool,
    scheduled_event_id: Option(String),
  )
}

pub type Modify {
  Modify(topic: Option(String), privacy_level: Option(PrivacyLevel))
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(StageInstance) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.string)
  use topic <- decode.field("topic", decode.string)
  use privacy_level <- decode.field("privacy_level", privacy_level_decoder())
  use scheduled_event_id <- decode.field(
    "guild_scheduled_event_id",
    decode.optional(decode.string),
  )
  decode.success(StageInstance(
    id:,
    guild_id:,
    channel_id:,
    topic:,
    privacy_level:,
    scheduled_event_id:,
  ))
}

@internal
pub fn privacy_level_decoder() -> decode.Decoder(PrivacyLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    2 -> decode.success(GuildOnly)
    _ -> decode.failure(GuildOnly, "PrivacyLevel")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  json.object(
    [
      [#("channel_id", json.string(create.channel_id))],
      [#("topic", json.string(create.topic))],
      [#("privacy_level", privacy_level_to_json(create.privacy_level))],
      [#("send_start_notification", json.bool(create.send_start_notification))],
      case create.scheduled_event_id {
        Some(id) -> [#("guild_scheduled_event_id", json.string(id))]
        None -> []
      },
    ]
    |> list.flatten,
  )
}

@internal
pub fn privacy_level_to_json(privacy_level: PrivacyLevel) -> Json {
  case privacy_level {
    GuildOnly -> 2
  }
  |> json.int
}

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  let topic = case modify.topic {
    Some(topic) -> [#("topic", json.string(topic))]
    None -> []
  }

  let privacy_level = case modify.privacy_level {
    Some(level) -> [#("privacy_level", privacy_level_to_json(level))]
    None -> []
  }

  [topic, privacy_level]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS -------------------------------------------------------- 

pub fn create(
  client: grom.Client,
  using create: Create,
  because reason: Option(String),
) -> Result(StageInstance, grom.Error) {
  let json = create |> create_to_json |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/stage-instances")
    |> rest.with_reason(reason)
    |> request.set_body(json)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create(
  channel_id channel_id: String,
  topic topic: String,
  send_start_notification send_start_notification: Bool,
) -> Create {
  Create(
    channel_id:,
    topic:,
    privacy_level: GuildOnly,
    send_start_notification:,
    scheduled_event_id: None,
  )
}

pub fn get(
  client: grom.Client,
  for channel_id: String,
) -> Result(StageInstance, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/stage-instances/" <> channel_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify(
  client: grom.Client,
  in channel_id: String,
  using modify: Modify,
  because reason: Option(String),
) -> Result(StageInstance, grom.Error) {
  let json = modify |> modify_to_json |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/stage-instances/" <> channel_id)
    |> rest.with_reason(reason)
    |> request.set_body(json)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete(
  client: grom.Client,
  from channel_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  client
  |> rest.new_request(http.Delete, "/stage-instances/" <> channel_id)
  |> rest.with_reason(reason)
  |> rest.execute
  |> result.replace(Nil)
}
