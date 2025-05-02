import flybycord/internal/error
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/result

// FUNCTIONS -------------------------------------------------------------------

pub fn with_reason(request: Request(a), reason: String) -> Request(a) {
  request
  |> request.prepend_header("x-audit-log-reason", reason)
}

pub fn execute(
  request: Request(String),
) -> Result(Response(String), error.FlybycordError) {
  use response <- result.try(
    request
    |> httpc.send
    |> result.map_error(error.HttpError),
  )

  response
  |> ensure_status_code_success
}

// HELPERS ---------------------------------------------------------------------

fn ensure_status_code_success(
  response: Response(String),
) -> Result(Response(String), error.FlybycordError) {
  case response.status {
    status if status >= 200 && status < 300 -> Ok(response)
    _ -> Error(error.StatusCodeUnsuccessful(response))
  }
}
