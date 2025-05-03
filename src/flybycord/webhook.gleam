import gleam/option.{type Option}

pub type Webhook {
  Webhook(
    id: String,
    name: String,
    avatar_hash: Option(String),
    type_: Option(Type),
  )
}

pub type Type {
  Incoming
  ChannelFollower
  Application
}
