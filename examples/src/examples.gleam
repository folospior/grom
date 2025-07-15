import gleam/option.{None, Some}
import grom/channel
import grom/client

const token = "l.u.c.y"

const guild_id = "768594524158427167"

pub fn main() {
  let client = client.Client(token:)

  let data =
    channel.CreateText(
      ..channel.new_create_text(named: "hello", in: guild_id),
      position: Some(100),
    )
    |> channel.CreateTextChannel

  client
  |> channel.create(using: data, because: None)
  |> echo
}
