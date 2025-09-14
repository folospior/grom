//// A SKU is an offer on Discord.
////
//// For example, if you're offering a premium subscription for your bot, you must create an SKU.

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import grom
import grom/internal/flags
import grom/internal/rest
import grom/subscription.{type Subscription}

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

pub type GetSubscriptionsQuery {
  AfterId(String)
  BeforeId(String)
  Limit(Int)
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 2), Available),
    #(int.bitwise_shift_left(1, 7), GuildSubscription),
    #(int.bitwise_shift_left(1, 8), UserSubscription),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Sku) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use application_id <- decode.field("application_id", decode.string)
  use name <- decode.field("name", decode.string)
  use slug <- decode.field("slug", decode.string)
  use flags <- decode.field("flags", flags.decoder(bits_flags()))
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

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_subscriptions(
  client: grom.Client,
  sku sku_id: String,
  for user_id: String,
  using query: List(GetSubscriptionsQuery),
) -> Result(List(Subscription), grom.Error) {
  let query =
    query
    |> list.map(fn(single_query) {
      case single_query {
        AfterId(id) -> #("after", id)
        BeforeId(id) -> #("before", id)
        Limit(limit) -> #("limit", int.to_string(limit))
      }
    })
    |> list.append([#("user_id", user_id)])

  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/skus/" <> sku_id <> "/subscriptions")
    |> request.set_query(query)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: subscription.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_subscription(
  client: grom.Client,
  sku sku_id: String,
  id subscription_id: String,
) -> Result(Subscription, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/skus/" <> sku_id <> "/subscriptions/" <> subscription_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: subscription.decoder())
  |> result.map_error(grom.CouldNotDecode)
}
