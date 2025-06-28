//// An `Entitlement` is something a user is entitled to have. Crazy, right?
////
//// An example of an entitlement is the license key for the premium version of your bot.
//// See [SKU](sku.html).

import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import grom/client.{type Client}
import grom/error.{type Error}
import grom/interaction/context_type
import grom/internal/rest
import grom/internal/time_rfc3339

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

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: Client,
  for application_id: String,
  id entitlement_id: String,
) -> Result(Entitlement, Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/applications/" <> application_id <> "/entitlements/" <> entitlement_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decoder())
  |> result.map_error(error.CouldNotDecode)
}

pub fn consume(
  client: Client,
  for application_id: String,
  id entitlement_id: String,
) -> Result(Nil, Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/applications/"
        <> application_id
        <> "/entitlements/"
        <> entitlement_id
        <> "/consume",
    )
    |> rest.execute,
  )

  Ok(Nil)
}
