import gleam/http/response
import gleeunit
import grom

pub fn main() {
  gleeunit.main()
}

/// 4 snippets (3 provided from Discord, 1 AI-generated) were used for error response tests.
/// All use the `new_category_channel_response` function, although it shouldn't be much of an issue to use other functions,
/// as they all use the same `parse_error_response` internal function.
pub fn error_response_1_test() {
  let assert Error(grom.ReceivedErrorResponse(_)) =
    echo grom.new_category_channel_response(
      response.new(200)
      |> response.set_body(
        "{\r\n  \"code\": 50035,\r\n  \"message\": \"Invalid Form Body\",\r\n  \"errors\": {\r\n    \"content\": {\r\n      \"_errors\": [\r\n        { \"code\": 50035, \"message\": \"Must be 2000 or fewer in length.\" }\r\n      ]\r\n    },\r\n    \"embeds\": {\r\n      \"0\": {\r\n        \"title\": {\r\n          \"_errors\": [\r\n            { \"code\": 50035, \"message\": \"Must be 256 or fewer in length.\" }\r\n          ]\r\n        },\r\n        \"fields\": {\r\n          \"0\": {\r\n            \"value\": {\r\n              \"_errors\": [\r\n                { \"code\": 50035, \"message\": \"Must be 1024 or fewer in length.\" }\r\n              ]\r\n            }\r\n          }\r\n        }\r\n      }\r\n    }\r\n  }\r\n}",
      ),
    )
}

pub fn error_response_2_test() {
  let assert Error(grom.ReceivedErrorResponse(_)) =
    echo grom.new_category_channel_response(
      response.new(200)
      |> response.set_body(
        "{\r\n  \"code\": 50035,\r\n  \"errors\": {\r\n    \"activities\": {\r\n      \"0\": {\r\n        \"platform\": {\r\n          \"_errors\": [\r\n            {\r\n              \"code\": \"BASE_TYPE_CHOICES\",\r\n              \"message\": \"Value must be one of ('desktop', 'android', 'ios').\"\r\n            }\r\n          ]\r\n        },\r\n        \"type\": {\r\n          \"_errors\": [\r\n            {\r\n              \"code\": \"BASE_TYPE_CHOICES\",\r\n              \"message\": \"Value must be one of (0, 1, 2, 3, 4, 5).\"\r\n            }\r\n          ]\r\n        }\r\n      }\r\n    }\r\n  },\r\n  \"message\": \"Invalid Form Body\"\r\n}",
      ),
    )
}

pub fn error_response_3_test() {
  let assert Error(grom.ReceivedErrorResponse(_)) =
    echo grom.new_category_channel_response(
      response.new(200)
      |> response.set_body(
        "{\r\n  \"code\": 50035,\r\n  \"errors\": {\r\n    \"access_token\": {\r\n      \"_errors\": [\r\n        {\r\n          \"code\": \"BASE_TYPE_REQUIRED\",\r\n          \"message\": \"This field is required\"\r\n        }\r\n      ]\r\n    }\r\n  },\r\n  \"message\": \"Invalid Form Body\"\r\n}",
      ),
    )
}

pub fn error_response_4_test() {
  let assert Error(grom.ReceivedErrorResponse(_)) =
    echo grom.new_category_channel_response(
      response.new(200)
      |> response.set_body(
        "{\r\n  \"code\": 50035,\r\n  \"message\": \"Invalid Form Body\",\r\n  \"errors\": {\r\n    \"_errors\": [\r\n      {\r\n        \"code\": \"APPLICATION_COMMAND_TOO_LARGE\",\r\n        \"message\": \"Command exceeds maximum size (8000)\"\r\n      }\r\n    ]\r\n  }\r\n}",
      ),
    )
}
