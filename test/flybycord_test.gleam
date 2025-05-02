import flybycord/permission
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

pub fn permission_to_string_test() {
  [permission.CreateInstantInvite, permission.Administrator]
  |> permission.to_string
  |> should.equal("9")
}
