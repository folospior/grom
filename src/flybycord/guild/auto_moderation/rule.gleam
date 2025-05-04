import flybycord/guild/auto_moderation/action.{type Action}
import flybycord/guild/auto_moderation/event
import flybycord/guild/auto_moderation/trigger

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
