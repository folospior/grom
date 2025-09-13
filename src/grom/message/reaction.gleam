import gleam/dynamic/decode
import gleam/http
import gleam/result
import gleam/uri
import grom
import grom/emoji.{type Emoji}
import grom/internal/rest

// TYPES -----------------------------------------------------------------------

pub type Reaction {
  Reaction(
    count: Int,
    count_details: CountDetails,
    current_user_reacted: Bool,
    current_user_burst_reacted: Bool,
    emoji: Emoji,
    burst_colors: List(Int),
  )
}

pub type Type {
  Normal
  Burst
}

pub type CountDetails {
  CountDetails(burst: Int, normal: Int)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Reaction) {
  use count <- decode.field("count", decode.int)
  use count_details <- decode.field("count_details", count_details_decoder())
  use current_user_reacted <- decode.field("me", decode.bool)
  use current_user_burst_reacted <- decode.field("me_burst", decode.bool)
  use emoji <- decode.field("emoji", emoji.decoder())
  use burst_colors <- decode.field("burst_colors", decode.list(decode.int))
  decode.success(Reaction(
    count:,
    count_details:,
    current_user_reacted:,
    current_user_burst_reacted:,
    emoji:,
    burst_colors:,
  ))
}

@internal
pub fn count_details_decoder() -> decode.Decoder(CountDetails) {
  use burst <- decode.field("burst", decode.int)
  use normal <- decode.field("normal", decode.int)
  decode.success(CountDetails(burst:, normal:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn type_to_int(type_: Type) -> Int {
  case type_ {
    Normal -> 0
    Burst -> 1
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn create(
  client: grom.Client,
  in channel_id: String,
  on message_id: String,
  emoji emoji_id: String,
) -> Result(Nil, grom.Error) {
  let emoji = uri.percent_encode(emoji_id)

  client
  |> rest.new_request(
    http.Put,
    "/channels/"
      <> channel_id
      <> "/messages/"
      <> message_id
      <> "/reactions/"
      <> emoji
      <> "/@me",
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn delete_own(
  client: grom.Client,
  in channel_id: String,
  from message_id: String,
  emoji emoji_id: String,
) -> Result(Nil, grom.Error) {
  let emoji = uri.percent_encode(emoji_id)

  client
  |> rest.new_request(
    http.Delete,
    "/channels/"
      <> channel_id
      <> "/messages/"
      <> message_id
      <> "/reactions/"
      <> emoji
      <> "/@me",
  )
  |> rest.execute
  |> result.replace(Nil)
}

pub fn delete_users(
  client: grom.Client,
  in channel_id: String,
  from message_id: String,
  emoji emoji_id: String,
  id user_id: String,
) -> Result(Nil, grom.Error) {
  let emoji = uri.percent_encode(emoji_id)

  client
  |> rest.new_request(
    http.Delete,
    "/channels/"
      <> channel_id
      <> "/messages/"
      <> message_id
      <> "/reactions/"
      <> emoji
      <> "/"
      <> user_id,
  )
  |> rest.execute
  |> result.replace(Nil)
}
