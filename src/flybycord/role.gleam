import flybycord/permission.{type Permission}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Role {
  Role(
    id: String,
    name: String,
    color: Int,
    hoisted: Bool,
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

// FLAGS -----------------------------------------------------------------------

fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 0), InPrompt)]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Role) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use color <- decode.field("color", decode.int)
  use hoisted <- decode.field("hoisted", decode.bool)
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
  use flags <- decode.field("flags", flags_decoder())
  decode.success(Role(
    id:,
    name:,
    color:,
    hoisted:,
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
pub fn flags_decoder() -> decode.Decoder(List(Flag)) {
  use flags <- decode.then(decode.int)
  bits_flags()
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(flags, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}
