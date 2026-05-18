import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/list
import gleam/uri.{type Uri}
import gleam_community/colour.{type Colour}

pub fn for_uri() -> Decoder(Uri) {
  use string <- decode.then(decode.string)
  case uri.parse(string) {
    Ok(uri) -> decode.success(uri)
    Error(_) -> decode.failure(uri.empty, "Uri")
  }
}

pub fn for_int_flags(bits_flags: List(#(Int, flag))) -> Decoder(List(flag)) {
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

pub fn for_string_flags(bits_flags: List(#(Int, flag))) -> Decoder(List(flag)) {
  use bits <- decode.then(decode.string)
  let bits = int.parse(bits)

  case bits {
    Error(_) -> decode.failure([], "List(flag)")
    Ok(bits) ->
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
}

pub fn for_hex_colour() -> Decoder(Colour) {
  use hex <- decode.then(decode.int)

  case colour.from_rgb_hex(hex) {
    Ok(colour) -> decode.success(colour)
    Error(_) -> decode.failure(colour.black, "Colour")
  }
}
