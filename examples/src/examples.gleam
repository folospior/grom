import gleam/erlang/process
import gleam/io
import gleam/option.{None, Some}
import gleam/otp/actor
import grom
import grom/gateway
import grom/gateway/intent
import grom/message
import grom/message/component
import grom/message/component/action_row.{ActionRow}
import grom/message/component/button

const token = "super secret token"

const channel_id = "1155216445211422794"

pub fn main() {
  let client = grom.Client(token:)

  let identify = gateway.identify(client, intent.all_unprivileged)

  // assume there's error handling here
  let assert Ok(actor) =
    actor.new(Nil)
    |> actor.on_message(fn(_current, event: gateway.Event) {
      case event {
        gateway.ReadyEvent(event) -> {
          io.println(event.application.id)
          let assert Ok(_) =
            message.Create(
              ..message.new_create(),
              content: Some("I'm ready!"),
              components: Some([
                component.ActionRow(
                  ActionRow(id: None, components: [
                    action_row.Button(button.Regular(
                      id: None,
                      is_disabled: False,
                      style: button.Primary,
                      label: Some("Click me!"),
                      emoji: None,
                      custom_id: "not_implemented_yet :(",
                    )),
                  ]),
                ),
              ]),
            )
            |> message.create(client, in: channel_id, using: _)
          actor.continue(Nil)
        }
        _ -> actor.continue(Nil)
      }
    })
    |> actor.start

  let actor = actor.data

  let assert Ok(_) = gateway.start(client, identify, actor)
  process.sleep_forever()
}
