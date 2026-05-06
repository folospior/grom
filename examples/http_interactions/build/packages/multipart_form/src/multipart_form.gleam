import gleam/http/request
import gleam/result
import multipart_form/form

// Generate a request with a multipart/form-data body from a Form
pub fn to_request(
  req req: request.Request(n),
  form form: form.Form,
) -> request.Request(BitArray) {
  let boundary = "gleam_multipart_form"

  req
  |> request.set_header(
    "Content-Type",
    "multipart/form-data; boundary=" <> boundary,
  )
  |> request.set_body(form.to_bit_array(form, boundary))
}

// Parse a Form from a request conaining a multipart/form-data body
pub fn from_request(
  req req: request.Request(BitArray),
) -> Result(form.Form, String) {
  use content_type <- result.try(
    request.get_header(req, "content-type")
    |> result.replace_error("Request does not hace content-type"),
  )

  case content_type {
    "multipart/form-data; boundary=" <> boundary ->
      form.from_bit_array(req.body, boundary)
    _ -> Error("Request is not a multipart form")
  }
}
