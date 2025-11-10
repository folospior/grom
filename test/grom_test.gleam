import gleam/http
import gleam/http/request
import gleam/json
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import grom
import grom/file.{File}
import grom/internal/rest
import grom/user/current_user

pub fn main() {
  gleeunit.main()
}

pub fn encode_modify_current_test() {
  current_user.Modify(..current_user.new_modify(), username: Some("fo1o"))
  |> current_user.modify_encode
  |> json.to_string
  |> should.equal("{\"username\":\"fo1o\"}")
}

pub fn multipart_request_test() {
  let expected =
    rest.new_request(grom.Client("token"), http.Post, "/")
    |> request.set_body(<<
      "--gleam_multipart_form\r\n":utf8,
      "Content-Disposition: form-data; name=\"payload_json\"\r\n":utf8,
      "Content-Type: application/json\r\n\r\n":utf8, "{}\r\n":utf8,
      "--gleam_multipart_form\r\n":utf8,
      "Content-Disposition: form-data; name=\"files[0]\"; filename=\"name\"\r\n":utf8,
      "Content-Type: image/png\r\n\r\n":utf8, "test\r\n":utf8,
      "--gleam_multipart_form\r\n":utf8,
      "Content-Disposition: form-data; name=\"files[1]\"; filename=\"name2\"\r\n":utf8,
      "Content-Type: image/jpeg\r\n\r\n":utf8, "jpeg\r\n":utf8,
      "--gleam_multipart_form--":utf8,
    >>)
    |> request.set_header(
      "content-type",
      "multipart/form-data; boundary=gleam_multipart_form",
    )

  let result =
    rest.new_multipart_request(
      grom.Client("token"),
      http.Post,
      "/",
      json.object([]),
      [
        File("name", "image/png", <<"test":utf8>>),
        File("name2", "image/jpeg", <<"jpeg":utf8>>),
      ],
    )

  result
  |> should.equal(expected)
}
