import gleam/erlang/process
import gleam/otp/actor
import grom
import grom/channel
import grom/gateway
import grom/gateway/intent
import grom/guild
import grom/message

const token = "super secret token"

pub fn main() {
  let client = grom.Client(token:)

  let identify = gateway.identify(client, intent.all_unprivileged)

  let assert Ok(actor) =
    actor.new(Nil)
    |> actor.on_message(fn(_current, event: gateway.Event) {
      case event {
        gateway.ReadyEvent(_event) -> {
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
