import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import grom
import stratus

pub opaque type Message {
  GetInfo(reply_to: Subject(Option(Info)))
  SetInfo(to: Option(Info))
  IsResumed(reply_to: Subject(Bool))
  Reset
}

pub type Info {
  Info(
    session_id: String,
    resume_gateway_url: String,
    last_received_close_reason: Option(stratus.CloseReason),
    connection_pid: Option(process.Pid),
    is_resumed: Bool,
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

pub fn set_info(actor: Subject(Message), to info: Option(Info)) -> Nil {
  actor.send(actor, SetInfo(to: info))
}

pub fn is_resumed(actor: Subject(Message)) -> Bool {
  actor.call(actor, 10, IsResumed)
}

pub fn reset(actor: Subject(Message)) -> Nil {
  actor.send(actor, Reset)
}

fn on_message(current: Option(Info), message: Message) {
  case message {
    GetInfo(..) -> {
      actor.send(message.reply_to, current)
      actor.continue(current)
    }
    IsResumed(..) -> {
      case current {
        Some(info) -> actor.send(message.reply_to, info.is_resumed)
        None -> actor.send(message.reply_to, False)
      }
      actor.continue(current)
    }
    SetInfo(..) ->
      case message.to {
        Some(info) -> {
          let url =
            string.replace(
              in: info.resume_gateway_url,
              each: "wss://",
              with: "https://",
            )
            <> "?v=10&encoding=json"
          let info =
            Info(
              info.session_id,
              url,
              info.last_received_close_reason,
              info.connection_pid,
              info.is_resumed,
            )
          actor.continue(Some(info))
        }
        None -> actor.continue(None)
      }
    Reset -> actor.continue(None)
  }
}

pub fn is_possible(info: Info) -> Bool {
  case info.last_received_close_reason {
    None -> False
    Some(stratus.NotProvided) -> True
    Some(stratus.Custom(reason)) -> {
      case stratus.get_custom_code(reason) {
        4000 -> True
        4001 -> True
        4002 -> True
        4003 -> True
        4004 -> False
        4005 -> True
        4007 -> True
        4008 -> True
        4009 -> True
        4010 -> False
        4011 -> False
        4012 -> False
        4013 -> False
        4014 -> False
        _ -> False
      }
    }
    Some(_) -> False
  }
}
