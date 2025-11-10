import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import grom
import grom/emoji.{type Emoji}
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/user.{type User}

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

pub type Create {
  Create(
    question: CreateQuestion,
    answers: List(CreateAnswer),
    duration: Option(Duration),
    allow_multiselect: Bool,
    layout_type: Option(LayoutType),
  )
}

pub type CreateQuestion {
  CreateQuestion(text: Option(String))
}

pub type CreateAnswer {
  CreateAnswer(media: Media)
}

pub type GetAnswerVotersQuery {
  AfterUserId(String)
  Limit(Int)
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

// this is cursed and shouldn't exist
@internal
pub fn create_decoder() -> decode.Decoder(Create) {
  use question <- decode.field("question", create_question_decoder())
  use answers <- decode.field(
    "answers",
    decode.list(of: create_answer_decoder()),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(time_duration.from_int_hours_decoder()),
  )
  use allow_multiselect <- decode.optional_field(
    "allow_multiselect",
    False,
    decode.bool,
  )
  use layout_type <- decode.optional_field(
    "layout_type",
    None,
    decode.optional(layout_type_decoder()),
  )

  decode.success(Create(
    question:,
    answers:,
    duration:,
    allow_multiselect:,
    layout_type:,
  ))
}

@internal
pub fn create_question_decoder() -> decode.Decoder(CreateQuestion) {
  // what was i thinking
  // why is a question's text optional
  // actually what was discord thinking
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.string),
  )
  decode.success(CreateQuestion(text))
}

@internal
pub fn create_answer_decoder() -> decode.Decoder(CreateAnswer) {
  use media <- decode.field("media", media_decoder())
  decode.success(CreateAnswer(media))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let question = [#("question", create_question_to_json(create.question))]

  let answers = [
    #("answers", json.array(create.answers, create_answer_to_json)),
  ]

  let duration = case create.duration {
    Some(duration) -> [#("duration", time_duration.to_int_hours_json(duration))]
    None -> []
  }

  let allow_multiselect = [
    #("allow_multiselect", json.bool(create.allow_multiselect)),
  ]

  let layout_type = case create.layout_type {
    Some(type_) -> [#("layout_type", layout_type_to_json(type_))]
    None -> []
  }

  [question, answers, duration, allow_multiselect, layout_type]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_question_to_json(question: CreateQuestion) -> Json {
  json.object(case question.text {
    Some(text) -> [#("text", json.string(text))]
    None -> []
  })
}

@internal
pub fn create_answer_to_json(answer: CreateAnswer) -> Json {
  json.object([#("poll_media", media_to_json(answer.media))])
}

@internal
pub fn media_to_json(media: Media) -> Json {
  let text = case media.text {
    Some(text) -> [#("text", json.string(text))]
    None -> []
  }

  let emoji = case media.emoji {
    Some(emoji) -> [#("emoji", emoji.to_json(emoji))]
    None -> []
  }

  [text, emoji]
  |> list.flatten
  |> json.object
}

@internal
pub fn layout_type_to_json(layout_type: LayoutType) -> Json {
  case layout_type {
    Default -> 1
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_voters_for_answer(
  client: grom.Client,
  in channel_id: String,
  on message_id: String,
  regarding answer_id: String,
  using query: List(GetAnswerVotersQuery),
) -> Result(List(User), grom.Error) {
  let query =
    list.map(query, fn(single_query) {
      case single_query {
        AfterUserId(id) -> #("after", id)
        Limit(limit) -> #("limit", int.to_string(limit))
      }
    })

  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/"
        <> channel_id
        <> "/polls/"
        <> message_id
        <> "/answers/"
        <> answer_id,
    )
    |> request.set_query(query)
    |> rest.execute,
  )

  let response_decoder = {
    use users <- decode.field("users", decode.list(of: user.decoder()))
    decode.success(users)
  }

  response.body
  |> json.parse(using: response_decoder)
  |> result.map_error(grom.CouldNotDecode)
}

pub fn new_create(
  asking question: CreateQuestion,
  answers answers: List(CreateAnswer),
  allowing_multiselect allow_multiselect: Bool,
) -> Create {
  Create(question, answers, None, allow_multiselect, None)
}

pub fn new_create_question() -> CreateQuestion {
  CreateQuestion(None)
}

pub fn new_media() -> Media {
  Media(None, None)
}
