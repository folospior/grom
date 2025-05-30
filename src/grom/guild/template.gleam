import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/time_rfc3339
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Template {
  Template(
    code: String,
    name: String,
    description: Option(String),
    usage_count: Int,
    creator_id: String,
    creator: User,
    created_at: Timestamp,
    updated_at: Timestamp,
    source_guild_id: String,
    is_dirty: Option(Bool),
  )
}

// DECODERS -------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Template) {
  use code <- decode.field("code", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use usage_count <- decode.field("usage_count", decode.int)
  use creator_id <- decode.field("creator_id", decode.string)
  use creator <- decode.field("creator", user.decoder())
  use created_at <- decode.field("created_at", time_rfc3339.decoder())
  use updated_at <- decode.field("updated_at", time_rfc3339.decoder())
  use source_guild_id <- decode.field("source_guild_id", decode.string)
  use is_dirty <- decode.field("is_dirty", decode.optional(decode.bool))
  decode.success(Template(
    code:,
    name:,
    description:,
    usage_count:,
    creator_id:,
    creator:,
    created_at:,
    updated_at:,
    source_guild_id:,
    is_dirty:,
  ))
}
