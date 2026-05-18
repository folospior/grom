import gleam/bit_array
import gleam/json.{type Json}
import mimetype

pub opaque type CreatedImage {
  CreatedImage(data: BitArray, mime: UploadedImageFormat)
}

pub type CreateError {
  /// Created images must be PNGs, JPEGs, or GIFs.
  /// 
  /// Contains the detected media (MIME) type.
  CreatedImageHasInvalidMediaType(media_type: String)
}

pub fn create(data data: BitArray) -> Result(CreatedImage, CreateError) {
  let mime =
    data
    |> mimetype.detect
    |> mimetype.to_string

  case mime {
    "image/png" -> Ok(CreatedImage(data, PngUploadedImage))
    "image/jpeg" -> Ok(CreatedImage(data, JpegUploadedImage))
    "image/gif" -> Ok(CreatedImage(data, GifUploadedImage))
    mime -> Error(CreatedImageHasInvalidMediaType(mime))
  }
}

type UploadedImageFormat {
  JpegUploadedImage
  PngUploadedImage
  GifUploadedImage
}

fn created_image_type_to_string(type_: UploadedImageFormat) -> String {
  case type_ {
    JpegUploadedImage -> "image/jpeg"
    PngUploadedImage -> "image/png"
    GifUploadedImage -> "image/gif"
  }
}

pub fn created_image_to_json(image: CreatedImage) -> Json {
  json.string(
    "data:"
    <> created_image_type_to_string(image.mime)
    <> ";base64,"
    <> bit_array.base64_encode(image.data, False),
  )
}
