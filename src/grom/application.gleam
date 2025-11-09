import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import grom
import grom/application/team.{type Team}
import grom/emoji.{type Emoji}
import grom/entitlement.{type Entitlement}
import grom/guild.{type Guild}
import grom/image
import grom/internal/flags
import grom/internal/rest
import grom/permission.{type Permission}
import grom/sku.{type Sku}
import grom/user.{type User}
import grom/webhook_event

// TYPES -----------------------------------------------------------------------

pub type Application {
  Application(
    id: String,
    name: String,
    icon_hash: Option(String),
    description: String,
    rpc_origins: Option(List(String)),
    is_bot_public: Bool,
    does_bot_require_code_grant: Bool,
    bot: Option(User),
    terms_of_service_url: Option(String),
    privacy_policy_url: Option(String),
    owner: Option(User),
    team: Option(Team),
    guild_id: Option(String),
    guild: Option(Guild),
    primary_sku_id: Option(String),
    slug: Option(String),
    cover_image_hash: Option(String),
    flags: Option(List(Flag)),
    approximate_guild_count: Option(Int),
    approximate_user_install_count: Option(Int),
    redirect_uris: Option(List(String)),
    interaction_endpoint_url: Option(String),
    role_connections_verification_url: Option(String),
    event_webhooks_url: Option(String),
    event_webhooks_status: Option(EventWebhookStatus),
    event_webhooks_types: Option(List(webhook_event.Type)),
    tags: Option(List(String)),
    install_params: Option(InstallParams),
    installation_context_config: Option(
      Dict(InstallationContext, InstallationContextConfig),
    ),
    custom_install_url: Option(String),
  )
}

pub type Flag {
  ApplicationAutoModerationRuleCreateBadge
  GatewayPresence
  GatewayPresenceLimited
  GatewayGuildMembers
  GatewayGuildMembersLimited
  VerificationPendingGuildLimit
  Embedded
  GatewayMessageContent
  GatewayMessageContentLimited
  ApplicationCommandBadge
}

pub type EventWebhookStatus {
  Disabled
  Enabled
  DisabledByDiscord
}

pub type InstallParams {
  InstallParams(scopes: List(String), permissions: List(Permission))
}

pub type InstallationContext {
  GuildInstall
  UserInstall
}

pub type InstallationContextConfig {
  InstallationContextConfig(oauth2_install_params: Option(InstallParams))
}

