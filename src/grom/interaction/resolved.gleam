import gleam/option.{type Option}
import grom/channel/thread
import grom/guild/member.{type Member}
import grom/guild/role.{type Role}
import grom/message.{type Message}
import grom/message/attachment.{type Attachment}
import grom/permission.{type Permission}
import grom/user.{type User}

pub type Resolved {
  Resolved(
    users: Option(List(#(String, User))),
    members: Option(List(#(String, Member))),
    roles: Option(List(#(String, Role))),
    channels: Option(List(#(String, Channel))),
    messages: Option(List(#(String, Message))),
    attachments: Option(List(#(String, Attachment))),
  )
}

pub type Channel {
  TextChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  VoiceChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  CategoryChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  AnnouncementChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  AnnouncementThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  PublicThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  PrivateThread(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
  StageChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  ForumChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
  MediaChannel(
    id: String,
    name: String,
    current_user_permissions: List(Permission),
  )
}
