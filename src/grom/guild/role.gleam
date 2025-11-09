import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/image
import grom/internal/flags
import grom/internal/rest
import grom/modification.{type Modification, Skip}
import grom/permission.{type Permission}

// TYPES -----------------------------------------------------------------------

pub type Role {
  Role(
    id: String,
    name: String,
    colors: Colors,
    is_hoisted: Bool,
    icon_hash: Option(String),
    unicode_emoji: Option(String),
    position: Int,
    permissions: List(Permission),
    is_managed: Bool,
    is_mentionable: Bool,
    tags: Option(Tags),
    flags: List(Flag),
  )
}

pub type Tags {
  Tags(
    bot_id: Option(String),
    integration_id: Option(String),
    premium_subscriber: Option(Nil),
    subscription_listing_id: Option(String),
    available_for_purchase: Option(Nil),
    guild_connections: Option(Nil),
  )
}

pub type Flag {
  InPrompt
}

pub type Colors {
  Colors(primary: Int, secondary: Option(Int), tertiary: Option(Int))
}

pub type Create {
  Create(
    /// If None -> "new role"
    name: Option(String),
    /// If None -> same as @everyone permissions
    permissions: Option(List(Permission)),
    colors: Option(Colors),
    is_hoisted: Bool,
    icon: Option(image.Data),
    unicode_emoji: Option(String),
    is_mentionable: Bool,
  )
}

pub type Modify {
  Modify(
    name: Modification(String),
    permissions: Modification(List(Permission)),
    colors: Modification(Colors),
    is_hoisted: Option(Bool),
    icon: Modification(image.Data),
    unicode_emoji: Modification(String),
    is_mentionable: Option(Bool),
  )
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 0), InPrompt)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Role) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use colors <- decode.field("colors", colors_decoder())
  use is_hoisted <- decode.field("hoisted", decode.bool)
  use icon_hash <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use unicode_emoji <- decode.optional_field(
    "unicode_emoji",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permissions <- decode.field("permissions", permission.decoder())
  use is_managed <- decode.field("managed", decode.bool)
  use is_mentionable <- decode.field("mentionable", decode.bool)
  use tags <- decode.optional_field(
    "tags",
    None,
    decode.optional(tags_decoder()),
  )
  use flags <- decode.field("flags", flags.decoder(bits_flags()))
  decode.success(Role(
    id:,
    name:,
    colors:,
    is_hoisted:,
    icon_hash:,
    unicode_emoji:,
    position:,
    permissions:,
    is_managed:,
    is_mentionable:,
    tags:,
    flags:,
  ))
}

@internal
pub fn tags_decoder() -> decode.Decoder(Tags) {
  use bot_id <- decode.field("bot_id", decode.optional(decode.string))
  use integration_id <- decode.field(
    "integration_id",
    decode.optional(decode.string),
  )
  use premium_subscriber <- decode.field(
    "premium_subscriber",
    decode.optional(decode.success(Nil)),
  )
  use subscription_listing_id <- decode.field(
    "subscription_listing_id",
    decode.optional(decode.string),
  )
  use available_for_purchase <- decode.field(
    "available_for_purchase",
    decode.optional(decode.success(Nil)),
  )
  use guild_connections <- decode.field(
    "guild_connections",
    decode.optional(decode.success(Nil)),
  )
  decode.success(Tags(
    bot_id:,
    integration_id:,
    premium_subscriber:,
    subscription_listing_id:,
    available_for_purchase:,
    guild_connections:,
  ))
}

