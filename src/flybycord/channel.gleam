import flybycord/channel/guild/category
import flybycord/channel/guild/forum
import flybycord/channel/guild/media
import flybycord/channel/guild/text
import flybycord/channel/guild/thread
import flybycord/channel/guild/voice
import flybycord/channel/user/dm
import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/rest
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/result

// TYPES -----------------------------------------------------------------------

pub type Channel {
  GuildText(text.Channel)
  Dm(dm.Channel)
  GuildVoice(voice.Channel)
  GuildCategory(category.Channel)
  Thread(thread.Thread)
  GuildForum(forum.Channel)
  GuildMedia(media.Channel)
}

pub type Type {
  GuildTextChannel
  DmChannel
  GuildVoiceChannel
  GuildCategoryChannel
  GuildAnnouncementChannel
  AnnouncementThreadChannel
  PublicThreadChannel
  PrivateThreadChannel
  GuildStageVoiceChannel
  GuildForumChannel
  GuildMediaChannel
}

pub type FollowedChannel {
  FollowedChannel(channel_id: String, webhook_id: String)
}

pub type Mention {
  Mention(
    id: String,
    guild_id: String,
    channel_type: Type,
    channel_name: String,
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Channel) {
  use variant <- decode.field("type", type_decoder())
  case variant {
    GuildTextChannel | GuildAnnouncementChannel -> {
      use channel <- decode.then(text.channel_decoder())
      decode.success(GuildText(channel))
    }
    DmChannel -> {
      use channel <- decode.then(dm.channel_decoder())
      decode.success(Dm(channel))
    }
    GuildVoiceChannel | GuildStageVoiceChannel -> {
      use channel <- decode.then(voice.channel_decoder())
      decode.success(GuildVoice(channel))
    }
    GuildCategoryChannel -> {
      use channel <- decode.then(category.channel_decoder())
      decode.success(GuildCategory(channel))
    }
    AnnouncementThreadChannel | PublicThreadChannel | PrivateThreadChannel -> {
      use thread <- decode.then(thread.decoder())
      decode.success(Thread(thread))
    }
    GuildForumChannel -> {
      use channel <- decode.then(forum.channel_decoder())
      decode.success(GuildForum(channel))
    }
    GuildMediaChannel -> {
      use channel <- decode.then(media.channel_decoder())
      decode.success(GuildMedia(channel))
    }
  }
}

@internal
pub fn followed_channel_decoder() -> decode.Decoder(FollowedChannel) {
  use channel_id <- decode.field("channel_id", decode.string)
  use webhook_id <- decode.field("webhook_id", decode.string)
  decode.success(FollowedChannel(channel_id:, webhook_id:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildTextChannel)
    1 -> decode.success(DmChannel)
    2 -> decode.success(GuildVoiceChannel)
    4 -> decode.success(GuildCategoryChannel)
    5 -> decode.success(GuildAnnouncementChannel)
    10 -> decode.success(AnnouncementThreadChannel)
    11 -> decode.success(PublicThreadChannel)
    12 -> decode.success(PrivateThreadChannel)
    13 -> decode.success(GuildStageVoiceChannel)
    15 -> decode.success(GuildForumChannel)
    16 -> decode.success(GuildMediaChannel)
    _ -> decode.failure(GuildTextChannel, "Type")
  }
}

@internal
pub fn mention_decoder() -> decode.Decoder(Mention) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use channel_type <- decode.field("type", type_decoder())
  use channel_name <- decode.field("name", decode.string)
  decode.success(Mention(id:, guild_id:, channel_type:, channel_name:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    GuildTextChannel -> 0
    DmChannel -> 1
    GuildVoiceChannel -> 2
    GuildCategoryChannel -> 4
    GuildAnnouncementChannel -> 5
    AnnouncementThreadChannel -> 10
    PublicThreadChannel -> 11
    PrivateThreadChannel -> 12
    GuildStageVoiceChannel -> 13
    GuildForumChannel -> 15
    GuildMediaChannel -> 16
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: Client,
  id channel_id: String,
) -> Result(Channel, error.FlybycordError) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/channels/" <> channel_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn delete(
  client: Client,
  id channel_id: String,
  reason reason: Option(String),
) -> Result(Channel, error.FlybycordError) {
  use response <- result.try(
    client
    |> rest.new_request(http.Delete, "/channels/" <> channel_id)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}

pub fn announcement_follow(
  client: Client,
  from channel_id: String,
  to webhook_channel_id: String,
  reason reason: Option(String),
) -> Result(FollowedChannel, error.FlybycordError) {
  let json =
    json.object([#("webhook_channel_id", json.string(webhook_channel_id))])

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/followers")
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: followed_channel_decoder())
  |> result.map_error(error.DecodeError)
}

pub fn trigger_typing_indicator(
  client: Client,
  in channel_id: String,
) -> Result(Nil, error.FlybycordError) {
  use _response <- result.try(
    client
    |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/typing")
    |> rest.execute,
  )

  Ok(Nil)
}
