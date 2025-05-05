import flybycord/guild/auto_moderation/keyword_preset
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None}

// TYPES -----------------------------------------------------------------------

pub type Type {
  Keyword
  Spam
  KeywordPreset
  MentionSpam
  MemberProfile
}

pub type Metadata {
  Metadata(
    keyword_filter: Option(List(String)),
    regex_patterns: Option(List(String)),
    presets: Option(List(keyword_preset.Type)),
    allow_list: Option(List(String)),
    mention_total_limit: Option(Int),
    is_mention_raid_protection_enabled: Option(Bool),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Keyword)
    3 -> decode.success(Spam)
    4 -> decode.success(KeywordPreset)
    5 -> decode.success(MentionSpam)
    6 -> decode.success(MemberProfile)
    _ -> decode.failure(Keyword, "Type")
  }
}

@internal
pub fn type_string_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.string)
  case int.parse(variant) {
    Ok(_) -> type_decoder()
    Error(_) -> decode.failure(Keyword, "Type")
  }
}

@internal
pub fn metadata_decoder() -> decode.Decoder(Metadata) {
  use keyword_filter <- decode.optional_field(
    "keyword_filter",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use regex_patterns <- decode.optional_field(
    "regex_patterns",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use presets <- decode.optional_field(
    "presets",
    None,
    decode.optional(decode.list(keyword_preset.type_decoder())),
  )
  use allow_list <- decode.optional_field(
    "allow_list",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use mention_total_limit <- decode.optional_field(
    "mention_total_limit",
    None,
    decode.optional(decode.int),
  )
  use is_mention_raid_protection_enabled <- decode.optional_field(
    "mention_raid_protection_enabled",
    None,
    decode.optional(decode.bool),
  )
  decode.success(Metadata(
    keyword_filter:,
    regex_patterns:,
    presets:,
    allow_list:,
    mention_total_limit:,
    is_mention_raid_protection_enabled:,
  ))
}
