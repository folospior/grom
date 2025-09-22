import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import grom
import grom/internal/rest
import grom/internal/time_duration

// TYPES -----------------------------------------------------------------------

pub type Rule {
  Rule(
    id: String,
    guild_id: String,
    name: String,
    creator_id: String,
    trigger: Trigger,
    actions: List(Action),
    is_enabled: Bool,
    exempt_role_ids: List(String),
    exempt_channel_ids: List(String),
  )
}

pub type TriggerType {
  Keyword
  Spam
  KeywordPreset
  MentionSpam
  MemberProfile
}

pub type Trigger {
  KeywordTrigger(
    keyword_filter: List(String),
    regex_patterns: List(String),
    allow_list: List(String),
  )
  MemberProfileTrigger(
    keyword_filter: List(String),
    regex_patterns: List(String),
    allow_list: List(String),
  )
  KeywordPresetTrigger(presets: List(KeywordPreset), allow_list: List(String))
  MentionSpamTrigger(
    total_mention_limit: Int,
    is_mention_raid_protection_enabled: Bool,
  )
  SpamTrigger
}

pub type KeywordPreset {
  ProfanityPreset
  SexualContentPreset
  SlursPreset
}

pub type Action {
  BlockMessage(custom_message: Option(String))
  SendAlertMessage(channel_id: String)
  TimeoutMember(duration: Duration)
  BlockMemberInteraction
}

pub opaque type CreateRule {
  CreateRule(
    name: String,
    trigger: Trigger,
    actions: List(Action),
    is_enabled: Bool,
    exempt_role_ids: Option(List(String)),
    exempt_channel_ids: Option(List(String)),
  )
}

pub opaque type ModifyRule {
  ModifyRule(
    name: Option(String),
    /// You can only modify the inner data, you _can't_ change the trigger.
    trigger: Option(Trigger),
    actions: Option(List(Action)),
    is_enabled: Option(Bool),
    exempt_role_ids: Option(List(String)),
    exempt_channel_ids: Option(List(String)),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn rule_decoder() -> decode.Decoder(Rule) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use name <- decode.field("name", decode.string)
  use creator_id <- decode.field("creator_id", decode.string)
  use trigger_type <- decode.field("trigger_type", decode.int)
  use trigger <- decode.field("trigger_metadata", trigger_decoder(trigger_type))
  use actions <- decode.field("actions", decode.list(action_decoder()))
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
    trigger:,
    actions:,
    is_enabled:,
    exempt_role_ids:,
    exempt_channel_ids:,
  ))
}

pub fn trigger_decoder(trigger_type: Int) -> decode.Decoder(Trigger) {
  case trigger_type {
    1 | 6 -> {
      use keyword_filter <- decode.field(
        "keyword_filter",
        decode.list(decode.string),
      )
      use regex_patterns <- decode.field(
        "regex_patterns",
        decode.list(decode.string),
      )
      use allow_list <- decode.field("allow_list", decode.list(decode.string))

      case trigger_type {
        1 ->
          decode.success(KeywordTrigger(
            keyword_filter:,
            regex_patterns:,
            allow_list:,
          ))
        6 ->
          decode.success(MemberProfileTrigger(
            keyword_filter:,
            regex_patterns:,
            allow_list:,
          ))
        _ -> decode.failure(KeywordTrigger([], [], []), "Trigger")
      }
    }
    3 -> decode.success(SpamTrigger)
    4 -> {
      use presets <- decode.field(
        "presets",
        decode.list(keyword_preset_decoder()),
      )
      use allow_list <- decode.field("allow_list", decode.list(decode.string))

      decode.success(KeywordPresetTrigger(presets:, allow_list:))
    }
    5 -> {
      use total_mention_limit <- decode.field("mention_total_limit", decode.int)
      use is_mention_raid_protection_enabled <- decode.field(
        "mention_raid_protection_enabled",
        decode.bool,
      )

      decode.success(MentionSpamTrigger(
        total_mention_limit:,
        is_mention_raid_protection_enabled:,
      ))
    }
    _ -> decode.failure(SpamTrigger, "Trigger")
  }
}

@internal
pub fn trigger_type_decoder() -> decode.Decoder(TriggerType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Keyword)
    3 -> decode.success(Spam)
    4 -> decode.success(KeywordPreset)
    5 -> decode.success(MentionSpam)
    6 -> decode.success(MemberProfile)
    _ -> decode.failure(Keyword, "TriggerType")
  }
}

