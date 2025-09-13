import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder(bits_flags: List(#(Int, flag))) -> decode.Decoder(List(flag)) {
  use bits <- decode.then(decode.int)

  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn to_json(flags: List(flag), bits_flags: List(#(Int, flag))) -> Json {
  json.int(flags |> to_int(bits_flags))
}

// INTERNAL FUNCTIONS ----------------------------------------------------------

@internal
pub fn to_int(flags: List(flag), bits_flags: List(#(Int, flag))) -> Int {
  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    let is_in_flags = list.any(flags, fn(curr) { curr == flag })
    case is_in_flags {
      True -> Ok(bit)
      False -> Error(Nil)
    }
  })
  |> int.sum
}
