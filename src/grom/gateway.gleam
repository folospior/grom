import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import grom
import grom/gateway/handlers.{type Handlers}
import grom/gateway/sequence
import grom/internal/rest
import repeatedly.{type Repeater}
import stratus

pub type GatewayResponse {
  GatewayResponse(
    url: String,
    shards: Int,
    session_start_limit: SessionStartLimit,
  )
}

pub type ReceiveEvent {
  Hello(HelloEvent)
  HeartbeatAcknowledged
}

pub type SendEvent {
  Heartbeat(HeartbeatEvent)
}

pub type HelloEvent {
  HelloEvent(heartbeat_interval: Duration)
}

pub type HeartbeatEvent {
  HeartbeatEvent(sequence: Option(Int))
}

pub type SessionStartLimit {
  SessionStartLimit(
    total: Int,
    remaining: Int,
    reset_after: Duration,
    /// Max amount of Identify requests allowed per 5 seconds
    max_concurrency: Int,
  )
}

type State {
  State(
    sequence_holder: Subject(sequence.Message),
    heartbeat_loop: Option(Repeater(Nil)),
  )
}

pub fn start(client: grom.Client, handlers: Handlers(a)) {
  use gateway_response <- result.try(
    client
    |> rest.new_request(http.Get, "/gateway/bot")
    |> rest.execute,
  )

  use gateway <- result.try(
    gateway_response.body
    |> json.parse(using: decoder())
    |> result.map_error(grom.CouldNotDecode),
  )

  let connection_url = gateway.url <> "?v=10&encoding=json"

  use connection_request <- result.try(
    request.to(connection_url)
    |> result.replace_error(grom.InvalidGatewayUrl(connection_url)),
  )

  use sequence_holder <- result.try(sequence.new_holder())
  let sequence_holder = sequence_holder.data

  let connection_builder =
    stratus.websocket(
      request: connection_request,
      init: fn() { #(State(sequence_holder:, heartbeat_loop: None), None) },
      loop: fn(state, message, connection) {
        case message {
          stratus.Text(event) -> {
            case on_receive_event(event, state, connection, handlers) {
              Ok(state) -> stratus.continue(state)
              Error(error) -> {
                handlers.error_handler(error)
                stratus.continue(state)
              }
            }
          }
          _ -> stratus.continue(state)
        }
      },
    )
    |> stratus.on_close(fn(state) {
      case state.heartbeat_loop {
        Some(loop) -> repeatedly.stop(loop)
        None -> Nil
      }
    })

  stratus.initialize(connection_builder)
  |> result.map_error(grom.CouldNotStartActor)
}

@internal
pub fn decoder() -> decode.Decoder(GatewayResponse) {
  use url <- decode.field("url", decode.string)
  use shards <- decode.field("shards", decode.int)
  use session_start_limit <- decode.field(
    "session_start_limit",
    session_start_limit_decoder(),
  )

  decode.success(GatewayResponse(url:, shards:, session_start_limit:))
}

@internal
pub fn session_start_limit_decoder() -> decode.Decoder(SessionStartLimit) {
  use total <- decode.field("total", decode.int)
  use remaining <- decode.field("remaining", decode.int)
  use reset_after <- decode.field("reset_after", {
    use duration <- decode.then(decode.int)

    duration
    |> duration.milliseconds
    |> decode.success
  })
  use max_concurrency <- decode.field("max_concurrency", decode.int)

  decode.success(SessionStartLimit(
    total:,
    remaining:,
    reset_after:,
    max_concurrency:,
  ))
}

fn on_receive_event(
  event: String,
  state: State,
  connection: stratus.Connection,
  handlers: Handlers(a),
) -> Result(State, grom.Error) {
  use event <- result.try(
    event
    |> json.parse(using: receive_event_decoder())
    |> result.map_error(grom.CouldNotDecode),
  )

  case event {
    Hello(event) -> on_hello_event(event, state, connection, handlers)
  }
}

fn on_hello_event(
  event: HelloEvent,
  state: State,
  connection: stratus.Connection,
  handlers: Handlers(a),
) -> Result(State, grom.Error) {
  let interval_milliseconds =
    event.heartbeat_interval
    |> duration.to_seconds
    |> float.multiply(1000.0)

  interval_milliseconds
  |> float.multiply(get_jitter())
  |> float.round
  |> process.sleep

  use _ <- result.try(
    HeartbeatEvent(None)
    |> heartbeat_event_to_json
    |> json.to_string
    |> stratus.send_text_message(connection, _)
    |> result.replace_error(grom.CouldNotSendSocketMessage),
  )

  let repeater =
    repeatedly.call(float.round(interval_milliseconds), Nil, fn(_state, _i) {
      let sequence =
        state.sequence_holder
        |> sequence.get

      case
        {
          HeartbeatEvent(sequence:)
          |> heartbeat_event_to_json
          |> json.to_string
          |> stratus.send_text_message(connection, _)
          |> result.replace_error(grom.CouldNotSendSocketMessage)
        }
      {
        Ok(_) -> Nil
        Error(error) -> {
          handlers.error_handler(error)
          Nil
        }
      }
    })

  Ok(State(..state, heartbeat_loop: Some(repeater)))
}

fn get_jitter() -> Float {
  case float.random() {
    0.0 -> get_jitter()
    x -> x
  }
}

fn receive_event_decoder() -> decode.Decoder(ReceiveEvent) {
  use opcode <- decode.field("op", decode.int)
  use data <- decode.optional_field("d", HeartbeatAcknowledged, case opcode {
    10 -> hello_event_decoder()
    _ -> decode.failure(Hello(HelloEvent(duration.seconds(0))), "ReceiveEvent")
  })

  decode.success(data)
}

fn hello_event_decoder() -> decode.Decoder(ReceiveEvent) {
  use heartbeat_interval <- decode.field("heartbeat_interval", {
    use duration <- decode.then(decode.int)

    duration
    |> duration.milliseconds
    |> decode.success
  })

  decode.success(Hello(HelloEvent(heartbeat_interval:)))
}

fn heartbeat_event_to_json(event: HeartbeatEvent) -> json.Json {
  json.object([
    #("op", json.int(1)),
    #("d", json.nullable(event.sequence, json.int)),
  ])
}
