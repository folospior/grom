# Your First Bot
This documentation is heavily inspired by the amazing [D++](https://dpp.dev) library. All kudos to them!

This page will explain, step-by-step, how to create your first bot using Grom.
We will be using a Go example as a simple side-by-side comparison.

Grom is a library for the Erlang target. We will, hence, be using Erlang libraries for this example.

Before we head into the code, let's start our project up.
```bash
  gleam new your_first_bot
  cd your_first_project
  gleam add grom logging gleam_erlang envoy dotenv_gleam
  echo "BOT_TOKEN=<INSERT TOKEN HERE> > .env"
```

Now that we've added all the necessary dependencies, let's explain what we'll need them for:
- `grom` - I assume you already know what it is - the Gleam Discord API library.
- `logging` - self-explanatory, we'll need this for logging.
- `gleam_erlang` - we will need this for the `process.sleep_forever()` function, which will be used so that our program doesn't
exit once we start the connection to Discord.
- `envoy` - we will need this for environment variable management.
- `dotenv_gleam` - we will need this for automatically parsing the `.env` file.

## The comparison
In any case this documentation is out-of-date, I welcome you to read through the
[your_first_bot](../examples/your_first_bot) and [your_first_go_bot](../examples/your_first_go_bot) directories.

Let's cut to the chase.

<table>
<tr>
<th>Explanation</th>
<th>Gleam</th>
<th>Go</th>
</tr>
<tr>
<td>The entire code.</td>

<td>

```gleam
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

  let gateway_start_result =
    gateway.new(identify, state)
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

fn on_event(
  state: State,
  event: gateway.Event,
  connection: gateway.Connection(State),
) {
  case event {
    gateway.ErrorEvent(error) -> {
      logging.log(logging.Warning, string.inspect(error))
      gateway.continue(state)
    }
    gateway.ReadyEvent(ready) -> on_ready(state, ready, connection)
    gateway.InteractionCreatedEvent(interaction) ->
      on_interaction_created(state, interaction, connection)
    _ -> gateway.continue(state)
  }
}

fn on_ready(
  state: State,
  ready: gateway.ReadyMessage,
  connection: gateway.Connection(State),
) {
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
```

</td>

<td>todo: Go</td>
</tr>
</table>
