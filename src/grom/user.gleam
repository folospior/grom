import gleam/option.{type Option}
import grom/snowflake.{type Snowflake}

pub type User {
  User(
    id: Snowflake(snowflake.UserId),
    name: String,
    discriminator: String,
    global_name: Option(String),
  )
}
