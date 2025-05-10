import gleam/json.{type Json}

// TYPES -----------------------------------------------------------------------

/// Sometimes, you'll find yourself passing this type into a `modify` function.
/// This is because Gleam really has no way of determining whether to skip something
/// or to send `null`.
pub type Modification(a) {
  /// Will send `a`.
  New(a)
  /// Will send `null`.
  Delete
  /// Will not send anything.
  Skip
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn encode(
  modification: Modification(a),
  key: String,
  success_encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  case modification {
    New(value) -> [#(key, success_encoder(value))]
    Delete -> [#(key, json.null())]
    Skip -> []
  }
}
