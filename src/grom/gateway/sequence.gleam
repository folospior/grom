import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import grom

pub type Message {
  Get(reply_to: Subject(Option(Int)))
  Set(Option(Int))
  Shutdown
}

pub fn new_holder() -> Result(actor.Started(Subject(Message)), grom.Error) {
  actor.new(None)
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

pub fn get(from actor: Subject(Message)) -> Option(Int) {
  actor
  |> actor.call(10, Get)
}

pub fn set(actor: Subject(Message), to new: Option(Int)) -> Nil {
  actor
  |> actor.send(Set(new))
}

pub fn shutdown(actor: Subject(Message)) -> Nil {
  actor
  |> actor.send(Shutdown)
}

fn on_message(
  current: Option(Int),
  message: Message,
) -> actor.Next(Option(Int), a) {
  case message {
    Set(new) -> actor.continue(new)
    Get(..) -> {
      process.send(message.reply_to, current)
      actor.continue(current)
    }
    Shutdown -> actor.stop()
  }
}
