import flybycord/client
import flybycord/user

pub fn main() {
  let client =
    client.Client(
      token: "MTM1Mjk5Nzc2ODY3OTEzMzE4NA.GdrKea.QDZfIY6THPdJjUuFwpcR4Bj8h905fwC6N-EtY0",
    )
  let assert Ok(user) =
    client
    |> user.get_user("808763186811633735")

  echo user
}
