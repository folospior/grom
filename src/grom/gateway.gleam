import gleam/bool
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/static_supervisor
import gleam/otp/supervision
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import grom
import grom/application
import grom/gateway/connection_pid
import grom/gateway/heartbeat
import grom/gateway/intent.{type Intent}
import grom/gateway/resuming
import grom/gateway/sequence
import grom/gateway/user_message.{
  type RequestGuildMembersMessage, type UpdatePresenceMessage,
  type UpdateVoiceStateMessage, type UserMessage,
}
import grom/guild
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/user.{type User}
import operating_system
import repeatedly
import stratus

// TYPES -----------------------------------------------------------------------

pub type GatewayData {
  GatewayData(
    url: String,
    recommended_shards: Int,
    session_start_limits: SessionStartLimits,
  )
}

pub type ReadyApplication {
  ReadyApplication(id: String, flags: List(application.Flag))
}

pub type Shard {
  Shard(id: Int, num_shards: Int)
}

pub type Event {
  ReadyEvent(ReadyMessage)
  ErrorEvent(grom.Error)
  ResumedEvent
}

pub type SessionStartLimits {
  SessionStartLimits(
    maximum_starts: Int,
    remaining_starts: Int,
    resets_after: Duration,
    max_identify_requests_per_5_seconds: Int,
  )
}

pub opaque type State {
  State(
    actor: Subject(Event),
    sequence_holder: Subject(sequence.Message),
    heartbeat_counter: Subject(heartbeat.Message),
    resuming_info_holder: Subject(resuming.Message),
    connection_pid_holder: Subject(connection_pid.Message),
    identify: IdentifyMessage,
    user_message_subject_holder: Subject(user_message.Message),
  )
}

// RECEIVE EVENTS --------------------------------------------------------------

pub type ReceivedMessage {
  Hello(HelloMessage)
  Dispatch(sequence: Int, message: DispatchedMessage)
  HeartbeatAcknowledged
  HeartbeatRequest
  ReconnectRequest
}

pub type HelloMessage {
  HelloMessage(heartbeat_interval: Duration)
}

// RECEIVED DISPATCH EVENTS ----------------------------------------------------

pub type DispatchedMessage {
  Ready(ReadyMessage)
  Resumed
}

pub type ReadyMessage {
  ReadyMessage(
    api_version: Int,
    user: User,
    guilds: List(guild.UnavailableGuild),
    session_id: String,
    resume_gateway_url: String,
    shard: Option(Shard),
    application: ReadyApplication,
  )
}

// SEND EVENTS -----------------------------------------------------------------

pub type SentMessage {
  Heartbeat(HeartbeatMessage)
  Identify(IdentifyMessage)
  Resume(ResumeMessage)
}

pub type HeartbeatMessage {
  HeartbeatMessage(last_sequence: Option(Int))
}

pub type IdentifyMessage {
  IdentifyMessage(
    token: String,
    properties: IdentifyProperties,
    supports_compression: Bool,
    max_offline_members: Option(Int),
    shard: Option(Shard),
    presence: Option(UpdatePresenceMessage),
    intents: List(Intent),
  )
}

pub type ResumeMessage {
  ResumeMessage(token: String, session_id: String, last_sequence: Int)
}

