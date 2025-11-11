import dotenv_gleam
import envoy
import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/actor
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
    |> gateway.identify(intents: intent.all_unprivileged)

  let state = State(client:)

  use actor <- create_actor(state)

  let gateway_start_result =
    client
    |> gateway.start(identify, notify: actor)

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

fn create_actor(
  state: State,
  next: fn(process.Subject(gateway.Event)) -> Nil,
) -> Nil {
  let actor =
    actor.new(state)
    |> actor.on_message(on_event)
    |> actor.start

  case actor {
    Ok(actor) -> next(actor.data)
    Error(err) ->
      logging.log(
        logging.Critical,
        "Couldn't start the gateway: " <> string.inspect(err),
      )
  }
}

fn on_event(state: State, event: gateway.Event) {
  case event {
    gateway.ErrorEvent(error) -> {
      logging.log(logging.Warning, string.inspect(error))
      actor.continue(state)
    }
    gateway.ReadyEvent(ready) -> on_ready(state, ready)
    gateway.InteractionCreatedEvent(interaction) ->
      on_interaction_created(state, interaction)
    _ -> actor.continue(state)
  }
}

fn on_ready(state: State, ready: gateway.ReadyMessage) {
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
      actor.continue(state)
    }
    Error(err) -> {
      logging.log(
        logging.Error,
        "Couldn't bulk overwrite global commands: " <> string.inspect(err),
      )
      actor.stop()
    }
  }
}

fn on_interaction_created(state: State, interaction: Interaction) {
  case interaction.data {
    interaction.CommandExecuted(command) ->
      on_command_executed(state, interaction, command)
    _ -> actor.continue(state)
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
    _ -> actor.continue(state)
  }
}

fn on_slash_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.SlashCommandExecution,
) {
  case command.name {
    "ping" -> on_ping_command(state, interaction)
    _ -> actor.continue(state)
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

  actor.continue(state)
}
