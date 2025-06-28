import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import grom/channel/thread.{type Thread}
import grom/client.{type Client}
import grom/error.{type Error}
import grom/file.{type File}
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/message/allowed_mentions.{type AllowedMentions}
import grom/message/attachment
import grom/message/component.{type Component}
import grom/message/embed.{type Embed}

// TYPES -----------------------------------------------------------------------

pub type Tag {
  Tag(
    id: String,
    name: String,
    is_moderated: Bool,
    emoji_id: Option(String),
    emoji_name: Option(String),
  )
}

pub opaque type StartThread {
  StartThread(
    name: String,
    auto_archive_duration: Option(Duration),
    rate_limit_per_user: Option(Duration),
    message: StartThreadMessage,
    applied_tags_ids: Option(List(String)),
    files: Option(List(File)),
  )
}

pub opaque type StartThreadMessage {
  StartThreadMessage(
    content: Option(String),
    embeds: Option(List(Embed)),
    allowed_mentions: Option(AllowedMentions),
    components: Option(List(Component)),
    sticker_ids: Option(List(String)),
    attachments: Option(List(attachment.Create)),
    flags: Option(List(StartThreadMessageFlag)),
  )
}

pub type StartThreadMessageFlag {
  SuppressEmbeds
  SuppressNotifications
}

pub type Flag {
  RequiresTag
}

pub type DefaultReaction {
  DefaultReaction(emoji_id: Option(String), emoji_name: Option(String))
}

pub type SortOrder {
  SortByLatestActivity
  SortByCreationDate
}

pub type Layout {
  LayoutNotSet
  ListLayout
  GalleryLayout
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [#(int.bitwise_shift_left(1, 4), RequiresTag)]
}

@internal
pub fn bits_start_thread_message_flags() -> List(#(Int, StartThreadMessageFlag)) {
  [
    #(int.bitwise_shift_left(1, 2), SuppressEmbeds),
    #(int.bitwise_shift_left(1, 12), SuppressNotifications),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn default_reaction_decoder() -> decode.Decoder(DefaultReaction) {
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(DefaultReaction(emoji_id:, emoji_name:))
}

@internal
pub fn sort_order_type_decoder() -> decode.Decoder(SortOrder) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(SortByLatestActivity)
    1 -> decode.success(SortByCreationDate)
    _ -> decode.failure(SortByLatestActivity, "SortOrderType")
  }
}

@internal
pub fn layout_type_decoder() -> decode.Decoder(Layout) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(LayoutNotSet)
    1 -> decode.success(ListLayout)
    2 -> decode.success(GalleryLayout)
    _ -> decode.failure(LayoutNotSet, "LayoutType")
  }
}

