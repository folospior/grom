import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import grom
import grom/guild
import grom/guild_member.{type GuildMember}
import grom/image
import grom/internal/rest
import grom/permission.{type Permission}
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
  GetGuildsBeforeId(String)
  GetGuildsAfterId(String)
  GetGuildsLimit(Int)
  /// Refers to the approximate_member and approximate_presence counts
  GetGuildsWithCounts(Bool)
}

pub type PartialGuild {
  PartialGuild(
    id: String,
    name: String,
    icon_hash: Option(String),
    banner_hash: Option(String),
    is_current_user_owner: Bool,
    current_user_permissions: List(Permission),
    features: List(guild.Feature),
    approximate_member_count: Option(Int),
    approximate_presence_count: Option(Int),
  )
}

// DECODERS -------------------------------------------------------------------

fn partial_guild_decoder() -> decode.Decoder(PartialGuild) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(decode.string))
  use banner_hash <- decode.field("banner", decode.optional(decode.string))
  use is_current_user_owner <- decode.field("owner", decode.bool)
  use current_user_permissions <- decode.field(
    "permissions",
    permission.decoder(),
  )
  use features <- decode.field("features", decode.list(guild.feature_decoder()))
  use approximate_member_count <- decode.optional_field(
    "approximate_member_count",
    None,
    decode.optional(decode.int),
  )
  use approximate_presence_count <- decode.optional_field(
    "approximate_presence_count",
    None,
    decode.optional(decode.int),
  )
  decode.success(PartialGuild(
    id:,
    name:,
    icon_hash:,
    banner_hash:,
    is_current_user_owner:,
    current_user_permissions:,
    features:,
    approximate_member_count:,
    approximate_presence_count:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_to_json(modify: Modify) -> Json {
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

pub fn get(client: grom.Client) -> Result(User, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/users/@me")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: user.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn modify(
  client: grom.Client,
  with data: Modify,
) -> Result(User, grom.Error) {
  let json = data |> modify_to_json
  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/users/@me")
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: user.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_modify() -> Modify {
  Modify(username: None, avatar: None, banner: None)
}

pub fn get_guilds(
  client: grom.Client,
  with query: List(GetGuildsQuery),
) -> Result(List(PartialGuild), grom.Error) {
  let query =
    list.map(query, fn(parameter) {
      case parameter {
        GetGuildsBeforeId(id) -> #("before", id)
        GetGuildsAfterId(id) -> #("after", id)
        GetGuildsLimit(limit) -> #("limit", limit |> int.to_string)
        GetGuildsWithCounts(with_counts) -> #(
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
  |> json.parse(using: decode.list(of: partial_guild_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_as_member(
  client: grom.Client,
  guild_id: String,
) -> Result(GuildMember, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/users/@me/guilds/" <> guild_id <> "/member")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: guild_member.decoder())
  |> result.map_error(grom.CouldNotDecode)
}
