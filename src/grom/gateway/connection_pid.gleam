import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor

pub opaque type Message {
  Get(reply_to: Subject(Option(process.Pid)))
  Set(new: process.Pid)
  Reset
}

pub fn new_holder() {
  actor.new(None)
  |> actor.on_message(on_message)
  |> actor.start
}

pub fn get(actor: Subject(Message)) -> Option(process.Pid) {
  actor.call(actor, 10, Get)
}

pub fn set(actor: Subject(Message), to new: process.Pid) -> Nil {
  actor.send(actor, Set(new:))
}

pub fn reset(actor: Subject(Message)) -> Nil {
  actor.send(actor, Reset)
}

fn on_message(current: Option(process.Pid), message: Message) {
  case message {
    Get(..) -> {
      actor.send(message.reply_to, current)
      actor.continue(current)
    }
    Set(new:) -> actor.continue(Some(new))
    Reset -> actor.continue(None)
  }
}
