import flybycord/client.{type Client}
import flybycord/image
import flybycord/rest
import gleam/http
import gleam/http/request.{type Request}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES ----------------------------------------------------------------------

pub type Modify {
  Modify(
    username: Option(String),
    avatar: Option(image.Data),
    banner: Option(image.Data),
  )
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(client: Client) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me")
}

pub fn modify(client: Client, with data: Modify) -> Request(String) {
  let json = data |> modify_encode
  client
  |> rest.new_request(http.Patch, "/users/@me")
  |> request.set_body(json |> json.to_string)
}

pub fn new_modify() -> Modify {
  Modify(username: None, avatar: None, banner: None)
}

pub fn modify_username(object: Modify, username: String) -> Modify {
  Modify(..object, username: Some(username))
}

pub fn modify_avatar(object: Modify, avatar: image.Data) -> Modify {
  Modify(..object, avatar: Some(avatar))
}

pub fn modify_banner(object: Modify, banner: image.Data) -> Modify {
  Modify(..object, banner: Some(banner))
}

pub fn get_guilds(client: Client) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me/guilds")
}

pub fn get_as_member(client: Client, guild_id: String) -> Request(String) {
  client
  |> rest.new_request(http.Get, "/users/@me/guilds/" <> guild_id <> "/member")
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_encode(object: Modify) -> Json {
  let Modify(username:, avatar:, banner:) = object
  let username = case username {
    Some(name) -> [#("username", json.string(name))]
    None -> []
  }

  let avatar = case avatar {
    Some(image) -> [#("avatar", json.string(image))]
    None -> []
  }

  let banner = case banner {
    Some(image) -> [#("banner", json.string(image))]
    None -> []
  }

  [username, avatar, banner]
  |> list.flatten
  |> json.object
}
