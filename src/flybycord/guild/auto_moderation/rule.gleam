import flybycord/guild/auto_moderation/action.{type Action}
import flybycord/guild/auto_moderation/event
import flybycord/guild/auto_moderation/trigger
import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Rule {
  Rule(
    id: String,
    guild_id: String,
    name: String,
    creator_id: String,
    event_type: event.Type,
    trigger_type: trigger.Type,
    trigger_metadata: trigger.Metadata,
    actions: List(Action),
    is_enabled: Bool,
    exempt_role_ids: List(String),
    exempt_channel_ids: List(String),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Rule) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use name <- decode.field("name", decode.string)
  use creator_id <- decode.field("creator_id", decode.string)
  use event_type <- decode.field("event_type", event.type_decoder())
  use trigger_type <- decode.field("trigger_type", trigger.type_decoder())
  use trigger_metadata <- decode.field(
    "trigger_metadata",
    trigger.metadata_decoder(),
  )
  use actions <- decode.field("actions", decode.list(action.decoder()))
  use is_enabled <- decode.field("enabled", decode.bool)
  use exempt_role_ids <- decode.field(
    "exempt_roles",
    decode.list(decode.string),
  )
  use exempt_channel_ids <- decode.field(
    "exempt_channels",
    decode.list(decode.string),
  )
  decode.success(Rule(
    id:,
    guild_id:,
    name:,
    creator_id:,
    event_type:,
    trigger_type:,
    trigger_metadata:,
    actions:,
    is_enabled:,
    exempt_role_ids:,
    exempt_channel_ids:,
  ))
}
