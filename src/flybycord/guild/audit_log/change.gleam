import gleam/dynamic/decode
import gleam/option.{type Option}

// TYPES -----------------------------------------------------------------------

/// The change object describes what was changed, its old value and new value.
///
/// You will need to decode the old and new values based on what was changed
/// using [gleam/dynamic/decode](https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html)
pub type Change {
  Change(
    /// What was changed. Generally a name of a field in an object's constructor.
    /// 
    /// Some fields are _undocumented_.
    ///
    /// See [exceptions](https://discord.com/developers/docs/resources/audit-log#audit-log-change-object-audit-log-change-exceptions).
    key: String,
    old_value: Option(decode.Dynamic),
    new_value: Option(decode.Dynamic),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Change) {
  use key <- decode.field("key", decode.string)
  use old_value <- decode.field("old_value", decode.optional(decode.dynamic))
  use new_value <- decode.field("new_value", decode.optional(decode.dynamic))
  decode.success(Change(key:, old_value:, new_value:))
}
