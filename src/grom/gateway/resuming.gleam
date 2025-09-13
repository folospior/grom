import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import grom
import stratus

pub opaque type Message {
  GetInfo(reply_to: Subject(Option(Info)))
  SetInfo(to: Info)
}

pub type Info {
  Info(
    session_id: String,
    resume_gateway_url: String,
    last_received_close_reason: Option(stratus.CloseReason),
  )
}

pub fn info_holder_start() {
  actor.new(None)
  |> actor.on_message(on_message)
  |> actor.start
  |> result.map_error(grom.CouldNotStartActor)
}

pub fn get_info(actor: Subject(Message)) -> Option(Info) {
  actor.call(actor, 10, GetInfo)
}

pub fn set_info(actor: Subject(Message), to info: Info) -> Nil {
  actor.send(actor, SetInfo(to: info))
}

fn on_message(current: Option(Info), message: Message) {
  case message {
    GetInfo(..) -> {
      actor.send(message.reply_to, current)
      actor.continue(current)
    }
    SetInfo(..) -> actor.continue(Some(message.to))
  }
}
