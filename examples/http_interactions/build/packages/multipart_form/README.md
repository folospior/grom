# multipart_form

[![Package Version](https://img.shields.io/hexpm/v/multipart_form)](https://hex.pm/packages/multipart_form)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/multipart_form/)

```sh
gleam add multipart_form@1
```

```gleam
import gleam/http
import gleam/http/request
import multipart_form
import multipart_form/field

pub fn main() {
  let test_image = <<>> // Image BitArray ommited for reading convinience
  let form = [
    #("description", field.String("A random image found on the web")),
    #("file", field.File("image.jpg", "image/jpeg", test_image)),
  ]

  let req =
    request.new()
    |> request.set_scheme(http.Https)
    |> request.set_method(http.Post)
    |> request.set_path("/index.html")
    |> request.set_host("example.com")
    |> request.set_header("host", "example.com")
    |> multipart_form.to_request(form)

    // Do stuff with your request here
}
```

Further documentation can be found at <https://hexdocs.pm/multipart_form>.

## Development

```sh
gleam test  # Run the tests
```
