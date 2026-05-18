import gleam/http/response.{type Response}
import gleam/json

pub type RestError {
    CouldNotDecodeResponse(json.DecodeError)
    ReceivedUnsuccessfulStatusCode(Response(String))
    ReceivedErrorResponse(ErrorResponse)
}

pub type ErrorResponse {

}