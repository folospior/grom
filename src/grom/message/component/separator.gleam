import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// TYPES -----------------------------------------------------------------------

pub type Separator {
  Separator(id: Option(Int), show_divider: Bool, spacing: Spacing)
}

pub type Spacing {
  SmallPadding
  LargePadding
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Separator) {
  use id <- decode.optional_field("id", None, decode.optional(decode.int))
  use show_divider <- decode.optional_field("divider", True, decode.bool)
  use spacing <- decode.optional_field(
    "spacing",
    SmallPadding,
    spacing_decoder(),
  )

  decode.success(Separator(id:, show_divider:, spacing:))
}

@internal
pub fn spacing_decoder() -> decode.Decoder(Spacing) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(SmallPadding)
    2 -> decode.success(LargePadding)
    _ -> decode.failure(SmallPadding, "Spacing")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(separator: Separator) -> Json {
  let type_ = [#("type", json.int(14))]

  let id = case separator.id {
    Some(id) -> [#("id", json.int(id))]
    None -> []
  }

  let show_divider = [#("divider", json.bool(separator.show_divider))]

  let spacing = [#("spacing", spacing_to_json(separator.spacing))]

  [type_, id, show_divider, spacing]
  |> list.flatten
  |> json.object
}

@internal
pub fn spacing_to_json(spacing: Spacing) -> Json {
  case spacing {
    SmallPadding -> 1
    LargePadding -> 2
  }
  |> json.int
}
