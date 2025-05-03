import flybycord/emoji.{type Emoji}
import gleam/dynamic/decode

// TYPES -----------------------------------------------------------------------

pub type Reaction {
  Reaction(
    count: Int,
    count_details: CountDetails,
    current_user_reacted: Bool,
    current_user_burst_reacted: Bool,
    emoji: Emoji,
    burst_colors: List(Int),
  )
}

pub type CountDetails {
  CountDetails(burst: Int, normal: Int)
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Reaction) {
  use count <- decode.field("count", decode.int)
  use count_details <- decode.field("count_details", count_details_decoder())
  use current_user_reacted <- decode.field("me", decode.bool)
  use current_user_burst_reacted <- decode.field("me_burst", decode.bool)
  use emoji <- decode.field("emoji", emoji.decoder())
  use burst_colors <- decode.field("burst_colors", decode.list(decode.int))
  decode.success(Reaction(
    count:,
    count_details:,
    current_user_reacted:,
    current_user_burst_reacted:,
    emoji:,
    burst_colors:,
  ))
}

@internal
pub fn count_details_decoder() -> decode.Decoder(CountDetails) {
  use burst <- decode.field("burst", decode.int)
  use normal <- decode.field("normal", decode.int)
  decode.success(CountDetails(burst:, normal:))
}
