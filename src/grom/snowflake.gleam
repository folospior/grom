import gleam/int
import gleam/result
import gleam/time/timestamp.{type Timestamp}

const discord_epoch = 1_420_070_400_000

pub fn get_creation_timestamp(of snowflake: String) -> Result(Timestamp, Nil) {
  use integer <- result.map(int.parse(snowflake))

  let milliseconds =
    integer
    |> int.bitwise_shift_right(22)
    |> int.add(discord_epoch)

  let seconds = milliseconds / 1000

  timestamp.from_unix_seconds(seconds)
}
