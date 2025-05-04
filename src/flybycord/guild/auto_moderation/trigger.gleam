import flybycord/guild/auto_moderation/keyword_preset

pub type Type {
  Keyword
  Spam
  KeywordPreset
  MentionSpam
  MemberProfile
}

pub type Metadata {
  TriggerMetadata(
    keyword_filter: List(String),
    regex_patterns: List(String),
    presets: List(keyword_preset.Type),
    allow_list: List(String),
    mention_total_limit: Int,
    is_mention_raid_protection_enabled: Bool,
  )
}
