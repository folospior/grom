import flybycord/channel/forum
import flybycord/channel/permission_overwrite.{type PermissionOverwrite}
import flybycord/channel/thread
import flybycord/channel/voice_channel
import flybycord/client.{type Client}
import flybycord/error
import flybycord/internal/rest
import flybycord/internal/time_duration
import flybycord/internal/time_rfc3339
import flybycord/permission.{type Permission}
import flybycord/user.{type User}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Channel {
  GuildTextChannel(
    id: String,
    type_: Type,
    guild_id: String,
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
  )
  DmChannel(
    id: String,
    type_: Type,
    last_message_id: Option(String),
    recipients: List(User),
    current_user_permissions: Option(List(Permission)),
  )
  GuildVoiceChannel(
    id: String,
    type_: Type,
    guild_id: String,
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    is_nsfw: Bool,
    bitrate: Int,
    user_limit: Option(Int),
    parent_id: Option(String),
    rtc_region: Option(String),
    video_quality_mode: voice_channel.VideoQualityMode,
    current_user_permissions: Option(List(Permission)),
  )
  GuildCategoryChannel(
    id: String,
    type_: Type,
    guild_id: String,
    position: Int,
    permission_overwrites: List(PermissionOverwrite),
    name: String,
    current_user_permissions: Option(List(Permission)),
  )
  ThreadChannel(
    id: String,
    type_: Type,
    guild_id: String,
    position: Int,
    name: String,
    last_message_id: Option(String),
    rate_limit_per_user: Duration,
    parent_id: String,
    message_count: Int,
    member_count: Int,
    metadata: thread.Metadata,
    current_member: Option(thread.Member),
    current_user_permissions: Option(List(Permission)),
    flags: List(thread.Flag),
    total_message_sent: Int,
    applied_tags_ids: Option(List(String)),
  )
  GuildForumChannel(
    id: String,
    type_: Type,
    guild_id: String,
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
    available_tags: List(forum.Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Option(forum.SortOrderType),
    default_forum_layout: forum.LayoutType,
  )
  GuildMediaChannel(
    id: String,
    type_: Type,
    guild_id: String,
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
    available_tags: List(forum.Tag),
    default_reaction_emoji: Option(forum.DefaultReaction),
    default_thread_rate_limit_per_user: Option(Duration),
    default_sort_order: Option(forum.SortOrderType),
  )
}

pub type Type {
  GuildText
  Dm
  GuildVoice
  GuildCategory
  GuildAnnouncement
  AnnouncementThread
  PublicThread
  PrivateThread
  GuildStageVoice
  GuildForum
  GuildMedia
}

pub type Mention {
  Mention(id: String, guild_id: String, type_: Type, name: String)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Channel) {
  use variant <- decode.field("type", type_decoder())
  case variant {
    GuildText | GuildAnnouncement -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
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
      decode.success(GuildTextChannel(
        id:,
        type_:,
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
      ))
    }
    Dm -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
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
      decode.success(DmChannel(
        id:,
        type_:,
        last_message_id:,
        recipients:,
        current_user_permissions:,
      ))
    }
    GuildVoice | GuildStageVoice -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
      use position <- decode.field("position", decode.int)
      use permission_overwrites <- decode.field(
        "permission_overwrites",
        decode.list(permission_overwrite.decoder()),
      )
      use name <- decode.field("name", decode.string)
      use is_nsfw <- decode.field("nsfw", decode.bool)
      use bitrate <- decode.field("bitrate", decode.int)
      use user_limit <- decode.optional_field(
        "user_limit",
        None,
        decode.optional(decode.int),
      )
      use parent_id <- decode.field("parent_id", decode.optional(decode.string))
      use rtc_region <- decode.field(
        "rtc_region",
        decode.optional(decode.string),
      )
      use video_quality_mode <- decode.field(
        "video_quality_mode",
        voice_channel.video_quality_mode_decoder(),
      )
      use current_user_permissions <- decode.optional_field(
        "permissions",
        None,
        decode.optional(permission.decoder()),
      )
      decode.success(GuildVoiceChannel(
        id:,
        type_:,
        guild_id:,
        position:,
        permission_overwrites:,
        name:,
        is_nsfw:,
        bitrate:,
        user_limit:,
        parent_id:,
        rtc_region:,
        video_quality_mode:,
        current_user_permissions:,
      ))
    }
    GuildCategory -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
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
      decode.success(GuildCategoryChannel(
        id:,
        type_:,
        guild_id:,
        position:,
        permission_overwrites:,
        name:,
        current_user_permissions:,
      ))
    }
    AnnouncementThread | PublicThread | PrivateThread -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
      use position <- decode.field("position", decode.int)
      use name <- decode.field("name", decode.string)
      use last_message_id <- decode.field(
        "last_message_id",
        decode.optional(decode.string),
      )
      use rate_limit_per_user <- decode.field(
        "rate_limit_per_user",
        time_duration.from_minutes_decoder(),
      )
      use parent_id <- decode.field("parent_id", decode.string)
      use message_count <- decode.field("message_count", decode.int)
      use member_count <- decode.field("member_count", decode.int)
      use metadata <- decode.field("metadata", thread.metadata_decoder())
      use current_member <- decode.optional_field(
        "current_member",
        None,
        decode.optional(thread.member_decoder()),
      )
      use current_user_permissions <- decode.optional_field(
        "permissions",
        None,
        decode.optional(permission.decoder()),
      )
      use flags <- decode.field("flags", thread.flags_decoder())
      use total_message_sent <- decode.field("total_message_sent", decode.int)
      use applied_tags_ids <- decode.optional_field(
        "applied_tags_ids",
        None,
        decode.optional(decode.list(decode.string)),
      )
      decode.success(ThreadChannel(
        id:,
        type_:,
        guild_id:,
        position:,
        name:,
        last_message_id:,
        rate_limit_per_user:,
        parent_id:,
        message_count:,
        member_count:,
        metadata:,
        current_member:,
        current_user_permissions:,
        flags:,
        total_message_sent:,
        applied_tags_ids:,
      ))
    }
    GuildForum -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
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
      use default_forum_layout <- decode.field(
        "default_forum_layout",
        forum.layout_type_decoder(),
      )
      decode.success(GuildForumChannel(
        id:,
        type_:,
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
        default_reaction_emoji:,
        default_thread_rate_limit_per_user:,
        default_sort_order:,
        default_forum_layout:,
      ))
    }
    GuildMedia -> {
      use id <- decode.field("id", decode.string)
      use type_ <- decode.field("type", type_decoder())
      use guild_id <- decode.field("guild_id", decode.string)
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
      decode.success(GuildMediaChannel(
        id:,
        type_:,
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
        default_reaction_emoji:,
        default_thread_rate_limit_per_user:,
        default_sort_order:,
      ))
    }
  }
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildText)
    1 -> decode.success(Dm)
    2 -> decode.success(GuildVoice)
    4 -> decode.success(GuildCategory)
    5 -> decode.success(GuildAnnouncement)
    10 -> decode.success(AnnouncementThread)
    11 -> decode.success(PublicThread)
    12 -> decode.success(PrivateThread)
    13 -> decode.success(GuildStageVoice)
    15 -> decode.success(GuildForum)
    16 -> decode.success(GuildMedia)
    _ -> decode.failure(GuildText, "Type")
  }
}

@internal
pub fn mention_decoder() -> decode.Decoder(Mention) {
  use id <- decode.field("id", decode.string)
  use guild_id <- decode.field("guild_id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use name <- decode.field("name", decode.string)
  decode.success(Mention(id:, guild_id:, type_:, name:))
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
