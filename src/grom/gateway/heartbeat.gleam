import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import gleam/time/duration.{type Duration}
import grom

pub opaque type Message {
  Heartbeat
  HeartbeatAck
  Interval(Duration)
  Reset
  Get(reply_recipient: Subject(Counter))
}

pub type Counter {
  Counter(interval: Duration, heartbeat: Int, heartbeat_ack: Int)
}

pub fn counter_start() {
  actor.new(Counter(duration.seconds(0), 0, 0))
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

pub fn get(actor: Subject(Message)) -> Counter {
  actor.call(actor, 10, Get)
}

pub fn sent(actor: Subject(Message)) -> Nil {
  actor.send(actor, Heartbeat)
}

pub fn acknoweledged(actor: Subject(Message)) -> Nil {
  actor.send(actor, HeartbeatAck)
}

pub fn interval(actor: Subject(Message), interval: Duration) -> Nil {
  actor.send(actor, Interval(interval))
}

pub fn reset(actor: Subject(Message)) -> Nil {
  actor.send(actor, Reset)
}

fn on_message(current: Counter, message: Message) {
  case message {
    Get(..) -> {
      actor.send(message.reply_recipient, current)
      actor.continue(current)
    }
    Heartbeat ->
      actor.continue(Counter(..current, heartbeat: current.heartbeat + 1))
    HeartbeatAck ->
      actor.continue(
        Counter(..current, heartbeat_ack: current.heartbeat_ack + 1),
      )
    Interval(interval) -> actor.continue(Counter(..current, interval:))
    Reset -> actor.continue(Counter(duration.seconds(0), 0, 0))
  }
}
