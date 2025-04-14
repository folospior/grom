import gleam/httpc
import gleam/json

pub type FlybycordError {
  HttpError(httpc.HttpError)
  DecodeError(json.DecodeError)
  StatusCodeUnsuccessful(Int)
}
