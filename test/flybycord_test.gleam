import flybycord/user/current_user
import gleam/json
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn encode_modify_current_test() {
  current_user.new_modify()
  |> current_user.modify_username("fo1o")
  |> current_user.modify_encode
  |> json.to_string
  |> should.equal("{\"username\":\"fo1o\"}")
}