pub type IdentifyProperties {
  IdentifyProperties(os: String, browser: String, device: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn data_decoder() -> decode.Decoder(GatewayData) {
  use url <- decode.field("url", decode.string)
  use recommended_shards <- decode.field("shards", decode.int)
  use session_start_limits <- decode.field(
    "session_start_limit",
    session_start_limits_decoder(),
  )

  decode.success(GatewayData(url:, recommended_shards:, session_start_limits:))
}

@internal
pub fn session_start_limits_decoder() -> decode.Decoder(SessionStartLimits) {
  use maximum_starts <- decode.field("total", decode.int)
  use remaining_starts <- decode.field("remaining", decode.int)
  use resets_after <- decode.field(
    "reset_after",
    time_duration.from_milliseconds_decoder(),
  )

  use max_identify_requests_per_5_seconds <- decode.field(
    "max_concurrency",
    decode.int,
  )

  decode.success(SessionStartLimits(
    maximum_starts:,
    remaining_starts:,
    resets_after:,
    max_identify_requests_per_5_seconds:,
  ))
}

@internal
pub fn message_decoder() -> decode.Decoder(ReceivedMessage) {
  use opcode <- decode.field("op", decode.int)
  case opcode {
    0 -> {
      use sequence <- decode.field("s", decode.int)
      use type_ <- decode.field("t", decode.string)
      use message <- decode.field("d", case type_ {
        "READY" -> {
          use ready <- decode.then(ready_message_decoder())
          decode.success(Ready(ready))
        }
        "RESUMED" -> decode.success(Resumed)
        _ -> decode.failure(Resumed, "DispatchedMessage")
      })
      decode.success(Dispatch(sequence:, message:))
    }
    1 -> decode.success(HeartbeatRequest)
    7 -> decode.success(ReconnectRequest)
    10 -> {
      use msg <- decode.field("d", hello_event_decoder())
      decode.success(Hello(msg))
    }
    11 -> decode.success(HeartbeatAcknowledged)
    _ ->
      decode.failure(Hello(HelloMessage(duration.seconds(0))), "ReceivedEvent")
  }
}

@internal
pub fn hello_event_decoder() -> decode.Decoder(HelloMessage) {
  use heartbeat_interval <- decode.field(
    "heartbeat_interval",
    time_duration.from_milliseconds_decoder(),
  )

  decode.success(HelloMessage(heartbeat_interval:))
}

@internal
pub fn ready_message_decoder() -> decode.Decoder(ReadyMessage) {
  use api_version <- decode.field("v", decode.int)
  use user <- decode.field("user", user.decoder())
  use guilds <- decode.field(
    "guilds",
    decode.list(of: guild.unavailable_guild_decoder()),
  )
  use session_id <- decode.field("session_id", decode.string)
  use resume_gateway_url <- decode.field("resume_gateway_url", decode.string)
  use shard <- decode.optional_field(
    "shard",
    None,
    decode.optional(shard_decoder()),
  )
  use application <- decode.field("application", ready_application_decoder())

  decode.success(ReadyMessage(
    api_version:,
    user:,
    guilds:,
    session_id:,
    resume_gateway_url:,
    shard:,
    application:,
  ))
}

@internal
pub fn shard_decoder() -> decode.Decoder(Shard) {
  use id <- decode.field(0, decode.int)
  use num_shards <- decode.field(1, decode.int)
  decode.success(Shard(id:, num_shards:))
}

@internal
pub fn ready_application_decoder() -> decode.Decoder(ReadyApplication) {
  use id <- decode.field("id", decode.string)
  use flags <- decode.field("flags", flags.decoder(application.bits_flags()))
  decode.success(ReadyApplication(id:, flags:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn message_to_json(message: SentMessage) -> Json {
  case message {
    Heartbeat(msg) -> heartbeat_to_json(msg)
    Identify(msg) -> identify_to_json(msg)
    Resume(msg) -> resume_to_json(msg)
  }
}

fn resume_to_json(message: ResumeMessage) -> Json {
  json.object([
    #("op", json.int(6)),
    #(
      "d",
      json.object([
        #("token", json.string(message.token)),
        #("session_id", json.string(message.session_id)),
        #("seq", json.int(message.last_sequence)),
      ]),
    ),
  ])
}

fn identify_to_json(msg: IdentifyMessage) -> Json {
  let data = {
    let token = [#("token", json.string(msg.token))]

    let properties = [
      #("properties", identify_properties_to_json(msg.properties)),
    ]

    let supports_compression = [
      #("compress", json.bool(msg.supports_compression)),
    ]

    let max_offline_members = case msg.max_offline_members {
      Some(threshold) -> [#("large_threshold", json.int(threshold))]
      None -> []
    }

    let shard = case msg.shard {
      Some(shard) -> [
        #("shard", json.array([shard.id, shard.num_shards], json.int)),
      ]
      None -> []
    }

    let presence = case msg.presence {
      Some(presence) -> [
        #("presence", user_message.update_presence_to_json(presence, False)),
      ]
      None -> []
    }

    let intents = [
      #("intents", flags.to_json(msg.intents, intent.bits_intents())),
    ]

    [
      token,
      properties,
      supports_compression,
      max_offline_members,
      shard,
      presence,
      intents,
    ]
    |> list.flatten
    |> json.object
  }

  json.object([#("op", json.int(2)), #("d", data)])
}

fn identify_properties_to_json(properties: IdentifyProperties) -> Json {
  [
    #("os", json.string(properties.os)),
    #("browser", json.string(properties.browser)),
    #("device", json.string(properties.device)),
  ]
  |> json.object
}

fn heartbeat_to_json(heartbeat: HeartbeatMessage) -> Json {
  json.object([
    #("op", json.int(1)),
    #("d", json.nullable(heartbeat.last_sequence, json.int)),
  ])
}

// FUNCTIONS -------------------------------------------------------------------

pub fn get_data(client: grom.Client) -> Result(GatewayData, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/gateway/bot")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: data_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn start(
  client: grom.Client,
  identify: IdentifyMessage,
  notify actor: Subject(Event),
) {
  use state <- result.try(
    init_state(actor, identify)
    |> result.replace_error(actor.InitFailed("couldn't init state")),
  )

  use _ <- result.try(
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(supervised(client, state))
    |> static_supervisor.start,
  )

  Ok(state)
}

fn supervised(client: grom.Client, state: State) {
  state.connection_pid_holder
  |> connection_pid.set(to: process.self())

  let start = case resuming.get_info(state.resuming_info_holder) {
    Some(info) -> {
      case resuming.is_possible(info) {
        True -> resume(client, state, info)
        False -> new_connection(client, state)
      }
    }
    None -> new_connection(client, state)
  }

  let restart = supervision.Permanent
  let significant = False
  let child_type = supervision.Supervisor

  supervision.ChildSpecification(start:, restart:, significant:, child_type:)
}

fn new_connection(client: grom.Client, state: State) {
  fn() {
    use gateway_data <- result.try(
      client
      |> get_data
      |> result.replace_error(actor.InitFailed("couldn't get gateway data")),
    )

    let request_url =
      string.replace(in: gateway_data.url, each: "wss://", with: "https://")
      <> "?v=10&encoding=json"

    use connection_request <- result.try(
      request.to(request_url)
      |> result.replace_error(actor.InitFailed("couldn't parse connection url")),
    )

    heartbeat.reset(state.heartbeat_counter)
    sequence.reset(state.sequence_holder)
    resuming.reset(state.resuming_info_holder)

    use subject <- result.try(
      stratus.new(connection_request, state)
      |> stratus.on_message(fn(state, message, connection) {
        on_message(client, state, message, connection)
      })
      |> stratus.on_close(on_close)
      |> stratus.start
      |> result.replace_error(actor.InitFailed(
        "couldn't start websocket connection",
      )),
    )

    state.user_message_subject_holder
    |> user_message.set_subject(subject.data)

    Ok(subject)
  }
}

fn resume(client: grom.Client, state: State, info: resuming.Info) {
  fn() {
    use connection_request <- result.try(
      request.to(info.resume_gateway_url)
      |> result.replace_error(actor.InitFailed("couldn't parse connection url")),
    )

    use subject <- result.try(
      stratus.new(connection_request, state)
      |> stratus.on_message(fn(state, message, connection) {
        on_message(client, state, message, connection)
      })
      |> stratus.on_close(on_close)
      |> stratus.start
      |> result.replace_error(actor.InitFailed(
        "couldn't start websocket connection",
      )),
    )

    state.user_message_subject_holder
    |> user_message.set_subject(subject.data)

    process.send(
      subject.data,
      stratus.to_user_message(user_message.StartResume),
    )

    Ok(subject)
  }
}

fn on_close(state: State, close_reason: stratus.CloseReason) {
  let resuming_info = resuming.get_info(state.resuming_info_holder)
  let new_resuming_info = case resuming_info {
    Some(info) ->
      Some(
        resuming.Info(..info, last_received_close_reason: Some(close_reason)),
      )
    None -> None
  }

  state.resuming_info_holder
  |> resuming.set_info(to: new_resuming_info)

  // consult on if this is a bug, no idea tbh
  // i think it's impossible state for the connection_pid to be none by the time this function gets called
  // typing requires work, impossible states defined as possible values i think
  case connection_pid.get(state.connection_pid_holder) {
    Some(pid) -> process.kill(pid)
    None -> Nil
  }
}

pub fn identify(client: grom.Client, intents: List(Intent)) -> IdentifyMessage {
  IdentifyMessage(
    token: client.token,
    properties: IdentifyProperties(
      os: operating_system.name(),
      browser: "grom",
      device: "grom",
    ),
    supports_compression: False,
    max_offline_members: None,
    shard: None,
    presence: None,
    intents:,
  )
}

pub fn identify_with_presence(
  identify: IdentifyMessage,
  presence: UpdatePresenceMessage,
) -> IdentifyMessage {
  IdentifyMessage(..identify, presence: Some(presence))
}

pub fn update_presence(state: State, using message: UpdatePresenceMessage) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartPresenceUpdate(message)),
      )
    None -> Nil
  }
}

pub fn update_voice_state(state: State, using message: UpdateVoiceStateMessage) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartVoiceStateUpdate(message)),
      )
    None -> Nil
  }
}

