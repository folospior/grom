//// Hi there!
//// Did you read the README yet?
//// If not, now is a good time to do so. This code won't make a whole lot of sense without reading the README.

import envoy
import gleam/erlang/process
import gleam/http/request.{Request}
import gleam/http/response
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/factory_supervisor
import gleam/otp/static_supervisor
import grom
import grom/command
import grom/interaction.{type Interaction}
import logging
import mist
import wisp
import wisp/wisp_mist

type RequestHandlerState {
  RequestHandlerState(
    client: grom.Client,
    discord_public_key: String,
    interaction_handler_name: process.Name(
      factory_supervisor.Message(
        Interaction,
        process.Subject(InteractionHandlerMessage),
      ),
    ),
  )
}

type InteractionHandlerState {
  InteractionHandlerState(client: grom.Client)
}

pub fn main() -> Nil {
  // First, let's get our environment variables:
  let assert Ok(token) = envoy.get("DISCORD_TOKEN")

  // We normally get our application's ID from the Gateway READY event.
  // Since we're not connecting to the gateway, we have to hard-code it.
  let assert Ok(application_id) = envoy.get("DISCORD_APPLICATION_ID")

  // The public key is specific to your application.
  // It's used to verify the origin of HTTP requests is Discord, and that Discord intended to send that interaction to your app.
  let assert Ok(public_key) = envoy.get("DISCORD_PUBLIC_KEY")

  // We're going to be using wisp, so let's configure its logger:
  wisp.configure_logger()

  // Let's create the grom client:
  let client = grom.Client(token:)

  // Let's create a test command.
  let global_commands = [
    command.CreateGlobalSlash(command.new_create_global_slash_command(
      named: "ping",
      description: "Ping pong!",
    )),
  ]

  // We're asserting to make sure that command is 100% there when we start up our program.
  let assert Ok(_commands) =
    client
    |> command.bulk_overwrite_global(of: application_id, new: global_commands)

  // -----
  // Let's create a factory supervisor, which will create workers which will handle our interactions.
  // This makes sure that Discord's HTTP request doesn't timeout.
  //
  // Note: You still have 3 seconds to send `interaction.respond`, and either defer it or send a message.
  // -----

  // Let's create a name, which will be a way to contact our factory from our request handler.
  let interaction_handler_name = process.new_name("interaction_handler_factory")

  // We're going to create a static supervisor later on, so let's use the `factory_supervisor.supervised` function.
  let interaction_handler_factory =
    // Using `factory_supervisor.worker_child` sets the worker's timeout at 5000ms by default.
    //
    // Look into using the `factory_supervisor.supervisor_child` if your interaction handler is also a supervisor.
    factory_supervisor.worker_child(fn(interaction) {
      start_interaction_handler(InteractionHandlerState(client), interaction)
    })
    |> factory_supervisor.named(interaction_handler_name)
    |> factory_supervisor.supervised

  // -----
  // We're going to be using webhooks as a way to handle interactions, so let's create an API endpoints,
  // where Discord will be sending our interactions.
  // -----

  // From the wisp docs:
  // 
  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  // We're going to create a static supervisor later on, so let's use the `mist.supervised` function.
  let http_server =
    wisp_mist.handler(
      fn(request) {
        handle_request(
          request,
          RequestHandlerState(client, public_key, interaction_handler_name),
        )
      },
      secret_key_base,
    )
    |> mist.new
    |> mist.port(2137)
    // This has to be a public internet facing API.
    |> mist.bind("0.0.0.0")
    |> mist.supervised

  let assert Ok(_supervisor) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(interaction_handler_factory)
    |> static_supervisor.add(http_server)
    |> static_supervisor.start

  process.sleep_forever()
}

type InteractionHandlerMessage {
  InteractionCreated(interaction: Interaction)
}

fn start_interaction_handler(
  state: InteractionHandlerState,
  interaction: Interaction,
) -> Result(
  actor.Started(process.Subject(InteractionHandlerMessage)),
  actor.StartError,
) {
  actor.new_with_initialiser(4000, fn(subject) {
    let selector =
      process.new_selector()
      |> process.select(subject)

    process.send(subject, InteractionCreated(interaction))

    actor.initialised(state)
    |> actor.returning(subject)
    |> actor.selecting(selector)
    |> Ok
  })
  |> actor.on_message(handle_interaction_handler_message)
  |> actor.start
}

fn handle_interaction_handler_message(
  state: InteractionHandlerState,
  message: InteractionHandlerMessage,
) -> actor.Next(InteractionHandlerState, a) {
  case message {
    InteractionCreated(interaction) -> handle_interaction(state, interaction)
  }
}

fn handle_interaction(
  state: InteractionHandlerState,
  interaction: Interaction,
) -> actor.Next(InteractionHandlerState, a) {
  let _result =
    state.client
    |> interaction.respond(
      to: interaction,
      using: interaction.RespondWithChannelMessageWithSource(
        interaction.ResponseMessage(
          ..interaction.new_response_message(),
          content: Some("Pong!"),
        ),
      ),
    )

  actor.continue(state)
}

fn handle_request(
  request: wisp.Request,
  state: RequestHandlerState,
) -> wisp.Response {
  case wisp.path_segments(request) {
    ["discord-interactions"] -> {
      use body <- wisp.require_string_body(request)

      let request = Request(..request, body:)

      interaction.handle_http_interaction_request(
        request,
        state.discord_public_key,
        fn(interaction) { handle_interaction_request(state, interaction) },
      )
      |> response.map(wisp.Text)
    }
    _ -> wisp.not_found()
  }
}

fn handle_interaction_request(
  state: RequestHandlerState,
  interaction: Result(Interaction, interaction.HttpError),
) -> Nil {
  case interaction {
    Ok(interaction) -> {
      let factory =
        factory_supervisor.get_by_name(state.interaction_handler_name)

      let start_result =
        factory
        |> factory_supervisor.start_child(interaction)

      case start_result {
        Ok(_) -> logging.log(logging.Info, "Started interaction handler worker")
        Error(_) ->
          logging.log(
            logging.Warning,
            "Could not start interaction handler worker",
          )
      }
    }
    Error(interaction.CouldNotParseInteraction(_)) ->
      logging.log(logging.Warning, "Could not parse interaction")
    Error(interaction.CouldNotValidateSecurityHeaders(_)) ->
      logging.log(logging.Warning, "Could not validate security headers")
  }
}