pub type GetEntitlementsQuery {
  UserId(String)
  SkuIds(Set(String))
  BeforeId(String)
  AfterId(String)
  Limit(Int)
  GuildId(String)
  ExcludeEnded(Bool)
  ExcludeDeleted(Bool)
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 6), ApplicationAutoModerationRuleCreateBadge),
    #(int.bitwise_shift_left(1, 12), GatewayPresence),
    #(int.bitwise_shift_left(1, 13), GatewayPresenceLimited),
    #(int.bitwise_shift_left(1, 14), GatewayGuildMembers),
    #(int.bitwise_shift_left(1, 15), GatewayGuildMembersLimited),
    #(int.bitwise_shift_left(1, 16), VerificationPendingGuildLimit),
    #(int.bitwise_shift_left(1, 17), Embedded),
    #(int.bitwise_shift_left(1, 18), GatewayMessageContent),
    #(int.bitwise_shift_left(1, 19), GatewayMessageContentLimited),
    #(int.bitwise_shift_left(1, 23), ApplicationCommandBadge),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Application) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(decode.string))
  use description <- decode.field("description", decode.string)
  use rpc_origins <- decode.optional_field(
    "rpc_origins",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use is_bot_public <- decode.field("bot_public", decode.bool)
  use does_bot_require_code_grant <- decode.field(
    "bot_require_code_grant",
    decode.bool,
  )
  use bot <- decode.optional_field("bot", None, decode.optional(user.decoder()))
  use terms_of_service_url <- decode.optional_field(
    "terms_of_service_url",
    None,
    decode.optional(decode.string),
  )
  use privacy_policy_url <- decode.optional_field(
    "privacy_policy_url",
    None,
    decode.optional(decode.string),
  )
  use owner <- decode.optional_field(
    "owner",
    None,
    decode.optional(user.decoder()),
  )
  use team <- decode.field("team", decode.optional(team.decoder()))
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(decode.string),
  )
  use guild <- decode.optional_field(
    "guild",
    None,
    decode.optional(guild.decoder()),
  )
  use primary_sku_id <- decode.optional_field(
    "primary_sku_id",
    None,
    decode.optional(decode.string),
  )
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use cover_image_hash <- decode.optional_field(
    "cover_image",
    None,
    decode.optional(decode.string),
  )
  use flags <- decode.optional_field(
    "flags",
    None,
    decode.optional(flags.decoder(bits_flags())),
  )
  use approximate_guild_count <- decode.optional_field(
    "approximate_guild_count",
    None,
    decode.optional(decode.int),
  )
  use approximate_user_install_count <- decode.optional_field(
    "approximate_user_install_count",
    None,
    decode.optional(decode.int),
  )
  use redirect_uris <- decode.optional_field(
    "redirect_uris",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use interaction_endpoint_url <- decode.optional_field(
    "interaction_endpoint_url",
    None,
    decode.optional(decode.string),
  )
  use role_connections_verification_url <- decode.optional_field(
    "role_connections_verification_url",
    None,
    decode.optional(decode.string),
  )
  use event_webhooks_url <- decode.optional_field(
    "event_webhooks_url",
    None,
    decode.optional(decode.string),
  )
  use event_webhooks_status <- decode.optional_field(
    "event_webhooks_status",
    None,
    decode.optional(event_webhook_status_decoder()),
  )
  use event_webhooks_types <- decode.optional_field(
    "event_webhooks_types",
    None,
    decode.optional(decode.list(webhook_event.type_decoder())),
  )
  use tags <- decode.optional_field(
    "tags",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use install_params <- decode.optional_field(
    "install_params",
    None,
    decode.optional(install_params_decoder()),
  )
  use installation_context_config <- decode.optional_field(
    "integration_types_config",
    None,
    decode.optional(decode.dict(
      installation_context_decoder(),
      installation_context_config_decoder(),
    )),
  )
  use custom_install_url <- decode.optional_field(
    "custom_install_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(Application(
    id:,
    name:,
    icon_hash:,
    description:,
    rpc_origins:,
    is_bot_public:,
    does_bot_require_code_grant:,
    bot:,
    terms_of_service_url:,
    privacy_policy_url:,
    owner:,
    team:,
    guild_id:,
    guild:,
    primary_sku_id:,
    slug:,
    cover_image_hash:,
    flags:,
    approximate_guild_count:,
    approximate_user_install_count:,
    redirect_uris:,
    interaction_endpoint_url:,
    role_connections_verification_url:,
    event_webhooks_url:,
    event_webhooks_status:,
    event_webhooks_types:,
    tags:,
    install_params:,
    installation_context_config:,
    custom_install_url:,
  ))
}

@internal
pub fn install_params_decoder() -> decode.Decoder(InstallParams) {
  use scopes <- decode.field("scopes", decode.list(decode.string))
  use permissions <- decode.field("permissions", permission.decoder())
  decode.success(InstallParams(scopes:, permissions:))
}

@internal
pub fn installation_context_decoder() -> decode.Decoder(InstallationContext) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildInstall)
    1 -> decode.success(UserInstall)
    _ -> decode.failure(GuildInstall, "IntegrationType")
  }
}

@internal
pub fn installation_context_config_decoder() -> decode.Decoder(
  InstallationContextConfig,
) {
  use oauth2_install_params <- decode.optional_field(
    "oauth2_install_params",
    None,
    decode.optional(install_params_decoder()),
  )
  decode.success(InstallationContextConfig(oauth2_install_params:))
}

@internal
pub fn event_webhook_status_decoder() -> decode.Decoder(EventWebhookStatus) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Disabled)
    2 -> decode.success(Enabled)
    3 -> decode.success(DisabledByDiscord)
    _ -> decode.failure(Disabled, "EventWebhookStatus")
  }
}

// ENCODERS --------------------------------------------------------------------

@internal
pub fn install_params_to_json(install_params: InstallParams) -> Json {
  let InstallParams(scopes:, permissions:) = install_params
  json.object([
    #("scopes", json.array(scopes, json.string)),
    #("permissions", permission.to_json(permissions)),
  ])
}

