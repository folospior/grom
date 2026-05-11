import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/time/timestamp.{type Timestamp}

pub type UserId

pub type GuildId

pub type ChannelId

pub type MessageId

/// A snowflake is another name for an ID.
///
/// Different objects have their ID types in this module, for example [`UserId`](#UserId), [`GuildId`](#GuildId),
/// this is used in different APIs like `Snowflake(UserId)` or `Snowflake(GuildId)`.
/// 
/// It is possible to [retrieve an object's creation date & time](#get_creation_time) from its snowflake.
pub opaque type Snowflake(a) {
  Snowflake(id: Int)
}

/// First second of 2015, as milliseconds since the Unix epoch (first second of 1970) 
const discord_epoch: Int = 1_420_070_400_000

/// Used for creating arbitary snowflakes.
/// 
/// This should only be used for hardcoding values or retrieving IDs from a database.
/// 
/// Don't use this function to change `Snowflake(a)` to a `Snowflake(b)`.
/// It won't work correctly anyway - imagine calling `guild.get_request()` using a user's ID
///
/// Example usage:
/// ```
/// let guild_id: Snowflake(Guild) = new_snowflake(768594524158427167)
/// ```
pub fn new(id: Int) -> Snowflake(a) {
  Snowflake(id)
}

/// Returns a snowflake's creation timestamp with millisecond precision.
pub fn get_creation_time(of_object_with_id id: Snowflake(a)) -> Timestamp {
  let milliseconds =
    id.id
    // The ID's timestamp is located in bits 63 - 22
    |> int.bitwise_shift_right(22)
    // It's denoted in milliseconds since the Discord epoch
    |> int.add(discord_epoch)

  // In order to have the least precision loss and to adapt to the timestamp API,
  // we have to convert our timestamp to seconds and nanoseconds 
  let seconds = milliseconds / 1000

  // These are nanoseconds with millisecond precision.
  let nanoseconds =
    milliseconds
    // We're accounting for the precision loss that came from converting to seconds
    |> int.subtract(seconds * 1000)
    // Converting to nanoseconds, there's no precision loss here
    |> int.multiply(1_000_000)

  timestamp.from_unix_seconds_and_nanoseconds(seconds:, nanoseconds:)
}

pub fn decoder() -> Decoder(Snowflake(a)) {
  // Discord uses strings to represent snowflakes
  use id <- decode.then(decode.string)
  case int.parse(id) {
    Ok(id) -> decode.success(Snowflake(id))
    Error(_nil) -> decode.failure(Snowflake(0), "Snowflake")
  }
}

pub fn to_int(id: Snowflake(a)) -> Int {
  id.id
}

pub fn to_string(id: Snowflake(a)) -> String {
  int.to_string(id.id)
}

pub fn to_json(id: Snowflake(a)) -> Json {
  // Discord uses strings to represent snowflakes
  json.string(to_string(id))
}
