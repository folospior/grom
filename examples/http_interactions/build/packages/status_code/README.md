# status_code

[![Package Version](https://img.shields.io/hexpm/v/status_code)](https://hex.pm/packages/status_code)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/status_code/)

```sh
gleam add status_code gleam_httpc gleam_http
```
```gleam
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/io
import gleam/result
import status_code

pub fn main() -> Nil {
  let response =
    request.new()
    |> request.set_scheme(http.Https)
    |> request.set_host("example.org")
    |> request.set_method(http.Get)
    |> httpc.send
    |> result.unwrap(response.new(status_code.not_found))

  case response.status {
    status if status == status_code.ok -> io.println("Ok!")
    status if status == status_code.forbidden ->
      io.println("We've been forbidden from entering this realm")
    status if status == status_code.im_a_teapot ->
      io.println("Never ask a teapot for coffee")
    _ -> io.println("A strange thing has happened...")
  }
}
```

Further documentation can be found at <https://hexdocs.pm/status_code>.
