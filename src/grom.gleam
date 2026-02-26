import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import gleam_community/colour.{type Colour}
import status_code

const version: String = "v6.0.0"

/// A snowflake is another name for an ID.
/// It is possible to retrieve an object's creation date from its snowflake.
pub opaque type Snowflake(a) {
  Snowflake(id: Int)
}

/// An error that is returned if something goes wrong using REST (HTTP) API calls.
/// Examples include:
/// * No internet connection -> CouldNotReceiveResponse
/// * A Discord internal server error -> ReceivedUnsuccessfulStatusCode
/// * A bad request (e.g. message content too long) -> ReceivedErrorResponse
/// * A response decoding failure due to a breaking change with the Discord API -> CouldNotDecodeResponse
pub type RestError {
  CouldNotReceiveResponse(httpc.HttpError)
  ReceivedUnsuccessfulStatusCode(Response(String))
  ReceivedErrorResponse(ErrorResponse)
  CouldNotDecodeResponse(json.DecodeError)
}

/// An image hash is used to download images from Discord.
/// Every non-attachment image (avatars, banners, even guild tag badges) is hashed by Discord and is able to be downloaded through a link.
pub opaque type ImageHash {
  ImageHash(hash: String)
}

/// Returns the image hash in string form.
/// Generally not needed.
pub fn image_hash_to_string(image_hash: ImageHash) -> String {
  image_hash.hash
}

fn image_hash_decoder() -> Decoder(ImageHash) {
  decode.map(decode.string, ImageHash)
}

fn snowflake_to_json(snowflake: Snowflake(a)) -> Json {
  snowflake.id
  |> int.to_string
  |> json.string
}

pub fn snowflake_to_string(snowflake: Snowflake(a)) -> String {
  snowflake.id
  |> int.to_string
}

pub fn snowflake_to_int(snowflake: Snowflake(a)) -> Int {
  snowflake.id
}

fn snowflake_decoder() -> Decoder(Snowflake(a)) {
  use id <- decode.then(decode.string)
  case int.parse(id) {
    Ok(id) -> decode.success(Snowflake(id))
    Error(_) -> decode.failure(Snowflake(0), "Snowflake")
  }
}

/// Used for creating arbitary snowflakes.
/// This should only be used for hardcoding values or retrieving IDs from a database.
/// Don't use this function to change `Snowflake(a)` to a `Snowflake(b)`.
///
/// Example usage:
/// ```
/// let guild_id: Snowflake(Guild) = new_snowflake(768594524158427167)
/// ```
pub fn new_snowflake(from id: Int) -> Snowflake(a) {
  Snowflake(id)
}

fn flags_decoder(bits_flags: List(#(Int, flag))) -> Decoder(List(flag)) {
  use bits <- decode.then(decode.int)

  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    case int.bitwise_and(bits, bit) != 0 {
      True -> Ok(flag)
      False -> Error(Nil)
    }
  })
  |> decode.success
}

fn flags_to_int(flags: List(flag), bits_flags: List(#(Int, flag))) -> Int {
  bits_flags
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    let is_in_flags = list.any(flags, fn(curr) { curr == flag })
    case is_in_flags {
      True -> Ok(bit)
      False -> Error(Nil)
    }
  })
  |> int.sum
}

fn flags_to_json(flags: List(flag), bits_flags: List(#(Int, flag))) -> Json {
  json.int(flags |> flags_to_int(bits_flags))
}

pub type User {
  User(
    id: Snowflake(User),
    username: String,
    /// Mostly deprecated. Only bots have discriminators nowadays.
    /// Users will very likely have their discriminator set to `0`.
    /// Used in the past when usernames weren't user-specific.
    /// Doesn't include the `#` prefix.
    discriminator: String,
    /// Also called a display name.
    /// Is `None` when the user doesn't have a global name, and rather uses their username as their display name.
    global_name: Option(String),
    /// Is `None` when the user uses a default avatar.
    avatar_hash: Option(ImageHash),
    /// Whether the user is a bot user.
    is_bot: Bool,
    /// Whether the user is Discord's official system account.
    is_system: Bool,
    /// Is `None` if it isn't known whether the user has enabled MFA.
    /// MFA = multi-factor authentication.
    has_mfa_enabled: Option(Bool),
    /// Is `None` when the user doesn't use a custom banner.
    banner_hash: Option(ImageHash),
    /// The user's banner accent colour in RGB hexadecimal format.
    /// Is `None` when the user uses a default color based on avatar.
    accent_colour: Option(Colour),
    /// The user's chosen locale.
    /// Full list of locales: [link](https://docs.discord.com/developers/reference#locales)
    /// Discord hasn't disclosed when this field could be `None`. 
    locale: Option(String),
    flags: List(UserFlag),
    /// Is `None` if the user's premium type isn't known.
    premium_type: Option(UserPremiumType),
    /// Publicly visible flags - aka Discord badges.
    /// Visible in the top right corner of a person's profile in the apps.
    public_flags: List(UserFlag),
    /// Is `None` when the user has no avatar decorations.
    avatar_decoration: Option(UserAvatarDecoration),
    /// Is `None` when the user has no collectibles.
    collectibles: Option(UserCollectibles),
    /// Is `None` if the user never had a primary guild.
    primary_guild: Option(UserPrimaryGuild),
  )
}

fn hex_colour_decoder() -> Decoder(Colour) {
  use hex <- decode.then(decode.int)

  case colour.from_rgb_hex(hex) {
    Ok(colour) -> decode.success(colour)
    Error(_) -> decode.failure(colour.black, "Colour")
  }
}

fn user_decoder() -> Decoder(User) {
  use id <- decode.field("id", snowflake_decoder())
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use global_name <- decode.field("global_name", decode.optional(decode.string))
  use avatar_hash <- decode.field(
    "avatar",
    decode.optional(image_hash_decoder()),
  )
  use is_bot <- decode.optional_field("bot", False, decode.bool)
  use is_system <- decode.optional_field("system", False, decode.bool)
  use has_mfa_enabled <- decode.optional_field(
    "mfa_enabled",
    None,
    decode.optional(decode.bool),
  )
  use banner_hash <- decode.optional_field(
    "banner",
    None,
    decode.optional(image_hash_decoder()),
  )
  use accent_colour <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(hex_colour_decoder()),
  )
  use locale <- decode.optional_field(
    "locale",
    None,
    decode.optional(decode.string),
  )
  use flags <- decode.optional_field(
    "flags",
    [],
    flags_decoder(bits_user_flags()),
  )
  use premium_type <- decode.optional_field(
    "premium_type",
    None,
    decode.optional(user_premium_type_decoder()),
  )
  use public_flags <- decode.optional_field(
    "public_flags",
    [],
    flags_decoder(bits_user_flags()),
  )
  use avatar_decoration <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(user_avatar_decoration_decoder()),
  )
  use collectibles <- decode.optional_field(
    "collectibles",
    None,
    decode.optional(user_collectibles_decoder()),
  )
  use primary_guild <- decode.optional_field(
    "primary_guild",
    None,
    decode.optional(user_primary_guild_decoder()),
  )
  decode.success(User(
    id:,
    username:,
    discriminator:,
    global_name:,
    avatar_hash:,
    is_bot:,
    is_system:,
    has_mfa_enabled:,
    banner_hash:,
    accent_colour:,
    locale:,
    flags:,
    premium_type:,
    public_flags:,
    avatar_decoration:,
    collectibles:,
    primary_guild:,
  ))
}

