import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json
import gleam/otp/actor

// TYPES -----------------------------------------------------------------------

pub type Client {
  Client(token: String)
}

pub type Error {
  HttpError(httpc.HttpError)
  CouldNotDecode(json.DecodeError)
  StatusCodeUnsuccessful(Response(String))
  ResponseNotValidUtf8(BitArray)
  InvalidGatewayUrl(String)
  CouldNotStartActor(actor.StartError)
  CouldNotSendSocketMessage
}

// FUNCTIONS -------------------------------------------------------------------

pub fn version() -> String {
  "v0.0.0"
}
