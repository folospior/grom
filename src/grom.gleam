import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json
import gleam/otp/actor
import stratus

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
  CouldNotInitializeWebsocketConnection(stratus.InitializationError)
  CouldNotStartActor(actor.StartError)
}

// FUNCTIONS -------------------------------------------------------------------

pub fn version() {
  "v0.0.0"
}
