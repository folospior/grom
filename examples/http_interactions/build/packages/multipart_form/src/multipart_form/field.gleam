import gleam/bit_array

pub type FormBody {
  String(String)
  StringWithType(content: String, content_type: String)
  File(name: String, content_type: String, content: BitArray)
}

pub fn to_bit_array(
  field_name field: String,
  field_body element: FormBody,
  boundary boundary: String,
) -> BitArray {
  let body = case element {
    File(filename, content_type, content) -> <<
      "Content-Disposition: form-data; name=\"":utf8,
      field:utf8,
      "\"; filename=\"":utf8,
      filename:utf8,
      "\"\r\nContent-Type: ":utf8,
      content_type:utf8,
      "\r\n\r\n":utf8,
      content:bits,
    >>
    String(content) -> <<
      "Content-Disposition: form-data; name=\"":utf8,
      field:utf8,
      "\"\r\n\r\n":utf8,
      content:utf8,
    >>
    StringWithType(content, type_) -> <<
      "Content-Disposition: form-data; name=\"":utf8,
      field:utf8,
      "\"\r\nContent-Type: ":utf8,
      type_:utf8,
      "\r\n\r\n":utf8,
      content:utf8,
    >>
  }

  bit_array.concat([<<"--":utf8, boundary:utf8, "\r\n":utf8>>, body, <<"\r\n">>])
}
