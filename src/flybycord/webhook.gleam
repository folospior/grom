import flybycord/channel.{type Channel}
import flybycord/guild.{type Guild}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Webhook {
  Webhook(
    id: String,
    type_: Type,
    guild_id: Option(String),
    channel_id: Option(String),
    user: Option(User),
    name: Option(String),
    avatar_hash: Option(String),
    token: Option(String),
    application_id: Option(String),
    source_guild: Option(Guild),
    source_channel: Option(Channel),
    url: Option(String),
  )
}

pub type Type {
  Incoming
  ChannelFollower
  Application
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Webhook) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use channel_id <- decode.field("channel_id", decode.optional(decode.string))
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user.decoder()),
  )
  use name <- decode.field("name", decode.optional(decode.string))
  use avatar_hash <- decode.field("avatar", decode.optional(decode.string))
  use token <- decode.optional_field(
    "token",
    None,
    decode.optional(decode.string),
  )
  use application_id <- decode.field(
    "application_id",
    decode.optional(decode.string),
  )
  use source_guild <- decode.optional_field(
    "source_guild",
    None,
    decode.optional(guild.decoder()),
  )
  use source_channel <- decode.optional_field(
    "source_channel",
    None,
    decode.optional(channel.decoder()),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  decode.success(Webhook(
    id:,
    type_:,
    guild_id:,
    channel_id:,
    user:,
    name:,
    avatar_hash:,
    token:,
    application_id:,
    source_guild:,
    source_channel:,
    url:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Incoming)
    2 -> decode.success(ChannelFollower)
    3 -> decode.success(Application)
    _ -> decode.failure(Incoming, "Type")
  }
}
