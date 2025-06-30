import gleam/bit_array
import gleam/json.{type Json}

// TYPES -----------------------------------------------------------------------

pub opaque type Data {
  Data(String)
}

pub type ContentType {
  Jpeg
  Png
  Gif
}

// FUNCTIONS -------------------------------------------------------------------

pub fn from_bit_array(
  image data: BitArray,
  file_type content_type: ContentType,
) -> Data {
  let mime = case content_type {
    Jpeg -> "image/jpeg"
    Png -> "image/png"
    Gif -> "image/gif"
  }
  let base64 = bit_array.base64_encode(data, False)

  Data("data:" <> mime <> ";base64," <> base64)
}

@internal
pub fn to_base64(image: Data) -> String {
  let Data(base64) = image
  base64
}

@internal
pub fn to_json(image: Data) -> Json {
  image
  |> to_base64
  |> json.string
}
