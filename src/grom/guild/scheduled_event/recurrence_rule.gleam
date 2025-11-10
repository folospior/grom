import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp.{type Timestamp}
import grom/internal/time_rfc3339

// TYPES -----------------------------------------------------------------------

pub type RecurrenceRule {
  RecurrenceRule(
    start: Timestamp,
    end: Option(Timestamp),
    frequency: Frequency,
    interval: Int,
    by_weekday: Option(List(Weekday)),
    by_n_weekday: Option(List(NWeekday)),
    by_month: Option(List(Month)),
    by_month_day: Option(List(Int)),
    by_year_day: Option(List(Int)),
    count: Option(Int),
  )
}

pub type Frequency {
  Yearly
  Monthly
  Weekly
  Daily
}

pub type Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

pub type NWeekday {
  NWeekday(n: Int, day: Weekday)
}

pub type Month {
  January
  February
  March
  April
  May
  June
  July
  August
  September
  October
  November
  December
}

pub type Create {
  Create(
    start: Timestamp,
    frequency: Frequency,
    interval: Int,
    by_weekday: Option(List(Weekday)),
    by_n_weekday: Option(List(NWeekday)),
    by_month: Option(List(Month)),
    by_month_day: Option(List(Int)),
  )
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(RecurrenceRule) {
  use start <- decode.field("start", time_rfc3339.decoder())
  use end <- decode.field("end", decode.optional(time_rfc3339.decoder()))
  use frequency <- decode.field("frequency", frequency_decoder())
  use interval <- decode.field("interval", decode.int)
  use by_weekday <- decode.field(
    "by_weekday",
    decode.optional(decode.list(weekday_decoder())),
  )
  use by_n_weekday <- decode.field(
    "by_n_weekday",
    decode.optional(decode.list(n_weekday_decoder())),
  )
  use by_month <- decode.field(
    "by_month",
    decode.optional(decode.list(month_decoder())),
  )
  use by_month_day <- decode.field(
    "by_month_day",
    decode.optional(decode.list(decode.int)),
  )
  use by_year_day <- decode.field(
    "by_year_day",
    decode.optional(decode.list(decode.int)),
  )
  use count <- decode.field("count", decode.optional(decode.int))
  decode.success(RecurrenceRule(
    start:,
    end:,
    frequency:,
    interval:,
    by_weekday:,
    by_n_weekday:,
    by_month:,
    by_month_day:,
    by_year_day:,
    count:,
  ))
}

@internal
pub fn frequency_decoder() -> decode.Decoder(Frequency) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Yearly)
    1 -> decode.success(Monthly)
    2 -> decode.success(Weekly)
    3 -> decode.success(Daily)
    _ -> decode.failure(Yearly, "Frequency")
  }
}

@internal
pub fn weekday_decoder() -> decode.Decoder(Weekday) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(Monday)
    1 -> decode.success(Tuesday)
    2 -> decode.success(Wednesday)
    3 -> decode.success(Thursday)
    4 -> decode.success(Friday)
    5 -> decode.success(Saturday)
    6 -> decode.success(Sunday)
    _ -> decode.failure(Monday, "Weekday")
  }
}

@internal
pub fn n_weekday_decoder() -> decode.Decoder(NWeekday) {
  use n <- decode.field("n", decode.int)
  use day <- decode.field("day", weekday_decoder())
  decode.success(NWeekday(n:, day:))
}

@internal
pub fn month_decoder() -> decode.Decoder(Month) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(January)
    2 -> decode.success(February)
    3 -> decode.success(March)
    4 -> decode.success(April)
    5 -> decode.success(May)
    6 -> decode.success(June)
    7 -> decode.success(July)
    8 -> decode.success(August)
    9 -> decode.success(September)
    10 -> decode.success(October)
    11 -> decode.success(November)
    12 -> decode.success(December)
    _ -> decode.failure(January, "Month")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn create_to_json(create: Create) -> Json {
  let start = [#("start", time_rfc3339.to_json(create.start))]

  let frequency = [#("frequency", frequency_to_json(create.frequency))]

  let interval = [#("interval", json.int(create.interval))]

  let by_weekday = case create.by_weekday {
    Some(days) -> [#("by_weekday", json.array(days, weekday_to_json))]
    None -> []
  }

  let by_n_weekday = case create.by_n_weekday {
    Some(n_weekdays) -> [
      #("by_n_weekday", json.array(n_weekdays, n_weekday_to_json)),
    ]
    None -> []
  }

  let by_month = case create.by_month {
    Some(months) -> [#("by_month", json.array(months, month_to_json))]
    None -> []
  }

  let by_month_day = case create.by_month_day {
    Some(days_of_the_month) -> [
      #("by_month_days", json.array(days_of_the_month, json.int)),
    ]
    None -> []
  }

  [start, frequency, interval, by_weekday, by_n_weekday, by_month, by_month_day]
  |> list.flatten
  |> json.object
}

@internal
pub fn frequency_to_json(frequency: Frequency) -> Json {
  case frequency {
    Yearly -> 0
    Monthly -> 1
    Weekly -> 2
    Daily -> 3
  }
  |> json.int
}

@internal
pub fn weekday_to_json(weekday: Weekday) -> Json {
  case weekday {
    Monday -> 0
    Tuesday -> 1
    Wednesday -> 2
    Thursday -> 3
    Friday -> 4
    Saturday -> 5
    Sunday -> 6
  }
  |> json.int
}

@internal
pub fn n_weekday_to_json(n_weekday: NWeekday) -> Json {
  json.object([
    #("n", json.int(n_weekday.n)),
    #("day", weekday_to_json(n_weekday.day)),
  ])
}

@internal
pub fn month_to_json(month: Month) -> Json {
  case month {
    January -> 1
    February -> 2
    March -> 3
    April -> 4
    May -> 5
    June -> 6
    July -> 7
    August -> 8
    September -> 9
    October -> 10
    November -> 11
    December -> 12
  }
  |> json.int
}
