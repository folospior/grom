import gleam/bit_array
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import grom
import grom/file.{type File}
import multipart_form
import multipart_form/field
import status_code

// CONSTANTS -------------------------------------------------------------------

const discord_url = "discord.com"

const discord_api_path = "api/v10"

// INTERNAL FUNCTIONS ----------------------------------------------------------

@internal
pub fn execute(request: Request(String)) -> Result(Response(String), grom.Error) {
  use response <- result.try(
    request
    |> httpc.send
    |> result.map_error(grom.HttpError),
  )

  response
  |> ensure_status_code_success
}

@internal
pub fn execute_bytes(
  request: Request(BitArray),
) -> Result(Response(String), grom.Error) {
  use response <- result.try(
    request
    |> httpc.send_bits
    |> result.map_error(grom.HttpError),
  )

  use body <- result.try(
    response.body
    |> bit_array.to_string
    |> result.replace_error(grom.ResponseNotValidUtf8(response.body)),
  )

  let response = Response(..response, body:)

  response
  |> ensure_status_code_success
}

@internal
pub fn new_request(
  client: grom.Client,
  method: http.Method,
  path: String,
) -> Request(String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_url)
  |> request.set_path(discord_api_path <> path)
  |> request.set_method(method)
  |> request.prepend_header("authorization", "Bot " <> client.token)
  |> request.prepend_header(
    "user-agent",
    "DiscordBot (https://github.com/folospior/grom, " <> grom.version() <> ")",
  )
  |> request.prepend_header("content-type", "application/json")
}

@internal
pub fn new_multipart_request(
  client: grom.Client,
  method: http.Method,
  path: String,
  payload_json: Json,
  files: List(File),
) -> Request(BitArray) {
  let #(_, file_parts) =
    files
    |> list.map_fold(0, fn(acc, file) {
      #(acc + 1, #(
        "files[" <> acc |> int.to_string <> "]",
        field.File(file.name, file.content_type, file.content),
      ))
    })

  new_request(client, method, path)
  |> multipart_form.to_request(
    [
      [
        #(
          "payload_json",
          field.StringWithType(
            payload_json |> json.to_string,
            "application/json",
          ),
        ),
      ],
      file_parts,
    ]
    |> list.flatten,
  )
}

@internal
pub fn with_reason(request: Request(a), reason: Option(String)) -> Request(a) {
  case reason {
    Some(reason) ->
      request
      |> request.prepend_header("x-audit-log-reason", reason)
    None -> request
  }
}

// PRIVATE FUNCTIONS -----------------------------------------------------------

fn ensure_status_code_success(
  response: Response(String),
) -> Result(Response(String), grom.Error) {
  case status_code.is_successful(response.status) {
    True -> Ok(response)
    False -> Error(grom.StatusCodeUnsuccessful(response))
  }
}
