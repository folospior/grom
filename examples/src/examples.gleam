import dotenv_gleam
import envoy
import grom/client
import grom/user

pub fn main() {
  dotenv_gleam.config()
  let assert Ok(token) = envoy.get("TOKEN")
  let client = client.Client(token: token)
  let assert Ok(user) =
    client
    |> user.get_user("808763186811633735")

  echo user

  let assert Ok(self) = client |> user.get_current_user
  echo self
}
