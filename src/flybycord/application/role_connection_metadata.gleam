import flybycord/client.{type Client}
import flybycord/internal/error
import flybycord/internal/rest
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/function
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

// TYPES -----------------------------------------------------------------------

pub type RoleConnectionMetadata {
  RoleConnectionMetadata(
    type_: Type,
    key: String,
    name: String,
    name_localizations: Option(Dict(String, String)),
    description: String,
    description_localizations: Option(Dict(String, String)),
  )
}

pub type Type {
  IntegerLessThanOrEqual
  IntegerGreaterThanOrEqual
  IntegerEqual
  IntegerNotEqual
  DatetimeLessThanOrEqual
  DatetimeGreaterThanOrEqual
  BooleanEqual
  BooleanNotEqual
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(RoleConnectionMetadata) {
  use type_ <- decode.field("type", type_decoder())
  use key <- decode.field("key", decode.string)
  use name <- decode.field("name", decode.string)
  use name_localizations <- decode.optional_field(
    "name_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  use description <- decode.field("description", decode.string)
  use description_localizations <- decode.optional_field(
    "description_localizations",
    None,
    decode.optional(decode.dict(decode.string, decode.string)),
  )
  decode.success(RoleConnectionMetadata(
    type_:,
    key:,
    name:,
    name_localizations:,
    description:,
    description_localizations:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(IntegerLessThanOrEqual)
    2 -> decode.success(IntegerGreaterThanOrEqual)
    3 -> decode.success(IntegerEqual)
    4 -> decode.success(IntegerNotEqual)
    5 -> decode.success(DatetimeLessThanOrEqual)
    6 -> decode.success(DatetimeGreaterThanOrEqual)
    7 -> decode.success(BooleanEqual)
    8 -> decode.success(BooleanNotEqual)
    _ -> decode.failure(IntegerLessThanOrEqual, "Type")
  }
}

// ENCODERS --------------------------------------------------------------------

fn encode(metadata: RoleConnectionMetadata) -> Json {
  let name_localizations = case metadata.name_localizations {
    Some(localizations) -> [
      #(
        "name_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  let description_localizations = case metadata.description_localizations {
    Some(localizations) -> [
      #(
        "description_localizations",
        json.dict(localizations, function.identity, json.string),
      ),
    ]
    None -> []
  }

  [
    [
      #("type", type_encode(metadata.type_)),
      #("key", json.string(metadata.key)),
      #("name", json.string(metadata.name)),
    ],
    name_localizations,
    description_localizations,
  ]
  |> list.flatten
  |> json.object
}

fn type_encode(type_: Type) -> Json {
  case type_ {
    IntegerLessThanOrEqual -> 1
    IntegerGreaterThanOrEqual -> 2
    IntegerEqual -> 3
    IntegerNotEqual -> 4
    DatetimeLessThanOrEqual -> 5
    DatetimeGreaterThanOrEqual -> 6
    BooleanEqual -> 7
    BooleanNotEqual -> 8
  }
  |> json.int
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(
  client: Client,
  application_id: String,
) -> Result(List(RoleConnectionMetadata), error.FlybycordError) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/role-connections/metadata",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(decoder()))
  |> result.map_error(error.DecodeError)
}

pub fn modify(
  client: Client,
  application_id: String,
  new metadata: List(RoleConnectionMetadata),
) -> Result(List(RoleConnectionMetadata), error.FlybycordError) {
  let json = json.array(metadata, encode)

  use response <- result.try(
    client
    |> rest.new_request(
      http.Put,
      "/applications/" <> application_id <> "/role-connections/metadata",
    )
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(decoder()))
  |> result.map_error(error.DecodeError)
}
