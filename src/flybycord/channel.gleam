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
import gleam/json
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

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn create_dm(
  client: Client,
  recipient_id: String,
) -> Result(Channel, error.FlybycordError) {
  let json = json.object([#("recipient_id", json.string(recipient_id))])

  use response <- result.try(
    client
    |> rest.new_request(http.Post, "/users/@me/channels")
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.DecodeError)
}