fn user_primary_guild_decoder() -> Decoder(UserPrimaryGuild) {
  use is_enabled <- decode.field(
    "identity_enabled",
    decode.optional(decode.bool),
  )
  case is_enabled {
    Some(True) -> {
      use id <- decode.field("identity_guild_id", snowflake_decoder())
      use tag <- decode.field("tag", decode.string)
      use badge_hash <- decode.field("badge", image_hash_decoder())

      decode.success(ActiveUserPrimaryGuild(id:, tag:, badge_hash:))
    }
    Some(False) -> decode.success(ManuallyClearedUserPrimaryGuild)
    None -> decode.success(AutomaticallyClearedUserPrimaryGuild)
  }
}

fn user_avatar_decoration_decoder() -> Decoder(UserAvatarDecoration) {
  use hash <- decode.field("asset", image_hash_decoder())
  use sku_id <- decode.field("sku_id", snowflake_decoder())
  decode.success(UserAvatarDecoration(hash:, sku_id:))
}

fn user_premium_type_decoder() -> Decoder(UserPremiumType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(UserHasNoPremiumSubscription)
    1 -> decode.success(UserHasNitroClassic)
    2 -> decode.success(UserHasNitro)
    3 -> decode.success(UserHasNitroBasic)
    _ -> decode.failure(UserHasNoPremiumSubscription, "PremiumType")
  }
}

pub type UserPrimaryGuild {
  /// A user actively has a primary guild tag.
  ActiveUserPrimaryGuild(
    id: Snowflake(Guild),
    tag: String,
    badge_hash: ImageHash,
  )
  /// The user's primary guild was cleared by Discord because the guild became ineligible for guild tags.
  AutomaticallyClearedUserPrimaryGuild
  /// The user manually removed their guild tag.
  ManuallyClearedUserPrimaryGuild
}

// TODO: GET RID OF ME, ACTUALLY USE SKUs
pub type Sku

pub type UserAvatarDecoration {
  UserAvatarDecoration(hash: ImageHash, sku_id: Snowflake(Sku))
}

pub type UserCollectibles {
  UserCollectibles(
    /// Is `None` when the user doesn't have a nameplate.
    nameplate: Option(UserNameplate),
  )
}

/// A nameplate is a decoration around a user's Direct Messages / online member list view tab.
pub type UserNameplate {
  UserNameplate(
    sku_id: Snowflake(Sku),
    hash: ImageHash,
    /// Currently unused.
    label: String,
    palette: UserNameplatePalette,
  )
}

pub type UserNameplatePalette {
  CrimsonUserNameplate
  BerryUserNameplate
  SkyUserNameplate
  TealUserNameplate
  ForestUserNameplate
  BubbleGumUserNameplate
  VioletUserNameplate
  CobaltUserNameplate
  CloverUserNameplate
  LemonUserNameplate
  WhiteUserNameplate
}

pub type UserFlag {
  /// Given to official Discord staff.
  UserIsStaff
  /// Given to partnered guild owners.
  UserIsDiscordPartner
  /// Given to participants of Hypesquad events.
  UserIsHypesquadEventsMember
  /// Given to Discord Bug Hunters, first level of the badge.
  UserIsBugHunterLevel1
  UserBelongsToHypesquadBravery
  UserBelongsToHypesquadBrilliance
  UserBelongsToHypesquadBalance
  /// Given to "early Nitro supporters".
  UserIsPremiumEarlySupporter
  /// The user is actually a development team.
  UserIsTeamPseudoUser
  /// Given to Discord Bug Hunters, second level of the badge.
  UserIsBugHunterLevel2
  /// Given to verified bot users.
  UserIsVerifiedBot
  /// Given to early verified bot developers. No longer obtainable.
  UserIsVerifiedDeveloper
  /// Given to people who passed the Discord Certified Moderator course.
  UserIsCertifiedModerator
  /// The bot only uses HTTP webhook interaction and is shown in the online member list.
  BotUsesHttpInteractions
  /// Given to [active developers](https://support-dev.discord.com/hc/articles/10113997751447).
  /// No longer obtainable.
  UserIsActiveDeveloper
}

fn bits_user_flags() -> List(#(Int, UserFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), UserIsStaff),
    #(int.bitwise_shift_left(1, 1), UserIsDiscordPartner),
    #(int.bitwise_shift_left(1, 2), UserIsHypesquadEventsMember),
    #(int.bitwise_shift_left(1, 3), UserIsBugHunterLevel1),
    #(int.bitwise_shift_left(1, 6), UserBelongsToHypesquadBravery),
    #(int.bitwise_shift_left(1, 7), UserBelongsToHypesquadBrilliance),
    #(int.bitwise_shift_left(1, 8), UserBelongsToHypesquadBalance),
    #(int.bitwise_shift_left(1, 9), UserIsPremiumEarlySupporter),
    #(int.bitwise_shift_left(1, 10), UserIsTeamPseudoUser),
    #(int.bitwise_shift_left(1, 14), UserIsBugHunterLevel2),
    #(int.bitwise_shift_left(1, 16), UserIsVerifiedBot),
    #(int.bitwise_shift_left(1, 17), UserIsVerifiedDeveloper),
    #(int.bitwise_shift_left(1, 18), UserIsCertifiedModerator),
    #(int.bitwise_shift_left(1, 19), BotUsesHttpInteractions),
    #(int.bitwise_shift_left(1, 22), UserIsActiveDeveloper),
  ]
}

