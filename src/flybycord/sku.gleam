//// A SKU is an offer on Discord.
////
//// For example, if you're offering a premium subscription for your bot, you must create an SKU.

import gleam/dynamic/decode
import gleam/int
import gleam/list

// TYPES -----------------------------------------------------------------------

pub type Sku {
  Sku(
    id: String,
    type_: Type,
    application_id: String,
    name: String,
    slug: String,
    flags: List(Flag),
  )
}

pub type Type {
  Durable
  Consumable
  Subscription
  SubscriptionGroup
}

pub type Flag {
  Available
  GuildSubscription
  UserSubscription
}

// FLAGS -----------------------------------------------------------------------

fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 2), Available),
    #(int.bitwise_shift_left(1, 7), GuildSubscription),
    #(int.bitwise_shift_left(1, 8), UserSubscription),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn sku_decoder() -> decode.Decoder(Sku) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use application_id <- decode.field("application_id", decode.string)
  use name <- decode.field("name", decode.string)
  use slug <- decode.field("slug", decode.string)
  use flags <- decode.field("flags", flags_decoder())
  decode.success(Sku(id:, type_:, application_id:, name:, slug:, flags:))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    2 -> decode.success(Durable)
    3 -> decode.success(Consumable)
    5 -> decode.success(Subscription)
    6 -> decode.success(SubscriptionGroup)
    _ -> decode.failure(Durable, "Type")
  }
}

@internal
pub fn flags_decoder() -> decode.Decoder(List(Flag)) {
  use bits <- decode.then(decode.int)

  bits_flags()
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}
