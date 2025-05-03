import flybycord/guild/scheduled_event/recurrence_rule.{type RecurrenceRule}
import flybycord/internal/time_rfc3339
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

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
  StageInstance
  Voice
  External
}

pub type EntityMetadata {
  EntityMetadata(location: Option(String))
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
    1 -> decode.success(StageInstance)
    2 -> decode.success(Voice)
    3 -> decode.success(External)
    _ -> decode.failure(StageInstance, "EntityType")
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
