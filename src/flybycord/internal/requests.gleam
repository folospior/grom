import flybycord/client.{type Client}
import flybycord/internal/error
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json
import gleam/result

// CONSTANTS -------------------------------------------------------------------

const discord_url = "discord.com"

const discord_api_path = "api/v10"

// FUNCTIONS -------------------------------------------------------------------

fn new_request(token: String, path: String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_url)
  |> request.set_path(discord_api_path <> path)
  |> request.prepend_header("authorization", "Bot " <> token)
  |> request.prepend_header(
    "user-agent",
    "DiscordBot (https://github.com/folospior/flybycord, "
      <> client.version()
      <> ")",
  )
  |> request.prepend_header("content-type", "application/json")
}

fn ensure_status_code_success(
  response: Response(String),
) -> Result(Response(String), error.FlybycordError) {
  case response.status {
    status if status >= 200 && status < 300 -> Ok(response)
    _ -> Error(error.StatusCodeUnsuccessful(response))
  }
}

@internal
pub fn get(
  client: Client,
  to path: String,
) -> Result(Response(String), error.FlybycordError) {
  use response <- result.try(
    new_request(client.token, path)
    |> request.set_method(http.Get)
    |> httpc.send
    |> result.map_error(error.HttpError),
  )

  response
  |> ensure_status_code_success
}

@internal
pub fn patch(
  client: Client,
  to path: String,
  using data: json.Json,
) -> Result(Response(String), error.FlybycordError) {
  use response <- result.try(
    new_request(client.token, path)
    |> request.set_method(http.Patch)
    |> request.set_body(data |> json.to_string)
    |> httpc.send
    |> result.map_error(error.HttpError),
  )

  response
  |> ensure_status_code_success
}

@internal
pub fn delete(
  client: Client,
  to path: String,
) -> Result(Response(String), error.FlybycordError) {
  use response <- result.try(
    new_request(client.token, path)
    |> request.set_method(http.Delete)
    |> httpc.send
    |> result.map_error(error.HttpError),
  )

  response
  |> ensure_status_code_success
}
