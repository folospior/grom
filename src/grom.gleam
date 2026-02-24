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
import gleam/time/timestamp.{type Timestamp}
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
pub type RestError(body) {
  CouldNotReceiveResponse(httpc.HttpError)
  ReceivedUnsuccessfulStatusCode(Response(body))
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
    /// The user's banner accent color in RGB hexadecimal format.
    /// Is `None` when the user uses a default color based on avatar.
    accent_color: Option(Int),
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
  use accent_color <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(decode.int),
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
    accent_color:,
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

// TODO: GET RID OF ME, ACTUALLY USE GUILDS
pub type Guild

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
) -> Result(a, RestError(String)) {
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
  response: Response(body),
) -> Result(Response(body), RestError(body)) {
  case status_code.is_successful(response.status) {
    True -> Ok(response)
    False -> Error(ReceivedUnsuccessfulStatusCode(response))
  }
}

fn parse_error_response(
  response: Response(String),
) -> Result(Response(String), RestError(String)) {
  let result =
    response.body
    |> json.parse(using: error_response_decoder())

  case result {
    Ok(error) -> Error(ReceivedErrorResponse(error))
    Error(_) -> Ok(response)
  }
}

pub fn get_current_user(token token: String) -> Result(User, RestError(String)) {
  new_api_request(token:, to: "/users/@me", method: http.Get)
  |> send_request(decode_with: user_decoder())
}

pub fn get_user(
  token token: String,
  id id: Snowflake(User),
) -> Result(User, RestError(String)) {
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
) -> Result(User, RestError(String)) {
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

// TODO: GET RID OF ME! USE ACTUAL ROLES
pub type Role

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
) -> Result(GuildMember, RestError(String)) {
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
) -> Result(Nil, RestError(String)) {
  new_api_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id),
    method: http.Delete,
  )
  |> send_request(decode_with: decode.success(Nil))
}
