import flybycord/emoji.{type Emoji}
import flybycord/internal/time_rfc3339
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Poll {
  Poll(
    question: Media,
    answers: List(Answer),
    expiry: Option(Timestamp),
    allows_multiselect: Bool,
    layout_type: LayoutType,
    results: Option(Results),
  )
}

pub type Media {
  Media(text: Option(String), emoji: Option(Emoji))
}

pub type Answer {
  Answer(answer_id: Int, poll_media: Media)
}

pub type Results {
  Results(is_finalized: Bool, answer_counts: List(AnswerCount))
}

pub type AnswerCount {
  AnswerCount(id: Int, count: Int, current_user_voted: Bool)
}

pub type LayoutType {
  Default
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Poll) {
  use question <- decode.field("question", media_decoder())
  use answers <- decode.field("answers", decode.list(answer_decoder()))
  use expiry <- decode.field("expiry", decode.optional(time_rfc3339.decoder()))
  use allows_multiselect <- decode.field("allow_multiselect", decode.bool)
  use layout_type <- decode.field("layout_type", layout_type_decoder())
  use results <- decode.optional_field(
    "results",
    None,
    decode.optional(results_decoder()),
  )
  decode.success(Poll(
    question:,
    answers:,
    expiry:,
    allows_multiselect:,
    layout_type:,
    results:,
  ))
}

@internal
pub fn media_decoder() -> decode.Decoder(Media) {
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.string),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji.decoder()),
  )
  decode.success(Media(text:, emoji:))
}

@internal
pub fn answer_decoder() -> decode.Decoder(Answer) {
  use answer_id <- decode.field("answer_id", decode.int)
  use poll_media <- decode.field("poll_media", media_decoder())
  decode.success(Answer(answer_id:, poll_media:))
}

@internal
pub fn layout_type_decoder() -> decode.Decoder(LayoutType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Default)
    _ -> decode.failure(Default, "LayoutType")
  }
}

@internal
pub fn results_decoder() -> decode.Decoder(Results) {
  use is_finalized <- decode.field("is_finalized", decode.bool)
  use answer_counts <- decode.field(
    "answer_counts",
    decode.list(answer_count_decoder()),
  )
  decode.success(Results(is_finalized:, answer_counts:))
}

@internal
pub fn answer_count_decoder() -> decode.Decoder(AnswerCount) {
  use id <- decode.field("id", decode.int)
  use count <- decode.field("count", decode.int)
  use current_user_voted <- decode.field("me_voted", decode.bool)
  decode.success(AnswerCount(id:, count:, current_user_voted:))
}
