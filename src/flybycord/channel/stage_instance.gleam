import gleam/dynamic/decode
import gleam/option.{type Option}

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

// DECODERS --------------------------------------------------------------------

@internal
pub fn stage_instance_decoder() -> decode.Decoder(StageInstance) {
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
