import flybycord/image
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type ModifyCurrentUser {
  ModifyCurrentUser(
    username: Option(String),
    avatar: Option(image.Data),
    banner: Option(image.Data),
  )
}

pub fn new() -> ModifyCurrentUser {
  ModifyCurrentUser(username: None, avatar: None, banner: None)
}

pub fn with_username(
  object: ModifyCurrentUser,
  username: String,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..object, username: Some(username))
}

pub fn with_avatar(
  object: ModifyCurrentUser,
  avatar: image.Data,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..object, avatar: Some(avatar))
}

pub fn with_banner(
  object: ModifyCurrentUser,
  banner: image.Data,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..object, banner: Some(banner))
}

@internal
pub fn encode(object: ModifyCurrentUser) -> Json {
  let ModifyCurrentUser(username:, avatar:, banner:) = object
  let username = case username {
    Some(name) -> [#("username", json.string(name))]
    None -> []
  }

  let avatar = case avatar {
    Some(image) -> [#("avatar", json.string(image))]
    None -> []
  }

  let banner = case banner {
    Some(image) -> [#("banner", json.string(image))]
    None -> []
  }

  [username, avatar, banner]
  |> list.flatten
  |> json.object
}
