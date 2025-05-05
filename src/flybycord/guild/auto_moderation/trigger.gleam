import flybycord/guild/auto_moderation/keyword_preset
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}

// TYPES -----------------------------------------------------------------------

pub type Type {
  Keyword
  Spam
  KeywordPreset
  MentionSpam
  MemberProfile
}

pub type Metadata {
  KeywordMetadata(
    keyword_filter: List(String),
    regex_patterns: List(String),
    allow_list: List(String),
  )
  MemberProfileMetadata(
    keyword_filter: List(String),
    regex_patterns: List(String),
    allow_list: List(String),
  )
  KeywordPresetMetadata(
    presets: List(keyword_preset.Type),
    allow_list: List(String),
  )
  MentionSpamMetadata(
    mention_total_limit: Int,
    is_mention_raid_protection_enabled: Bool,
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
pub fn metadata_decoder(type_: Type) -> decode.Decoder(Metadata) {
  case type_ {
    Keyword -> keyword_metadata_decoder()
    MemberProfile -> member_profile_metadata_decoder()
    KeywordPreset -> keyword_preset_metadata_decoder()
    MentionSpam -> mention_spam_metadata_decoder()
    Spam -> decode.failure(KeywordPresetMetadata([], []), "Metadata")
  }
}

fn keyword_metadata_decoder() -> decode.Decoder(Metadata) {
  use keyword_filter <- decode.field(
    "keyword_filter",
    decode.list(decode.string),
  )
  use regex_patterns <- decode.field(
    "regex_patterns",
    decode.list(decode.string),
  )
  use allow_list <- decode.field("allow_list", decode.list(decode.string))
  decode.success(KeywordMetadata(keyword_filter:, regex_patterns:, allow_list:))
}

fn member_profile_metadata_decoder() -> decode.Decoder(Metadata) {
  use keyword_filter <- decode.field(
    "keyword_filter",
    decode.list(decode.string),
  )
  use regex_patterns <- decode.field(
    "regex_patterns",
    decode.list(decode.string),
  )
  use allow_list <- decode.field("allow_list", decode.list(decode.string))
  decode.success(MemberProfileMetadata(
    keyword_filter:,
    regex_patterns:,
    allow_list:,
  ))
}

fn keyword_preset_metadata_decoder() -> decode.Decoder(Metadata) {
  use presets <- decode.field(
    "presets",
    decode.list(keyword_preset.type_decoder()),
  )
  use allow_list <- decode.field("allow_list", decode.list(decode.string))
  decode.success(KeywordPresetMetadata(presets:, allow_list:))
}

fn mention_spam_metadata_decoder() -> decode.Decoder(Metadata) {
  use mention_total_limit <- decode.field("mention_total_limit", decode.int)
  use is_mention_raid_protection_enabled <- decode.field(
    "mention_raid_protection_enabled",
    decode.bool,
  )
  decode.success(MentionSpamMetadata(
    mention_total_limit:,
    is_mention_raid_protection_enabled:,
  ))
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn type_encode(type_: Type) -> Json {
  case type_ {
    Keyword -> 1
    Spam -> 3
    KeywordPreset -> 4
    MentionSpam -> 5
    MemberProfile -> 6
  }
  |> json.int
}

@internal
pub fn metadata_encode(metadata: Metadata) -> Json {
  case metadata {
    KeywordMetadata(keyword_filter, regex_patterns, allow_list) -> [
      #("keyword_filter", json.array(keyword_filter, json.string)),
      #("regex_patterns", json.array(regex_patterns, json.string)),
      #("allow_list", json.array(allow_list, json.string)),
    ]
    MemberProfileMetadata(keyword_filter, regex_patterns, allow_list) -> [
      #("keyword_filter", json.array(keyword_filter, json.string)),
      #("regex_patterns", json.array(regex_patterns, json.string)),
      #("allow_list", json.array(allow_list, json.string)),
    ]
    KeywordPresetMetadata(presets, allow_list) -> [
      #("presets", json.array(presets, keyword_preset.type_encode)),
      #("allow_list", json.array(allow_list, json.string)),
    ]
    MentionSpamMetadata(mention_total_limit, is_mention_raid_protection_enabled) -> [
      #("mention_total_limit", json.int(mention_total_limit)),
      #(
        "mention_raid_protection_enabled",
        json.bool(is_mention_raid_protection_enabled),
      ),
    ]
  }
  |> json.object
}
