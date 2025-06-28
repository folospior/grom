import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json

// TYPES -----------------------------------------------------------------------

pub type Error {
  HttpError(httpc.HttpError)
  CouldNotDecode(json.DecodeError)
  StatusCodeUnsuccessful(Response(String))
  BodyNotValidUtf8(BitArray)
}