/// Describes what level of a Nitro subscription a user has.
pub type UserPremiumType {
  UserHasNoPremiumSubscription
  UserHasNitroClassic
  UserHasNitro
  UserHasNitroBasic
}

fn user_collectibles_decoder() -> Decoder(UserCollectibles) {
  use nameplate <- decode.optional_field(
    "nameplate",
    None,
    decode.optional(user_nameplate_decoder()),
  )
  decode.success(UserCollectibles(nameplate:))
}

fn user_nameplate_decoder() -> Decoder(UserNameplate) {
  use sku_id <- decode.field("sku_id", snowflake_decoder())
  use hash <- decode.field("asset", image_hash_decoder())
  use label <- decode.field("label", decode.string)
  use palette <- decode.field("palette", user_nameplate_palette_decoder())

  decode.success(UserNameplate(sku_id, hash, label, palette))
}

fn user_nameplate_palette_decoder() -> Decoder(UserNameplatePalette) {
  use variant <- decode.then(decode.string)

  case variant {
    "crimson" -> decode.success(CrimsonUserNameplate)
    "berry" -> decode.success(BerryUserNameplate)
    "sky" -> decode.success(SkyUserNameplate)
    "teal" -> decode.success(TealUserNameplate)
    "forest" -> decode.success(ForestUserNameplate)
    "bubble_gum" -> decode.success(BubbleGumUserNameplate)
    "violet" -> decode.success(VioletUserNameplate)
    "cobalt" -> decode.success(CobaltUserNameplate)
    "clover" -> decode.success(CloverUserNameplate)
    "lemon" -> decode.success(LemonUserNameplate)
    "white" -> decode.success(WhiteUserNameplate)
    _ -> decode.failure(CrimsonUserNameplate, "UserNameplatePalette")
  }
}

/// Used to get the default user avatar.
/// If it returns an error - you got lucky - the user still has a discriminator and it somehow isn't an integer.
pub fn get_user_index(of user: User) -> Result(Int, Nil) {
  case user.discriminator {
    "0" -> {
      let id = user.id |> snowflake_to_int
      Ok(int.bitwise_shift_right(id, 22) % 6)
    }
    _ -> {
      use discriminator <- result.map(int.parse(user.discriminator))
      discriminator % 5
    }
  }
}

const discord_api_url: String = "discord.com"

const discord_api_path: String = "api/v10"

fn new_api_request(
  token token: String,
  to path: String,
  method method: http.Method,
) -> Request(String) {
  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_api_url)
  |> request.set_path(discord_api_path <> path)
  |> request.set_method(method)
  |> request.prepend_header("authorization", "Bot " <> token)
  |> request.prepend_header(
    "user-agent",
    "DiscordBot (https://github.com/folospior/grom, " <> version <> ")",
  )
  |> request.prepend_header("content-type", "application/json")
}

fn send_request(
  request: Request(String),
  decode_with decoder: Decoder(a),
) -> Result(a, RestError) {
  request
  |> httpc.send
  // If httpc.send failed, put the error into this
  |> result.map_error(CouldNotReceiveResponse)
  // If httpc.send succeeded, check if the response is an error response.
  // If it is - return an Error with the ErrorResponse inside.
  |> result.try(parse_error_response)
  // If the response isn't errorneous - check if the response has a successful status code.
  // If it doesn't - return an Error with the Response object inside
  |> result.try(ensure_status_code_success)
  // If all of the checks above succeeded - parse the response body based on the provided decoder.
  // If parsing fails - return an Error with the DecodeError inside.
  |> result.try(fn(response) {
    response.body
    |> json.parse(using: decoder)
    |> result.map_error(CouldNotDecodeResponse)
  })
}

fn send_no_content_request(request: Request(String)) -> Result(Nil, RestError) {
  request
  |> httpc.send
  // If httpc.send failed, put the error into this
  |> result.map_error(CouldNotReceiveResponse)
  // If httpc.send succeeded, check if the response is an error response.
  // If it is - return an Error with the ErrorResponse inside.
  |> result.try(parse_error_response)
  // If the response isn't errorneous - check if the response has a successful status code.
  // If it doesn't - return an Error with the Response object inside
  |> result.try(ensure_status_code_success)
  // If all the checks above succeeded, return Ok(Nil)
  |> result.replace(Nil)
}

fn request_with_reason(
  request: Request(a),
  reason: Option(String),
) -> Request(a) {
  case reason {
    Some(reason) ->
      request
      |> request.prepend_header("x-audit-log-reason", reason)
    None -> request
  }
}

pub type ErrorResponse {
  ErrorResponse(
    /// See the list of error codes: [link](https://docs.discord.com/developers/topics/opcodes-and-status-codes#json)
    code: Int,
    /// User-friendly message briefly explaining what error happened.
    message: String,
    /// This is a dynamic object that is best not parsed. I recommend just printing it if needed.
    /// It contains detailed information regarding what error happened.
    /// It would be nearly impossible to properly parse it. It is also sometimes absent from the response.
    errors: Option(Dynamic),
  )
}

fn error_response_decoder() -> Decoder(ErrorResponse) {
  use code <- decode.field("code", decode.int)
  use message <- decode.field("message", decode.string)
  use errors <- decode.optional_field(
    "errors",
    None,
    decode.optional(decode.dynamic),
  )
  decode.success(ErrorResponse(code:, message:, errors:))
}

fn ensure_status_code_success(
  response: Response(String),
) -> Result(Response(String), RestError) {
  case status_code.is_successful(response.status) {
    True -> Ok(response)
    False -> Error(ReceivedUnsuccessfulStatusCode(response))
  }
}

