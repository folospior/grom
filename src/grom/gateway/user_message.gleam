import gleam/erlang/process.{type Subject}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/activity.{type Activity}
import grom/internal/time_timestamp
import stratus

@internal
pub type UserMessage {
  StartResume
  StartPresenceUpdate(UpdatePresenceMessage)
  StartVoiceStateUpdate(UpdateVoiceStateMessage)
  StartGuildMembersRequest(RequestGuildMembersMessage)
  StartSoundboardSoundsRequest(guild_ids: List(String))
}

pub type UpdatePresenceMessage {
  UpdatePresenceMessage(
    /// Only for Idle.
    since: Option(Timestamp),
    activities: List(Activity),
    status: PresenceStatus,
    is_afk: Bool,
  )
}

pub type UpdateVoiceStateMessage {
  UpdateVoiceStateMessage(
    guild_id: String,
    /// Set to `None` if disconnecting.
    channel_id: Option(String),
    is_self_muted: Bool,
    is_self_deafened: Bool,
  )
}

pub type RequestGuildMembersMessage {
  RequestAllGuildMembersMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
  )
  RequestGuildMembersByIdsMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
    user_ids: List(String),
  )
  RequestGuildMembersByQueryMessage(
    guild_id: String,
    with_presences: Bool,
    nonce: Option(String),
    query: String,
    limit: Int,
  )
}

pub type PresenceStatus {
  Online
  DoNotDisturb
  Idle
  Invisible
  Offline
}

pub opaque type Message {
  GetSubject(
    reply_to: Subject(Option(Subject(stratus.InternalMessage(UserMessage)))),
  )
  SetSubject(to: Subject(stratus.InternalMessage(UserMessage)))
  ResetSubject
}

@internal
pub fn new_subject_holder(
  subject: Option(Subject(stratus.InternalMessage(UserMessage))),
) {
  actor.new(subject)
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

@internal
pub fn update_presence_to_json(
  msg: UpdatePresenceMessage,
  with_opcode: Bool,
) -> Json {
  let data = {
    let since = case msg.since, msg.status {
      Some(timestamp), Idle -> [
        #("since", json.int(time_timestamp.to_unix_milliseconds(timestamp))),
      ]
      _, _ -> [#("since", json.null())]
    }

    let activities = [
      #("activities", json.array(msg.activities, activity.to_json)),
    ]

    let status = [#("status", presence_status_to_json(msg.status))]

    let is_afk = [#("afk", json.bool(msg.is_afk))]

    [since, activities, status, is_afk]
    |> list.flatten
    |> json.object
  }

  case with_opcode {
    True -> json.object([#("op", json.int(3)), #("d", data)])
    False -> data
  }
}

@internal
pub fn presence_status_to_json(status: PresenceStatus) -> Json {
  case status {
    Online -> "online"
    DoNotDisturb -> "dnd"
    Idle -> "idle"
    Invisible -> "invisible"
    Offline -> "offline"
  }
  |> json.string
}

@internal
pub fn request_guild_members_message_to_json(
  message: RequestGuildMembersMessage,
) -> Json {
  let data = {
    let guild_id = [#("guild_id", json.string(message.guild_id))]

    let with_presences = [#("presences", json.bool(message.with_presences))]

    let nonce = case message.nonce {
      Some(nonce) -> [#("nonce", json.string(nonce))]
      None -> []
    }

    let #(query, limit, user_ids) = case message {
      RequestAllGuildMembersMessage(..) -> #(
        [#("query", json.string(""))],
        [#("limit", json.int(0))],
        [],
      )
      RequestGuildMembersByIdsMessage(..) -> #([], [], [
        #("user_ids", json.array(message.user_ids, json.string)),
      ])
      RequestGuildMembersByQueryMessage(..) -> #(
        [#("query", json.string(message.query))],
        [#("limit", json.int(message.limit))],
        [],
      )
    }

    [guild_id, with_presences, nonce, query, limit, user_ids]
    |> list.flatten
    |> json.object
  }

  json.object([#("op", json.int(8)), #("d", data)])
}

@internal
pub fn update_voice_state_message_to_json(
  message: UpdateVoiceStateMessage,
) -> Json {
  json.object([
    #("op", json.int(4)),
    #(
      "d",
      json.object([
        #("guild_id", json.string(message.guild_id)),
        #("channel_id", json.nullable(message.channel_id, json.string)),
        #("self_mute", json.bool(message.is_self_muted)),
        #("self_deaf", json.bool(message.is_self_deafened)),
      ]),
    ),
  ])
}

@internal
pub fn get_subject(
  actor: Subject(Message),
) -> Option(Subject(stratus.InternalMessage(UserMessage))) {
  actor.call(actor, 10, GetSubject)
}

@internal
pub fn set_subject(
  actor: Subject(Message),
  to new: Subject(stratus.InternalMessage(UserMessage)),
) -> Nil {
  actor.send(actor, SetSubject(to: new))
}

fn on_message(
  current: Option(Subject(stratus.InternalMessage(UserMessage))),
  message: Message,
) -> actor.Next(Option(Subject(stratus.InternalMessage(UserMessage))), Message) {
  case message {
    GetSubject(reply_to) -> {
      actor.send(reply_to, current)
      actor.continue(current)
    }
    SetSubject(to: new) -> actor.continue(Some(new))
    ResetSubject -> actor.continue(None)
  }
}
