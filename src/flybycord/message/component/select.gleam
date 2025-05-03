import flybycord/channel.{type Channel}
import flybycord/role.{type Role}
import flybycord/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Value {
  StringValue(String)
  UserValue(User)
  RoleValue(Role)
  MentionableValue(Mentionable)
  ChannelValue(Channel)
}

pub type Mentionable {
  UserMentionable(User)
  RoleMentionable(Role)
}
// DECODERS --------------------------------------------------------------------
