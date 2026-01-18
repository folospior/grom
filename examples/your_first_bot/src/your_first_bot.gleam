import dotenv_gleam
import envoy
import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/string
import grom
import grom/activity
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

  let state = State(client:)

  let assert Ok(data) = gateway.get_data(client)

  let gateway_start_result =
    gateway.new(state, identify, data)
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
    gateway.ReadyEvent(ready) -> on_ready(state, ready)
    gateway.InteractionCreatedEvent(interaction) ->
      on_interaction_created(state, interaction)
    _ -> gateway.continue(state)
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
    }
    Error(err) -> {
      logging.log(
        logging.Error,
        "Couldn't bulk overwrite global commands: " <> string.inspect(err),
      )
    }
  }

  connection
  |> gateway.update_presence(using: gateway.UpdatePresenceMessage(
    status: gateway.Online,
    since: None,
    activities: [
      activity.new(named: "the gateway connection", type_: activity.Watching),
    ],
    is_afk: False,
  ))

  gateway.continue(state)
}

fn on_interaction_created(
  state: State,
  interaction: Interaction,
  connection: gateway.Connection(State),
) {
  case interaction.data {
    interaction.CommandExecuted(command) ->
      on_command_executed(state, interaction, command, connection)
    _ -> gateway.continue(state)
  }
}

fn on_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.CommandExecution,
  connection: gateway.Connection(State),
) {
  case command {
    interaction.SlashCommandExecuted(command) ->
      on_slash_command_executed(state, interaction, command, connection)
    _ -> gateway.continue(state)
  }
}

fn on_slash_command_executed(
  state: State,
  interaction: Interaction,
  command: interaction.SlashCommandExecution,
  connection: gateway.Connection(State),
) {
  case command.name {
    "ping" -> on_ping_command(state, interaction)
    "soundboards" -> on_soundboards_command(state, interaction, connection)
    "join" -> on_join_command(state, interaction, connection)
    _ -> gateway.continue(state)
  }
}

fn on_join_command(
  state: State,
  interaction: Interaction,
  connection: gateway.Connection(State),
) -> gateway.Next(State) {
  connection
  |> gateway.update_voice_state(using: gateway.UpdateVoiceStateMessage(
    "1155216444691325049",
    Some("1155216445211422795"),
    False,
    False,
  ))

  let _response_result =
    state.client
    |> interaction.respond(
      to: interaction,
      using: interaction.RespondWithChannelMessageWithSource(
        interaction.ResponseMessage(
          ..interaction.new_response_message(),
          content: Some("Joined!"),
        ),
      ),
    )

  gateway.continue(state)
}

fn on_soundboards_command(
  state: State,
  interaction: Interaction,
  connection: gateway.Connection(State),
) -> gateway.Next(State) {
  connection
  |> gateway.request_soundboard_sounds(for: ["1155216444691325049"])

  let _response_result =
    state.client
    |> interaction.respond(
      to: interaction,
      using: interaction.RespondWithChannelMessageWithSource(
        interaction.ResponseMessage(
          ..interaction.new_response_message(),
          content: Some("See the console!"),
        ),
      ),
    )

  gateway.continue(state)
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
