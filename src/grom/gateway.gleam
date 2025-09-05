import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import gleam/time/duration.{type Duration}
import grom
import grom/gateway/sequence
import grom/internal/rest
import grom/internal/time_duration
import stratus

// TYPES -----------------------------------------------------------------------

pub type GatewayData {
  GatewayData(
    url: String,
    recommended_shards: Int,
    session_start_limits: SessionStartLimits,
  )
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
  State(sequence_holder: Subject(sequence.Message))
}

// RECEIVE EVENTS --------------------------------------------------------------

pub type ReceivedMessage {
  Hello(HelloMessage)
}

pub type HelloMessage {
  HelloMessage(heartbeat_interval: Duration)
}

// SEND EVENTS -----------------------------------------------------------------

pub type SentMessage {
  Heartbeat(HeartbeatMessage)
}

pub type HeartbeatMessage {
  HeartbeatMessage(last_sequence: Option(Int))
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
    10 -> {
      use msg <- decode.field("d", hello_event_decoder())
      decode.success(Hello(msg))
    }
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

// ENCODERS --------------------------------------------------------------------

@internal
pub fn message_to_json(message: SentMessage) -> Json {
  case message {
    Heartbeat(msg) -> heartbeat_to_json(msg)
  }
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

pub fn start(client: grom.Client) {
  use gateway_data <- result.try(
    client
    |> get_data,
  )

  use connection_request <- result.try(
    request.to(gateway_data.url <> "?v=10&encoding=json")
    |> result.replace_error(grom.InvalidGatewayUrl(gateway_data.url)),
  )

  stratus.new_with_initialiser(connection_request, init_connection)
  |> stratus.on_message(on_message)
  |> stratus.start
  |> result.map_error(grom.CouldNotInitializeWebsocketConnection)
}

fn init_connection() {
  use sequence_holder <- result.try(
    sequence.holder_start() |> result.map_error(string.inspect),
  )
  let sequence_holder = sequence_holder.data

  let state = State(sequence_holder:)

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
  let message = case parse_message(text_message) {
    Ok(message) -> message
    Error(_) -> todo as "proper error handling"
  }

  case message.sequence {
    None -> Nil
    sequence -> sequence.set(state.sequence_holder, to: sequence)
  }

  case message.event {
    Receive(Hello(event)) -> on_hello_event(event)
    Send(_) -> {
      let _ = stratus.close_unexpected_condition(connection, <<>>)
      Nil
    }
  }

  stratus.continue(state)
}

fn on_hello_event(event: HelloEvent) {
  start_heartbeats(event.heartbeat_interval)
}

fn start_heartbeats(interval: Duration) {
  let wait_duration =
    interval
    |> duration.to_seconds
    |> float.multiply(1000.0)
    |> float.multiply(jitter())
    |> float.round

  process.spawn(fn() {
    process.sleep(wait_duration)
    //
  })
  Nil
}

fn send_heartbeat(state: State, connection: stratus.Connection) {
  let last_sequence = sequence.get(state.sequence_holder)

  last_sequence
  |> HeartbeatEvent
}

fn parse_message(text_message: String) -> Result(Message, grom.Error) {
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

pub fn receive_opcode(event: ReceiveEvent) -> Int {
  case event {
    Hello(..) -> 10
  }
}
