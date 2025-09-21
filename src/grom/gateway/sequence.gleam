import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import grom

pub opaque type Message {
  Set(to: Option(Int))
  Get(reply_recipient: Subject(Option(Int)))
  Reset
}

pub fn holder_start() {
  actor.new(None)
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

pub fn set(actor: Subject(Message), to new: Option(Int)) -> Nil {
  actor.send(actor, Set(new))
}

pub fn get(actor: Subject(Message)) -> Option(Int) {
  actor.call(actor, 10, Get)
}

pub fn reset(actor: Subject(Message)) -> Nil {
  actor.send(actor, Reset)
}

fn on_message(current: Option(Int), message: Message) {
  case message {
    Set(to: new) -> actor.continue(new)
    Get(reply_recipient:) -> {
      actor.send(reply_recipient, current)
      actor.continue(current)
    }
    Reset -> actor.continue(None)
  }
}
