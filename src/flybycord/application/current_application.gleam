import flybycord/application.{type Application}
import flybycord/client.{type Client}
import flybycord/error
import flybycord/image
import flybycord/internal/flags
import flybycord/internal/rest
import flybycord/modification.{type Modification, Delete, New, Skip}
import flybycord/webhook_event
import gleam/dict.{type Dict}
import gleam/http
import gleam/http/request
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

// TYPES -----------------------------------------------------------------------

pub opaque type Modify {
  Modify(
    custom_install_url: Option(String),
    description: Option(String),
    role_connections_verification_url: Option(String),
    install_params: Option(application.InstallParams),
    installation_contexts_config: Option(
      Dict(
        application.InstallationContext,
        application.InstallationContextConfig,
      ),
    ),
    flags: Option(List(application.Flag)),
    icon: Modification(image.Data),
    cover_image: Modification(image.Data),
    interactions_endpoint_url: Option(String),
    tags: Option(List(String)),
    event_webhooks_url: Option(String),
    event_webhooks_status: Option(application.EventWebhookStatus),
    event_webhooks_types: Option(List(webhook_event.Type)),
  )
}

// ENCODERS --------------------------------------------------------------------

fn modify_encode(modify: Modify) -> Json {
  let custom_install_url = case modify.custom_install_url {
    Some(url) -> [#("custom_install_url", json.string(url))]
    None -> []
  }

  let description = case modify.description {
    Some(description) -> [#("description", json.string(description))]
    None -> []
  }

  let role_connections_verification_url = case
    modify.role_connections_verification_url
  {
    Some(url) -> [#("role_connections_verification_url", json.string(url))]
    None -> []
  }

  let install_params = case modify.install_params {
    Some(params) -> [
      #("install_params", application.install_params_encode(params)),
    ]
    None -> []
  }

  let installation_contexts_config = case modify.installation_contexts_config {
    Some(config) -> [
      #(
        "integration_types_config",
        json.dict(
          config,
          application.installation_context_to_string,
          application.installation_context_config_encode,
        ),
      ),
    ]
    None -> []
  }

  let flags = case modify.flags {
    Some(flags) -> [#("flags", flags.encode(flags, application.bits_flags()))]
    None -> []
  }

  let icon =
    modify.icon
    |> modification.encode("icon", json.string)

  let cover_image =
    modify.cover_image
    |> modification.encode("cover_image", json.string)

  let interactions_endpoint_url = case modify.interactions_endpoint_url {
    Some(url) -> [#("interactions_endpoint_url", json.string(url))]
    None -> []
  }

  let tags = case modify.tags {
    Some(tags) -> [#("tags", json.array(tags, json.string))]
    None -> []
  }

  let event_webhooks_url = case modify.event_webhooks_url {
    Some(url) -> [#("event_webhooks_url", json.string(url))]
    None -> []
  }

  let event_webhooks_status = case modify.event_webhooks_status {
    Some(status) -> [
      #(
        "event_webhooks_status",
        application.event_webhook_status_encode(status),
      ),
    ]
    None -> []
  }

  let event_webhooks_types = case modify.event_webhooks_types {
    Some(types) -> [
      #("event_webhooks_types", json.array(types, webhook_event.type_encode)),
    ]
    None -> []
  }

  [
    custom_install_url,
    description,
    role_connections_verification_url,
    install_params,
    installation_contexts_config,
    flags,
    icon,
    cover_image,
    interactions_endpoint_url,
    tags,
    event_webhooks_url,
    event_webhooks_status,
    event_webhooks_types,
  ]
  |> list.flatten
  |> json.object
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get(client: Client) -> Result(Application, error.FlybycordError) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/applications/@me")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: application.decoder())
  |> result.map_error(error.DecodeError)
}

pub fn modify(
  client: Client,
  with modify: Modify,
) -> Result(Application, error.FlybycordError) {
  let json = modify |> modify_encode

  use response <- result.try(
    client
    |> rest.new_request(http.Patch, "/applications/@me")
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: application.decoder())
  |> result.map_error(error.DecodeError)
}

pub fn new_modify() -> Modify {
  Modify(
    custom_install_url: None,
    description: None,
    role_connections_verification_url: None,
    install_params: None,
    installation_contexts_config: None,
    flags: None,
    icon: Skip,
    cover_image: Skip,
    interactions_endpoint_url: None,
    tags: None,
    event_webhooks_url: None,
    event_webhooks_status: None,
    event_webhooks_types: None,
  )
}

pub fn modify_custom_install_url(modify: Modify, url: String) -> Modify {
  Modify(..modify, custom_install_url: Some(url))
}

pub fn modify_description(modify: Modify, description: String) -> Modify {
  Modify(..modify, description: Some(description))
}

pub fn modify_role_connections_verification_url(
  modify: Modify,
  url: String,
) -> Modify {
  Modify(..modify, role_connections_verification_url: Some(url))
}

pub fn modify_install_params(
  modify: Modify,
  params: application.InstallParams,
) -> Modify {
  Modify(..modify, install_params: Some(params))
}

/// Only `GatewayPresenceLimited`, `GatewayGuildMembersLimited`, and `GatewayMessageContentLimited`
/// flags can be updated.
pub fn modify_flags(modify: Modify, flags: List(application.Flag)) -> Modify {
  Modify(..modify, flags: Some(flags))
}

pub fn modify_icon(modify: Modify, icon: Modification(image.Data)) -> Modify {
  Modify(..modify, icon:)
}

pub fn modify_cover_image(
  modify: Modify,
  cover_image: Modification(image.Data),
) -> Modify {
  Modify(..modify, cover_image:)
}

pub fn modify_interactions_endpoint_url(modify: Modify, url: String) -> Modify {
  Modify(..modify, interactions_endpoint_url: Some(url))
}

pub fn modify_tags(modify: Modify, tags: List(String)) -> Modify {
  Modify(..modify, tags: Some(tags))
}

pub fn modify_event_webhooks_url(modify: Modify, url: String) -> Modify {
  Modify(..modify, event_webhooks_url: Some(url))
}

pub fn modify_event_webhooks_status(
  modify: Modify,
  status: application.EventWebhookStatus,
) -> Modify {
  Modify(..modify, event_webhooks_status: Some(status))
}

pub fn modify_event_webhooks_types(
  modify: Modify,
  types: List(webhook_event.Type),
) -> Modify {
  Modify(..modify, event_webhooks_types: Some(types))
}
