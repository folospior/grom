import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type FileUpload {
  FileUpload(
    id: Option(Int),
    custom_id: String,
    min_values: Int,
    max_values: Int,
    is_required: Bool,
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(FileUpload) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use custom_id <- decode.field("custom_id", decode.string)
  use min_values <- decode.optional_field("min_values", 1, decode.int)
  use max_values <- decode.optional_field("max_values", 1, decode.int)
  use is_required <- decode.optional_field("required", True, decode.bool)

  decode.success(FileUpload(
    id:,
    custom_id:,
    min_values:,
    max_values:,
    is_required:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(file_upload: FileUpload) -> Json {
  let id = case file_upload.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  [
    id,
    [
      #("type", json.int(19)),
      #("custom_id", json.string(file_upload.custom_id)),
      #("min_values", json.int(file_upload.min_values)),
      #("max_values", json.int(file_upload.max_values)),
      #("required", json.bool(file_upload.is_required)),
    ],
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn new(custom_id: String) -> FileUpload {
  FileUpload(
    id: None,
    custom_id:,
    min_values: 1,
    max_values: 1,
    is_required: True,
  )
}
