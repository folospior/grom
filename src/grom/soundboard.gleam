import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/internal/rest
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Sound {
  Sound(
    name: String,
    id: String,
    /// From `0.0` to `1.0`.
    volume: Float,
    emoji_id: Option(String),
    emoji_name: Option(String),
    guild_id: Option(String),
    is_available: Bool,
    creator: Option(User),
  )
}

pub opaque type Data {
  Data(String)
}

pub type ContentType {
  Mpeg
  Ogg
}

pub type SoundId {
  StringId(String)
  IntId(Int)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn sound_decoder() -> decode.Decoder(Sound) {
  use name <- decode.field("name", decode.string)
  use id <- decode.field("sound_id", decode.string)
  use volume <- decode.field("volume", decode.float)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use is_available <- decode.field("available", decode.bool)
  use creator <- decode.field("user", decode.optional(user.decoder()))
  decode.success(Sound(
    name:,
    id:,
    volume:,
    emoji_id:,
    emoji_name:,
    guild_id:,
    is_available:,
    creator:,
  ))
}

@internal
pub fn sound_id_decoder() -> decode.Decoder(SoundId) {
  let string_decoder = decode.map(decode.string, StringId)
  let int_decoder = decode.map(decode.int, IntId)
  decode.one_of(string_decoder, or: [int_decoder])
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn send_sound(
  client: grom.Client,
  in channel_id: String,
  id sound_id: String,
  source_guild guild_id: Option(String),
) -> Result(Nil, grom.Error) {
  let json =
    json.object(
      [
        [#("sound_id", json.string(sound_id))],
        case guild_id {
          Some(id) -> [#("source_guild_id", json.string(id))]
          None -> []
        },
      ]
      |> list.flatten,
    )
    |> json.to_string

  client
  |> rest.new_request(
    http.Post,
    "/channels/" <> channel_id <> "/send-soundboard-sound",
  )
  |> request.set_body(json)
  |> rest.execute
  |> result.replace(Nil)
}

pub fn get_default_sounds(
  client: grom.Client,
) -> Result(List(Sound), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/soundboard-default-sounds")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: sound_decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn data_from_bit_array(
  bit_array: BitArray,
  content_type: ContentType,
) -> Data {
  let content_type = case content_type {
    Mpeg -> "audio/mpeg"
    Ogg -> "audio/ogg"
  }

  let data = bit_array.base64_encode(bit_array, False)

  Data("data:" <> content_type <> ";base64," <> data)
}

@internal
pub fn data_to_base64(image: Data) -> String {
  let Data(base64) = image
  base64
}

@internal
pub fn data_to_json(image: Data) -> Json {
  image
  |> data_to_base64
  |> json.string
}
