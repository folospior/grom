import gleam/option.{Some}
import gleam/time/timestamp
import grom
import grom/message
import grom/message/embed.{Embed}

pub fn main() -> Nil {
  let client = grom.Client("token")

  let _result =
    client
    |> message.create(
      in: "channel id",
      using: message.Create(
        ..message.new_create(),
        embeds: Some([
          Embed(
            ..embed.new(),
            author: Some(
              embed.Author(
                ..embed.new_author("Lucy"),
                icon_url: Some(
                  "https://avatars.githubusercontent.com/u/36161205?s=200&v=4",
                ),
              ),
            ),
            color: Some(0xffaff3),
            title: Some(":star: | Welcome to `grom`!"),
            description: Some(
              "Grom is a Gleam library for the Discord API targeting the Erlang VM.",
            ),
            timestamp: Some(timestamp.system_time()),
            footer: Some(embed.new_footer(
              containing: "Thank you for using grom!",
            )),
          ),
        ]),
      ),
    )

  Nil
}
