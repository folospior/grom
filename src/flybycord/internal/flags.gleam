import gleam/dynamic/decode
import gleam/int
import gleam/list

@internal
pub fn decoder(flags: List(#(Int, flag))) -> decode.Decoder(List(flag)) {
  use bits <- decode.then(decode.int)

  flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}
