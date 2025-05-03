import flybycord/client.{type Client}
import flybycord/rest
import flybycord/user/modify_current_user.{type ModifyCurrentUser}
import gleam/http
import gleam/http/request.{type Request}
import gleam/json

pub fn get(client: Client) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me")
}

pub fn modify(client: Client, with data: ModifyCurrentUser) -> Request(String) {
  let json = data |> modify_current_user.encode
  client
  |> rest.new_request(http.Patch, "/users/@me")
  |> request.set_body(json |> json.to_string)
}

pub fn get_guilds(client: Client) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me/guilds")
}

pub fn get_guild_member(client: Client, guild_id: String) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me/guilds/" <> guild_id <> "/member")
}
