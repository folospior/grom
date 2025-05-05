import flybycord/client.{type Client}
import flybycord/error
import flybycord/guild/auto_moderation/action.{type Action}
import flybycord/guild/auto_moderation/event
import flybycord/guild/auto_moderation/trigger
import flybycord/internal/rest
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

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

/// Disabled by default. Enable with `create_with_is_enabled()`.
pub opaque type Create {
  Create(
    name: String,
    event_type: event.Type,
    trigger_type: trigger.Type,
    trigger_metadata: Option(trigger.Metadata),
    actions: List(Action),
    is_enabled: Option(Bool),
    exempt_role_ids: Option(List(String)),
    exempt_channel_ids: Option(List(String)),
  )
}

pub opaque type Modify {
  Modify(
    name: Option(String),
    event_type: Option(event.Type),
    trigger_metadata: Option(trigger.Metadata),
    actions: Option(List(Action)),
    is_enabled: Option(Bool),
    exempt_role_ids: Option(List(String)),
    exempt_channel_ids: Option(List(String)),
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
    trigger.metadata_decoder(trigger_type),
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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_encode(create: Create) -> Json {
  let trigger_metadata = case create.trigger_metadata {
    Some(metadata) -> [#("trigger_metadata", trigger.metadata_encode(metadata))]
    None -> []
  }
  let is_enabled = case create.is_enabled {
    Some(enabled) -> [#("enabled", json.bool(enabled))]
    None -> []
  }
  let exempt_role_ids = case create.exempt_role_ids {
    Some(ids) -> [#("exempt_roles", json.array(ids, json.string))]
    None -> []
  }
  let exempt_channel_ids = case create.exempt_channel_ids {
    Some(ids) -> [#("exempt_channels", json.array(ids, json.string))]
    None -> []
  }

  [
    [
      #("name", json.string(create.name)),
      #("event_type", event.type_encode(create.event_type)),
      #("trigger_type", trigger.type_encode(create.trigger_type)),
      #("actions", json.array(create.actions, action.encode)),
    ],
    trigger_metadata,
    is_enabled,
    exempt_role_ids,
    exempt_channel_ids,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let name = case modify.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }
  let event_type = case modify.event_type {
    Some(type_) -> [#("event_type", event.type_encode(type_))]
    None -> []
  }
  let trigger_metadata = case modify.trigger_metadata {
    Some(metadata) -> [#("trigger_metadata", trigger.metadata_encode(metadata))]
    None -> []
  }
  let actions = case modify.actions {
    Some(actions) -> [#("actions", json.array(actions, action.encode))]
    None -> []
  }
  let is_enabled = case modify.is_enabled {
    Some(enabled) -> [#("enabled", json.bool(enabled))]
    None -> []
  }
  let exempt_role_ids = case modify.exempt_role_ids {
    Some(ids) -> [#("exempt_roles", json.array(ids, json.string))]
    None -> []
  }
  let exempt_channel_ids = case modify.exempt_channel_ids {
    Some(ids) -> [#("exempt_channels", json.array(ids, json.string))]
    None -> []
  }

  [
    name,
    event_type,
    trigger_metadata,
    actions,
    is_enabled,
    exempt_role_ids,
    exempt_channel_ids,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS -------------------------------------------------------

pub fn get(
  client: Client,
  in guild_id: String,
  id rule_id: String,
) -> Result(Rule, error.FlybycordError) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/auto-moderation/rules/" <> rule_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn create(
  client: Client,
  in guild_id: String,
  with create: Create,
  reason reason: Option(String),
) -> Result(Rule, error.FlybycordError) {
  let json = create |> create_encode

  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/guilds/" <> guild_id <> "/auto-moderation/rules",
    )
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_create(
  name: String,
  event_type: event.Type,
  trigger_type: trigger.Type,
  actions: List(Action),
) -> Create {
  Create(
    name:,
    event_type:,
    trigger_type:,
    actions:,
    trigger_metadata: None,
    is_enabled: None,
    exempt_role_ids: None,
    exempt_channel_ids: None,
  )
}

pub fn create_with_trigger_metadata(
  create: Create,
  metadata: trigger.Metadata,
) -> Create {
  Create(..create, trigger_metadata: Some(metadata))
}

pub fn create_with_is_enabled(create: Create, is_enabled: Bool) -> Create {
  Create(..create, is_enabled: Some(is_enabled))
}

pub fn create_with_exempt_role_ids(
  create: Create,
  exempt_role_ids: List(String),
) -> Create {
  Create(..create, exempt_role_ids: Some(exempt_role_ids))
}

pub fn create_with_exempt_channel_ids(
  create: Create,
  exempt_channel_ids: List(String),
) -> Create {
  Create(..create, exempt_channel_ids: Some(exempt_channel_ids))
}

pub fn modify(
  client: Client,
  in guild_id: String,
  id rule_id: String,
  with modify: Modify,
  reason reason: Option(String),
) {
  let json = modify |> modify_encode

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/guilds/" <> guild_id <> "/auto-moderation/rules/" <> rule_id,
    )
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn modify_name(modify: Modify, name: String) -> Modify {
  Modify(..modify, name: Some(name))
}

pub fn modify_event_type(modify: Modify, event_type: event.Type) -> Modify {
  Modify(..modify, event_type: Some(event_type))
}

pub fn modify_trigger_metadata(
  modify: Modify,
  trigger_metadata: trigger.Metadata,
) -> Modify {
  Modify(..modify, trigger_metadata: Some(trigger_metadata))
}

pub fn modify_actions(modify: Modify, actions: List(Action)) -> Modify {
  Modify(..modify, actions: Some(actions))
}

pub fn modify_is_enabled(modify: Modify, is_enabled: Bool) -> Modify {
  Modify(..modify, is_enabled: Some(is_enabled))
}

pub fn modify_exempt_role_ids(
  modify: Modify,
  exempt_role_ids: List(String),
) -> Modify {
  Modify(..modify, exempt_role_ids: Some(exempt_role_ids))
}

pub fn modify_exempt_channel_ids(
  modify: Modify,
  exempt_channel_ids: List(String),
) -> Modify {
  Modify(..modify, exempt_channel_ids: Some(exempt_channel_ids))
}

pub fn delete(
  client: Client,
  in guild_id: String,
  id rule_id: String,
  reason reason: Option(String),
) -> Result(Nil, error.FlybycordError) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/auto-moderation/rules/" <> rule_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}