@internal
pub fn tag_decoder() -> decode.Decoder(Tag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji_id <- decode.field("emoji_id", decode.optional(decode.string))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(Tag(id:, name:, is_moderated:, emoji_id:, emoji_name:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn default_reaction_encode(default_reaction: DefaultReaction) -> Json {
  let DefaultReaction(emoji_id:, emoji_name:) = default_reaction
  json.object([
    #("emoji_id", case emoji_id {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
    #("emoji_name", case emoji_name {
      None -> json.null()
      Some(value) -> json.string(value)
    }),
  ])
}

@internal
pub fn sort_order_type_encode(sort_order_type: SortOrder) -> Json {
  case sort_order_type {
    SortByLatestActivity -> 0
    SortByCreationDate -> 1
  }
  |> json.int
}

@internal
pub fn layout_type_encode(layout_type: Layout) -> Json {
  case layout_type {
    LayoutNotSet -> 0
    ListLayout -> 1
    GalleryLayout -> 2
  }
  |> json.int
}

@internal
pub fn tag_to_json(tag: Tag) -> Json {
  let id = #("id", json.string(tag.id))
  let name = #("name", json.string(tag.name))
  let is_moderated = #("moderated", json.bool(tag.is_moderated))
  let emoji_id = #("emoji_id", json.nullable(tag.emoji_id, json.string))
  let emoji_name = #("emoji_name", json.nullable(tag.emoji_name, json.string))

  [id, name, is_moderated, emoji_id, emoji_name]
  |> json.object
}

@internal
pub fn start_thread_to_json(start_thread: StartThread) -> Json {
  let name = [#("name", json.string(start_thread.name))]

  let auto_archive_duration = case start_thread.auto_archive_duration {
    Some(duration) -> [
      #("auto_archive_duration", time_duration.to_int_seconds_encode(duration)),
    ]
    None -> []
  }

  let rate_limit_per_user = case start_thread.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let message = [
    #("message", start_thread_message_to_json(start_thread.message)),
  ]

  let applied_tags_ids = case start_thread.applied_tags_ids {
    Some(ids) -> [#("applied_tags", json.array(ids, json.string))]
    None -> []
  }

  [name, auto_archive_duration, rate_limit_per_user, message, applied_tags_ids]
  |> list.flatten
  |> json.object
}

@internal
pub fn start_thread_message_to_json(message: StartThreadMessage) -> Json {
  let content = case message.content {
    Some(content) -> [#("content", json.string(content))]
    None -> []
  }

  let embeds = case message.embeds {
    Some(embeds) -> [#("embeds", json.array(embeds, embed.to_json))]
    None -> []
  }

  let allowed_mentions = case message.allowed_mentions {
    Some(allowed_mentions) -> [
      #("allowed_mentions", allowed_mentions.to_json(allowed_mentions)),
    ]
    None -> []
  }

  let components = case message.components {
    Some(components) -> [
      #("components", json.array(components, component.to_json)),
    ]
    None -> []
  }

  let sticker_ids = case message.sticker_ids {
    Some(ids) -> [#("sticker_ids", json.array(ids, json.string))]
    None -> []
  }

  let attachments = case message.attachments {
    Some(attachments) -> [
      #("attachments", json.array(attachments, attachment.create_to_json)),
    ]
    None -> []
  }

  let flags = case message.flags {
    Some(flags) -> [
      #(
        "flags",
        flags
          |> flags.to_int(bits_start_thread_message_flags())
          |> json.int,
      ),
    ]
    None -> []
  }

  [
    content,
    embeds,
    allowed_mentions,
    components,
    sticker_ids,
    attachments,
    flags,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn start_thread(
  client: Client,
  in channel_id: String,
  with start_thread: StartThread,
  because reason: Option(String),
) -> Result(Thread, Error) {
  use response <- result.try(case start_thread.files {
    Some(files) -> {
      client
      |> rest.new_multipart_request(
        http.Post,
        "/channels/" <> channel_id <> "/threads",
        start_thread_to_json(start_thread),
        files,
      )
      |> rest.with_reason(reason)
      |> rest.execute_multipart
    }
    None -> {
      let json = start_thread |> start_thread_to_json

      client
      |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/threads")
      |> request.set_body(json |> json.to_string)
      |> rest.with_reason(reason)
      |> rest.execute
    }
  })

  response.body
  |> json.parse(using: thread.decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn new_start_thread(
  name: String,
  message: StartThreadMessage,
) -> StartThread {
  StartThread(name, None, None, message, None, None)
}

pub fn start_thread_with_auto_archive_duration(
  start_thread: StartThread,
  auto_archive_duration: Duration,
) -> StartThread {
  StartThread(
    ..start_thread,
    auto_archive_duration: Some(auto_archive_duration),
  )
}

pub fn start_thread_with_rate_limit_per_user(
  start_thread: StartThread,
  rate_limit_per_user: Duration,
) -> StartThread {
  StartThread(..start_thread, rate_limit_per_user: Some(rate_limit_per_user))
}

pub fn start_thread_with_applied_tags(
  start_thread: StartThread,
  ids applied_tags_ids: List(String),
) -> StartThread {
  StartThread(..start_thread, applied_tags_ids: Some(applied_tags_ids))
}

pub fn start_thread_with_files(
  start_thread: StartThread,
  files: List(File),
) -> StartThread {
  StartThread(..start_thread, files: Some(files))
}

pub fn new_start_thread_message() -> StartThreadMessage {
  StartThreadMessage(None, None, None, None, None, None, None)
}

pub fn start_thread_message_with_content(
  start_thread_message: StartThreadMessage,
  content: String,
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, content: Some(content))
}

pub fn start_thread_message_with_embeds(
  start_thread_message: StartThreadMessage,
  embeds: List(Embed),
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, embeds: Some(embeds))
}

pub fn start_thread_message_with_allowed_mentions(
  start_thread_message: StartThreadMessage,
  allowed_mentions: AllowedMentions,
) -> StartThreadMessage {
  StartThreadMessage(
    ..start_thread_message,
    allowed_mentions: Some(allowed_mentions),
  )
}

pub fn start_thread_message_with_components(
  start_thread_message: StartThreadMessage,
  components: List(Component),
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, components: Some(components))
}

pub fn start_thread_message_with_stickers(
  start_thread_message: StartThreadMessage,
  ids sticker_ids: List(String),
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, sticker_ids: Some(sticker_ids))
}

pub fn start_thread_message_with_attachments(
  start_thread_message: StartThreadMessage,
  attachments: List(attachment.Create),
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, attachments: Some(attachments))
}

pub fn start_thread_message_with_flags(
  start_thread_message: StartThreadMessage,
  flags: List(StartThreadMessageFlag),
) -> StartThreadMessage {
  StartThreadMessage(..start_thread_message, flags: Some(flags))
}
