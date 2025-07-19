import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json

// TYPES -----------------------------------------------------------------------

pub type Client {
  Client(token: String)
}

pub type Error {
  HttpError(httpc.HttpError)
  CouldNotDecode(json.DecodeError)
  StatusCodeUnsuccessful(Response(String))
  ResponseNotValidUtf8(BitArray)
}

// FUNCTIONS -------------------------------------------------------------------

pub fn version() {
  "v0.0.0"
}
