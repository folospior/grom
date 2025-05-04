import flybycord/channel
import flybycord/channel/thread
import flybycord/guild/member.{type Member}
import flybycord/guild/role.{type Role}
import flybycord/message.{type Message}
import flybycord/message/attachment.{type Attachment}
import flybycord/permission.{type Permission}
import flybycord/user.{type User}
import gleam/option.{type Option}

pub type Resolved {
  Resolved(
    users: Option(List(#(String, User))),
    members: Option(List(#(String, Member))),
    roles: Option(List(#(String, Role))),
    channels: Option(List(#(String, PartialChannel))),
    messages: Option(List(#(String, Message))),
    attachments: Option(List(#(String, Attachment))),
  )
}

pub type PartialChannel {
  PartialChannel(
    id: String,
    name: String,
    type_: channel.Type,
    permissions: List(Permission),
  )
  PartialThread(
    id: String,
    name: String,
    type_: channel.Type,
    permissions: List(Permission),
    metadata: thread.Metadata,
    parent_id: String,
  )
}
