import dotenv_gleam
import envoy
import gleam/erlang/process
import gleam/option.{Some}
import gleam/string
import grom
import grom/command
import grom/gateway
import grom/gateway/intent
import grom/interaction.{type Interaction}
import logging

type State {
  State(client: grom.Client)
}

pub fn main() -> Nil {
  logging.configure()

  let assert Ok(_) = dotenv_gleam.config()
  let assert Ok(token) = envoy.get("BOT_TOKEN")

  let client = grom.Client(token:)

  let identify =
    client
    |> gateway.identify(intents: intent.all)

  let assert Ok(data) = gateway.get_data(client)

  let gateway_start_result =
    gateway.new(State(client), identify, data)
    |> gateway.on_event(do: on_event)
    |> gateway.start

  case gateway_start_result {
    Ok(_) -> {
      logging.log(logging.Info, "Started the gateway!")
      process.sleep_forever()
    }
    Error(err) -> {
      logging.log(
        logging.Error,
        "Couldn't start the gateway: " <> string.inspect(err),
      )
    }
  }
}

fn on_event(state: State, event: gateway.Event) {
  case event {
    gateway.ErrorEvent(error) -> {
      logging.log(logging.Warning, string.inspect(error))
      gateway.continue(state)
    }
    gateway.AllShardsReadyEvent(ready) -> on_ready(state, ready)
    gateway.InteractionCreatedEvent(interaction) ->
      on_interaction_created(state, interaction)
    _ -> gateway.continue(state)
  }
}

fn on_ready(state: State, ready: gateway.AllShardsReadyMessage) {
  logging.log(logging.Info, "Ready!")

  let global_commands = [
    command.CreateGlobalSlash(command.new_create_global_slash_command(
      named: "ping",
      description: "Ping-pong! 🏓",
    )),
  ]

  let bulk_overwrite_result =
    state.client
    |> command.bulk_overwrite_global(
      of: ready.application.id,
      new: global_commands,
    )

  case bulk_overwrite_result {
    Ok(_) -> {
      logging.log(
        logging.Info,
        "Overwrote the commands for " <> ready.application.id,
      )
    }
    Error(err) -> {
      logging.log(
        logging.Error,
        "Couldn't bulk overwrite global commands: " <> string.inspect(err),
      )
    }
  }

  gateway.continue(state)
}

fn on_interaction_created(state: State, interaction: Interaction) {
  case interaction.data {
    interaction.CommandExecuted(command) ->
      on_command_executed(state, interaction, command)
    _ -> gateway.continue(state)
  }
}

fn on_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.CommandExecution,
) {
  case command {
    interaction.SlashCommandExecuted(command) ->
      on_slash_command_executed(state, interaction, command)
    _ -> gateway.continue(state)
  }
}

fn on_slash_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.SlashCommandExecution,
) {
  case command.name {
    "ping" -> on_ping_command(state, interaction)
    _ -> gateway.continue(state)
  }
}

fn on_ping_command(state: State, interaction: Interaction) {
  let response =
    interaction.RespondWithChannelMessageWithSource(
      interaction.ResponseMessage(
        ..interaction.new_response_message(),
        content: Some("Pong!"),
      ),
    )

  let _response_result =
    state.client
    |> interaction.respond(to: interaction, using: response)

  gateway.continue(state)
}
