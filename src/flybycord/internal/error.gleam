import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json

// TYPES -----------------------------------------------------------------------

pub type FlybycordError {
  HttpError(httpc.HttpError)
  DecodeError(json.DecodeError)
  StatusCodeUnsuccessful(Response(String))
}