fn parse_error_response(
  response: Response(String),
) -> Result(Response(String), RestError) {
  let result =
    response.body
    |> json.parse(using: error_response_decoder())

  case result {
    Ok(error) -> Error(ReceivedErrorResponse(error))
    Error(_) -> Ok(response)
  }
}

pub fn get_current_user(token token: String) -> Result(User, RestError) {
  new_api_request(token:, to: "/users/@me", method: http.Get)
  |> send_request(decode_with: user_decoder())
}

pub fn get_user(
  token token: String,
  id id: Snowflake(User),
) -> Result(User, RestError) {
  new_api_request(
    token:,
    to: "/users/" <> snowflake_to_string(id),
    method: http.Get,
  )
  |> send_request(decode_with: user_decoder())
}

/// This type is used to diffrentiate between the ways of modifying an object.
/// Some parts of an object can be changed to a different value, but not deleted - for this, grom uses the Option type.
/// Other parts can be changed to a different value or deleted - for this, grom uses the Modification type.
/// 
/// The default behavior of modify functions is to not modify anything - for options: `None`, for modifications: `Skip`
pub type Modification(a) {
  /// Will modify the value to the new, provided value
  Modify(a)
  /// Will set the value to `null`, deleting it
  Delete
  /// Will not modify the value
  Skip
}

/// Used for uploading images to Discord.
/// You'll encounter this type in modify and create functions.
/// Use [image_data_from_bit_array](#image_data_from_bit_array) to create this.
pub opaque type ImageData {
  ImageData(data: String)
}

pub type ImageDataContentType {
  JpegImageData
  PngImageData
  GifImageData
}

pub fn image_data_from_bit_array(
  image data: BitArray,
  content_type content_type: ImageDataContentType,
) -> ImageData {
  let mime = case content_type {
    JpegImageData -> "image/jpeg"
    PngImageData -> "image/png"
    GifImageData -> "image/gif"
  }

  let base64 = bit_array.base64_encode(data, False)

  ImageData("data:" <> mime <> ";base64," <> base64)
}

fn image_data_to_json(image_data: ImageData) -> Json {
  image_data.data
  |> json.string
}

pub type ModifyCurrentUser {
  ModifyCurrentUser(
    /// May cause the discriminator to randomize if changed (mostly applies to bots).
    username: Option(String),
    avatar: Modification(ImageData),
    banner: Modification(ImageData),
  )
}

pub fn modify_current_user(
  token token: String,
  using modify: ModifyCurrentUser,
) -> Result(User, RestError) {
  let body = modify |> modify_current_user_to_json |> json.to_string

  new_api_request(token:, to: "/users/@me", method: http.Patch)
  |> request.set_body(body)
  |> send_request(decode_with: user_decoder())
}

pub fn new_modify_current_user() -> ModifyCurrentUser {
  ModifyCurrentUser(None, Skip, Skip)
}

pub fn modify_current_user_username(
  modify: ModifyCurrentUser,
  new username: String,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, username: Some(username))
}

pub fn modify_current_user_avatar(
  modify: ModifyCurrentUser,
  new avatar: Modification(ImageData),
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, avatar:)
}

pub fn modify_current_user_banner(
  modify: ModifyCurrentUser,
  new banner: Modification(ImageData),
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, banner:)
}

