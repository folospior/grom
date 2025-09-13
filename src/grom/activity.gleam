import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/flags
import grom/internal/time_timestamp

// TYPES ----------------------------------------------------------------------

pub type Activity {
  Activity(
    name: String,
    type_: Type,
    url: Option(String),
    created_at: Timestamp,
    timestamps: Option(Timestamps),
    application_id: Option(String),
    status_display_type: Option(DisplayType),
    details: Option(String),
    details_url: Option(String),
    state: Option(String),
    state_url: Option(String),
    emoji: Option(Emoji),
    party: Option(Party),
    assets: Option(Assets),
    secrets: Option(Secrets),
    is_instance: Option(Bool),
    flags: Option(List(Flag)),
    buttons: Option(List(Button)),
  )
}

pub type Type {
  Playing
  Streaming
  Listening
  Watching
  Custom
  Competing
}

pub type Timestamps {
  Timestamps(start: Option(Timestamp), end: Option(Timestamp))
}

pub type DisplayType {
  DisplayName
  DisplayState
  DisplayDetails
}

pub type Emoji {
  Emoji(name: String, id: Option(String), is_animated: Option(Bool))
}

pub type Party {
  Party(id: Option(String), current_size: Option(Int), max_size: Option(Int))
}

pub type Assets {
  Assets(
    large_image: Option(String),
    large_text: Option(String),
    large_url: Option(String),
    small_image: Option(String),
    small_text: Option(String),
    small_url: Option(String),
  )
}

pub type Secrets {
  Secrets(join: Option(String), spectate: Option(String), match: Option(String))
}

pub type Flag {
  Instance
  Join
  Spectate
  JoinRequest
  Sync
  Play
  PartyPrivacyFriends
  PartyPrivacyVoiceChannel
  Embedded
}

pub type Button {
  Button(label: String, url: String)
}

// FLAGS -----------------------------------------------------------------------

fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 0), Instance),
    #(int.bitwise_shift_left(1, 1), Join),
    #(int.bitwise_shift_left(1, 2), Spectate),
    #(int.bitwise_shift_left(1, 3), JoinRequest),
    #(int.bitwise_shift_left(1, 4), Sync),
    #(int.bitwise_shift_left(1, 5), Play),
    #(int.bitwise_shift_left(1, 6), PartyPrivacyFriends),
    #(int.bitwise_shift_left(1, 7), PartyPrivacyVoiceChannel),
    #(int.bitwise_shift_left(1, 8), Embedded),
  ]
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(activity: Activity) -> Json {
  let name = [#("name", json.string(activity.name))]

  let type_ = [#("type", type_to_json(activity.type_))]

  let url = case activity.url {
    Some(url) -> [#("url", json.string(url))]
    None -> []
  }

  let created_at = [
    #(
      "created_at",
      json.int(time_timestamp.to_unix_milliseconds(activity.created_at)),
    ),
  ]

  let timestamps = case activity.timestamps {
    Some(timestamps) -> [#("timestamps", timestamps_to_json(timestamps))]
    None -> []
  }

  let application_id = case activity.application_id {
    Some(id) -> [#("application_id", json.string(id))]
    None -> []
  }

  let status_display_type = case activity.status_display_type {
    Some(type_) -> [#("status_display_type", display_type_to_json(type_))]
    None -> []
  }

  let details = case activity.details {
    Some(details) -> [#("details", json.string(details))]
    None -> []
  }

  let details_url = case activity.details_url {
    Some(url) -> [#("details_url", json.string(url))]
    None -> []
  }

  let state = case activity.state {
    Some(state) -> [#("state", json.string(state))]
    None -> []
  }

  let state_url = case activity.state_url {
    Some(url) -> [#("state_url", json.string(url))]
    None -> []
  }

  let emoji = case activity.emoji {
    Some(emoji) -> [#("emoji", emoji_to_json(emoji))]
    None -> []
  }

  let party = case activity.party {
    Some(party) -> [#("party", party_to_json(party))]
    None -> []
  }

  let assets = case activity.assets {
    Some(assets) -> [#("assets", assets_to_json(assets))]
    None -> []
  }

  let secrets = case activity.secrets {
    Some(secrets) -> [#("secrets", secrets_to_json(secrets))]
    None -> []
  }

  let is_instance = case activity.is_instance {
    Some(instance) -> [#("instance", json.bool(instance))]
    None -> []
  }

  let flags = case activity.flags {
    Some(flags) -> [#("flags", flags.encode(flags, bits_flags()))]
    None -> []
  }

  let buttons = case activity.buttons {
    Some(buttons) -> [#("buttons", json.array(buttons, button_to_json))]
    None -> []
  }

  [
    name,
    type_,
    url,
    created_at,
    timestamps,
    application_id,
    status_display_type,
    details,
    details_url,
    state,
    state_url,
    emoji,
    party,
    assets,
    secrets,
    is_instance,
    flags,
    buttons,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn type_to_json(type_: Type) -> Json {
  case type_ {
    Playing -> 0
    Streaming -> 1
    Listening -> 2
    Watching -> 3
    Custom -> 4
    Competing -> 5
  }
  |> json.int
}

@internal
pub fn timestamps_to_json(timestamps: Timestamps) -> Json {
  let start = case timestamps.start {
    Some(timestamp) -> [
      #("start", json.int(time_timestamp.to_unix_milliseconds(timestamp))),
    ]
    None -> []
  }

  let end = case timestamps.end {
    Some(timestamp) -> [
      #("end", json.int(time_timestamp.to_unix_milliseconds(timestamp))),
    ]
    None -> []
  }

  [start, end]
  |> list.flatten
  |> json.object
}

@internal
pub fn display_type_to_json(display_type: DisplayType) -> Json {
  case display_type {
    DisplayName -> 0
    DisplayState -> 1
    DisplayDetails -> 2
  }
  |> json.int
}

@internal
pub fn emoji_to_json(emoji: Emoji) -> Json {
  let name = [#("name", json.string(emoji.name))]
  let id = case emoji.id {
    Some(id) -> [#("id", json.string(id))]
    None -> []
  }
  let is_animated = case emoji.is_animated {
    Some(animated) -> [#("animated", json.bool(animated))]
    None -> []
  }

  [name, id, is_animated]
  |> list.flatten
  |> json.object
}

@internal
pub fn party_to_json(party: Party) -> Json {
  let id = case party.id {
    Some(id) -> [#("id", json.string(id))]
    None -> []
  }

  let size = case party.current_size, party.max_size {
    Some(current), Some(max) -> [
      #("size", json.array([current, max], json.int)),
    ]
    _, _ -> []
  }

  [id, size]
  |> list.flatten
  |> json.object
}

@internal
pub fn assets_to_json(assets: Assets) -> Json {
  let large_image = case assets.large_image {
    Some(image) -> [#("large_image", json.string(image))]
    None -> []
  }

  let large_text = case assets.large_text {
    Some(text) -> [#("large_text", json.string(text))]
    None -> []
  }

  let large_url = case assets.large_url {
    Some(url) -> [#("large_url", json.string(url))]
    None -> []
  }

  let small_image = case assets.small_image {
    Some(image) -> [#("small_image", json.string(image))]
    None -> []
  }

  let small_text = case assets.small_text {
    Some(text) -> [#("small_text", json.string(text))]
    None -> []
  }

  let small_url = case assets.small_url {
    Some(url) -> [#("small_url", json.string(url))]
    None -> []
  }

  [large_image, large_text, large_url, small_image, small_text, small_url]
  |> list.flatten
  |> json.object
}

@internal
pub fn secrets_to_json(secrets: Secrets) -> Json {
  let join = case secrets.join {
    Some(secret) -> [#("join", json.string(secret))]
    None -> []
  }

  let spectate = case secrets.spectate {
    Some(secret) -> [#("spectate", json.string(secret))]
    None -> []
  }

  let match = case secrets.match {
    Some(secret) -> [#("match", json.string(secret))]
    None -> []
  }

  [join, spectate, match]
  |> list.flatten
  |> json.object
}

@internal
pub fn button_to_json(button: Button) -> Json {
  [#("label", json.string(button.label)), #("url", json.string(button.url))]
  |> json.object
}
