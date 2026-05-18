import grom/rest_error.{type RestError}
import gleam/http/response.{type Response}
import gleam/http
import gleam/http/request.{type Request}

const library_url = "https://github.com/folospior/grom"

const library_version = "v7.0.0-alpha"

const discord_url = "discord.com"

const discord_path = "api/v10"

pub fn new_request(
  method method: http.Method,
  to path: String,
  token token: String,
) -> Request(String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_url)
  |> request.set_path(discord_path <> path)
  |> request.set_method(method)
  |> request.set_header("authorization", "Bot " <> token)
  |> request.set_header("content-type", "application/json")
  |> request.set_header(
    "user-agent",
    // "DiscordBot (${library_url}, ${library_version})"
    "DiscordBot (" <> library_url <> ", " <> library_version <> ")",
  )
}

pub fn handle_response(response: Response(String), decode_with decoder: Decoder(a)) -> Result(a, RestError) {
    
}