pub fn request_guild_members(
  state: State,
  using message: RequestGuildMembersMessage,
) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartGuildMembersRequest(message)),
      )
    None -> Nil
  }
}

pub fn request_soundboard_sounds(state: State, for guild_ids: List(String)) {
  let subject = user_message.get_subject(state.user_message_subject_holder)

  case subject {
    Some(subject) ->
      process.send(
        subject,
        stratus.to_user_message(user_message.StartSoundboardSoundsRequest(
          guild_ids:,
        )),
      )
    None -> Nil
  }
}

fn init_state(actor: Subject(Event), identify: IdentifyMessage) {
  use sequence_holder <- result.try(
    sequence.holder_start() |> result.map_error(string.inspect),
  )
  let sequence_holder = sequence_holder.data

  use heartbeat_counter <- result.try(
    heartbeat.counter_start() |> result.map_error(string.inspect),
  )
  let heartbeat_counter = heartbeat_counter.data

  use resuming_info_holder <- result.try(
    resuming.info_holder_start()
    |> result.map_error(string.inspect),
  )
  let resuming_info_holder = resuming_info_holder.data

  use user_message_subject_holder <- result.try(
    user_message.new_subject_holder(None)
    |> result.map_error(string.inspect),
  )
  let user_message_subject_holder = user_message_subject_holder.data

  use connection_pid_holder <- result.try(
    connection_pid.new_holder()
    |> result.map_error(string.inspect),
  )
  let connection_pid_holder = connection_pid_holder.data

  let state =
    State(
      actor:,
      sequence_holder:,
      heartbeat_counter:,
      resuming_info_holder:,
      identify:,
      user_message_subject_holder:,
      connection_pid_holder:,
    )

  Ok(state)
}