fn modify_current_user_to_json(modify: ModifyCurrentUser) -> Json {
  let username = case modify.username {
    Some(new) -> [#("username", json.string(new))]
    None -> []
  }

  let avatar = modification_to_json(modify.avatar, "avatar", image_data_to_json)

  let banner = modification_to_json(modify.banner, "banner", image_data_to_json)

  [username, avatar, banner]
  |> list.flatten
  |> json.object
}

fn modification_to_json(
  modification: Modification(a),
  key: String,
  success_encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  case modification {
    Modify(value) -> [#(key, success_encoder(value))]
    Delete -> [#(key, json.null())]
    Skip -> []
  }
}

pub type Role {
  Role(
    id: Snowflake(Role),
    name: String,
    colours: RoleColours,
    /// Whether the role is pinned in the guild user list.
    is_hoisted: Bool,
    /// Is `None` if the role doesn't have an icon.
    icon_hash: Option(ImageHash),
    /// Is `None` if the role doesn't have an associated emoji.
    unicode_emoji: Option(String),
    /// Position of this role in the hierarchy.
    /// Roles with the same position are sorted by ID.
    position: Int,
    /// Permissions given to members with this role.
    permissions: List(Permission),
    /// Whether this role is managed by an integration.
    /// Example: All bots added to a guild are given an integration-managed role.
    is_integration_managed: Bool,
    /// Whether this role is mentionable in text channels.
    is_mentionable: Bool,
    /// The ID of the bot user associated with this role.
    /// Is `None` if the role isn't a bot's rle.
    bot_id: Option(Snowflake(User)),
    /// The ID of the integration associated with this role.
    /// Is `None` if the role isn't an integration's role.
    integration_id: Option(Snowflake(Integration)),
    /// Whether this role is the role automatically given to the guild's boosters.
    is_booster_role: Bool,
    /// The ID of the subscription SKU for this role.
    /// Is `None` if the role isn't a subscription-based role.
    subscription_listing_id: Option(Snowflake(Sku)),
    is_available_for_purchase: Bool,
    /// Whether this role is linked to a Discord connection.
    /// Learn more: [link](https://support.discord.com/hc/en-us/articles/10388356626711-Connections-Linked-Roles-Admins)
    is_linked_role: Bool,
    flags: List(RoleFlag),
  )
}

pub type RoleFlag {
  RoleCanBeSeletedInOnboardingPrompt
}

fn bits_role_flags() -> List(#(Int, RoleFlag)) {
  [#(int.bitwise_shift_left(1, 0), RoleCanBeSeletedInOnboardingPrompt)]
}

// TODO: GET RID OF ME! USE ACTUAL INTEGRATIONS!
pub type Integration

pub type Permission {
  AllowCreatingInstantInvites
  AllowKickingMembers
  AllowBanningMembers
  /// Allows all permissions and bypasses channel permission overrides.
  AdministratorPermission
  /// Allows management and editing of channels
  AllowManagingChannels
  /// Allows management and editing of the guild
  AllowManagingGuild
  /// Allows adding new reactions to messages.
  /// Does not change the ability to react with an existing reaction.
  AllowAddingReactions
  AllowViewingAuditLog
  AllowPrioritySpeakingInVoiceChannels
  AllowStreamingInVoiceChannels
  /// Implicitly enabled by default.
  AllowViewingChannels
  /// Implicitly enabled by default.
  AllowSendingMessages
  /// Allows sending text-to-speech messages, read out loud by default to all readers.
  AllowSendingTtsMessages
  /// Allows deleting others' messages.
  AllowManagingMessages
  /// Automatically shows embeds of links sent by the permission's owner.
  AutoEmbedLinksPermission
  AllowAttachingFiles
  AllowReadingMessageHistory
  /// Allows mentioning `@everyone` - everyone in the guild and `@here` - every online person in the guild.
  AllowMentioningEveryone
  /// Allows using custom emojis from other servers.
  AllowUsingExternalEmojis
  AllowViewingGuildInsights
  AllowConnectingToVoiceChannels
  AllowSpeakingInVoiceChannels
  AllowMutingMembersInVoiceChannels
  AllowDeafeningMembersInVoiceChannels
  AllowMovingMembersBetweenVoiceChannels
  AllowUsingVoiceActivityDetection
  AllowChangingOwnNickname
  /// Allows modifying others' nicknames.
  AllowManagingNicknames
  /// Allows modifying others' roles.
  AllowManagingRoles
  AllowManagingWebhooks
  /// Allows editing and deleting the guild's custom emojis, stickers and soundboard sounds.
  AllowManagingGuildExpressions
  /// Allows using slash/context-menu commands.
  AllowUsingCommands
  AllowRequestingToSpeakInStageChannels
  /// Allows editing and deleting the guild's scheduled events.
  AllowManagingEvents
  /// Allows creating public and announcement threads.
  AllowCreatingPublicThreads
  AllowCreatingPrivateThreads
  /// Allows using custom stickers from other guilds.
  AllowUsingExternalStickers
  AllowSendingMessagesInThreads
  AllowUsingEmbeddedActivities
  /// Allows timing-out other members.
  AllowModeratingMembers
  /// Allows viewing role subscription insights.
  AllowViewingCreatorMonetizationAnalytics
  AllowUsingSoundboard
  /// Allows creating custom emojis, stickers and soundboard sounds.
  /// Also allows editing and deleting the aforementioned expressions created by the permission's owner.
  AllowCreatingGuildExpressions
  /// Allows creating scheduled events.
  /// Also allows editing and deleting events created by the permission's owner.
  AllowCreatingEvents
  /// Allows using soundboard sounds from other guilds.
  AllowUsingExternalSoundboardSounds
  AllowSendingVoiceMessages
  AllowSendingPolls
  /// Allows user-installed applications to send public responses.
  /// 
  /// When disabled, users will still be able to use their apps, but their responses will be ephemeral.
  /// This only applies to apps that are not installed at the guild level.
  AllowUsingExternalApplications
  AllowPinningMessages
  AllowBypassingSlowmode
}

pub type RoleColours {
  RoleColours(
    /// The primary colour of the role.
    primary_colour: Colour,
    /// The secondary colour of the role.
    /// If present, this will make the role colour a gradient between the provided colours.
    /// Can only be set to `Some(colour)` if the guild has the `GuildCanUseEnhancedRoleColours` feature.
    secondary_colour: Option(Colour),
    /// The tertiary colour of the role.
    /// If present, this will turn the gradient into a holographic style.
    /// Can only be set to `Some(colour)` if the guild has the `GuildCanUseEnhancedRoleColours` feature.
    ///
    /// Note: When sending `tertiary_colour`, the API enforces the role colour to be a holographic style with the values:
    /// - `primary_colour = 0xA9C9FF`
    /// - `secondary_colour = 0xFFBBEC`
    /// - `tertiary_colour = 0xFFC3A0`
    tertiary_colour: Option(Colour),
  )
}

// MESSAGE_CREATE && MESSAGE_UPDATE: DO NOT USE THIS TYPE
// CREATE A NEW TYPE FOR THESE EVENTS: THEY WILL NOT HAVE THE USER FIELD
// 
// VOICE_STATE_UPDATE: DO NOT USE THIS TYPE
// CREATE A NEW TYPE FOR THIS EVENT: IT WILL NOT HAVE THE JOINED_AT FIELD IF THE MEMBER WAS INVITED AS A GUEST
//
// INTERACTIONS: DO NOT USE THIS TYPE
// CREATE A NEW TYPE FOR INTERACTIONS: IT WILL HAVE THE PERMISSIONS FIELD
pub type GuildMember {
  GuildMember(
    /// Corresponding user object.
    user: User,
    /// Guild-specific nickname.
    /// Is `None` when the member doesn't have a guild-specific nickname. 
    nick: Option(String),
    /// Guild-specific avatar hash.
    /// Is `None` if the member chose not to use a guild-specific avatar.
    avatar_hash: Option(ImageHash),
    /// Guild-specific banner hash.
    /// Is `None` if the member chose not to use a guild-specific banner.
    banner_hash: Option(ImageHash),
    /// List of the member's roles in this guild.
    role_ids: List(Snowflake(Role)),
    /// When the member joined the guild.
    joined_at: Timestamp,
    /// Since when the member is boosting the guild.
    /// Is `None` if the member chose not to boost the guild.
    boosting_since: Option(Timestamp),
    /// Whether the member is deafened in voice channels for this guild.
    is_deafened: Bool,
    /// Whether the member is muted in voice channels for this guild.
    is_muted: Bool,
    flags: List(GuildMemberFlag),
    /// Whether the member has not yet passed the membership screening requirements.
    is_pending: Bool,
    /// When the member's timeout will expire, returning their ability to communicate in the guild.
    /// IMPORTANT: the member is not timed out if this field is `None` **or a time in the past**.
    communication_disabled_until: Option(Timestamp),
    /// Guild-specific avatar decoration.
    /// Is `None` if the member chose not to use guild-specific avatar decorations.
    avatar_decoration: Option(UserAvatarDecoration),
  )
}

fn rfc3339_decoder() -> Decoder(Timestamp) {
  use rfc3339 <- decode.then(decode.string)
  case timestamp.parse_rfc3339(rfc3339) {
    Ok(ts) -> decode.success(ts)
    Error(_) -> decode.failure(timestamp.from_unix_seconds(0), "Timestamp")
  }
}

fn guild_member_decoder() -> Decoder(GuildMember) {
  use user <- decode.field("user", user_decoder())
  use nick <- decode.field("nick", decode.optional(decode.string))
  use avatar_hash <- decode.field(
    "avatar",
    decode.optional(image_hash_decoder()),
  )
  use banner_hash <- decode.field(
    "banner",
    decode.optional(image_hash_decoder()),
  )
  use role_ids <- decode.field("roles", decode.list(snowflake_decoder()))
  use joined_at <- decode.field("joined_at", rfc3339_decoder())
  use boosting_since <- decode.optional_field(
    "premium_since",
    None,
    decode.optional(rfc3339_decoder()),
  )
  use is_deafened <- decode.field("deaf", decode.bool)
  use is_muted <- decode.field("mute", decode.bool)
  use flags <- decode.field("flags", flags_decoder(bits_guild_member_flags()))
  use is_pending <- decode.optional_field("pending", False, decode.bool)
  use communication_disabled_until <- decode.optional_field(
    "communication_disabled_until",
    None,
    decode.optional(rfc3339_decoder()),
  )
  use avatar_decoration <- decode.optional_field(
    "avatar_decoration_data",
    None,
    decode.optional(user_avatar_decoration_decoder()),
  )
  decode.success(GuildMember(
    user:,
    nick:,
    avatar_hash:,
    banner_hash:,
    role_ids:,
    joined_at:,
    boosting_since:,
    is_deafened:,
    is_muted:,
    flags:,
    is_pending:,
    communication_disabled_until:,
    avatar_decoration:,
  ))
}

pub type GuildMemberFlag {
  /// Member left and rejoined the guild
  GuildMemberRejoined
  /// Member completed onboarding
  GuildMemberCompletedOnboarding
  /// Member is exempt from guild verification requirements
  GuildMemberBypassesVerification
  /// Member has started onboarding
  GuildMemberStartedOnboarding
  /// Member is a guest and can only access the voice channel they were invited to
  GuildMemberIsGuest
  /// Member has started Server Guide new member actions
  GuildMemberStartedHomeActions
  /// Member has completed Server Guide new member actions
  GuildMemberCompletedHomeActions
  /// Member's username, display name or nickname is blocked by AutoMod
  GuildMemberUsernameQuarantinedByAutomod
  /// Member has dismissed the DM settings upsell
  GuildMemberAcknowledgedDmSettingsUpsell
  /// Member's guild tag is blocked by AutoMod
  GuildMemberGuildTagQuarantinedByAutomod
}

fn bits_guild_member_flags() -> List(#(Int, GuildMemberFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), GuildMemberRejoined),
    #(int.bitwise_shift_left(1, 1), GuildMemberCompletedOnboarding),
    #(int.bitwise_shift_left(1, 2), GuildMemberBypassesVerification),
    #(int.bitwise_shift_left(1, 3), GuildMemberStartedOnboarding),
    #(int.bitwise_shift_left(1, 4), GuildMemberIsGuest),
    #(int.bitwise_shift_left(1, 5), GuildMemberStartedHomeActions),
    #(int.bitwise_shift_left(1, 6), GuildMemberCompletedHomeActions),
    #(int.bitwise_shift_left(1, 7), GuildMemberUsernameQuarantinedByAutomod),
    #(int.bitwise_shift_left(1, 9), GuildMemberAcknowledgedDmSettingsUpsell),
    #(int.bitwise_shift_left(1, 10), GuildMemberGuildTagQuarantinedByAutomod),
  ]
}

pub fn get_current_user_as_guild_member(
  token token: String,
  for guild_id: Snowflake(Guild),
) -> Result(GuildMember, RestError) {
  new_api_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id) <> "/member",
    method: http.Get,
  )
  |> send_request(decode_with: guild_member_decoder())
}

pub fn leave_guild(
  token token: String,
  id guild_id: Snowflake(Guild),
) -> Result(Nil, RestError) {
  new_api_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id),
    method: http.Delete,
  )
  |> send_no_content_request
}

