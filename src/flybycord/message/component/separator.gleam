import gleam/dynamic/decode
import gleam/option.{type Option, None}

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