@internal
pub fn installation_context_to_string(context: InstallationContext) -> String {
  case context {
    GuildInstall -> 0
    UserInstall -> 1
  }
  |> int.to_string
}

@internal
pub fn installation_context_to_json(context: InstallationContext) -> Json {
  case context {
    GuildInstall -> 0
    UserInstall -> 1
  }
  |> json.int
}

@internal
pub fn installation_context_config_to_json(
  installation_context_config: InstallationContextConfig,
) -> Json {
  let InstallationContextConfig(oauth2_install_params:) =
    installation_context_config
  json.object([
    #("oauth2_install_params", case oauth2_install_params {
      None -> json.null()
      option.Some(params) -> install_params_to_json(params)
    }),
  ])
}

@internal
pub fn event_webhook_status_to_json(
  event_webhook_status: EventWebhookStatus,
) -> Json {
  case event_webhook_status {
    Disabled -> json.int(1)
    Enabled -> json.int(2)
    DisabledByDiscord -> json.int(3)
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn get_emojis(
  client: grom.Client,
  for application_id: String,
) -> Result(List(Emoji), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/emojis",
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.at(["items"], decode.list(emoji.decoder())))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_emoji(
  client: grom.Client,
  for application_id: String,
  id emoji_id: String,
) -> Result(Emoji, grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/emojis/" <> emoji_id,
    )
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn create_emoji(
  client: grom.Client,
  for application_id: String,
  named name: String,
  bytes image: image.Data,
) -> Result(Emoji, grom.Error) {
  let json =
    json.object([
      #("name", json.string(name)),
      #("image", json.string(image |> image.to_base64)),
    ])

  use response <- result.try(
    client
    |> rest.new_request(
      http.Post,
      "/applications/" <> application_id <> "/emojis",
    )
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn rename_emoji(
  client: grom.Client,
  for application_id: String,
  id emoji_id: String,
  to name: String,
) -> Result(Emoji, grom.Error) {
  let json = json.object([#("name", json.string(name))])

  use response <- result.try(
    client
    |> rest.new_request(
      http.Patch,
      "/applications/" <> application_id <> "/emojis/" <> emoji_id,
    )
    |> request.set_body(json |> json.to_string)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: emoji.decoder())
  |> result.map_error(grom.CouldNotDecode)
}

pub fn delete_emoji(
  client: grom.Client,
  from application_id: String,
  id emoji_id: String,
) -> Result(Nil, grom.Error) {
  use _response <- result.try(
    client
    |> rest.new_request(
      http.Delete,
      "/applications/" <> application_id <> "/emojis/" <> emoji_id,
    )
    |> rest.execute,
  )

  Ok(Nil)
}

pub fn get_entitlements(
  client: grom.Client,
  for application_id: String,
  with query: Set(GetEntitlementsQuery),
) -> Result(List(Entitlement), grom.Error) {
  let query =
    set.map(query, fn(item) {
      case item {
        UserId(id) -> #("user_id", id)
        SkuIds(ids) -> #(
          "sku_ids",
          ids
            |> set.to_list
            |> string.join(","),
        )
        BeforeId(id) -> #("before", id)
        AfterId(id) -> #("after", id)
        Limit(limit) -> #("limit", limit |> int.to_string)
        GuildId(id) -> #("guild_id", id)
        ExcludeEnded(exclude) -> #(
          "exclude_ended",
          exclude
            |> bool.to_string
            |> string.lowercase,
        )
        ExcludeDeleted(exclude) -> #(
          "exclude_deleted",
          exclude
            |> bool.to_string
            |> string.lowercase,
        )
      }
    })

  use response <- result.try(
    client
    |> rest.new_request(
      http.Get,
      "/applications/" <> application_id <> "/entitlements",
    )
    |> request.set_query(query |> set.to_list)
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(entitlement.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}

pub fn get_skus(
  client: grom.Client,
  for application_id: String,
) -> Result(List(Sku), grom.Error) {
  use response <- result.try(
    client
    |> rest.new_request(http.Get, "/applications/" <> application_id <> "/skus")
    |> rest.execute,
  )

  response.body
  |> json.parse(using: decode.list(of: sku.decoder()))
  |> result.map_error(grom.CouldNotDecode)
}
