import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import grom
import stratus

pub opaque type Message {
  GetInfo(reply_to: Subject(Option(Info)))
  SetInfo(to: Option(Info))
  Reset
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

pub fn set_info(actor: Subject(Message), to info: Option(Info)) -> Nil {
  actor.send(actor, SetInfo(to: info))
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
          let info = Info(info.session_id, url, info.last_received_close_reason)
          actor.continue(Some(info))
        }
        None -> actor.continue(None)
      }
    Reset -> actor.continue(None)
  }
}

pub fn is_possible(info: Info) -> Bool {
  let resumable_codes = [4000, 4001, 4002, 4003, 4005, 4007, 4008, 4009]

  // None - not resumable
  // NotProvided - resumable
  case info.last_received_close_reason {
    Some(stratus.NotProvided) -> True
    Some(stratus.Custom(reason)) ->
      resumable_codes
      |> list.contains(stratus.get_custom_code(reason))
    _ -> False
  }
}
