import gleam/bool
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import grom/client.{type Client}
import grom/error.{type Error}
import grom/guild_member.{type GuildMember}
import grom/image
import grom/internal/rest
import grom/user.{type User}

// TYPES ----------------------------------------------------------------------

pub type Modify {
  Modify(
    username: Option(String),
    avatar: Option(image.Data),
    banner: Option(image.Data),
  )
}

pub type GetGuildsQuery {
  BeforeId(String)
  AfterId(String)
  Limit(Int)
  WithCounts(Bool)
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_encode(modify: Modify) -> Json {
  let Modify(username:, avatar:, banner:) = modify
  let username = case username {
    Some(name) -> [#("username", json.string(name))]
    None -> []
  }

  let avatar = case avatar {
    Some(image) -> [#("avatar", image.to_json(image))]
    None -> []
  }

  let banner = case banner {
    Some(image) -> [#("banner", image.to_json(image))]
    None -> []
  }

  [username, avatar, banner]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(client: Client) -> Result(User, Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/users/@me")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: user.decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn modify(client: Client, with data: Modify) -> Result(User, Error) {
  let json = data |> modify_encode
  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/users/@me")
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: user.decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn new_modify() -> Modify {
  Modify(username: None, avatar: None, banner: None)
}

pub fn modify_username(modify: Modify, username: String) -> Modify {
  Modify(..modify, username: Some(username))
}

pub fn modify_avatar(modify: Modify, avatar: image.Data) -> Modify {
  Modify(..modify, avatar: Some(avatar))
}

pub fn modify_banner(modify: Modify, banner: image.Data) -> Modify {
  Modify(..modify, banner: Some(banner))
}

pub fn get_guilds(
  client: Client,
  with query: List(GetGuildsQuery),
) -> Result(User, Error) {
  let query =
    list.map(query, fn(parameter) {
      case parameter {
        BeforeId(id) -> #("before", id)
        AfterId(id) -> #("after", id)
        Limit(limit) -> #("limit", limit |> int.to_string)
        WithCounts(with_counts) -> #(
          "with_counts",
          with_counts
            |> bool.to_string
            |> string.lowercase,
        )
      }
    })

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/users/@me/guilds")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: user.decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_as_member(
  client: Client,
  guild_id: String,
) -> Result(GuildMember, Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/users/@me/guilds/" <> guild_id <> "/member")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: guild_member.decoder())
  |> result.map_error(error.CouldNotDecode)
}
