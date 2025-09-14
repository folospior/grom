import gleam/dynamic/decode
import gleam/option.{type Option, None}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/time_rfc3339

// TYPES -----------------------------------------------------------------------

pub type Subscription {
  Subscription(
    id: String,
    user_id: String,
    sku_ids: List(String),
    entitlement_ids: List(String),
    renewal_sku_ids: List(String),
    current_period_start: Timestamp,
    current_period_end: Timestamp,
    status: Status,
    canceled_at: Option(Timestamp),
    country: Option(String),
  )
}

pub type Status {
  Active
  Ending
  Inactive
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Subscription) {
  use id <- decode.field("id", decode.string)
  use user_id <- decode.field("user_id", decode.string)
  use sku_ids <- decode.field("sku_ids", decode.list(decode.string))
  use entitlement_ids <- decode.field(
    "entitlement_ids",
    decode.list(decode.string),
  )
  use renewal_sku_ids <- decode.field(
    "renewal_sku_ids",
    decode.list(decode.string),
  )
  use current_period_start <- decode.field(
    "current_period_start",
    time_rfc3339.decoder(),
  )
  use current_period_end <- decode.field(
    "current_period_end",
    time_rfc3339.decoder(),
  )
  use status <- decode.field("status", status_decoder())
  use canceled_at <- decode.field(
    "canceled_at",
    decode.optional(time_rfc3339.decoder()),
  )
  use country <- decode.optional_field(
    "country",
    None,
    decode.optional(decode.string),
  )
  decode.success(Subscription(
    id:,
    user_id:,
    sku_ids:,
    entitlement_ids:,
    renewal_sku_ids:,
    current_period_start:,
    current_period_end:,
    status:,
    canceled_at:,
    country:,
  ))
}

@internal
pub fn status_decoder() -> decode.Decoder(Status) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Active)
    1 -> decode.success(Ending)
    2 -> decode.success(Inactive)
    _ -> decode.failure(Active, "Status")
  }
}
