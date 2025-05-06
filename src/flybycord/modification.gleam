// TYPES -----------------------------------------------------------------------

/// Sometimes, you'll find yourself passing this type into a `modify` function.
/// This is because Gleam really has no way of determining whether to skip something
/// or to send `null`.
pub type Modification(a) {
  // Will send `a`.
  New(a)
  // Will send `null`.
  Delete
  // Will not send anything.
  Skip
}
