import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import grom/application
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type InteractionMetadata {
  InteractionMetadata(
    id: String,
    type_: Type,
    user: User,
    authorizing_integration_owners: Dict(
      application.InstallationContext,
      String,
    ),
    original_response_message_id: Option(String),
    target_user: Option(User),
    target_message_id: Option(String),
  )
}

pub type Type {
  Ping
  ApplicationCommand
  MessageComponent
  ApplicationCommandAutocomplete
  ModalSubmit
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(InteractionMetadata) {
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use user <- decode.field("user", user.decoder())
  use authorizing_integration_owners <- decode.field(
    "authorizing_integration_owners",
    decode.dict(application.installation_context_decoder(), decode.string),
  )
  use original_response_message_id <- decode.optional_field(
    "original_response_message_id",
    None,
    decode.optional(decode.string),
  )
  use target_user <- decode.optional_field(
    "target_user",
    None,
    decode.optional(user.decoder()),
  )
  use target_message_id <- decode.optional_field(
    "target_message_id",
    None,
    decode.optional(decode.string),
  )
  decode.success(InteractionMetadata(
    id:,
    type_:,
    user:,
    authorizing_integration_owners:,
    original_response_message_id:,
    target_user:,
    target_message_id:,
  ))
}

@internal
pub fn type_decoder() -> decode.Decoder(Type) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Ping)
    2 -> decode.success(ApplicationCommand)
    3 -> decode.success(MessageComponent)
    4 -> decode.success(ApplicationCommandAutocomplete)
    5 -> decode.success(ModalSubmit)
    _ -> decode.failure(Ping, "Type")
  }
}
