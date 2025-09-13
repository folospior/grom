import gleam/float
import gleam/time/timestamp.{type Timestamp}

@internal
pub fn to_unix_milliseconds(timestamp: Timestamp) -> Int {
  timestamp
  |> timestamp.to_unix_seconds
  |> float.multiply(1000.0)
  |> float.round
}
