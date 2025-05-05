//// An `Entitlement` is something a user is entitled to have. Crazy, right?
////
//// An example of an entitlement is the license key for the premium version of your bot.
//// See [SKU](sku.html).

import flybycord/internal/time_rfc3339
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}

// TYPES -----------------------------------------------------------------------

pub type Entitlement {
  Entitlement(
    id: String,
    sku_id: String,
    application_id: String,
    user_id: Option(String),
    type_: Type,
    is_deleted: Bool,
    starts_at: Option(Timestamp),
    ends_at: Option(Timestamp),
    guild_id: Option(String),
    /// Only present on consumable SKUs.
    is_consumed: Option(Bool),
  )
}

pub type Type {
  Purchase
  PremiumSubscription
  DeveloperGift
  TestModePurchase
  FreePurchase
  UserGift
  PremiumPurchase
  ApplicationSubscription
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Entitlement) {
  use id <- decode.field("id", decode.string)
  use sku_id <- decode.field("sku_id", decode.string)
  use application_id <- decode.field("application_id", decode.string)
  use user_id <- decode.optional_field(
    "user_id",
    None,
    decode.optional(decode.string),
  )
  use type_ <- decode.field("type", type_decoder())
  use is_deleted <- decode.field("deleted", decode.bool)
  use starts_at <- decode.field(
    "starts_at",
    decode.optional(time_rfc3339.decoder()),
  )
  use ends_at <- decode.field(
    "ends_at",
    decode.optional(time_rfc3339.decoder()),
  )
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use is_consumed <- decode.optional_field(
    "consumed",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Entitlement(
    id:,
    sku_id:,
    application_id:,
    user_id:,
    type_:,
    is_deleted:,
    starts_at:,
    ends_at:,
    guild_id:,
    is_consumed:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Purchase)
    2 -> decode.success(PremiumSubscription)
    3 -> decode.success(DeveloperGift)
    4 -> decode.success(TestModePurchase)
    5 -> decode.success(FreePurchase)
    6 -> decode.success(UserGift)
    7 -> decode.success(PremiumPurchase)
    8 -> decode.success(ApplicationSubscription)
    _ -> decode.failure(Purchase, "Type")
  }
}
