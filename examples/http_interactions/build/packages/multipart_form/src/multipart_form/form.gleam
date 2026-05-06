import gleam/bit_array
import gleam/http
import gleam/list
import gleam/option
import gleam/result
import multipart_form/field

// A Form is defined by a list of #(field_name, field_body)
pub type Form =
  List(#(String, field.FormBody))

// Converts the given form fields into a bitarray multipart body using the given boundary 
pub fn to_bit_array(form fields: Form, boundary boundary: String) -> BitArray {
  list.map(fields, fn(field) {
    let #(name, body) = field
    field.to_bit_array(name, body, boundary)
  })
  |> list.append([<<"--", boundary:utf8, "--">>])
  |> bit_array.concat
}

// Parse a Form from a multipart/form-data body with the given boundary
pub fn from_bit_array(
  body form: BitArray,
  boundary boundary: String,
) -> Result(Form, String) {
  parse_field(form, boundary, []) |> result.map(list.reverse)
}

fn parse_field(
  body: BitArray,
  boundary: String,
  fields: List(#(String, field.FormBody)),
) -> Result(List(#(String, field.FormBody)), String) {
  use headers <- result.try(
    http.parse_multipart_headers(body, boundary)
    |> result.replace_error("Failed to parse Field headers"),
  )
  use #(headers, rest) <- result.try(case headers {
    http.MoreRequiredForHeaders(_) -> Error("Must provide a full body")
    http.MultipartHeaders(headers, rest) -> Ok(#(headers, rest))
  })

  use header <- result.try(
    list.key_find(headers, "content-disposition")
    |> result.replace_error(
      "Invalid form field, does not contain Content-Disposition",
    ),
  )
  use header <- result.try(
    http.parse_content_disposition(header)
    |> result.replace_error(
      "Invalid form field, contains an invalid Content-Disposition header",
    ),
  )
  use field <- result.try(
    list.key_find(header.parameters, "name")
    |> result.replace_error("Invalid form field, does not contain field name"),
  )

  let filename =
    option.from_result(list.key_find(header.parameters, "filename"))

  use body <- result.try(
    http.parse_multipart_body(rest, boundary)
    |> result.replace_error("Failed to parse field body"),
  )
  use #(body, done, rest) <- result.try(case body {
    http.MoreRequiredForBody(_, _) -> Error("Must provide a full body")
    http.MultipartBody(body, done, rest) -> Ok(#(body, done, rest))
  })

  use field <- result.try(case filename {
    option.None -> {
      use content <- result.map(
        bit_array.to_string(body)
        |> result.replace_error("Invalid utf-8 string in string field"),
      )
      case list.key_find(headers, "content-type") {
        Ok(content_type) -> #(
          field,
          field.StringWithType(content:, content_type:),
        )
        Error(_) -> #(field, field.String(content))
      }
    }
    option.Some(filename) -> {
      use header <- result.map(
        list.key_find(headers, "content-type")
        |> result.replace_error(
          "Invalid form file field, does not contain Content-Type header",
        ),
      )
      #(field, field.File(filename, header, body))
    }
  })

  let fields = [field, ..fields]

  case done {
    False -> parse_field(rest, boundary, fields)
    True -> Ok(fields)
  }
}