@internal
pub fn colors_decoder() -> decode.Decoder(Colors) {
  use primary <- decode.field("primary_color", decode.int)
  use secondary <- decode.field("secondary_color", decode.optional(decode.int))
  use tertiary <- decode.field("tertiary_color", decode.optional(decode.int))

  decode.success(Colors(primary:, secondary:, tertiary:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let name = case create.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let permissions = case create.permissions {
    Some(permissions) -> [#("permissions", permission.to_json(permissions))]
    None -> []
  }

  let colors = case create.colors {
    Some(colors) -> [#("colors", colors_to_json(colors))]
    None -> []
  }

  let is_hoisted = [#("hoist", json.bool(create.is_hoisted))]

  let icon = case create.icon {
    Some(icon) -> [#("icon", image.to_json(icon))]
    None -> []
  }

  let unicode_emoji = case create.unicode_emoji {
    Some(emoji) -> [#("unicode_emoji", json.string(emoji))]
    None -> []
  }

  let is_mentionable = [#("mentionable", json.bool(create.is_mentionable))]

  [name, permissions, colors, is_hoisted, icon, unicode_emoji, is_mentionable]
  |> list.flatten
  |> json.object
}

@internal
pub fn colors_to_json(colors: Colors) -> Json {
  json.object([
    #("primary_color", json.int(colors.primary)),
    #("secondary_color", json.nullable(colors.secondary, json.int)),
    #("tertiary_color", json.nullable(colors.tertiary, json.int)),
  ])
}

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  let name =
    modify.name
    |> modification.to_json("name", json.string)

  let permissions =
    modify.permissions
    |> modification.to_json("permissions", permission.to_json)

  let colors =
    modify.colors
    |> modification.to_json("colors", colors_to_json)

  let is_hoisted = case modify.is_hoisted {
    Some(hoisted) -> [#("hoisted", json.bool(hoisted))]
    None -> []
  }

  let icon =
    modify.icon
    |> modification.to_json("icon", image.to_json)

  let unicode_emoji =
    modify.unicode_emoji
    |> modification.to_json("unicode_emoji", json.string)

  let is_mentionable = case modify.is_mentionable {
    Some(mentionable) -> [#("mentionable", json.bool(mentionable))]
    None -> []
  }

  [name, permissions, colors, is_hoisted, icon, unicode_emoji, is_mentionable]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: grom.Client,
  for guild_id: String,
  id role_id: String,
) -> Result(Role, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/guilds/" <> guild_id <> "/roles/" <> role_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create(
  client: grom.Client,
  in guild_id: String,
  using create: Create,
  because reason: Option(String),
) -> Result(Role, grom.Error) {
  let json =
    create
    |> create_to_json
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/guilds/" <> guild_id <> "/roles")
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

/// Usage example:
/// ```gleam
/// let create_role_data = role.Create(..role.new_create(), name: Some("name"))
///
/// use role <- result.try(
///   client
///   |> role.create(
///     in: "guild_id",
///     using: create_role_data,
///     because: Some("reason")
///   )
/// )
/// ```
pub fn new_create() -> Create {
  Create(None, None, None, False, None, None, False)
}

pub fn modify(
  client: grom.Client,
  in guild_id: String,
  id role_id: String,
  using modify: Modify,
  because reason: Option(String),
) -> Result(Role, grom.Error) {
  let json =
    modify
    |> modify_to_json
    |> json.to_string

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/guilds/" <> guild_id <> "/roles/" <> role_id,
    )
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(grom.CouldNotDecode)
}

/// Usage example:
/// ```gleam
/// let modify_role_data = role.Modify(
///   ..role.new_modify(),
///   name: New("name"),
///   icon: Delete,
/// )
///
/// use role <- result.try(
///   client
///   |> role.modify(
///     in: "guild_id",
///     id: "role_id",
///     using: modify_role_data,
///     because: Some("reason"),
///   ),
/// )
/// ```
pub fn new_modify() -> Modify {
  Modify(Skip, Skip, Skip, None, Skip, Skip, None)
}

pub fn delete(
  client: grom.Client,
  from guild_id: String,
  id role_id: String,
  because reason: Option(String),
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/guilds/" <> guild_id <> "/roles/" <> role_id,
    )
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  Ok(Nil)
}
