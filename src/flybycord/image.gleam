import gleam/bit_array

// TYPES -----------------------------------------------------------------------

pub type Data =
  String

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

  "data:" <> mime <> ";base64," <> base64
}
