import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/actor
import grom
import grom/application/current_application
import grom/command
import grom/component/container.{Container}
import grom/component/text_display
import grom/gateway
import grom/gateway/intent
import grom/interaction.{type Interaction}
import grom/message
import grom/permission

const token = "super secret token"

pub type State {
  State(client: grom.Client)
}

// Assume there's error handling all over this code
pub fn main() {
  let client = grom.Client(token:)

  let assert Ok(application) =
    client
    |> current_application.get()

  let assert Ok(_commands) =
    client
    |> command.bulk_overwrite_global(of: application.id, new: [
      command.CreateGlobalSlash(
        command.CreateGlobalSlashCommand(
          ..command.new_create_global_slash_command(
            named: "hello",
            description: "A welcoming message",
          ),
          // Require users to be administrators in order to use this command.
          default_member_permissions: Some([
            permission.Administrator,
          ]),
        ),
      ),
      command.CreateGlobalUser(command.new_create_global_user_command(
        named: "Get avatar",
      )),
    ])

  let identify = gateway.identify(client, intent.all_unprivileged)

  let state = State(client:)

  let assert Ok(actor) =
    actor.new(state)
    |> actor.on_message(on_event)
    |> actor.start
  let actor = actor.data

  let assert Ok(_) = gateway.start(client, identify, actor)
  process.sleep_forever()
}

fn on_event(state: State, event: gateway.Event) {
  case event {
    gateway.InteractionCreatedEvent(interaction) -> {
      on_interaction_created(state, interaction)
      actor.continue(state)
    }
    _ -> actor.continue(state)
  }
}

fn on_interaction_created(state: State, interaction: Interaction) {
  case interaction.data {
    interaction.CommandExecuted(command) ->
      on_command_executed(state, interaction, command)
    _ -> Nil
  }
}

fn on_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.CommandExecution,
) {
  case command {
    interaction.SlashCommandExecuted(executed) ->
      on_slash_command_executed(state, interaction, executed)
    _ -> Nil
  }
}

fn on_slash_command_executed(
  state: State,
  interaction: Interaction,
  executed: interaction.SlashCommandExecution,
) {
  case executed.command_name {
    "hello" -> on_hello_command(state, interaction)
    _ -> Nil
  }
}

fn on_hello_command(state: State, interaction: Interaction) {
  let _ =
    state.client
    |> interaction.respond(
      to: interaction,
      using: interaction.RespondWithChannelMessageWithSource(
        interaction.ResponseMessage(
          ..interaction.new_response_message(),
          flags: Some([interaction.ResponseMessageWithComponentsV2]),
          components: Some([
            message.Container(
              Container(
                ..container.new(containing: [
                  container.TextDisplay(text_display.new(
                    showing: "# Welcome to Grom!",
                  )),
                ]),
                accent_color: Some(0xffaff3),
              ),
            ),
          ]),
        ),
      ),
    )
  Nil
}
