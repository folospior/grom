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
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/activity.{type Activity}
import grom/application
import grom/gateway/heartbeat
import grom/gateway/intent.{type Intent}
import grom/gateway/resuming
import grom/gateway/sequence
import grom/guild
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_timestamp
import grom/user.{type User, User}
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

pub type PresenceStatus {
  Online
  DoNotDisturb
  Idle
  Invisible
  Offline
}

pub type Event {
  ReadyEvent(ReadyMessage)
  ErrorEvent(grom.Error)
}

pub type SessionStartLimits {
  SessionStartLimits(
    maximum_starts: Int,
    remaining_starts: Int,
    resets_after: Duration,
    max_identify_requests_per_5_seconds: Int,
  )
}

type State {
  State(
    actor: Subject(Event),
    sequence_holder: Subject(sequence.Message),
    heartbeat_counter: Subject(heartbeat.Message),
    resuming_info_holder: Subject(resuming.Message),
    identify: IdentifyMessage,
  )
}

// RECEIVE EVENTS --------------------------------------------------------------

pub type ReceivedMessage {
  Hello(HelloMessage)
  Dispatch(DispatchedMessage)
  HeartbeatAcknowledged
  HeartbeatRequest
}

pub type HelloMessage {
  HelloMessage(heartbeat_interval: Duration)
}

// RECEIVED DISPATCH EVENTS ----------------------------------------------------

pub type DispatchedMessage {
  Ready(sequence: Int, data: ReadyMessage)
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
  UpdatePresence(UpdatePresenceMessage)
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

pub type UpdatePresenceMessage {
  UpdatePresenceMessage(
    /// Only for Idle.
    since: Option(Timestamp),
    activities: List(Activity),
    status: PresenceStatus,
    is_afk: Bool,
  )
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
      use data <- decode.field("d", case type_ {
        "READY" -> {
          use ready <- decode.then(ready_message_decoder())
          decode.success(Ready(sequence, ready))
        }
        _ ->
          decode.failure(
            Ready(
              0,
              ReadyMessage(
                api_version: 0,
                user: User(
                  "",
                  "",
                  "",
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                  None,
                ),
                guilds: [],
                session_id: "",
                resume_gateway_url: "",
                shard: None,
                application: ReadyApplication("", []),
              ),
            ),
            "DispatchedMessage",
          )
      })
      decode.success(Dispatch(data))
    }
    1 -> decode.success(HeartbeatRequest)
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
    UpdatePresence(msg) -> update_presence_to_json(msg, True)
  }
}

fn update_presence_to_json(
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

fn presence_status_to_json(status: PresenceStatus) -> Json {
  case status {
    Online -> "online"
    DoNotDisturb -> "dnd"
    Idle -> "idle"
    Invisible -> "invisible"
    Offline -> "offline"
  }
  |> json.string
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
        #("presence", update_presence_to_json(presence, False)),
      ]
      None -> []
    }

    let intents = [
      #("intents", flags.encode(msg.intents, intent.bits_intents())),
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
  use gateway_data <- result.try(
    client
    |> get_data,
  )

  let request_url =
    string.replace(in: gateway_data.url, each: "wss://", with: "https://")
    <> "?v=10&encoding=json"

  use connection_request <- result.try(
    request.to(request_url)
    |> result.replace_error(grom.InvalidGatewayUrl(gateway_data.url)),
  )

  stratus.new_with_initialiser(connection_request, fn() {
    init_state(actor, identify)
  })
  |> stratus.on_message(on_message)
  |> stratus.start
  |> result.map_error(grom.CouldNotInitializeWebsocketConnection)
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

  let state =
    State(
      actor:,
      sequence_holder:,
      heartbeat_counter:,
      resuming_info_holder:,
      identify:,
    )

  Ok(stratus.initialised(state))
}

fn on_message(
  state: State,
  message: stratus.Message(a),
  connection: stratus.Connection,
) {
  case message {
    stratus.Text(text_message) ->
      on_text_message(state, connection, text_message)
    _ -> stratus.continue(state)
  }
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
    Dispatch(message) -> on_dispatch(state, message)
    HeartbeatAcknowledged -> on_heartbeat_acknowledged(state)
    HeartbeatRequest -> on_heartbeat_request(state, connection)
  }

  stratus.continue(state)
}

fn on_dispatch(state: State, message: DispatchedMessage) {
  state.sequence_holder
  |> sequence.set(to: Some(message.sequence))

  case message {
    Ready(data:, ..) -> on_ready(state, data)
  }
}

fn on_ready(state: State, message: ReadyMessage) {
  state.resuming_info_holder
  |> resuming.set_info(to: resuming.Info(
    session_id: message.session_id,
    resume_gateway_url: message.resume_gateway_url,
    last_received_close_reason: None,
  ))

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

fn start_heartbeats(
  state: State,
  connection: stratus.Connection,
  interval: Duration,
) {
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
  Nil
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
  }
}