// TODO: GET RID OF ME! USE ACTUAL CHANNELS
pub type Channel

pub type Guild {
  Guild(
    id: Snowflake(Guild),
    name: String,
    /// Image hash of the guild icon.
    /// An icon is the picture shown in the server list.
    /// Is `None` when the guild doesn't have an icon.
    icon_hash: Option(ImageHash),
    /// Image hash of the guild splash.
    /// A splash is the picture shown when a user joins a guild, at the "Accept Invite" UI.
    /// Is `None` when the guild doesn't have a splash. 
    splash_hash: Option(ImageHash),
    /// Image hash of the guild discovery splash.
    /// A discovery splash is the picture shown when a user clicks on a guild in the "Server Discovery" UI.
    /// Is `None` when the guild isn't discoverable or doesn't have a discovery splash.
    discovery_splash_hash: Option(ImageHash),
    owner_id: Snowflake(User),
    /// The "AFK channel" is the channel to which inactive voice channel users are moved.
    /// Is `None` when the guild doesn't have a configured AFK channel.
    afk_channel_id: Option(Snowflake(Channel)),
    /// The time of inactivity after a voice channel user is marked as AFK in this guild.
    afk_timeout: Duration,
    /// Whether the "server widget" is enabled.
    /// The server widget is a feature allowing guild advertisements on websites.
    is_widget_enabled: Bool,
    /// The channel to which the widget will generate an invite to.
    /// Is `None` if the widget was configured to not generate invites or is disabled.
    widget_channel_id: Option(Snowflake(Channel)),
    /// The verification level required for a guild member to be able to communicate in a guild.
    required_verification_level: GuildMemberVerificationLevel,
    /// The default setting regarding sending push notifications to members' devices.
    /// Note that this can be overriden on a per-member basis.
    default_message_notification_setting: GuildDefaultMessageNotificationSetting,
    explicit_content_filter_setting: GuildExplicitContentFilterSetting,
    roles: List(Role),
    emojis: List(Emoji),
    features: List(GuildFeature),
    /// MFA = multi-factor authentication
    required_mfa_level: GuildRequiredMfaLevel,
    /// Application ID of the guild creator if it is created by a bot.
    application_id: Option(Snowflake(Application)),
    /// The system channel is the channel where certain notifications, such as on-boost messages are sent.
    /// Is `None` if the guild does not use system messages.
    system_channel_id: Option(Snowflake(Channel)),
    system_channel_flags: List(GuildSystemChannelFlag),
    /// Is `None` if the guild doesn't have a rules channel.
    rules_channel_id: Option(Snowflake(Channel)),
    /// The maximum number of presences for the guild.
    /// Is always `None`, apart from the largest of guilds.
    max_presences: Option(Int),
    /// According to [discord.py](https://discordpy.readthedocs.io/en/latest/api.html?highlight=max_members#discord.Guild.max_members), this is always `None`, unless the guild is received from `get_guild()`.
    max_members: Option(Int),
    /// Is `None` if the guild doesn't have a vanity url.
    vanity_url_code: Option(String),
    /// Is `None` if the guild doesn't have a description.
    description: Option(String),
    /// Is `None` if the guild doesn't have a banner.
    banner_hash: Option(ImageHash),
    premium_tier: GuildPremiumTier,
    premium_subscription_count: Option(Int),
    preferred_locale: String,
    public_updates_channel_id: Option(String),
    max_video_channel_users: Option(Int),
    max_stage_video_channel_users: Option(Int),
    approximate_member_count: Option(Int),
    approximate_presence_count: Option(Int),
    welcome_screen: Option(WelcomeScreen),
    nsfw_level: NsfwLevel,
    stickers: Option(List(Sticker)),
    is_premium_progress_bar_enabled: Bool,
    safety_alerts_channel_id: Option(String),
    incidents_data: Option(IncidentsData),
  )
}

