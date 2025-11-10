import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/guild/scheduled_event/recurrence_rule.{type RecurrenceRule}
import grom/image
import grom/internal/rest
import grom/internal/time_rfc3339
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type ScheduledEvent {
  ScheduledEvent(
    id: String,
    guild_id: String,
    channel_id: Option(String),
    creator_id: Option(String),
    name: String,
    description: Option(String),
    scheduled_start_time: Timestamp,
    scheduled_end_time: Option(Timestamp),
    privacy_level: PrivacyLevel,
    status: Status,
    entity_type: EntityType,
    entity_id: Option(String),
    entity_metadata: Option(EntityMetadata),
    creator: Option(User),
    image_hash: Option(String),
    recurrence_rule: Option(RecurrenceRule),
  )
}

pub type PrivacyLevel {
  GuildOnly
}

pub type Status {
  Scheduled
  Active
  Completed
  Canceled
}

pub type EntityType {
  InStageInstance
  InVoiceChannel
  ExternallyHosted
}

pub type EntityMetadata {
  EntityMetadata(location: Option(String))
}

pub type Create {
  CreateExternal(
    entity_metadata: EntityMetadata,
    name: String,
    privacy_level: PrivacyLevel,
    scheduled_start_time: Timestamp,
    scheduled_end_time: Timestamp,
    description: Option(String),
    image: Option(image.Data),
    recurrence_rule: Option(recurrence_rule.Create),
  )
  CreateInStageInstance(
    channel_id: String,
    name: String,
    privacy_level: PrivacyLevel,
    scheduled_start_time: Timestamp,
    scheduled_end_time: Option(Timestamp),
    description: Option(String),
    image: Option(image.Data),
    recurrence_rule: Option(recurrence_rule.Create),
  )
  CreateInVoiceChannel(
    channel_id: String,
    name: String,
    privacy_level: PrivacyLevel,
    scheduled_start_time: Timestamp,
    scheduled_end_time: Option(Timestamp),
    description: Option(String),
    image: Option(image.Data),
    recurrence_rule: Option(recurrence_rule.Create),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(ScheduledEvent) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use channel_id <- decode.field("channel_id", decode.optional(decode.string))
  use creator_id <- decode.optional_field(
    "creator_id",
    None,
    decode.optional(decode.string),
  )
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use scheduled_start_time <- decode.field(
    "scheduled_start_time",
    time_rfc3339.decoder(),
  )
  use scheduled_end_time <- decode.field(
    "scheduled_end_time",
    decode.optional(time_rfc3339.decoder()),
  )
  use privacy_level <- decode.field("privacy_level", privacy_level_decoder())
  use status <- decode.field("status", status_decoder())
  use entity_type <- decode.field("entity_type", entity_type_decoder())
  use entity_id <- decode.field("entity_id", decode.optional(decode.string))
  use entity_metadata <- decode.field(
    "entity_metadata",
    decode.optional(entity_metadata_decoder()),
  )
  use creator <- decode.field("creator", decode.optional(user.decoder()))
  use image_hash <- decode.field("image_hash", decode.optional(decode.string))
  use recurrence_rule <- decode.field(
    "recurrence_rule",
    decode.optional(recurrence_rule.decoder()),
  )
  decode.success(ScheduledEvent(
    id:,
    guild_id:,
    channel_id:,
    creator_id:,
    name:,
    description:,
    scheduled_start_time:,
    scheduled_end_time:,
    privacy_level:,
    status:,
    entity_type:,
    entity_id:,
    entity_metadata:,
    creator:,
    image_hash:,
    recurrence_rule:,
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

@internal
pub fn status_decoder() -> decode.Decoder(Status) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Scheduled)
    2 -> decode.success(Active)
    3 -> decode.success(Completed)
    4 -> decode.success(Canceled)
    _ -> decode.failure(Scheduled, "Status")
  }
}

@internal
pub fn entity_type_decoder() -> decode.Decoder(EntityType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(InStageInstance)
    2 -> decode.success(InVoiceChannel)
    3 -> decode.success(ExternallyHosted)
    _ -> decode.failure(InStageInstance, "EntityType")
  }
}

@internal
pub fn entity_metadata_decoder() -> decode.Decoder(EntityMetadata) {
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(decode.string),
  )
  decode.success(EntityMetadata(location:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let channel_id = case create {
    CreateInStageInstance(channel_id:, ..) -> [
      #("channel_id", json.string(channel_id)),
    ]
    CreateInVoiceChannel(channel_id:, ..) -> [
      #("channel_id", json.string(channel_id)),
    ]
    _ -> []
  }

  let entity_metadata = case create {
    CreateExternal(entity_metadata:, ..) -> [
      #("entity_metadata", entity_metadata_to_json(entity_metadata)),
    ]
    _ -> []
  }

  let name = [#("name", json.string(create.name))]

  let privacy_level = [
    #("privacy_level", privacy_level_to_json(create.privacy_level)),
  ]

  let scheduled_start_time = [
    #("scheduled_start_time", time_rfc3339.to_json(create.scheduled_start_time)),
  ]

  let scheduled_end_time = case create {
    CreateExternal(scheduled_end_time:, ..) -> [
      #("scheduled_end_time", time_rfc3339.to_json(scheduled_end_time)),
    ]
    CreateInStageInstance(scheduled_end_time:, ..)
    | CreateInVoiceChannel(scheduled_end_time:, ..) ->
      case scheduled_end_time {
        Some(time) -> [#("scheduled_end_time", time_rfc3339.to_json(time))]
        None -> []
      }
  }

  let description = case create.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let entity_type = [
    #("entity_type", case create {
      CreateInStageInstance(..) -> json.int(1)
      CreateInVoiceChannel(..) -> json.int(2)
      CreateExternal(..) -> json.int(3)
    }),
  ]

  let image = case create.image {
    Some(image) -> [#("image", image.to_json(image))]
    None -> []
  }

  let recurrence_rule = case create.recurrence_rule {
    Some(rule) -> [#("recurrence_rule", recurrence_rule.create_to_json(rule))]
    None -> []
  }

  [
    channel_id,
    entity_metadata,
    name,
    privacy_level,
    scheduled_start_time,
    scheduled_end_time,
    description,
    entity_type,
    image,
    recurrence_rule,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn entity_metadata_to_json(entity_metadata: EntityMetadata) -> Json {
  json.object(case entity_metadata.location {
    Some(location) -> [#("location", json.string(location))]
    None -> []
  })
}

@internal
pub fn privacy_level_to_json(privacy_level: PrivacyLevel) -> Json {
  case privacy_level {
    GuildOnly -> 2
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn create(
  client: grom.Client,
  in guild_id: String,
  using create: Create,
  because reason: Option(String),
) -> Result(ScheduledEvent, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/guilds/" <> guild_id <> "/scheduled-events",
    )
    |> request.set_body(create |> create_to_json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get(
  client: grom.Client,
  for guild_id: String,
  id event_id: String,
) -> Result(ScheduledEvent, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/scheduled-events/" <> event_id,
    )
    |> request.set_query([#("with_user_count", "true")])
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}
