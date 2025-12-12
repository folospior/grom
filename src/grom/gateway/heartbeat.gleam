import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/otp/actor
import gleam/result
import gleam/time/duration.{type Duration}
import grom

pub opaque type CounterMessage {
  Heartbeat
  HeartbeatAck
  ResetCounter
  GetCounter(reply_recipient: Subject(Counter))
}

pub type Message {
  Tick
  Stop
}

pub type State {
  State(callback: fn() -> Nil, interval: Duration, subject: Subject(Message))
}

pub type Counter {
  Counter(heartbeat: Int, heartbeat_ack: Int)
}

pub type IntervalMessage {
  GetInterval(reply_to: Subject(Duration))
  SetInterval(to: Duration)
}

pub fn start_interval_holder() {
  actor.new(duration.seconds(0))
  |> actor.on_message(on_interval_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

fn on_interval_message(current: Duration, message: IntervalMessage) {
  case message {
    GetInterval(reply_to:) -> {
      actor.send(reply_to, current)
      actor.continue(current)
    }
    SetInterval(to: new) -> actor.continue(new)
  }
}

pub fn get_interval(actor: Subject(IntervalMessage)) -> Duration {
  actor.call(actor, 10, GetInterval)
}

pub fn set_interval(actor: Subject(IntervalMessage), to new: Duration) -> Nil {
  actor.send(actor, SetInterval(to: new))
}

pub fn start(
  call callback: fn() -> Nil,
  every interval: Duration,
  after initial_wait: Duration,
) -> Result(actor.Started(Subject(Message)), grom.Error) {
  actor.new_with_initialiser(20, fn(subject) {
    let selector =
      process.new_selector()
      |> process.select(subject)

    subject
    |> process.send_after(
      initial_wait
        |> duration.to_seconds
        |> float.multiply(1000.0)
        |> float.round,
      Tick,
    )

    actor.initialised(State(callback:, interval:, subject:))
    |> actor.selecting(selector)
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

fn on_message(state: State, message: Message) {
  case message {
    Tick -> {
      state.callback()

      process.send_after(
        state.subject,
        state.interval
          |> duration.to_seconds
          |> float.multiply(1000.0)
          |> float.round,
        Tick,
      )

      actor.continue(state)
    }
    Stop -> {
      actor.stop()
    }
  }
}

pub fn counter_start() {
  actor.new(Counter(0, 0))
  |> actor.on_message(on_counter_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

pub fn get_count(actor: Subject(CounterMessage)) -> Counter {
  actor.call(actor, 10, GetCounter)
}

pub fn sent(actor: Subject(CounterMessage)) -> Nil {
  actor.send(actor, Heartbeat)
}

pub fn acknowledged(actor: Subject(CounterMessage)) -> Nil {
  actor.send(actor, HeartbeatAck)
}

pub fn reset(actor: Subject(CounterMessage)) -> Nil {
  actor.send(actor, ResetCounter)
}

fn on_counter_message(current: Counter, message: CounterMessage) {
  case message {
    GetCounter(..) -> {
      actor.send(message.reply_recipient, current)
      actor.continue(current)
    }
    Heartbeat ->
      actor.continue(Counter(..current, heartbeat: current.heartbeat + 1))
    HeartbeatAck ->
      actor.continue(
        Counter(..current, heartbeat_ack: current.heartbeat_ack + 1),
      )
    ResetCounter -> actor.continue(Counter(0, 0))
  }
}