pub type GuildPremiumTier {
  /// The guild hasn't unlocked any server boost perks.
  GuildWithoutPremium
  /// Server boost level 1 perks.
  GuildPremiumTier1
  /// Server boost level 2 perks.
  GuildPremiumTier2
  /// Server boost level 3 perks.
  GuildPremiumTier3
}

pub type GuildSystemChannelFlag {
  /// Suppresses the member join notifications.
  GuildSystemChannelWithoutJoinNotifications
  /// Suppresses the server boost notifications.
  GuildSystemChannelWithoutPremiumNotifications
  /// Suppresses server setup tips.
  GuildSystemChannelWithoutGuildReminderNotifications
  /// Hides the sticker reply buttons to member join notifications.
  GuildSystemChannelWithoutJoinNotificationStickerReplyButtons
  /// Suppresses role subscription purchase/renewal notifications.
  GuildSystemChannelWithoutRoleSubscriptionPurchaseNotifications
  /// Hides the sticker reply buttons to role subscription purchase/renewal notifications.
  GuildSystemChannelWithoutRoleSubscriptionPurchaseNotificationStickerReplyButtons
}

// TODO: GET RID OF ME! USE ACTUAL APPLICATIONS
pub type Application

pub type GuildRequiredMfaLevel {
  GuildDoesNotRequireMfa
  GuildRequiresMfaForModerationActions
}

pub type GuildFeature {
  GuildCanUseAnimatedBanner
  GuildCanUseAnimatedIcon
  /// Guild uses the [old permission configuration behavior](https://docs.discord.com/developers/change-log#upcoming-application-command-permission-changes).
  GuildUsesOldPermissionConfigurationBehavior
  /// Guild has set up auto-moderation rules.
  /// This does not guarantee that the guild currently has auto-moderation rules set-up.
  GuildCreatedAutoModerationRules
  GuildCanUseBanner
  /// Guild can use the welcome screen, Membership Screening, stage channels, and server discovery and receives community updates.
  GuildIsCommunity
  GuildUsesMonetization
  GuildUsesRoleSubscriptionPromoPage
  /// Guild has been set as a support server on the App Directory.
  GuildIsDeveloperSupportServer
  /// Guild can be discovered in the discovery tab.
  GuildIsDiscoverable
  /// Guild can be featured in the discovery tab.
  GuildIsFeaturable
  /// Guild has currently paused invites as an anti-raid measure.
  GuildHasPausedInvites
  GuildCanUseInviteSplash
  GuildUsesMembershipScreening
  GuildHasMoreSoundboardSoundSlots
  GuildHasMoreStickerSlots
  GuildCanCreateAnnouncementChannels
  /// Guild is partnered with Discord.
  GuildIsPartnered
  GuildCanBePreviewed
  GuildDisabledRaidAlerts
  GuildCanUseRoleIcons
  GuildHasPurchasableRoleSubscriptions
  GuildUsesRoleSubscriptions
  /// Guild has created soundboard sounds.
  /// This does not guarantee that the guild currently has any soundboard sounds.
  GuildCreatedSoundboardSounds
  GuildUsesTicketedEvents
  GuildCanUseVanityUrl
  /// Guild is verified by Discord.
  GuildIsVerified
  GuildCanUse384KbpsVoiceBitrate
  GuildUsesWelcomeScreen
  GuildCanUseGuestInvites
  GuildCanUseGuildTags
  GuildCanUseEnhancedRoleColours
}

