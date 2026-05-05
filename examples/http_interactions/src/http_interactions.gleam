//// Hi there!
//// Did you read the README yet?
//// If not, now is a good time to do so. This code won't make a whole lot of sense without reading the README.

import envoy
import gleam/erlang/process
import gleam/http
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

pub fn main() -> Nil {
  // First, let's get our environment variables:
  let assert Ok(discord_token) = envoy.get("DISCORD_TOKEN")

  // We normally get our application's ID from the Gateway READY event.
  // Since we're not connecting to the gateway, we have to hard-code it.
  //
  // We're going to use it to create a command on program start-up.
  let assert Ok(discord_application_id) = envoy.get("DISCORD_APPLICATION_ID")

  // The public key is specific to your application.
  // It's used to verify the origin of HTTP requests is Discord, and that Discord intended to send that interaction to your app.
  let assert Ok(discord_public_key) = envoy.get("DISCORD_PUBLIC_KEY")

  // We're going to be using wisp, so let's configure its logger:
  wisp.configure_logger()

  // Let's create the grom client:
  let client = grom.Client(token: discord_token)

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
    |> command.bulk_overwrite_global(
      of: discord_application_id,
      new: global_commands,
    )

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
      start_interaction_handler(InteractionHandlerContext(client), interaction)
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
      // We have to create an anonymous function here, since mist expects a fn(Request),
      // and our handler also has the context in its signature.
      fn(request) {
        handle_request(
          request,
          RequestHandlerContext(
            client,
            discord_public_key,
            interaction_handler_name,
          ),
        )
      },
      secret_key_base,
    )
    |> mist.new
    |> mist.port(2137)
    // This has to be a public internet facing API.
    |> mist.bind("0.0.0.0")
    |> mist.supervised

  // Creating a top-level supervisor which supervises our handler factory and http server.
  let assert Ok(_supervisor) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(interaction_handler_factory)
    |> static_supervisor.add(http_server)
    |> static_supervisor.start

  // All logic will be handled in other processes/actors, so let's just put this one to sleep.
  process.sleep_forever()
}