fn on_message(
  client: grom.Client,
  state: State,
  message: stratus.Message(UserMessage),
  connection: stratus.Connection,
) {
  case message {
    stratus.Text(text_message) ->
      on_text_message(state, connection, text_message)
    stratus.User(user_message.StartResume) ->
      start_resume(client, state, connection)
    stratus.User(user_message.StartPresenceUpdate(msg)) ->
      start_presence_update(state, connection, msg)
    stratus.User(user_message.StartVoiceStateUpdate(msg)) ->
      start_voice_state_update(state, connection, msg)
    stratus.User(user_message.StartGuildMembersRequest(msg)) ->
      start_guild_members_request(state, connection, msg)
    stratus.User(user_message.StartSoundboardSoundsRequest(guild_ids)) ->
      start_soundboard_sounds_request(state, connection, guild_ids)
    _ -> stratus.continue(state)
  }
}

fn start_guild_members_request(
  state: State,
  connection: stratus.Connection,
  msg: RequestGuildMembersMessage,
) {
  let _ =
    msg
    |> user_message.request_guild_members_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_voice_state_update(
  state: State,
  connection: stratus.Connection,
  msg: UpdateVoiceStateMessage,
) {
  let _ =
    msg
    |> user_message.update_voice_state_message_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_presence_update(
  state: State,
  connection: stratus.Connection,
  msg: UpdatePresenceMessage,
) {
  let _ =
    msg
    |> user_message.update_presence_to_json(True)
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn start_soundboard_sounds_request(
  state: State,
  connection: stratus.Connection,
  guild_ids: List(String),
) {
  let json =
    json.object([
      #("op", json.int(31)),
      #("d", json.object([#("guild_ids", json.array(guild_ids, json.string))])),
    ])

  let _ =
    json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  stratus.continue(state)
}

fn on_text_message(
  state: State,
  connection: stratus.Connection,
  text_message: String,
) {
  use message <-
    fn(next) {
      case parse_message(text_message) {
        Ok(msg) -> next(msg)
        Error(err) -> {
          actor.send(state.actor, ErrorEvent(err))
          stratus.continue(state)
        }
      }
    }

  case message {
    Hello(event) -> on_hello_event(state, connection, event)
    Dispatch(sequence, message) -> on_dispatch(state, sequence, message)
    HeartbeatAcknowledged -> on_heartbeat_acknowledged(state)
    HeartbeatRequest -> on_heartbeat_request(state, connection)
    ReconnectRequest -> on_reconnect_request(state, connection)
  }

  stratus.continue(state)
}

fn on_reconnect_request(state: State, connection: stratus.Connection) -> Nil {
  let _ = stratus.close(connection, because: stratus.NotProvided)

  let resuming_info = resuming.get_info(state.resuming_info_holder)

  case resuming_info {
    Some(info) ->
      resuming.set_info(
        state.resuming_info_holder,
        to: Some(
          resuming.Info(
            ..info,
            last_received_close_reason: Some(stratus.NotProvided),
          ),
        ),
      )
    None -> Nil
  }

  case connection_pid.get(state.connection_pid_holder) {
    Some(pid) -> process.kill(pid)
    None -> Nil
  }
}

fn start_resume(
  client: grom.Client,
  state: State,
  connection: stratus.Connection,
) {
  let resuming_info = resuming.get_info(state.resuming_info_holder)
  let last_sequence = sequence.get(state.sequence_holder)

  let _ =
    case resuming_info, last_sequence {
      Some(info), Some(sequence) ->
        ResumeMessage(client.token, info.session_id, sequence)
      // unreachable - we need to have gotten the ready event otherwise we wouldn't even get here
      // really reconsidering my typing choices
      _, _ -> ResumeMessage("", "", 0)
    }
    |> resume_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(fn(error) {
      actor.send(state.actor, ErrorEvent(grom.CouldNotSendEvent(error)))
    })

  let heartbeat_counter = heartbeat.get(state.heartbeat_counter)

  start_heartbeats(state, connection, heartbeat_counter.interval)

  stratus.continue(state)
}

fn on_dispatch(state: State, sequence: Int, message: DispatchedMessage) {
  state.sequence_holder
  |> sequence.set(to: Some(sequence))

  case message {
    Ready(msg) -> on_ready(state, msg)
    Resumed -> actor.send(state.actor, ResumedEvent)
  }
}

fn on_ready(state: State, message: ReadyMessage) {
  state.resuming_info_holder
  |> resuming.set_info(
    to: Some(resuming.Info(
      session_id: message.session_id,
      resume_gateway_url: message.resume_gateway_url,
      last_received_close_reason: Some(stratus.NotProvided),
    )),
  )

  state.actor
  |> actor.send(ReadyEvent(message))
}

fn on_heartbeat_request(state: State, connection: stratus.Connection) -> Nil {
  case send_heartbeat(state, connection) {
    Ok(_) -> Nil
    Error(err) -> {
      state.actor
      |> actor.send(ErrorEvent(err))
    }
  }
}

fn on_heartbeat_acknowledged(state: State) -> Nil {
  state.heartbeat_counter
  |> heartbeat.acknoweledged
}

fn on_hello_event(
  state: State,
  connection: stratus.Connection,
  event: HelloMessage,
) {
  start_heartbeats(state, connection, event.heartbeat_interval)
  send_identify(state, connection)
}

fn send_identify(state: State, connection: stratus.Connection) {
  let result =
    state.identify
    |> identify_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent)

  case result {
    Ok(_) -> Nil
    Error(error) -> actor.send(state.actor, ErrorEvent(error))
  }
}

/// returns the pid of the process taking care of the heartbeat loop
fn start_heartbeats(
  state: State,
  connection: stratus.Connection,
  interval: Duration,
) {
  state.heartbeat_counter
  |> heartbeat.interval(interval)

  let regular_wait_duration =
    interval
    |> duration.to_seconds
    |> float.multiply(1000.0)
    |> float.round

  let initial_wait_duration =
    interval
    |> duration.to_seconds
    |> float.multiply(1000.0)
    |> float.multiply(jitter())
    |> float.round

  process.spawn(fn() {
    process.sleep(initial_wait_duration)

    use <-
      fn(next) {
        case
          send_heartbeat(state, connection)
          |> result.map_error(grom.CouldNotStartHeartbeatCycle)
        {
          Ok(_) -> next()
          Error(error) -> actor.send(state.actor, ErrorEvent(error))
        }
      }

    repeatedly.call(regular_wait_duration, Nil, fn(_state, _i) {
      case send_heartbeat(state, connection) {
        Ok(_) -> Nil
        Error(error) -> actor.send(state.actor, ErrorEvent(error))
      }
    })
    Nil
  })
}

fn send_heartbeat(
  state: State,
  connection: stratus.Connection,
) -> Result(Nil, grom.Error) {
  let last_sequence = sequence.get(state.sequence_holder)

  let counter = heartbeat.get(state.heartbeat_counter)
  use <- bool.guard(
    when: counter.heartbeat != counter.heartbeat_ack,
    return: stratus.close(connection, stratus.UnexpectedCondition(<<>>))
      |> result.map_error(grom.CouldNotCloseWebsocketConnection),
  )

  use _nil <- result.try(
    last_sequence
    |> HeartbeatMessage
    |> heartbeat_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.map_error(grom.CouldNotSendEvent),
  )

  Ok(heartbeat.sent(state.heartbeat_counter))
}

fn parse_message(text_message: String) -> Result(ReceivedMessage, grom.Error) {
  text_message
  |> json.parse(using: message_decoder())
  |> result.map_error(grom.CouldNotDecode)
}

fn jitter() -> Float {
  case float.random() {
    0.0 -> jitter()
    jitter -> jitter
  }
}

pub fn receive_opcode(event: ReceivedMessage) -> Int {
  case event {
    Dispatch(..) -> 0
    Hello(..) -> 10
    HeartbeatAcknowledged -> 11
    HeartbeatRequest -> 1
    ReconnectRequest -> 7
  }
}
