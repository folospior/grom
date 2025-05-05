// TYPES -----------------------------------------------------------------------

/// Sometimes, you'll find yourself passing an Option value with this type.
/// This is because Gleam really has no way of determining whether to skip something
/// or to send `null`.
///
/// Using `None` will not send the parameter, leaving it unchanged.
/// Using `Some(Remove)` will send `null` instead of skipping the parameter, removing it from Discord's architecture.
/// Using `Some(Add(a))` will send the regular value, adding it to Discord's architecture.
pub type AddOrRemove(a) {
  Add(a)
  Remove
}
