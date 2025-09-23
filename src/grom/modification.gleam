import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{None, Some}

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

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder(of inner: decode.Decoder(a)) -> decode.Decoder(Modification(a)) {
  let exists_decoder = {
    use value <- decode.then(decode.optional(inner))
    case value {
      Some(value) -> New(value)
      None -> Delete
    }
    |> decode.success
  }

  let not_set_decoder = decode.success(Skip)

  decode.one_of(exists_decoder, or: [not_set_decoder])
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(
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