@internal
pub fn keyword_preset_decoder() -> decode.Decoder(KeywordPreset) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(ProfanityPreset)
    2 -> decode.success(SexualContentPreset)
    3 -> decode.success(SlursPreset)
    _ -> decode.failure(ProfanityPreset, "KeywordPreset")
  }
}

@internal
pub fn action_decoder() -> decode.Decoder(Action) {
  use type_ <- decode.field("type", decode.int)
  use action <- decode.field("metadata", case type_ {
    1 -> {
      use custom_message <- decode.optional_field(
        "custom_message",
        None,
        decode.optional(decode.string),
      )
      decode.success(BlockMessage(custom_message:))
    }
    2 -> {
      use channel_id <- decode.field("channel_id", decode.string)
      decode.success(SendAlertMessage(channel_id:))
    }
    3 -> {
      use duration <- decode.field(
        "duration_seconds",
        time_duration.from_int_seconds_decoder(),
      )
      decode.success(TimeoutMember(duration:))
    }
    4 -> decode.success(BlockMemberInteraction)
    _ -> decode.failure(BlockMessage(None), "Action")
  })

  decode.success(action)
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_rule_to_json(create_rule: CreateRule) -> Json {
  let name = [#("name", json.string(create_rule.name))]

  let event_type = [
    #("event_type", case create_rule.trigger {
      MemberProfileTrigger(..) -> json.int(2)
      _ -> json.int(1)
    }),
  ]

  let trigger_type = [
    #("trigger_type", case create_rule.trigger {
      KeywordTrigger(..) -> json.int(1)
      SpamTrigger -> json.int(3)
      KeywordPresetTrigger(..) -> json.int(4)
      MentionSpamTrigger(..) -> json.int(5)
      MemberProfileTrigger(..) -> json.int(6)
    }),
  ]

  let trigger = case create_rule.trigger {
    SpamTrigger -> []
    _ -> [#("trigger_metadata", trigger_to_json(create_rule.trigger))]
  }

  let is_enabled = [#("enabled", json.bool(create_rule.is_enabled))]

  let exempt_role_ids = case create_rule.exempt_role_ids {
    Some(ids) -> [#("exempt_roles", json.array(ids, json.string))]
    None -> []
  }

  let exempt_channel_ids = case create_rule.exempt_channel_ids {
    Some(ids) -> [#("exempt_channels", json.array(ids, json.string))]
    None -> []
  }

  [
    name,
    event_type,
    trigger_type,
    trigger,
    is_enabled,
    exempt_role_ids,
    exempt_channel_ids,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn trigger_to_json(trigger: Trigger) -> Json {
  case trigger {
    KeywordTrigger(..) -> [
      #("keyword_filter", json.array(trigger.keyword_filter, json.string)),
      #("regex_patterns", json.array(trigger.regex_patterns, json.string)),
      #("allow_list", json.array(trigger.allow_list, json.string)),
    ]
    SpamTrigger -> []
    KeywordPresetTrigger(..) -> [
      #("presets", json.array(trigger.presets, keyword_preset_to_json)),
      #("allow_list", json.array(trigger.allow_list, json.string)),
    ]
    MentionSpamTrigger(..) -> [
      #("mention_total_limit", json.int(trigger.total_mention_limit)),
      #(
        "mention_raid_protection_enabled",
        json.bool(trigger.is_mention_raid_protection_enabled),
      ),
    ]
    MemberProfileTrigger(..) -> [
      #("keyword_filter", json.array(trigger.keyword_filter, json.string)),
      #("regex_patterns", json.array(trigger.regex_patterns, json.string)),
      #("allow_list", json.array(trigger.allow_list, json.string)),
    ]
  }
  |> json.object
}

@internal
pub fn keyword_preset_to_json(keyword_preset: KeywordPreset) -> Json {
  case keyword_preset {
    ProfanityPreset -> 1
    SexualContentPreset -> 2
    SlursPreset -> 3
  }
  |> json.int
}

@internal
pub fn action_to_json(action: Action) -> Json {
  [
    [
      #("type", case action {
        BlockMessage(..) -> json.int(1)
        SendAlertMessage(..) -> json.int(2)
        TimeoutMember(..) -> json.int(3)
        BlockMemberInteraction -> json.int(4)
      }),
    ],
    case action {
      BlockMemberInteraction -> []
      BlockMessage(..) -> [
        #("metadata", {
          let custom_message = case action.custom_message {
            Some(message) -> [#("custom_message", json.string(message))]
            None -> []
          }

          [custom_message]
          |> list.flatten
          |> json.object
        }),
      ]
      TimeoutMember(..) -> [
        #(
          "metadata",
          json.object([
            #(
              "duration_seconds",
              time_duration.to_int_seconds_encode(action.duration),
            ),
          ]),
        ),
      ]
      SendAlertMessage(..) -> [
        #(
          "metadata",
          json.object([#("channel_id", json.string(action.channel_id))]),
        ),
      ]
    },
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn modify_rule_to_json(modify_rule: ModifyRule) -> Json {
  let name = case modify_rule.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let trigger = case modify_rule.trigger {
    Some(SpamTrigger) | None -> []
    Some(trigger) -> [#("trigger_metadata", trigger_to_json(trigger))]
  }

  let actions = case modify_rule.actions {
    Some(actions) -> [#("actions", json.array(actions, action_to_json))]
    None -> []
  }

  let is_enabled = case modify_rule.is_enabled {
    Some(enabled) -> [#("enabled", json.bool(enabled))]
    None -> []
  }

  let exempt_role_ids = case modify_rule.exempt_role_ids {
    Some(ids) -> [#("exempt_roles", json.array(ids, json.string))]
    None -> []
  }

  let exempt_channel_ids = case modify_rule.exempt_channel_ids {
    Some(ids) -> [#("exempt_channels", json.array(ids, json.string))]
    None -> []
  }

  [name, trigger, actions, is_enabled, exempt_role_ids, exempt_channel_ids]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_rule(
  client: grom.Client,
  from guild_id: String,
  id rule_id: String,
) -> Result(Rule, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/auto-moderation/rules/" <> rule_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: rule_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_rule(
  client: grom.Client,
  in guild_id: String,
  with create_rule: CreateRule,
  because reason: Option(String),
) -> Result(Rule, grom.Error) {
  let json = create_rule |> create_rule_to_json

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
  |> json.parse(using: rule_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create_rule(
  named name: String,
  on trigger: Trigger,
  do actions: List(Action),
  enable is_enabled: Bool,
) -> CreateRule {
  CreateRule(
    name:,
    trigger:,
    actions:,
    is_enabled:,
    exempt_role_ids: None,
    exempt_channel_ids: None,
  )
}

pub fn create_rule_with_exempt_roles(
  create_rule: CreateRule,
  ids exempt_role_ids: List(String),
) -> CreateRule {
  CreateRule(..create_rule, exempt_role_ids: Some(exempt_role_ids))
}

pub fn create_rule_with_exempt_channels(
  create_rule: CreateRule,
  ids exempt_channel_ids: List(String),
) -> CreateRule {
  CreateRule(..create_rule, exempt_channel_ids: Some(exempt_channel_ids))
}

pub fn modify_rule(
  client: grom.Client,
  in guild_id: String,
  id rule_id: String,
  with modify_rule: ModifyRule,
  because reason: Option(String),
) -> Result(Rule, grom.Error) {
  let json = modify_rule |> modify_rule_to_json

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/guilds/" <> guild_id <> "/auto-moderation/rules/" <> rule_id,
    )
    |> request.set_body(json |> json.to_string)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: rule_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify_rule_name(modify_rule: ModifyRule, new name: String) -> ModifyRule {
  ModifyRule(..modify_rule, name: Some(name))
}

pub fn modify_rule_trigger(
  modify_rule: ModifyRule,
  new trigger: Trigger,
) -> ModifyRule {
  ModifyRule(..modify_rule, trigger: Some(trigger))
}

pub fn modify_rule_actions(
  modify_rule: ModifyRule,
  new actions: List(Action),
) -> ModifyRule {
  ModifyRule(..modify_rule, actions: Some(actions))
}

pub fn enable_rule(modify_rule: ModifyRule) -> ModifyRule {
  ModifyRule(..modify_rule, is_enabled: Some(True))
}

pub fn disable_rule(modify_rule: ModifyRule) -> ModifyRule {
  ModifyRule(..modify_rule, is_enabled: Some(False))
}

pub fn exempt_roles_from_rule(
  modify_rule: ModifyRule,
  ids exempt_role_ids: List(String),
) -> ModifyRule {
  ModifyRule(..modify_rule, exempt_role_ids: Some(exempt_role_ids))
}

pub fn exempt_channels_from_rule(
  modify_rule: ModifyRule,
  ids exempt_channel_ids: List(String),
) -> ModifyRule {
  ModifyRule(..modify_rule, exempt_channel_ids: Some(exempt_channel_ids))
}

pub fn delete_rule(
  client: grom.Client,
  from guild_id: String,
  id rule_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
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