// This is a helper type which contains all of the resources a request handler requires.
type RequestHandlerContext {
  RequestHandlerContext(
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

// Our request handler.
fn handle_request(
  request: wisp.Request,
  context: RequestHandlerContext,
) -> wisp.Response {
  // Some common wisp middleware.
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes()

  case wisp.path_segments(request) {
    // We only want to handle requests on the /discord-interactions path.
    ["discord-interactions"] -> {
      // All requests to this endpoint must be made with the POST method.
      use <- wisp.require_method(request, http.Post)

      // Wisp provides us with a Request(wisp.Connection), but grom requires a Request(String).
      // We're going to have to convert it.
      use body <- wisp.require_string_body(request)

      // Creating a request with all the same data as the original one, just replacing its body with the string body.
      let request = Request(..request, body:)

      // This function does a lot of the heavy lifting for us.
      // It handles:
      // - automatic responses to PING requests
      // - security header validation (discord signs messages with the app's private key)
      // - parsing the request body as an Interaction
      //
      // A caveat with using this function is that it only responds to the request after the provided handler function has finished.
      // This means we cannot put any long, blocking code in the handler, as it will trigger an HTTP timeout and invalidate the interaction.
      interaction.handle_http_interaction_request(
        request,
        // We provide the function with our app's public key to verify the origin of all requests.
        context.discord_public_key,
        // This is the handler. Don't put blocking code here.
        fn(interaction) { handle_interaction_request(context, interaction) },
      )
      // Wisp still requires us to return a Response(wisp.Body), so let's convert our Response(String) to that:
      |> response.map(wisp.Text)
    }
    // You can, of course, add other endpoints to this handler - it's your API!
    _ -> wisp.not_found()
  }
}

fn handle_interaction_request(
  context: RequestHandlerContext,
  interaction: Result(Interaction, interaction.HttpError),
) -> Nil {
  // The request handler provides us with a Result(Interaction, interaction.HttpError).
  // This allows you to log errors properly using your infrastructure - here shown with a simple `logging.log`
  case interaction {
    Ok(interaction) ->
      handle_successful_interaction_request(context, interaction)
    Error(interaction.CouldNotParseInteraction(_)) ->
      logging.log(logging.Warning, "Could not parse interaction")
    Error(interaction.CouldNotValidateSecurityHeaders(_)) ->
      logging.log(logging.Warning, "Could not validate security headers")
  }
}

fn handle_successful_interaction_request(
  context: RequestHandlerContext,
  interaction: Interaction,
) -> Nil {
  // Let's begin handling our successful interactions by getting our factory supervisor.
  let factory = factory_supervisor.get_by_name(context.interaction_handler_name)

  // Let's now start a worker child under that factory supervisor.
  // 
  // This will put all the long, blocking logic onto another process,
  // allowing the current one to send the HTTP response.
  let start_result =
    factory
    |> factory_supervisor.start_child(interaction)

  // Let's log what happened with the start:
  case start_result {
    Ok(_) -> logging.log(logging.Info, "Started interaction handler worker")
    Error(_) ->
      logging.log(logging.Warning, "Could not start interaction handler worker")
  }
}

// This is a helper type containing all the resources an interaction handler requires.
// In our case, we only need a grom.Client, but many interactions require calls to external services, databases, etc.
type InteractionHandlerContext {
  InteractionHandlerContext(client: grom.Client)
}

// This is the message type for our handler actor.
// We only deal with one message in our case - InteractionCreated.
//
// You might want to change this if you modify your interaction handler to handle more messages,
// for example, if you make it spawn more actors and expect to receive messages back from them.
type InteractionHandlerMessage {
  InteractionCreated(interaction: Interaction)
}

fn start_interaction_handler(
  context: InteractionHandlerContext,
  interaction: Interaction,
) -> Result(
  actor.Started(process.Subject(InteractionHandlerMessage)),
  actor.StartError,
) {
  actor.new_with_initialiser(4000, fn(subject) {
    // Every actor has an associated selector.
    // We must select our provided subject if we want to send messages to it.
    let selector =
      process.new_selector()
      |> process.select(subject)

    // Let's send a message on actor start-up.
    process.send(subject, InteractionCreated(interaction))

    actor.initialised(context)
    |> actor.returning(subject)
    |> actor.selecting(selector)
    |> Ok
  })
  |> actor.on_message(handle_interaction_handler_message)
  |> actor.start
}

fn handle_interaction_handler_message(
  context: InteractionHandlerContext,
  message: InteractionHandlerMessage,
) -> actor.Next(InteractionHandlerContext, a) {
  // We only deal with one type of message here,
  // but the case statement exists for future-proofing.
  case message {
    InteractionCreated(interaction) -> handle_interaction(context, interaction)
  }
}

// Finally, we get to handle our interaction.
fn handle_interaction(
  context: InteractionHandlerContext,
  interaction: Interaction,
) -> actor.Next(InteractionHandlerContext, a) {
  // At this step, you'd:
  // - defer the interaction (you want this most of the time)
  // - pattern match on the interaction data, command names, modal custom IDs, etc.

  // But here, let's skip all that and just immediately respond with "Pong!" to every interaction
  // sent to our bot.
  let _result =
    context.client
    |> interaction.respond(
      to: interaction,
      using: interaction.RespondWithChannelMessageWithSource(
        interaction.ResponseMessage(
          ..interaction.new_response_message(),
          content: Some("Pong!"),
        ),
      ),
    )

  // Our actor has finished its job - responded to an interaction.
  // It's no longer needed, so let's stop it.
  actor.stop()
}
// Got through all this? Make sure to read through the README's finalizing
// section. It's got lots of important information about how to set this up.
