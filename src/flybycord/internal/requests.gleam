import flybycord/client
import flybycord/internal/error
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/result

const discord_url = "discord.com"

const discord_api_path = "api/v10"

pub fn get(
  client: client.Client,
  path: String,
) -> Result(Response(String), error.FlybycordError) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_url)
  |> request.set_path(discord_api_path <> path)
  |> request.set_method(http.Get)
  |> request.prepend_header("authorization", "Bot " <> client.token)
  |> request.prepend_header(
    "user-agent",
    "DiscordBot (https://github.com/folospior/flybycord, v0.0.0)",
  )
  |> request.prepend_header("content-type", "application/json")
  |> httpc.send
  |> result.map_error(error.HttpError)
}
