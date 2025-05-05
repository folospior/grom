import flybycord/application.{type Application}
import flybycord/channel.{type Channel}
import flybycord/guild.{type Guild}
import flybycord/user.{type User}
import gleam/option.{type Option}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Invite {
  Invite(
    type_: Type,
    code: String,
    guild: Option(Guild),
    channel: Option(Channel),
    inviter: Option(User),
    target_type: Option(TargetType),
    target_user: Option(User),
    target_application: Option(Application),
    approximate_presence_count: Option(Int),
    approximate_member_count: Option(Int),
    expires_at: Option(Timestamp),
  )
}

pub type Type {
  Guild
  GroupDm
  Friend
}

pub type TargetType {
  Stream
  EmbeddedApplication
}

pub type Metadata {
  Metadata(
    uses: Int,
    max_uses: Int,
    max_age: Duration,
    is_temporary: Bool,
    created_at: Timestamp,
  )
}
