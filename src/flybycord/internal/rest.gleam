import flybycord/client.{type Client}
import flybycord/error
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/option.{type Option, None, Some}
import gleam/result

// CONSTANTS -------------------------------------------------------------------

const discord_url = "discord.com"

const discord_api_path = "api/v10"

// INTERNAL FUNCTIONS ----------------------------------------------------------

@internal
pub fn execute(
  request: Request(String),
) -> Result(Response(String), error.FlybycordError) {
  use response <- result.try(
    request
    |> httpc.send
    |> result.map_error(error.HttpError),
  )

  response
  |> ensure_status_code_success
}

@internal
pub fn new_request(
  client: Client,
  method: http.Method,
  path: String,
) -> Request(String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_url)
  |> request.set_path(discord_api_path <> path)
  |> request.set_method(method)
  |> request.prepend_header("authorization", "Bot" <> client.token)
  |> request.prepend_header(
    "user-agent",
    "DiscordBot (https://github.com/folospior/flybycord, "
      <> client.version()
      <> ")",
  )
  |> request.prepend_header("content-type", "application/json")
}

@internal
pub fn with_reason(request: Request(a), reason: Option(String)) -> Request(a) {
  case reason {
    Some(reason) ->
      request
      |> request.prepend_header("x-audit-log-reason", reason)
    None -> request
  }
}

// PRIVATE FUNCTIONS -----------------------------------------------------------

fn ensure_status_code_success(
  response: Response(String),
) -> Result(Response(String), error.FlybycordError) {
  case response.status {
    status if status >= 200 && status < 300 -> Ok(response)
    _ -> Error(error.StatusCodeUnsuccessful(response))
  }
}
