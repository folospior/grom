import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import stratus

pub opaque type Message {
  GetPid(reply_to: Subject(Option(process.Pid)))
  SetPid(new: process.Pid)
  Get(reply_to: Subject(Option(stratus.Connection)))
  Set(new: stratus.Connection)
}

pub type State {
  State(pid: Option(process.Pid), connection: Option(stratus.Connection))
}

pub fn new_holder() {
  actor.new(State(None, None))
  |> actor.on_message(on_message)
  |> actor.start
}

pub fn get_pid(actor: Subject(Message)) -> Option(process.Pid) {
  actor.call(actor, 10, GetPid)
}

pub fn set_pid(actor: Subject(Message), to new: process.Pid) -> Nil {
  actor.send(actor, SetPid(new:))
}

pub fn get(actor: Subject(Message)) -> Option(stratus.Connection) {
  actor.call(actor, 10, Get)
}

pub fn set(actor: Subject(Message), to new: stratus.Connection) {
  actor.send(actor, Set(new))
}

fn on_message(current: State, message: Message) {
  case message {
    GetPid(..) -> {
      actor.send(message.reply_to, current.pid)
      actor.continue(current)
    }
    SetPid(new:) -> actor.continue(State(..current, pid: Some(new)))
    Get(..) -> {
      actor.send(message.reply_to, current.connection)
      actor.continue(current)
    }
    Set(new:) -> actor.continue(State(..current, connection: Some(new)))
  }
}
