import gleam/option.{type Option}
import grom/channel
import grom/channel/guild/thread
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
