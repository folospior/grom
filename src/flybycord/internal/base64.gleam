import gleam/bit_array
import gleam/dynamic/decode

pub fn decoder() -> decode.Decoder(BitArray) {
  use string <- decode.then(decode.string)
  case bit_array.base64_decode(string) {
    Ok(bits) -> decode.success(bits)
    Error(_) -> decode.failure(<<>>, "BitArray")
  }
}
