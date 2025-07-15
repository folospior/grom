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
import grom/channel/forum
import grom/channel/media
import grom/channel/permission_overwrite.{type PermissionOverwrite}
import grom/channel/thread.{type Thread}
import grom/client.{type Client}
import grom/error.{type Error}
import grom/internal/flags
import grom/internal/rest
import grom/internal/time_duration
import grom/internal/time_rfc3339
import grom/message.{type Message}
import grom/modification.{type Modification, Skip}
import grom/permission.{type Permission}
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Channel {
  Text(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    topic: Option(String),
    is_nsfw: Bool,
    last_message_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    last_pin_timestamp: Option(Timestamp),
    current_user_permissions: Option(List(Permission)),
    default_auto_archive_duration: Duration,
  )
  Dm(
    id: String,
    last_message_id: Option(String),
    recipients: List(User),
    current_user_permissions: Option(List(Permission)),
  )
  Voice(
    id: String,
    guild_id: String,
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    is_nsfw: Bool,
    last_message_id: Option(String),
    bitrate: Int,
    user_limit: Int,
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    rtc_region_id: Option(String),
    video_quality_mode: VideoQualityMode,
    current_user_permissions: Option(List(Permission)),
  )
  Category(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    current_user_permissions: Option(List(Permission)),
  )
  Announcement(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    topic: Option(String),
    is_nsfw: Bool,
    last_message_id: Option(String),
    parent_id: Option(String),
    last_pin_timestamp: Option(Timestamp),
    current_user_permissions: Option(List(Permission)),
    default_auto_archive_duration: Duration,
  )
  Thread(Thread)
  Stage(
    id: String,
    guild_id: String,
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    is_nsfw: Bool,
    last_message_id: Option(String),
    bitrate: Int,
    user_limit: Int,
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    rtc_region_id: Option(String),
    video_quality_mode: VideoQualityMode,
    current_user_permissions: Option(List(Permission)),
  )
  Forum(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    topic: Option(String),
    is_nsfw: Bool,
    last_thread_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    default_auto_archive_duration: Option(Duration),
    current_user_permissions: Option(List(Permission)),
    flags: List(forum.Flag),
    available_tags: List(forum.Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Duration,
    default_sort_order: Option(forum.SortOrder),
    default_layout: forum.Layout,
  )
  Media(
    id: String,
    guild_id: Option(String),
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    topic: Option(String),
    is_nsfw: Bool,
    last_thread_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: Option(String),
    default_auto_archive_duration: Option(Duration),
    current_user_permissions: Option(List(Permission)),
    flags: List(media.Flag),
    available_tags: List(forum.Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Option(forum.SortOrder),
  )
}

pub opaque type Modify {
  ModifyText(
    name: Option(String),
    convert_to_announcement: Bool,
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
    default_thread_rate_limit_per_user: Option(Duration),
  )
  ModifyVoice(
    name: Option(String),
    position: Modification(Int),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    bitrate: Modification(Int),
    user_limit: Modification(Int),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    rtc_region_id: Modification(String),
    video_quality_mode: Modification(VideoQualityMode),
  )
  ModifyCategory(
    name: Option(String),
    position: Modification(Int),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
  )
  ModifyAnnouncement(
    name: Option(String),
    convert_to_text: Bool,
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
  )
  ModifyThread(
    name: Option(String),
    is_archived: Option(Bool),
    auto_archive_duration: Option(Duration),
    is_locked: Option(Bool),
    is_invitable: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    flags: Option(List(thread.Flag)),
    applied_tags_ids: Option(List(String)),
  )
  ModifyStage(
    name: Option(String),
    position: Modification(Int),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    bitrate: Modification(Int),
    user_limit: Modification(Int),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    rtc_region_id: Modification(String),
    video_quality_mode: Modification(VideoQualityMode),
  )
  ModifyForum(
    name: Option(String),
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
    flags: Option(List(forum.Flag)),
    available_tags: Option(List(forum.Tag)),
    default_reaction_emoji: Modification(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Modification(forum.SortOrder),
    default_layout: Option(forum.Layout),
  )
  ModifyMedia(
    name: Option(String),
    position: Modification(Int),
    topic: Modification(String),
    is_nsfw: Option(Bool),
    rate_limit_per_user: Modification(Duration),
    permission_overwrites: Modification(List(permission_overwrite.Create)),
    parent_id: Modification(String),
    default_auto_archive_duration: Modification(Duration),
    flags: Option(List(media.Flag)),
    available_tags: Option(List(forum.Tag)),
    default_reaction_emoji: Modification(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Modification(forum.SortOrder),
  )
}

pub type Create {
  CreateTextChannel(CreateText)
  CreateDmChannel(CreateDm)
  CreateVoiceChannel(CreateVoice)
  CreateCategoryChannel(CreateCategory)
  CreateAnnouncementChannel(CreateAnnouncement)
  CreateStageChannel(CreateStage)
  CreateForumChannel(CreateForum)
  CreateMediaChannel(CreateMedia)
}

pub type CreateText {
  CreateText(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    parent_id: Option(String),
    is_nsfw: Bool,
    default_auto_archive_duration: Option(Duration),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

pub type CreateDm {
  CreateDm(recipient_id: String)
}

pub type CreateVoice {
  CreateVoice(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    bitrate: Option(Int),
    user_limit: Option(Int),
    rate_limit_per_user: Option(Duration),
    parent_id: Option(String),
    is_nsfw: Bool,
    rtc_region: Option(String),
    video_quality_mode: Option(VideoQualityMode),
  )
}

pub type CreateCategory {
  CreateCategory(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
  )
}

pub type CreateAnnouncement {
  CreateAnnouncement(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    topic: Option(String),
    parent_id: Option(String),
    is_nsfw: Bool,
    default_auto_archive_duration: Option(Duration),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

pub type CreateStage {
  CreateStage(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    bitrate: Option(Int),
    user_limit: Option(Int),
    rate_limit_per_user: Option(Duration),
    parent_id: Option(String),
    is_nsfw: Bool,
    rtc_region: Option(String),
    video_quality_mode: Option(VideoQualityMode),
  )
}

pub type CreateForum {
  CreateForum(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    parent_id: Option(String),
    is_nsfw: Bool,
    default_auto_archive_duration: Option(Duration),
    default_reaction_emoji: Option(forum.DefaultReaction),
    available_tags: Option(List(forum.Tag)),
    default_sort_order: Option(forum.SortOrder),
    default_forum_layout: Option(forum.Layout),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

pub type CreateMedia {
  CreateMedia(
    guild_id: String,
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(permission_overwrite.Create)),
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    parent_id: Option(String),
    default_auto_archive_duration: Option(Duration),
    default_reaction_emoji: Option(forum.DefaultReaction),
    available_tags: Option(List(forum.Tag)),
    default_sort_order: Option(forum.SortOrder),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

pub type FollowedChannel {
  FollowedChannel(channel_id: String, webhook_id: String)
}

pub type VideoQualityMode {
  AutomaticVideoQuality
  HDVideoQuality
}

pub type ReceivedThreads {
  ReceivedThreads(
    threads: List(Thread),
    members: List(thread.Member),
    has_more: Bool,
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Channel) {
  use type_ <- decode.field("type", decode.int)
  case type_ {
    0 -> text_decoder()
    1 -> dm_decoder()
    2 -> voice_decoder()
    4 -> category_decoder()
    5 -> announcement_decoder()
    10 | 11 | 12 -> {
      use thread <- decode.then(thread.decoder())
      decode.success(Thread(thread))
    }
    13 -> stage_decoder()
    15 -> forum_decoder()
    16 -> media_decoder()
    _ ->
      decode.failure(
        Text(
          "",
          None,
          0,
          [],
          "",
          None,
          False,
          None,
          duration.seconds(0),
          None,
          None,
          None,
          duration.seconds(0),
        ),
        "Channel",
      )
  }
}

@internal
pub fn text_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use topic <- decode.field("topic", decode.optional(decode.string))
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use last_pin_timestamp <- decode.field(
    "last_pin_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use default_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    time_duration.from_int_seconds_decoder(),
  )
  decode.success(Text(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_message_id:,
    rate_limit_per_user:,
    parent_id:,
    last_pin_timestamp:,
    current_user_permissions:,
    default_auto_archive_duration:,
  ))
}

@internal
pub fn dm_decoder() {
  use id <- decode.field("id", decode.string)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use recipients <- decode.field("recipients", decode.list(user.decoder()))
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Dm(
    id:,
    last_message_id:,
    recipients:,
    current_user_permissions:,
  ))
}

@internal
pub fn voice_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use bitrate <- decode.field("bitrate", decode.int)
  use user_limit <- decode.field("user_limit", decode.int)
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_int_seconds_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use rtc_region_id <- decode.field(
    "rtc_region",
    decode.optional(decode.string),
  )
  use video_quality_mode <- decode.optional_field(
    "video_quality_mode",
    AutomaticVideoQuality,
    video_quality_mode_decoder(),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Voice(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    is_nsfw:,
    last_message_id:,
    bitrate:,
    user_limit:,
    rate_limit_per_user:,
    parent_id:,
    rtc_region_id:,
    video_quality_mode:,
    current_user_permissions:,
  ))
}

@internal
pub fn category_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Category(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    current_user_permissions:,
  ))
}

@internal
pub fn announcement_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use topic <- decode.field("topic", decode.optional(decode.string))
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use last_pin_timestamp <- decode.field(
    "last_pin_timestamp",
    decode.optional(time_rfc3339.decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use default_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    time_duration.from_int_seconds_decoder(),
  )
  decode.success(Announcement(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_message_id:,
    parent_id:,
    last_pin_timestamp:,
    current_user_permissions:,
    default_auto_archive_duration:,
  ))
}

@internal
pub fn stage_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.field(
    "last_message_id",
    decode.optional(decode.string),
  )
  use bitrate <- decode.field("bitrate", decode.int)
  use user_limit <- decode.field("user_limit", decode.int)
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_int_seconds_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use rtc_region_id <- decode.field(
    "rtc_region",
    decode.optional(decode.string),
  )
  use video_quality_mode <- decode.optional_field(
    "video_quality_mode",
    AutomaticVideoQuality,
    video_quality_mode_decoder(),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  decode.success(Stage(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    is_nsfw:,
    last_message_id:,
    bitrate:,
    user_limit:,
    rate_limit_per_user:,
    parent_id:,
    rtc_region_id:,
    video_quality_mode:,
    current_user_permissions:,
  ))
}

@internal
pub fn forum_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use topic <- decode.field("topic", decode.optional(decode.string))
  use is_nsfw <- decode.field("is_nsfw", decode.bool)
  use last_thread_id <- decode.field(
    "last_thread_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use default_auto_archive_duration <- decode.optional_field(
    "default_auto_archive_duration",
    None,
    decode.optional(time_duration.from_minutes_decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use flags <- decode.field("flags", flags.decoder(forum.bits_flags()))
  use available_tags <- decode.field(
    "available_tags",
    decode.list(forum.tag_decoder()),
  )
  use default_reaction_emoji <- decode.field(
    "default_reaction_emoji",
    decode.optional(forum.default_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.field(
    "default_thread_rate_limit_per_user",
    time_duration.from_int_seconds_decoder(),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    decode.optional(forum.sort_order_type_decoder()),
  )
  use default_layout <- decode.field(
    "default_layout",
    forum.layout_type_decoder(),
  )
  decode.success(Forum(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_thread_id:,
    rate_limit_per_user:,
    parent_id:,
    default_auto_archive_duration:,
    current_user_permissions:,
    available_tags:,
    flags:,
    default_reaction_emoji:,
    default_thread_rate_limit_per_user:,
    default_sort_order:,
    default_layout:,
  ))
}

@internal
pub fn media_decoder() -> decode.Decoder(Channel) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permission_overwrites <- decode.field(
    "permission_overwrites",
    decode.list(permission_overwrite.decoder()),
  )
  use name <- decode.field("name", decode.string)
  use topic <- decode.field("topic", decode.optional(decode.string))
  use is_nsfw <- decode.field("is_nsfw", decode.bool)
  use last_thread_id <- decode.field(
    "last_thread_id",
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    time_duration.from_minutes_decoder(),
  )
  use parent_id <- decode.field("parent_id", decode.optional(decode.string))
  use default_auto_archive_duration <- decode.optional_field(
    "default_auto_archive_duration",
    None,
    decode.optional(time_duration.from_minutes_decoder()),
  )
  use current_user_permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(permission.decoder()),
  )
  use flags <- decode.field("flags", flags.decoder(media.bits_flags()))
  use available_tags <- decode.field(
    "available_tags",
    decode.list(forum.tag_decoder()),
  )
  use default_reaction_emoji <- decode.field(
    "default_reaction_emoji",
    decode.optional(forum.default_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.optional_field(
    "default_thread_rate_limit_per_user",
    None,
    decode.optional(time_duration.from_minutes_decoder()),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    decode.optional(forum.sort_order_type_decoder()),
  )
  decode.success(Media(
    id:,
    guild_id:,
    position:,
    permission_overwrites:,
    name:,
    topic:,
    is_nsfw:,
    last_thread_id:,
    rate_limit_per_user:,
    parent_id:,
    default_auto_archive_duration:,
    current_user_permissions:,
    flags:,
    available_tags:,
    default_reaction_emoji:,
    default_thread_rate_limit_per_user:,
    default_sort_order:,
  ))
}

@internal
pub fn video_quality_mode_decoder() -> decode.Decoder(VideoQualityMode) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(AutomaticVideoQuality)
    2 -> decode.success(HDVideoQuality)
    _ -> decode.failure(AutomaticVideoQuality, "VideoQualityMode")
  }
}

@internal
pub fn followed_channel_decoder() -> decode.Decoder(FollowedChannel) {
  use channel_id <- decode.field("channel_id", decode.string)
  use webhook_id <- decode.field("webhook_id", decode.string)
  decode.success(FollowedChannel(channel_id:, webhook_id:))
}

@internal
pub fn received_threads_decoder() -> decode.Decoder(ReceivedThreads) {
  use threads <- decode.field("threads", decode.list(thread.decoder()))
  use members <- decode.field("members", decode.list(thread.member_decoder()))
  use has_more <- decode.field("has_more", decode.bool)

  decode.success(ReceivedThreads(threads:, members:, has_more:))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn modify_to_json(modify: Modify) -> Json {
  case modify {
    ModifyText(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let type_ = case modify.convert_to_announcement {
        True -> [#("type", json.int(5))]
        False -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let topic =
        modify.topic
        |> modification.encode("topic", json.string)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let parent_id =
        modify.parent_id
        |> modification.encode("parent_id", json.string)

      let default_auto_archive_duration =
        modify.default_auto_archive_duration
        |> modification.encode(
          "default_auto_archive_duration",
          // FIXME: THIS IS SUPPOSED TO BE MINUTES!!!
          time_duration.to_int_seconds_encode,
        )

      let default_thread_rate_limit_per_user = case
        modify.default_thread_rate_limit_per_user
      {
        Some(limit) -> [
          #(
            "default_thread_rate_limit_per_user",
            time_duration.to_int_seconds_encode(limit),
          ),
        ]
        None -> []
      }

      [
        name,
        type_,
        position,
        topic,
        is_nsfw,
        rate_limit_per_user,
        permission_overwrites,
        parent_id,
        default_auto_archive_duration,
        default_thread_rate_limit_per_user,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyVoice(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let bitrate =
        modify.bitrate
        |> modification.encode("bitrate", json.int)

      let user_limit =
        modify.user_limit
        |> modification.encode("user_limit", json.int)

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let parent_id =
        modify.parent_id
        |> modification.encode("parent_id", json.string)

      let rtc_region_id =
        modify.rtc_region_id
        |> modification.encode("rtc_region", json.string)

      let video_quality_mode =
        modify.video_quality_mode
        |> modification.encode("video_quality_mode", video_quality_mode_to_json)

      [
        name,
        position,
        is_nsfw,
        rate_limit_per_user,
        bitrate,
        user_limit,
        permission_overwrites,
        parent_id,
        rtc_region_id,
        video_quality_mode,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyCategory(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      [name, position, permission_overwrites]
      |> list.flatten
      |> json.object
    }
    ModifyAnnouncement(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let type_ = case modify.convert_to_text {
        True -> [#("type", json.int(0))]
        False -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let topic =
        modify.topic
        |> modification.encode("topic", json.string)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let parent_id =
        modify.parent_id
        |> modification.encode("parent_id", json.string)

      let default_auto_archive_duration =
        modify.default_auto_archive_duration
        |> modification.encode(
          "default_auto_archive_duration",
          time_duration.to_int_seconds_encode,
        )

      [
        name,
        type_,
        position,
        topic,
        is_nsfw,
        permission_overwrites,
        parent_id,
        default_auto_archive_duration,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyThread(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let is_archived = case modify.is_archived {
        Some(archived) -> [#("archived", json.bool(archived))]
        None -> []
      }

      let auto_archive_duration = case modify.auto_archive_duration {
        Some(duration) -> [
          #(
            "auto_archive_duration",
            time_duration.to_int_seconds_encode(duration),
          ),
        ]
        None -> []
      }

      let is_locked = case modify.is_locked {
        Some(locked) -> [#("locked", json.bool(locked))]
        None -> []
      }

      let is_invitable = case modify.is_invitable {
        Some(invitable) -> [#("invitable", json.bool(invitable))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let flags = case modify.flags {
        Some(flags) -> [#("flags", flags.encode(flags, thread.bits_flags()))]
        None -> []
      }

      let applied_tags_ids = case modify.applied_tags_ids {
        Some(tags) -> [#("applied_tags", json.array(tags, json.string))]
        None -> []
      }

      [
        name,
        is_archived,
        auto_archive_duration,
        is_locked,
        is_invitable,
        rate_limit_per_user,
        flags,
        applied_tags_ids,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyStage(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let bitrate =
        modify.bitrate
        |> modification.encode("bitrate", json.int)

      let user_limit =
        modify.user_limit
        |> modification.encode("user_limit", json.int)

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let parent_id =
        modify.parent_id
        |> modification.encode("parent_id", json.string)

      let rtc_region_id =
        modify.rtc_region_id
        |> modification.encode("rtc_region", json.string)

      let video_quality_mode =
        modify.video_quality_mode
        |> modification.encode("video_quality_mode", video_quality_mode_to_json)

      [
        name,
        position,
        is_nsfw,
        rate_limit_per_user,
        bitrate,
        user_limit,
        permission_overwrites,
        parent_id,
        rtc_region_id,
        video_quality_mode,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyForum(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let topic =
        modify.topic
        |> modification.encode("topic", json.string)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let parent_id =
        modify.parent_id
        |> modification.encode("parent_id", json.string)

      let default_auto_archive_duration =
        modify.default_auto_archive_duration
        |> modification.encode(
          "default_auto_archive_duration",
          time_duration.to_int_seconds_encode,
        )

      let flags = case modify.flags {
        Some(flags) -> [#("flags", flags.encode(flags, forum.bits_flags()))]
        None -> []
      }

      let available_tags = case modify.available_tags {
        Some(tags) -> [#("available_tags", json.array(tags, forum.tag_to_json))]
        None -> []
      }

      let default_reaction_emoji =
        modify.default_reaction_emoji
        |> modification.encode(
          "default_reaction_emoji",
          forum.default_reaction_encode,
        )

      let default_thread_rate_limit_per_user = case
        modify.default_thread_rate_limit_per_user
      {
        Some(limit) -> [
          #(
            "default_thread_rate_limit_per_user",
            time_duration.to_int_seconds_encode(limit),
          ),
        ]
        None -> []
      }

      let default_sort_order =
        modify.default_sort_order
        |> modification.encode(
          "default_sort_order",
          forum.sort_order_type_encode,
        )

      [
        name,
        position,
        topic,
        is_nsfw,
        rate_limit_per_user,
        permission_overwrites,
        parent_id,
        default_auto_archive_duration,
        flags,
        available_tags,
        default_reaction_emoji,
        default_thread_rate_limit_per_user,
        default_sort_order,
      ]
      |> list.flatten
      |> json.object
    }
    ModifyMedia(..) -> {
      let name = case modify.name {
        Some(name) -> [#("name", json.string(name))]
        None -> []
      }

      let position =
        modify.position
        |> modification.encode("position", json.int)

      let topic =
        modify.topic
        |> modification.encode("topic", json.string)

      let is_nsfw = case modify.is_nsfw {
        Some(nsfw) -> [#("nsfw", json.bool(nsfw))]
        None -> []
      }

      let rate_limit_per_user =
        modify.rate_limit_per_user
        |> modification.encode(
          "rate_limit_per_user",
          time_duration.to_int_seconds_encode,
        )

      let permission_overwrites =
        modify.permission_overwrites
        |> modification.encode("permission_overwrites", json.array(
          _,
          permission_overwrite.create_to_json,
        ))

      let default_auto_archive_duration =
        modify.default_auto_archive_duration
        |> modification.encode(
          "default_auto_archive_duration",
          time_duration.to_int_seconds_encode,
        )

      let flags = case modify.flags {
        Some(flags) -> [#("flags", flags.encode(flags, media.bits_flags()))]
        None -> []
      }

      let available_tags = case modify.available_tags {
        Some(tags) -> [#("available_tags", json.array(tags, forum.tag_to_json))]
        None -> []
      }

      let default_reaction_emoji =
        modify.default_reaction_emoji
        |> modification.encode(
          "default_reaction_emoji",
          forum.default_reaction_encode,
        )

      let default_thread_rate_limit_per_user = case
        modify.default_thread_rate_limit_per_user
      {
        Some(limit) -> [
          #(
            "default_thread_rate_limit_per_user",
            time_duration.to_int_seconds_encode(limit),
          ),
        ]
        None -> []
      }

      let default_sort_order =
        modify.default_sort_order
        |> modification.encode(
          "default_sort_order",
          forum.sort_order_type_encode,
        )

      [
        name,
        position,
        topic,
        is_nsfw,
        rate_limit_per_user,
        permission_overwrites,
        default_auto_archive_duration,
        flags,
        available_tags,
        default_reaction_emoji,
        default_thread_rate_limit_per_user,
        default_sort_order,
      ]
      |> list.flatten
      |> json.object
    }
  }
}

@internal
pub fn video_quality_mode_to_json(video_quality_mode: VideoQualityMode) -> Json {
  case video_quality_mode {
    AutomaticVideoQuality -> 1
    HDVideoQuality -> 2
  }
  |> json.int
}

@internal
pub fn create_to_json(create: Create) -> Json {
  case create {
    CreateTextChannel(inner) -> create_text_to_json(inner)
    CreateDmChannel(inner) -> create_dm_to_json(inner)
    CreateVoiceChannel(inner) -> create_voice_to_json(inner)
    CreateCategoryChannel(inner) -> create_category_to_json(inner)
    CreateAnnouncementChannel(inner) -> create_announcement_to_json(inner)
    CreateStageChannel(inner) -> create_stage_to_json(inner)
    CreateForumChannel(inner) -> create_forum_to_json(inner)
    CreateMediaChannel(inner) -> create_media_to_json(inner)
  }
}

@internal
pub fn create_text_to_json(create_text: CreateText) -> Json {
  let name = [#("name", json.string(create_text.name))]

  let position = case create_text.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_text.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let topic = case create_text.topic {
    Some(topic) -> [#("topic", json.string(topic))]
    None -> []
  }

  let rate_limit_per_user = case create_text.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let parent_id = case create_text.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create_text.is_nsfw))]

  let default_auto_archive_duration = case
    create_text.default_auto_archive_duration
  {
    Some(duration) -> [
      #(
        "default_auto_archive_duration",
        json.int(time_duration.to_int_seconds(duration) / 60),
      ),
    ]
    None -> []
  }

  let default_thread_rate_limit_per_user = case
    create_text.default_thread_rate_limit_per_user
  {
    Some(limit) -> [
      #(
        "default_thread_rate_limit_per_user",
        time_duration.to_int_seconds_encode(limit),
      ),
    ]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    topic,
    rate_limit_per_user,
    parent_id,
    is_nsfw,
    default_auto_archive_duration,
    default_thread_rate_limit_per_user,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_dm_to_json(create_dm: CreateDm) -> Json {
  json.object([#("recipient_id", json.string(create_dm.recipient_id))])
}

@internal
pub fn create_voice_to_json(create_voice: CreateVoice) -> Json {
  let name = [#("name", json.string(create_voice.name))]

  let position = case create_voice.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_voice.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let bitrate = case create_voice.bitrate {
    Some(bitrate) -> [#("bitrate", json.int(bitrate))]
    None -> []
  }

  let user_limit = case create_voice.user_limit {
    Some(limit) -> [#("user_limit", json.int(limit))]
    None -> []
  }

  let rate_limit_per_user = case create_voice.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let parent_id = case create_voice.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create_voice.is_nsfw))]

  let rtc_region = case create_voice.rtc_region {
    Some(region) -> [#("rtc_region", json.string(region))]
    None -> []
  }

  let video_quality_mode = case create_voice.video_quality_mode {
    Some(mode) -> [#("video_quality_mode", video_quality_mode_to_json(mode))]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    bitrate,
    user_limit,
    rate_limit_per_user,
    parent_id,
    is_nsfw,
    rtc_region,
    video_quality_mode,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_category_to_json(create_category: CreateCategory) -> Json {
  let name = [#("name", json.string(create_category.name))]

  let position = case create_category.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_category.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  [name, position, permission_overwrites]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_announcement_to_json(
  create_announcement: CreateAnnouncement,
) -> Json {
  let name = [#("name", json.string(create_announcement.name))]

  let position = case create_announcement.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_announcement.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let topic = case create_announcement.topic {
    Some(topic) -> [#("topic", json.string(topic))]
    None -> []
  }

  let parent_id = case create_announcement.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create_announcement.is_nsfw))]

  let default_auto_archive_duration = case
    create_announcement.default_auto_archive_duration
  {
    Some(duration) -> [
      #(
        "default_auto_archive_duration",
        time_duration.to_int_seconds(duration) / 60
          |> json.int,
      ),
    ]
    None -> []
  }

  let default_thread_rate_limit_per_user = case
    create_announcement.default_thread_rate_limit_per_user
  {
    Some(limit) -> [
      #(
        "default_thread_rate_limit_per_user",
        time_duration.to_int_seconds_encode(limit),
      ),
    ]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    topic,
    parent_id,
    is_nsfw,
    default_auto_archive_duration,
    default_thread_rate_limit_per_user,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_stage_to_json(create_stage: CreateStage) -> Json {
  let name = [#("name", json.string(create_stage.name))]

  let position = case create_stage.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_stage.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let bitrate = case create_stage.bitrate {
    Some(bitrate) -> [#("bitrate", json.int(bitrate))]
    None -> []
  }

  let user_limit = case create_stage.user_limit {
    Some(limit) -> [#("user_limit", json.int(limit))]
    None -> []
  }

  let rate_limit_per_user = case create_stage.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let parent_id = case create_stage.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create_stage.is_nsfw))]

  let rtc_region = case create_stage.rtc_region {
    Some(region) -> [#("rtc_region", json.string(region))]
    None -> []
  }

  let video_quality_mode = case create_stage.video_quality_mode {
    Some(mode) -> [#("video_quality_mode", video_quality_mode_to_json(mode))]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    bitrate,
    user_limit,
    rate_limit_per_user,
    parent_id,
    is_nsfw,
    rtc_region,
    video_quality_mode,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_forum_to_json(create_forum: CreateForum) -> Json {
  let name = [#("name", json.string(create_forum.name))]

  let position = case create_forum.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_forum.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let topic = case create_forum.topic {
    Some(topic) -> [#("topic", json.string(topic))]
    None -> []
  }

  let rate_limit_per_user = case create_forum.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let parent_id = case create_forum.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let is_nsfw = [#("nsfw", json.bool(create_forum.is_nsfw))]

  let default_auto_archive_duration = case
    create_forum.default_auto_archive_duration
  {
    Some(duration) -> [
      #(
        "default_auto_archive_duration",
        time_duration.to_int_seconds(duration) / 60
          |> json.int,
      ),
    ]
    None -> []
  }

  let default_reaction_emoji = case create_forum.default_reaction_emoji {
    Some(emoji) -> [
      #("default_reaction_emoji", forum.default_reaction_encode(emoji)),
    ]
    None -> []
  }

  let available_tags = case create_forum.available_tags {
    Some(tags) -> [#("available_tags", json.array(tags, forum.tag_to_json))]
    None -> []
  }

  let default_sort_order = case create_forum.default_sort_order {
    Some(order) -> [
      #("default_sort_order", forum.sort_order_type_encode(order)),
    ]
    None -> []
  }

  let default_forum_layout = case create_forum.default_forum_layout {
    Some(layout) -> [#("default_forum_layout", forum.layout_to_json(layout))]
    None -> []
  }

  let default_thread_rate_limit_per_user = case
    create_forum.default_thread_rate_limit_per_user
  {
    Some(limit) -> [
      #(
        "default_thread_rate_limit_per_user",
        time_duration.to_int_seconds_encode(limit),
      ),
    ]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    topic,
    rate_limit_per_user,
    parent_id,
    is_nsfw,
    default_auto_archive_duration,
    default_reaction_emoji,
    available_tags,
    default_sort_order,
    default_forum_layout,
    default_thread_rate_limit_per_user,
  ]
  |> list.flatten
  |> json.object
}

@internal
pub fn create_media_to_json(create_media: CreateMedia) -> Json {
  let name = [#("name", json.string(create_media.name))]

  let position = case create_media.position {
    Some(position) -> [#("position", json.int(position))]
    None -> []
  }

  let permission_overwrites = case create_media.permission_overwrites {
    Some(overwrites) -> [
      #(
        "permission_overwrites",
        json.array(overwrites, permission_overwrite.create_to_json),
      ),
    ]
    None -> []
  }

  let topic = case create_media.topic {
    Some(topic) -> [#("topic", json.string(topic))]
    None -> []
  }

  let rate_limit_per_user = case create_media.rate_limit_per_user {
    Some(limit) -> [
      #("rate_limit_per_user", time_duration.to_int_seconds_encode(limit)),
    ]
    None -> []
  }

  let parent_id = case create_media.parent_id {
    Some(id) -> [#("parent_id", json.string(id))]
    None -> []
  }

  let default_auto_archive_duration = case
    create_media.default_auto_archive_duration
  {
    Some(duration) -> [
      #(
        "default_auto_archive_duration",
        time_duration.to_int_seconds(duration) / 60
          |> json.int,
      ),
    ]
    None -> []
  }

  let default_reaction_emoji = case create_media.default_reaction_emoji {
    Some(emoji) -> [
      #("default_reaction_emoji", forum.default_reaction_encode(emoji)),
    ]
    None -> []
  }

  let available_tags = case create_media.available_tags {
    Some(tags) -> [#("available_tags", json.array(tags, forum.tag_to_json))]
    None -> []
  }

  let default_sort_order = case create_media.default_sort_order {
    Some(order) -> [
      #("default_sort_order", forum.sort_order_type_encode(order)),
    ]
    None -> []
  }

  let default_thread_rate_limit_per_user = case
    create_media.default_thread_rate_limit_per_user
  {
    Some(limit) -> [
      #(
        "default_thread_rate_limit_per_user",
        time_duration.to_int_seconds_encode(limit),
      ),
    ]
    None -> []
  }

  [
    name,
    position,
    permission_overwrites,
    topic,
    rate_limit_per_user,
    parent_id,
    default_auto_archive_duration,
    default_reaction_emoji,
    available_tags,
    default_sort_order,
    default_thread_rate_limit_per_user,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(client: Client, id channel_id: String) -> Result(Channel, Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/channels/" <> channel_id)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn modify(
  client: Client,
  id channel_id: String,
  with modify: Modify,
  because reason: Option(String),
) -> Result(Channel, Error) {
  let json = modify |> modify_to_json

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/channels/" <> channel_id)
    |> rest.with_reason(reason)
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn new_modify_text() -> Modify {
  ModifyText(None, False, Skip, Skip, None, Skip, Skip, Skip, Skip, None)
}

pub fn new_modify_voice() -> Modify {
  ModifyVoice(None, Skip, None, Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn new_modify_category() -> Modify {
  ModifyCategory(None, Skip, Skip)
}

pub fn new_modify_announcement() -> Modify {
  ModifyAnnouncement(None, False, Skip, Skip, None, Skip, Skip, Skip)
}

pub fn new_modify_thread() -> Modify {
  ModifyThread(None, None, None, None, None, Skip, None, None)
}

pub fn new_modify_stage() -> Modify {
  ModifyStage(None, Skip, None, Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn new_modify_forum() -> Modify {
  ModifyForum(
    None,
    Skip,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    Skip,
    None,
    None,
    Skip,
    None,
    Skip,
    None,
  )
}

pub fn new_modify_media() -> Modify {
  ModifyMedia(
    None,
    Skip,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    Skip,
    None,
    None,
    Skip,
    None,
    Skip,
  )
}

pub fn modify_name(modify: Modify, new name: String) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, name: Some(name))
    ModifyVoice(..) -> ModifyVoice(..modify, name: Some(name))
    ModifyCategory(..) -> ModifyCategory(..modify, name: Some(name))
    ModifyAnnouncement(..) -> ModifyAnnouncement(..modify, name: Some(name))
    ModifyThread(..) -> ModifyThread(..modify, name: Some(name))
    ModifyStage(..) -> ModifyStage(..modify, name: Some(name))
    ModifyForum(..) -> ModifyForum(..modify, name: Some(name))
    ModifyMedia(..) -> ModifyMedia(..modify, name: Some(name))
  }
}

/// Only applies to `Text` channels. If ran on any other, the function has no effect.
pub fn convert_text_to_announcement(modify: Modify) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, convert_to_announcement: True)
    _ -> modify
  }
}

/// Only applies to `Announcement` channels. If ran on any other, the function has no effect.
pub fn convert_announcement_to_text(modify: Modify) -> Modify {
  case modify {
    ModifyAnnouncement(..) ->
      ModifyAnnouncement(..modify, convert_to_text: True)
    _ -> modify
  }
}

/// Only applies to `Text`, `Voice`, `Category`, `Announcement`, `Stage`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_position(modify: Modify, position: Modification(Int)) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, position:)
    ModifyVoice(..) -> ModifyVoice(..modify, position:)
    ModifyCategory(..) -> ModifyCategory(..modify, position:)
    ModifyAnnouncement(..) -> ModifyAnnouncement(..modify, position:)
    ModifyStage(..) -> ModifyStage(..modify, position:)
    ModifyForum(..) -> ModifyForum(..modify, position:)
    ModifyMedia(..) -> ModifyMedia(..modify, position:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Announcement`, `Forum`, and `Media` channnels. If ran on any other, the function has no effect.
pub fn modify_topic(modify: Modify, topic: Modification(String)) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, topic:)
    ModifyAnnouncement(..) -> ModifyAnnouncement(..modify, topic:)
    ModifyForum(..) -> ModifyForum(..modify, topic:)
    ModifyMedia(..) -> ModifyMedia(..modify, topic:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Voice`, `Announcement`, `Stage`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_nsfw_status(modify: Modify, is_nsfw: Bool) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, is_nsfw: Some(is_nsfw))
    ModifyVoice(..) -> ModifyVoice(..modify, is_nsfw: Some(is_nsfw))
    ModifyAnnouncement(..) ->
      ModifyAnnouncement(..modify, is_nsfw: Some(is_nsfw))
    ModifyStage(..) -> ModifyStage(..modify, is_nsfw: Some(is_nsfw))
    ModifyForum(..) -> ModifyForum(..modify, is_nsfw: Some(is_nsfw))
    ModifyMedia(..) -> ModifyMedia(..modify, is_nsfw: Some(is_nsfw))
    _ -> modify
  }
}

/// Only applies to `Text`, `Voice`, `Stage`, `Forum`, `Media`, and `Thread` channels. If ran on any other, the function has no effect.
pub fn modify_rate_limit_per_user(
  modify: Modify,
  rate_limit_per_user: Modification(Duration),
) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, rate_limit_per_user:)
    ModifyVoice(..) -> ModifyVoice(..modify, rate_limit_per_user:)
    ModifyStage(..) -> ModifyStage(..modify, rate_limit_per_user:)
    ModifyForum(..) -> ModifyForum(..modify, rate_limit_per_user:)
    ModifyMedia(..) -> ModifyMedia(..modify, rate_limit_per_user:)
    ModifyThread(..) -> ModifyThread(..modify, rate_limit_per_user:)
    _ -> modify
  }
}

/// Only applies to `Voice`, and `Stage` channels. If ran on any other, the function has no effect.
pub fn modify_bitrate(modify: Modify, bitrate: Modification(Int)) -> Modify {
  case modify {
    ModifyVoice(..) -> ModifyVoice(..modify, bitrate:)
    ModifyStage(..) -> ModifyStage(..modify, bitrate:)
    _ -> modify
  }
}

/// Only applies to `Voice`, and `Stage` channels. If ran on any other, the function has no effect.
pub fn modify_user_limit(
  modify: Modify,
  user_limit: Modification(Int),
) -> Modify {
  case modify {
    ModifyVoice(..) -> ModifyVoice(..modify, user_limit:)
    ModifyStage(..) -> ModifyStage(..modify, user_limit:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Voice`, `Category`, `Announcement`, `Stage`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_permission_overwrites(
  modify: Modify,
  permission_overwrites: Modification(List(permission_overwrite.Create)),
) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, permission_overwrites:)
    ModifyVoice(..) -> ModifyVoice(..modify, permission_overwrites:)
    ModifyCategory(..) -> ModifyCategory(..modify, permission_overwrites:)
    ModifyAnnouncement(..) ->
      ModifyAnnouncement(..modify, permission_overwrites:)
    ModifyStage(..) -> ModifyStage(..modify, permission_overwrites:)
    ModifyForum(..) -> ModifyForum(..modify, permission_overwrites:)
    ModifyMedia(..) -> ModifyMedia(..modify, permission_overwrites:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Voice`, `Announcement`, `Stage`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_parent_id(
  modify: Modify,
  parent_id: Modification(String),
) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, parent_id:)
    ModifyVoice(..) -> ModifyVoice(..modify, parent_id:)
    ModifyAnnouncement(..) -> ModifyAnnouncement(..modify, parent_id:)
    ModifyStage(..) -> ModifyStage(..modify, parent_id:)
    ModifyForum(..) -> ModifyForum(..modify, parent_id:)
    ModifyMedia(..) -> ModifyMedia(..modify, parent_id:)
    _ -> modify
  }
}

/// Only applies to `Voice`, and `Stage` channels. If ran on any other, the function has no effect.
pub fn modify_rtc_region_id(
  modify: Modify,
  rtc_region_id: Modification(String),
) -> Modify {
  case modify {
    ModifyVoice(..) -> ModifyVoice(..modify, rtc_region_id:)
    ModifyStage(..) -> ModifyStage(..modify, rtc_region_id:)
    _ -> modify
  }
}

/// Only applies to `Voice`, and `Stage` channels. If ran on any other, the function has no effect.
pub fn modify_video_quality_mode(
  modify: Modify,
  video_quality_mode: Modification(VideoQualityMode),
) -> Modify {
  case modify {
    ModifyVoice(..) -> ModifyVoice(..modify, video_quality_mode:)
    ModifyStage(..) -> ModifyStage(..modify, video_quality_mode:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Announcement`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_default_auto_archive_duration(
  modify: Modify,
  default_auto_archive_duration: Modification(Duration),
) -> Modify {
  case modify {
    ModifyText(..) -> ModifyText(..modify, default_auto_archive_duration:)
    ModifyAnnouncement(..) ->
      ModifyAnnouncement(..modify, default_auto_archive_duration:)
    ModifyForum(..) -> ModifyForum(..modify, default_auto_archive_duration:)
    ModifyMedia(..) -> ModifyMedia(..modify, default_auto_archive_duration:)
    _ -> modify
  }
}

/// Only applies to `Forum` channels. If ran on any other, the function has no effect.
pub fn modify_forum_flags(modify: Modify, new flags: List(forum.Flag)) -> Modify {
  case modify {
    ModifyForum(..) -> ModifyForum(..modify, flags: Some(flags))
    _ -> modify
  }
}

/// Only applies to `Media` channels. If ran on any other, the function has no effect.
pub fn modify_media_flags(modify: Modify, new flags: List(media.Flag)) -> Modify {
  case modify {
    ModifyMedia(..) -> ModifyMedia(..modify, flags: Some(flags))
    _ -> modify
  }
}

/// Only applies to `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_available_tags(
  modify: Modify,
  new available_tags: List(forum.Tag),
) -> Modify {
  case modify {
    ModifyForum(..) ->
      ModifyForum(..modify, available_tags: Some(available_tags))
    ModifyMedia(..) ->
      ModifyMedia(..modify, available_tags: Some(available_tags))
    _ -> modify
  }
}

/// Only applies to `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_default_reaction_emoji(
  modify: Modify,
  default_reaction_emoji: Modification(forum.DefaultReaction),
) -> Modify {
  case modify {
    ModifyForum(..) -> ModifyForum(..modify, default_reaction_emoji:)
    ModifyMedia(..) -> ModifyMedia(..modify, default_reaction_emoji:)
    _ -> modify
  }
}

/// Only applies to `Text`, `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_default_thread_rate_limit_per_user(
  modify: Modify,
  new default_thread_rate_limit_per_user: Duration,
) -> Modify {
  case modify {
    ModifyText(..) ->
      ModifyText(
        ..modify,
        default_thread_rate_limit_per_user: Some(
          default_thread_rate_limit_per_user,
        ),
      )
    ModifyForum(..) ->
      ModifyForum(
        ..modify,
        default_thread_rate_limit_per_user: Some(
          default_thread_rate_limit_per_user,
        ),
      )
    ModifyMedia(..) ->
      ModifyMedia(
        ..modify,
        default_thread_rate_limit_per_user: Some(
          default_thread_rate_limit_per_user,
        ),
      )
    _ -> modify
  }
}

/// Only applies to `Forum`, and `Media` channels. If ran on any other, the function has no effect.
pub fn modify_default_sort_order(
  modify: Modify,
  default_sort_order: Modification(forum.SortOrder),
) -> Modify {
  case modify {
    ModifyForum(..) -> ModifyForum(..modify, default_sort_order:)
    ModifyMedia(..) -> ModifyMedia(..modify, default_sort_order:)
    _ -> modify
  }
}

/// Only applies to `Forum` channels. If ran on any other, the function has no effect.
pub fn modify_forum_default_layout(
  modify: Modify,
  new default_layout: forum.Layout,
) -> Modify {
  case modify {
    ModifyForum(..) ->
      ModifyForum(..modify, default_layout: Some(default_layout))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn archive_thread(modify: Modify) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, is_archived: Some(True))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn unarchive_thread(modify: Modify) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, is_archived: Some(False))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn modify_auto_archive_duration(
  modify: Modify,
  new auto_archive_duration: Duration,
) -> Modify {
  case modify {
    ModifyThread(..) ->
      ModifyThread(..modify, auto_archive_duration: Some(auto_archive_duration))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn lock_thread(modify: Modify) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, is_locked: Some(True))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn unlock_thread(modify: Modify) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, is_locked: Some(False))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn modify_thread_invitable_status(
  modify: Modify,
  is_invitable: Bool,
) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, is_invitable: Some(is_invitable))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn modify_thread_flags(
  modify: Modify,
  new flags: List(thread.Flag),
) -> Modify {
  case modify {
    ModifyThread(..) -> ModifyThread(..modify, flags: Some(flags))
    _ -> modify
  }
}

/// Only applies to `Thread` channels. If ran on any other, the function has no effect.
pub fn modify_thread_applied_tags_ids(
  modify: Modify,
  new applied_tags_ids: List(String),
) -> Modify {
  case modify {
    ModifyThread(..) ->
      ModifyThread(..modify, applied_tags_ids: Some(applied_tags_ids))
    _ -> modify
  }
}

pub fn delete(
  client: Client,
  id channel_id: String,
  because reason: Option(String),
) -> Result(Channel, Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Delete, "/channels/" <> channel_id)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn announcement_follow(
  client: Client,
  from channel_id: String,
  to webhook_channel_id: String,
  because reason: Option(String),
) -> Result(FollowedChannel, Error) {
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
  |> result.map_error(error.CouldNotDecode)
}

pub fn trigger_typing_indicator(
  client: Client,
  in channel_id: String,
) -> Result(Nil, Error) {
  use _response <- result.try(
    client
    |> rest.new_request(http.Post, "/channels/" <> channel_id <> "/typing")
    |> rest.execute,
  )

  Ok(Nil)
}

// TODO: add pagination stuff!!
pub fn get_pinned_messages(
  client: Client,
  in channel_id: String,
) -> Result(List(Message), Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/" <> channel_id <> "/messages/pins",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(message.decoder()))
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_public_archived_threads(
  client: Client,
  in channel_id: String,
  earlier_than before: Option(Timestamp),
  maximum limit: Option(Int),
) -> Result(ReceivedThreads, Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/" <> channel_id <> "/threads/archived/public",
    )
    |> request.set_query(
      [
        case before {
          Some(timestamp) -> [
            #("before", timestamp.to_rfc3339(timestamp, duration.seconds(0))),
          ]
          None -> []
        },
        case limit {
          Some(limit) -> [#("limit", int.to_string(limit))]
          None -> []
        },
      ]
      |> list.flatten,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: received_threads_decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_private_archived_threads(
  client: Client,
  in channel_id: String,
  earlier_than before: Option(Timestamp),
  maximum limit: Option(Int),
) -> Result(ReceivedThreads, Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/" <> channel_id <> "/threads/archived/private",
    )
    |> request.set_query(
      [
        case before {
          Some(timestamp) -> [
            #("before", timestamp.to_rfc3339(timestamp, duration.seconds(0))),
          ]
          None -> []
        },
        case limit {
          Some(limit) -> [#("limit", int.to_string(limit))]
          None -> []
        },
      ]
      |> list.flatten,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: received_threads_decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_joined_private_archived_threads(
  client: Client,
  in channel_id: String,
  earlier_than before: Option(Timestamp),
  maximum limit: Option(Int),
) -> Result(ReceivedThreads, Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/channels/" <> channel_id <> "/users/@me/threads/archived/private",
    )
    |> request.set_query(
      [
        case before {
          Some(timestamp) -> [
            #("before", timestamp.to_rfc3339(timestamp, duration.seconds(0))),
          ]
          None -> []
        },
        case limit {
          Some(limit) -> [#("limit", int.to_string(limit))]
          None -> []
        },
      ]
      |> list.flatten,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: received_threads_decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn get_all_from_guild(
  client: Client,
  id guild_id: String,
) -> Result(List(Channel), Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/guilds/" <> guild_id <> "/channels")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(decoder()))
  |> result.map_error(error.CouldNotDecode)
}

/// `because` has no effect if creating a DM channel.
pub fn create(
  client: Client,
  using create: Create,
  because reason: Option(String),
) -> Result(Channel, Error) {
  let endpoint = case create {
    CreateDmChannel(_) -> "/users/@me/channels"
    CreateTextChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
    CreateVoiceChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
    CreateCategoryChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
    CreateAnnouncementChannel(inner) ->
      "/guilds/" <> inner.guild_id <> "/channels"
    CreateStageChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
    CreateForumChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
    CreateMediaChannel(inner) -> "/guilds/" <> inner.guild_id <> "/channels"
  }

  let json =
    create
    |> create_to_json
    |> json.to_string

  let reason = case create {
    CreateDmChannel(_) -> None
    _ -> reason
  }

  use response <- result.try(
    client
    |> rest.new_request(http.Post, endpoint)
    |> request.set_body(json)
    |> rest.with_reason(reason)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}