// i love this function - filip
fn guild_features_decoder() -> Decoder(List(GuildFeature)) {
  use strings <- decode.then(decode.list(decode.string))

  strings
  |> list.map(fn(string) {
    case string {
      "ANIMATED_BANNER" -> [GuildCanUseAnimatedBanner]
      "ANIMATED_ICON" -> [GuildCanUseAnimatedIcon]
      "APPLICATION_COMMAND_PERMISSIONS_V2" -> [
        GuildUsesOldPermissionConfigurationBehavior,
      ]
      "AUTO_MODERATION" -> [GuildCreatedAutoModerationRules]
      "BANNER" -> [GuildCanUseBanner]
      "COMMUNITY" -> [GuildIsCommunity]
      "CREATOR_MONETIZABLE_PROVISIONAL" -> [GuildUsesMonetization]
      "CREATOR_STORE_PAGE" -> [GuildUsesRoleSubscriptionPromoPage]
      "DEVELOPER_SUPPORT_SERVER" -> [GuildIsDeveloperSupportServer]
      "DISCOVERABLE" -> [GuildIsDiscoverable]
      "FEATURABLE" -> [GuildIsFeaturable]
      "INVITES_DISABLED" -> [GuildHasPausedInvites]
      "INVITE_SPLASH" -> [GuildCanUseInviteSplash]
      "MEMBER_VERIFICATION_GATE_ENABLED" -> [GuildUsesMembershipScreening]
      "MORE_SOUNDBOARD" -> [GuildHasMoreSoundboardSoundSlots]
      "MORE_STICKERS" -> [GuildHasMoreStickerSlots]
      "NEWS" -> [GuildCanCreateAnnouncementChannels]
      "PARTNERED" -> [GuildIsPartnered]
      "PREVIEW_ENABLED" -> [GuildCanBePreviewed]
      "RAID_ALERTS_DISABLED" -> [GuildDisabledRaidAlerts]
      "ROLE_ICONS" -> [GuildCanUseRoleIcons]
      "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE" -> [
        GuildHasPurchasableRoleSubscriptions,
      ]
      "ROLE_SUBSCRIPTIONS_ENABLED" -> [GuildUsesRoleSubscriptions]
      "SOUNDBOARD" -> [GuildCreatedSoundboardSounds]
      "TICKETED_EVENTS_ENABLED" -> [GuildUsesTicketedEvents]
      "VANITY_URL" -> [GuildCanUseVanityUrl]
      "VIP_REGIONS" -> [GuildCanUse384KbpsVoiceBitrate]
      "WELCOME_SCREEN_ENABLED" -> [GuildUsesWelcomeScreen]
      "GUESTS_ENABLED" -> [GuildCanUseGuestInvites]
      "GUILD_TAGS" -> [GuildCanUseGuildTags]
      "ENHANCED_ROLE_COLORS" -> [GuildCanUseEnhancedRoleColours]
      _ -> []
    }
  })
  |> list.flatten
  |> decode.success
}

// REACTIONS: DO NOT USE THIS OBJECT, IT WILL NOT HAVE THE NAME FIELD
pub type Emoji {
  UnicodeEmoji(character: String)
  CustomEmoji(CustomEmojiData)
  ApplicationEmoji(ApplicationEmojiData)
}

pub type CustomEmojiData {
  CustomEmojiData(
    id: Snowflake(Emoji),
    name: String,
    /// Is `None` if the emoji is not restricted on a per-role basis.
    allowed_roles_ids: Option(List(Snowflake(Role))),
    /// Whether this emoji must be wrapped in colons.
    requires_colons: Bool,
    /// Whether this emoji is managed by an integration.
    is_integration_managed: Bool,
    is_animated: Bool,
    /// May be `False` when a server loses boosts.
    is_available: Bool,
  )
}

pub type ApplicationEmojiData {
  ApplicationEmojiData(
    id: Snowflake(Emoji),
    name: String,
    creator: User,
    /// Is `None` if the emoji is not restricted on a per-role basis.
    allowed_roles_ids: Option(List(Snowflake(Role))),
    /// Whether this emoji must be wrapped in colons.
    requires_colons: Bool,
    /// Whether this emoji is managed by an integration.
    is_integration_managed: Bool,
    is_animated: Bool,
    is_available: Bool,
  )
}

fn emoji_decoder() -> Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(snowflake_decoder()))
  case id {
    None -> {
      use character <- decode.field("name", decode.string)
      decode.success(UnicodeEmoji(character:))
    }
    Some(id) -> {
      use name <- decode.field("name", decode.string)
      use allowed_roles_ids <- decode.optional_field(
        "roles",
        None,
        decode.optional(decode.list(of: snowflake_decoder())),
      )
      use creator <- decode.optional_field(
        "user",
        None,
        decode.optional(user_decoder()),
      )
      use requires_colons <- decode.optional_field(
        "require_colons",
        True,
        decode.bool,
      )
      use is_integration_managed <- decode.optional_field(
        "managed",
        False,
        decode.bool,
      )
      use is_animated <- decode.optional_field("animated", False, decode.bool)
      use is_available <- decode.optional_field("available", True, decode.bool)

      case creator {
        Some(creator) ->
          decode.success(
            ApplicationEmoji(ApplicationEmojiData(
              id:,
              name:,
              creator:,
              allowed_roles_ids:,
              requires_colons:,
              is_integration_managed:,
              is_animated:,
              is_available:,
            )),
          )
        None ->
          decode.success(
            CustomEmoji(CustomEmojiData(
              id:,
              name:,
              allowed_roles_ids:,
              requires_colons:,
              is_integration_managed:,
              is_animated:,
              is_available:,
            )),
          )
      }
    }
  }
}

pub type GuildMemberVerificationLevel {
  /// Access to the guild is unrestricted.
  NoGuildMemberVerification
  /// Access to the guild is granted to those who have verified their email with Discord.
  LowGuildMemberVerification
  /// Access to the guild is granted to those who have been registered on Discord for longer than 5 minutes.
  MediumGuildMemberVerification
  /// Access to the guild is granted to those who have been a member of the guild for longer than 10 minutes.
  HighGuildMemberVerification
  /// Access to the guild is granted to those who have verified their phone number with Discord.
  VeryHighGuildMemberVerification
}

pub type GuildDefaultMessageNotificationSetting {
  /// By default, notifications will be sent for all messages in the guild.
  NotifyForAllMessages
  /// By default, notifications will be sent only for messages in which the user was mentioned.
  NotifyOnlyForMentions
}

pub type GuildExplicitContentFilterSetting {
  /// Media will not be scanned for explicit content.
  GuildExplicitContentFilterDisabled
  /// Only media sent by members who do not have any roles will be scanned for explicit content.
  GuildExplicitContentFilterForMembersWithoutRoles
  /// Media sent by all members will be scanned for explicit content.
  GuildExplicitContentFilterForAllMembers
}
