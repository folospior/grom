import gleam/int
import gleam/option.{type Option}
import gleam/time/duration.{type Duration}
import grom
import grom/channel/forum
import grom/channel/thread.{type Thread}
import grom/error.{type Error}
import grom/file.{type File}
import grom/message/allowed_mentions.{type AllowedMentions}
import grom/message/attachment
import grom/message/component.{type Component}
import grom/message/embed.{type Embed}

// TYPES -----------------------------------------------------------------------

pub type Flag {
  RequiresTag
  HideMediaDownloadOptions
}

pub type StartThread =
  forum.StartThread

pub type StartThreadMessage =
  forum.StartThreadMessage

pub type StartThreadMessageFlag =
  forum.StartThreadMessageFlag

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 4), RequiresTag),
    #(int.bitwise_shift_left(1, 15), HideMediaDownloadOptions),
  ]
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn start_thread(
  client: grom.Client,
  in channel_id: String,
  with start_thread: StartThread,
  because reason: Option(String),
) -> Result(Thread, Error) {
  forum.start_thread(
    client,
    in: channel_id,
    with: start_thread,
    because: reason,
  )
}

pub fn new_start_thread(
  name: String,
  message: StartThreadMessage,
) -> StartThread {
  forum.new_start_thread(name, message)
}

pub fn start_thread_with_auto_archive_duration(
  start_thread: StartThread,
  auto_archive_duration: Duration,
) -> StartThread {
  start_thread
  |> forum.start_thread_with_auto_archive_duration(auto_archive_duration)
}

pub fn start_thread_with_rate_limit_per_user(
  start_thread: StartThread,
  rate_limit_per_user: Duration,
) -> StartThread {
  start_thread
  |> forum.start_thread_with_rate_limit_per_user(rate_limit_per_user)
}

pub fn start_thread_with_applied_tags(
  start_thread: StartThread,
  ids applied_tags_ids: List(String),
) -> StartThread {
  start_thread
  |> forum.start_thread_with_applied_tags(applied_tags_ids)
}

pub fn start_thread_with_files(
  start_thread: StartThread,
  files: List(File),
) -> StartThread {
  start_thread
  |> forum.start_thread_with_files(files)
}

pub fn new_start_thread_message() -> StartThreadMessage {
  forum.new_start_thread_message()
}

pub fn start_thread_message_with_content(
  start_thread_message: StartThreadMessage,
  content: String,
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_content(content)
}

pub fn start_thread_message_with_embeds(
  start_thread_message: StartThreadMessage,
  embeds: List(Embed),
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_embeds(embeds)
}

pub fn start_thread_message_with_allowed_mentions(
  start_thread_message: StartThreadMessage,
  allowed_mentions: AllowedMentions,
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_allowed_mentions(allowed_mentions)
}

pub fn start_thread_message_with_components(
  start_thread_message: StartThreadMessage,
  components: List(Component),
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_components(components)
}

pub fn start_thread_message_with_stickers(
  start_thread_message: StartThreadMessage,
  ids sticker_ids: List(String),
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_stickers(sticker_ids)
}

pub fn start_thread_message_with_attachments(
  start_thread_message: StartThreadMessage,
  attachments: List(attachment.Create),
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_attachments(attachments)
}

pub fn start_thread_message_with_flags(
  start_thread_message: StartThreadMessage,
  flags: List(StartThreadMessageFlag),
) -> StartThreadMessage {
  start_thread_message
  |> forum.start_thread_message_with_flags(flags)
}
