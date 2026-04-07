import datebook/weekday.{type Weekday}
import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/function
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import gleam_community/colour.{type Colour}
import json_value
import status_code

const version: String = "v6.0.0"

/// A snowflake is another name for an ID.
/// It is possible to retrieve an object's creation date & time from its snowflake.
pub opaque type Snowflake(a) {
  Snowflake(id: Int)
}

/// An authentication token, required to identify the user (bot) making requests.
/// See [`bot`](#bot) for creating bot tokens.
/// 
/// In the future, this will be extended to also support OAuth2 bearer tokens.
pub opaque type Token {
  BotToken(token: String)
}

/// Creates a token object for a bot.
pub fn bot(token: String) -> Token {
  BotToken(token)
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

fn permissions_decoder() -> Decoder(List(Permission)) {
  use string <- decode.then(decode.string)

  case int.parse(string) {
    Ok(bits) -> {
      bits_permissions()
      |> list.filter_map(fn(item) {
        let #(bit, flag) = item
        case int.bitwise_and(bits, bit) != 0 {
          True -> Ok(flag)
          False -> Error(Nil)
        }
      })
      |> decode.success
    }
    Error(_) -> decode.failure([], "Permission")
  }
}

fn bits_permissions() -> List(#(Int, Permission)) {
  [
    #(int.bitwise_shift_left(1, 0), AllowCreatingInstantInvites),
    #(int.bitwise_shift_left(1, 1), AllowKickingMembers),
    #(int.bitwise_shift_left(1, 2), AllowBanningMembers),
    #(int.bitwise_shift_left(1, 3), AdministratorPermission),
    #(int.bitwise_shift_left(1, 4), AllowManagingChannels),
    #(int.bitwise_shift_left(1, 5), AllowManagingGuild),
    #(int.bitwise_shift_left(1, 6), AllowAddingReactions),
    #(int.bitwise_shift_left(1, 7), AllowViewingAuditLog),
    #(int.bitwise_shift_left(1, 8), AllowPrioritySpeakingInVoiceChannels),
    #(int.bitwise_shift_left(1, 9), AllowStreamingInVoiceChannels),
    #(int.bitwise_shift_left(1, 10), AllowViewingChannels),
    #(int.bitwise_shift_left(1, 11), AllowSendingMessages),
    #(int.bitwise_shift_left(1, 12), AllowSendingTtsMessages),
    #(int.bitwise_shift_left(1, 13), AllowManagingMessages),
    #(int.bitwise_shift_left(1, 14), AutoEmbedLinksPermission),
    #(int.bitwise_shift_left(1, 15), AllowAttachingFiles),
    #(int.bitwise_shift_left(1, 16), AllowReadingMessageHistory),
    #(int.bitwise_shift_left(1, 17), AllowMentioningEveryone),
    #(int.bitwise_shift_left(1, 18), AllowUsingExternalEmojis),
    #(int.bitwise_shift_left(1, 19), AllowViewingGuildInsights),
    #(int.bitwise_shift_left(1, 20), AllowConnectingToVoiceChannels),
    #(int.bitwise_shift_left(1, 21), AllowSpeakingInVoiceChannels),
    #(int.bitwise_shift_left(1, 22), AllowMutingMembersInVoiceChannels),
    #(int.bitwise_shift_left(1, 23), AllowDeafeningMembersInVoiceChannels),
    #(int.bitwise_shift_left(1, 24), AllowMovingMembersBetweenVoiceChannels),
    #(int.bitwise_shift_left(1, 25), AllowUsingVoiceActivityDetection),
    #(int.bitwise_shift_left(1, 26), AllowChangingOwnNickname),
    #(int.bitwise_shift_left(1, 27), AllowManagingNicknames),
    #(int.bitwise_shift_left(1, 28), AllowManagingRoles),
    #(int.bitwise_shift_left(1, 29), AllowManagingWebhooks),
    #(int.bitwise_shift_left(1, 30), AllowManagingGuildExpressions),
    #(int.bitwise_shift_left(1, 31), AllowUsingCommands),
    #(int.bitwise_shift_left(1, 32), AllowRequestingToSpeakInStageChannels),
    #(int.bitwise_shift_left(1, 33), AllowManagingEvents),
    #(int.bitwise_shift_left(1, 34), AllowManagingThreads),
    #(int.bitwise_shift_left(1, 35), AllowCreatingPublicThreads),
    #(int.bitwise_shift_left(1, 36), AllowCreatingPrivateThreads),
    #(int.bitwise_shift_left(1, 37), AllowUsingExternalStickers),
    #(int.bitwise_shift_left(1, 38), AllowSendingMessagesInThreads),
    #(int.bitwise_shift_left(1, 39), AllowUsingEmbeddedActivities),
    #(int.bitwise_shift_left(1, 40), AllowModeratingMembers),
    #(int.bitwise_shift_left(1, 41), AllowViewingCreatorMonetizationAnalytics),
    #(int.bitwise_shift_left(1, 42), AllowUsingSoundboard),
    #(int.bitwise_shift_left(1, 43), AllowCreatingGuildExpressions),
    #(int.bitwise_shift_left(1, 44), AllowCreatingEvents),
    #(int.bitwise_shift_left(1, 45), AllowUsingExternalSoundboardSounds),
    #(int.bitwise_shift_left(1, 46), AllowSendingVoiceMessages),
    #(int.bitwise_shift_left(1, 49), AllowSendingPolls),
    #(int.bitwise_shift_left(1, 50), AllowUsingExternalApplications),
    #(int.bitwise_shift_left(1, 51), AllowPinningMessages),
    #(int.bitwise_shift_left(1, 52), AllowBypassingSlowmode),
  ]
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
  flags
  |> flags_to_int(bits_flags)
  |> json.int
}

fn permissions_to_json(permissions: List(Permission)) -> Json {
  permissions
  |> flags_to_int(bits_permissions())
  |> int.to_string
  |> json.string
}

pub type User {
  User(
    id: Snowflake(User),
    username: String,
    /// Mostly deprecated. Only bots have discriminators nowadays.
    /// 
    /// Users will very likely have their discriminator set to `0`.
    /// 
    /// Used in the past when usernames weren't user-specific.
    /// 
    /// Doesn't include the `#` prefix.
    discriminator: String,
    /// Also called a display name.
    /// 
    /// Is `None` when the user doesn't have a global name, and rather uses their username as their display name.
    global_name: Option(String),
    /// Is `None` when the user uses a default avatar.
    avatar_hash: Option(ImageHash),
    /// Whether the user is a bot user.
    is_bot: Bool,
    /// Whether the user is Discord's official system account.
    is_system: Bool,
    /// Is `None` if it isn't known whether the user has enabled MFA.
    /// 
    /// MFA = multi-factor authentication.
    has_mfa_enabled: Option(Bool),
    /// Is `None` when the user doesn't use a custom banner.
    banner_hash: Option(ImageHash),
    /// The user's banner accent colour in RGB hexadecimal format.
    /// 
    /// Is `None` when the user uses a default color based on avatar.
    accent_colour: Option(Colour),
    /// The user's chosen locale.
    /// 
    /// Discord hasn't disclosed when this field could be `None`. 
    locale: Option(Locale),
    /// The user's banner accent color in RGB hexadecimal format.
    /// 
    /// Is `None` when the user uses a default color based on avatar.
    accent_color: Option(Int),
    flags: List(UserFlag),
    /// Is `None` if the user's premium type isn't known.
    premium_type: Option(UserPremiumType),
    /// Publicly visible flags - aka Discord badges.
    /// 
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
  use accent_color <- decode.optional_field(
    "accent_color",
    None,
    decode.optional(decode.int),
  )
  use locale <- decode.optional_field(
    "locale",
    None,
    decode.optional(locale_decoder()),
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

fn new_request(
  token token: Token,
  to path: String,
  method method: http.Method,
) -> Request(String) {
  let token = case token {
    BotToken(token) -> "Bot " <> token
  }

  request.new()
  |> request.set_scheme(http.Https)
  |> request.set_host(discord_api_url)
  |> request.set_path(discord_api_path <> path)
  |> request.set_method(method)
  |> request.prepend_header("authorization", token)
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
  // If the response isn't erroneous - check if the response has a successful status code.
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
  // If the response isn't erroneous - check if the response has a successful status code.
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
    /// This contains a JSON string that is best not parsed. I recommend just printing/logging it if needed.
    /// It contains detailed information regarding what error happened.
    /// It would be nearly impossible to properly parse it. It is also sometimes absent from the response.
    errors: Option(String),
  )
}

fn error_response_decoder() -> Decoder(ErrorResponse) {
  use code <- decode.field("code", decode.int)
  use message <- decode.field("message", decode.string)
  use errors <- decode.optional_field(
    "errors",
    None,
    decode.optional(decode.map(json_value.decoder(), json_value.to_string)),
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

pub fn get_current_user(token token: Token) -> Result(User, RestError) {
  new_request(token:, to: "/users/@me", method: http.Get)
  |> send_request(decode_with: user_decoder())
}

pub fn get_user(
  token token: Token,
  id id: Snowflake(User),
) -> Result(User, RestError) {
  new_request(
    token:,
    to: "/users/" <> snowflake_to_string(id),
    method: http.Get,
  )
  |> send_request(decode_with: user_decoder())
}

/// This type is used to differentiate between the ways of modifying an object.
/// Some parts of an object can be changed to a different value, but not deleted - for this, grom uses the Option type.
/// Other parts can be changed to a different value or deleted - for this, grom uses the Modification type.
/// 
/// The default behavior of modify functions is to not modify anything - for options: `None`, for modifications: `Skip`
type Modification(a) {
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

/// Look into the `(new_)modify_current_user_*` functions to use this type using a builder pattern.
pub opaque type ModifyCurrentUser {
  ModifyCurrentUser(
    username: Option(String),
    avatar: Modification(ImageData),
    banner: Modification(ImageData),
  )
}

pub fn modify_current_user(
  token token: Token,
  using modify: ModifyCurrentUser,
) -> Result(User, RestError) {
  let body = modify |> modify_current_user_to_json |> json.to_string

  new_request(token:, to: "/users/@me", method: http.Patch)
  |> request.set_body(body)
  |> send_request(decode_with: user_decoder())
}

pub fn new_modify_current_user() -> ModifyCurrentUser {
  ModifyCurrentUser(None, Skip, Skip)
}

/// May cause the discriminator to randomize if changed (mostly applies to bots).
pub fn modify_current_user_username(
  modify: ModifyCurrentUser,
  new username: String,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, username: Some(username))
}

pub fn modify_current_user_avatar(
  modify: ModifyCurrentUser,
  new avatar: ImageData,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, avatar: Modify(avatar))
}

pub fn delete_current_user_avatar(
  modify: ModifyCurrentUser,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, avatar: Delete)
}

pub fn modify_current_user_banner(
  modify: ModifyCurrentUser,
  new banner: ImageData,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, banner: Modify(banner))
}

pub fn delete_current_user_banner(
  modify: ModifyCurrentUser,
) -> ModifyCurrentUser {
  ModifyCurrentUser(..modify, banner: Delete)
}

fn modify_current_user_to_json(modify: ModifyCurrentUser) -> Json {
  [
    optional_to_json(modify.username, "username", json.string),
    modification_to_json(modify.avatar, "avatar", image_data_to_json),
    modification_to_json(modify.banner, "banner", image_data_to_json),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

fn modification_to_json(
  modification: Modification(a),
  key: String,
  success_encoder: fn(a) -> Json,
) -> Result(#(String, Json), Nil) {
  case modification {
    Modify(value) -> Ok(#(key, success_encoder(value)))
    Delete -> Ok(#(key, json.null()))
    Skip -> Error(Nil)
  }
}

pub type Role {
  Role(
    id: Snowflake(Role),
    name: String,
    colours: RoleColours,
    /// Whether the role is pinned in the guild user list.
    is_hoisted: Bool,
    icon_hash: Option(ImageHash),
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
    /// Is `None` if the role isn't a bot's role.
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

fn role_decoder() -> Decoder(Role) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use colours <- decode.field("colors", role_colours_decoder())
  use is_hoisted <- decode.field("hoist", decode.bool)
  use icon_hash <- decode.optional_field(
    "icon",
    None,
    decode.optional(image_hash_decoder()),
  )
  use unicode_emoji <- decode.optional_field(
    "unicode_emoji",
    None,
    decode.optional(decode.string),
  )
  use position <- decode.field("position", decode.int)
  use permissions <- decode.field("permissions", permissions_decoder())
  use is_integration_managed <- decode.field("managed", decode.bool)
  use is_mentionable <- decode.field("mentionable", decode.bool)
  use bot_id <- decode.then(decode.optionally_at(
    ["tags", "bot_id"],
    None,
    decode.optional(snowflake_decoder()),
  ))
  use integration_id <- decode.then(decode.optionally_at(
    ["tags", "integration_id"],
    None,
    decode.optional(snowflake_decoder()),
  ))
  // this is weird, but essentially, in this case:
  // - absent == False
  // - null == True
  // so i use False as the absent value, and then just accept anything if it's present and return True
  use is_booster_role <- decode.then(decode.optionally_at(
    ["tags", "premium_subscriber"],
    False,
    decode.success(True),
  ))
  use subscription_listing_id <- decode.then(decode.optionally_at(
    ["tags", "subscription_listing_id"],
    None,
    decode.optional(snowflake_decoder()),
  ))
  use is_available_for_purchase <- decode.then(decode.optionally_at(
    ["tags", "available_for_purchase"],
    False,
    decode.success(True),
  ))
  use is_linked_role <- decode.then(decode.optionally_at(
    ["tags", "guild_connections"],
    False,
    decode.success(True),
  ))
  use flags <- decode.field("flags", flags_decoder(bits_role_flags()))
  decode.success(Role(
    id:,
    name:,
    colours:,
    is_hoisted:,
    icon_hash:,
    unicode_emoji:,
    position:,
    permissions:,
    is_integration_managed:,
    is_mentionable:,
    bot_id:,
    integration_id:,
    is_booster_role:,
    subscription_listing_id:,
    is_available_for_purchase:,
    is_linked_role:,
    flags:,
  ))
}

pub type RoleFlag {
  RoleCanBeSelectedInOnboardingPrompt
}

fn bits_role_flags() -> List(#(Int, RoleFlag)) {
  [#(int.bitwise_shift_left(1, 0), RoleCanBeSelectedInOnboardingPrompt)]
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
  /// Allows deleting and archiving threads, and viewing all public and private threads.
  AllowManagingThreads
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

fn colour_to_json(colour: Colour) -> Json {
  colour
  |> colour.to_rgb_hex
  |> json.int
}

fn role_colours_to_json(role_colours: RoleColours) -> Json {
  let RoleColours(primary_colour:, secondary_colour:, tertiary_colour:) =
    role_colours
  json.object([
    #("primary_color", colour_to_json(primary_colour)),
    #("secondary_color", json.nullable(secondary_colour, colour_to_json)),
    #("tertiary_color", json.nullable(tertiary_colour, colour_to_json)),
  ])
}

fn role_colours_decoder() -> Decoder(RoleColours) {
  use primary_colour <- decode.field("primary_color", hex_colour_decoder())
  use secondary_colour <- decode.field(
    "secondary_color",
    decode.optional(hex_colour_decoder()),
  )
  use tertiary_colour <- decode.field(
    "tertiary_color",
    decode.optional(hex_colour_decoder()),
  )
  decode.success(RoleColours(
    primary_colour:,
    secondary_colour:,
    tertiary_colour:,
  ))
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
  token token: Token,
  for guild_id: Snowflake(Guild),
) -> Result(GuildMember, RestError) {
  new_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id) <> "/member",
    method: http.Get,
  )
  |> send_request(decode_with: guild_member_decoder())
}

pub fn leave_guild(
  token token: Token,
  with_id guild_id: Snowflake(Guild),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id),
    method: http.Delete,
  )
  |> send_no_content_request
}

pub type Channel {
  Channel(id: Snowflake(Channel), data: ChannelData)
}

pub type ChannelData {
  ChannelGuild(GuildChannel)
  ChannelDm(DmChannel)
  ChannelThread(Thread)
}

pub type Thread {
  Thread(
    id: Snowflake(Thread),
    type_: ThreadType,
    /// Is `None` in some gateway events.
    guild_id: Option(Snowflake(Guild)),
    name: String,
    /// Is `None` if there are no messages in the channel.
    last_message_id: Option(Snowflake(Message)),
    /// The amount of time between a user has to wait between sending a message or creating a thread.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    parent_id: Snowflake(GuildChannel),
    /// Number of messages in the thread, not including the initial message or deleted messages.
    ///
    /// Inaccurate for threads created before July 1st, 2022 if they have more than 50 messages.
    message_count: Int,
    /// Stops counting at 50.
    approximate_member_count: Int,
    /// OP's ID.
    owner_id: Snowflake(User),
    is_archived: Bool,
    /// Time of inactivity after which the thread will be automatically archived.
    auto_archive_duration: ThreadAutoArchiveDuration,
    /// Time when the thread's archive status was last changed at.
    last_archive_status_change_at: Timestamp,
    /// If a thread is locked, only users with the `AllowManagingThreads` permission will be able to unarchive it.
    is_locked: Bool,
    /// Whether non-moderators can add other non-moderators to the thread.
    ///
    /// Always `True` on non-private threads. Varies depending on setting in private threads.
    is_invitable: Bool,
    /// Is `None` if the thread was created before September 1st, 2022.
    created_at: Option(Timestamp),
    flags: List(ThreadFlag),
    /// Similar to `message_count`, except it won't decrement when a message is deleted.
    total_message_count: Int,
    /// IDs of the tags that are applied to this thread.
    applied_tags_ids: List(Snowflake(ForumTag)),
  )
}

fn thread_decoder() -> Decoder(Thread) {
  use id <- decode.field("id", snowflake_decoder())
  use type_ <- decode.field("type", thread_type_decoder())
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use name <- decode.field("name", decode.string)
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use parent_id <- decode.field("parent_id", snowflake_decoder())
  use message_count <- decode.field("message_count", decode.int)
  use approximate_member_count <- decode.field("member_count", decode.int)
  use owner_id <- decode.field("owner_id", snowflake_decoder())
  use is_archived <- decode.subfield(
    ["thread_metadata", "archived"],
    decode.bool,
  )
  use auto_archive_duration <- decode.subfield(
    ["thread_metadata", "auto_archive_duration"],
    thread_auto_archive_duration_decoder(),
  )
  use last_archive_status_change_at <- decode.subfield(
    ["thread_metadata", "archive_timestamp"],
    rfc3339_decoder(),
  )
  use is_locked <- decode.subfield(["thread_metadata", "locked"], decode.bool)
  use is_invitable <- decode.then(decode.optionally_at(
    ["thread_metadata", "invitable"],
    True,
    decode.bool,
  ))
  use created_at <- decode.then(decode.optionally_at(
    ["thread_metadata", "create_timestamp"],
    None,
    decode.optional(rfc3339_decoder()),
  ))
  use flags <- decode.optional_field(
    "flags",
    [],
    flags_decoder(bits_thread_flags()),
  )
  use total_message_count <- decode.field("total_message_count", decode.int)
  use applied_tags_ids <- decode.field(
    "applied_tags",
    decode.list(snowflake_decoder()),
  )
  decode.success(Thread(
    id:,
    type_:,
    guild_id:,
    name:,
    last_message_id:,
    rate_limit_per_user:,
    parent_id:,
    message_count:,
    approximate_member_count:,
    owner_id:,
    is_archived:,
    auto_archive_duration:,
    last_archive_status_change_at:,
    is_locked:,
    is_invitable:,
    created_at:,
    flags:,
    total_message_count:,
    applied_tags_ids:,
  ))
}

fn thread_type_decoder() -> Decoder(ThreadType) {
  use variant <- decode.then(decode.int)
  case variant {
    10 -> decode.success(AnnouncementThread)
    11 -> decode.success(PublicThread)
    12 -> decode.success(PrivateThread)
    _ -> decode.failure(AnnouncementThread, "ThreadType")
  }
}

pub type ForumTag {
  ForumTag(
    id: Snowflake(ForumTag),
    name: String,
    /// Whether this tag can only be added/removed from threads by a member with the `AllowManagingThreads` permission.
    is_moderated: Bool,
    emoji: ForumTagEmoji,
  )
}

fn forum_tag_to_json(forum_tag: ForumTag) -> Json {
  let ForumTag(id:, name:, is_moderated:, emoji:) = forum_tag
  json.object([
    #("id", snowflake_to_json(id)),
    #("name", json.string(name)),
    #("moderated", json.bool(is_moderated)),
    #("emoji", forum_tag_emoji_to_json(emoji)),
  ])
}

pub type ForumTagEmoji {
  StandardForumTagEmoji(character: String)
  CustomForumTagEmoji(id: Snowflake(CustomEmoji))
}

fn forum_tag_decoder() -> Decoder(ForumTag) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use is_moderated <- decode.field("moderated", decode.bool)
  use emoji <- decode.then(
    decode.one_of(
      {
        use emoji_id <- decode.field("emoji_id", snowflake_decoder())
        decode.success(CustomForumTagEmoji(id: emoji_id))
      },
      or: [
        {
          use character <- decode.field("emoji_name", decode.string)
          decode.success(StandardForumTagEmoji(character:))
        },
      ],
    ),
  )
  decode.success(ForumTag(id:, name:, is_moderated:, emoji:))
}

pub type ThreadFlag {
  /// The thread is pinned on top of its parent Forum or Media channel.
  ThreadIsPinned
}

fn bits_thread_flags() -> List(#(Int, ThreadFlag)) {
  [#(int.bitwise_shift_left(1, 1), ThreadIsPinned)]
}

pub fn guild_channel_id_to_channel_id(
  id: Snowflake(GuildChannel),
) -> Snowflake(Channel) {
  Snowflake(id.id)
}

pub fn category_channel_id_to_channel_id(
  id: Snowflake(CategoryChannel),
) -> Snowflake(Channel) {
  Snowflake(id.id)
}

pub type ThreadType {
  AnnouncementThread
  PublicThread
  PrivateThread
}

pub type GuildChannel {
  GuildChannel(
    id: Snowflake(GuildChannel),
    data: GuildChannelData,
    permission_overwrites: List(PermissionOverwrite),
    /// Is `None` in some gateway events.
    guild_id: Option(Snowflake(Guild)),
    /// Channels with the same position are sorted by ID.
    position: Int,
    name: String,
  )
}

fn guild_channel_decoder() -> Decoder(GuildChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use data <- decode.then(guild_channel_data_decoder())
  use permission_overwrites <- decode.optional_field(
    "permission_overwrites",
    [],
    decode.list(permission_overwrite_decoder()),
  )
  use guild_id <- decode.optional_field(
    "guild_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use position <- decode.field("position", decode.int)
  use name <- decode.field("name", decode.string)
  decode.success(GuildChannel(
    id:,
    data:,
    permission_overwrites:,
    guild_id:,
    position:,
    name:,
  ))
}

pub type GuildChannelData {
  ChannelText(TextChannel)
  ChannelVoice(VoiceChannel)
  ChannelCategory(CategoryChannel)
  ChannelAnnouncement(AnnouncementChannel)
  ChannelStage(StageChannel)
  ChannelForum(ForumChannel)
  ChannelMedia(MediaChannel)
}

fn guild_channel_data_decoder() -> Decoder(GuildChannelData) {
  use type_ <- decode.field("type", decode.int)

  case type_ {
    0 -> decode.map(text_channel_decoder(), ChannelText)
    2 -> decode.map(voice_channel_decoder(), ChannelVoice)
    4 -> decode.map(category_channel_decoder(), ChannelCategory)
    5 -> decode.map(announcement_channel_decoder(), ChannelAnnouncement)
    13 -> decode.map(stage_channel_decoder(), ChannelStage)
    15 -> decode.map(forum_channel_decoder(), ChannelForum)
    16 -> decode.map(media_channel_decoder(), ChannelMedia)
    _ ->
      decode.failure(
        ChannelCategory(CategoryChannel(Snowflake(0))),
        "GuildChannelData",
      )
  }
}

pub type TextChannel {
  TextChannel(
    id: Snowflake(TextChannel),
    topic: Option(String),
    is_nsfw: Bool,
    /// Is `None` if there are no messages in the channel.
    last_message_id: Option(Snowflake(Message)),
    /// The amount of time between a user has to wait between sending a message or creating a thread.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    /// Is `None` in some gateway events and if there are no pinned messages.
    last_pin_timestamp: Option(Timestamp),
    default_thread_auto_archive_duration: ThreadAutoArchiveDuration,
    default_thread_rate_limit_per_user: Duration,
    /// Is `None` if the channel isn't in a category.
    parent_id: Option(Snowflake(CategoryChannel)),
  )
}

fn text_channel_decoder() -> Decoder(TextChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use topic <- decode.optional_field(
    "topic",
    None,
    decode.optional(decode.string),
  )
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use last_pin_timestamp <- decode.optional_field(
    "last_pin_timestamp",
    None,
    decode.optional(rfc3339_decoder()),
  )
  use default_thread_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    thread_auto_archive_duration_decoder(),
  )
  use default_thread_rate_limit_per_user <- decode.field(
    "default_thread_rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  decode.success(TextChannel(
    id:,
    topic:,
    is_nsfw:,
    last_message_id:,
    rate_limit_per_user:,
    last_pin_timestamp:,
    default_thread_auto_archive_duration:,
    default_thread_rate_limit_per_user:,
    parent_id:,
  ))
}

pub type DmChannel {
  DmChannel(
    id: Snowflake(DmChannel),
    /// Is `None` if there are no messages in the channel.
    last_message_id: Option(Snowflake(Message)),
    recipient: User,
    /// Is `None` in some gateway events and if there are no pinned messages.
    last_pin_timestamp: Option(Timestamp),
  )
}

pub type VoiceChannel {
  VoiceChannel(
    id: Snowflake(VoiceChannel),
    is_nsfw: Bool,
    /// Is `None` if no messages have been sent in the voice channel adjacent text channel.
    last_message_id: Option(Snowflake(Message)),
    /// Bitrate in bits per second.
    bitrate: Int,
    user_limit: Option(Int),
    /// The amount of time between a user has to wait between sending a message in the voice channel adjacent text channel.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    /// Voice Region ID for the voice channel.
    /// Automatically assigned if `None`.
    rtc_region_id: Option(String),
    video_quality_mode: VideoQualityMode,
    /// Is `None` if the channel isn't in a category.
    parent_id: Option(Snowflake(CategoryChannel)),
  )
}

fn voice_channel_decoder() -> Decoder(VoiceChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )

  use bitrate <- decode.field("bitrate", decode.int)
  use user_limit <- decode.optional_field(
    "user_limit",
    None,
    decode.optional(decode.int),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use rtc_region_id <- decode.optional_field(
    "rtc_region",
    None,
    decode.optional(decode.string),
  )
  use video_quality_mode <- decode.field(
    "video_quality_mode",
    video_quality_mode_decoder(),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  decode.success(VoiceChannel(
    id:,
    is_nsfw:,
    last_message_id:,
    bitrate:,
    user_limit:,
    rate_limit_per_user:,
    rtc_region_id:,
    video_quality_mode:,
    parent_id:,
  ))
}

pub type VideoQualityMode {
  AutomaticVideoQuality
  /// 720p
  HdVideoQuality
}

fn video_quality_mode_to_json(video_quality_mode: VideoQualityMode) -> Json {
  case video_quality_mode {
    AutomaticVideoQuality -> json.int(1)
    HdVideoQuality -> json.int(2)
  }
}

fn video_quality_mode_decoder() -> Decoder(VideoQualityMode) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(AutomaticVideoQuality)
    2 -> decode.success(HdVideoQuality)
    _ -> decode.failure(AutomaticVideoQuality, "VideoQualityMode")
  }
}

pub type ThreadAutoArchiveDuration {
  ArchiveThreadAfter1Hour
  ArchiveThreadAfter1Day
  ArchiveThreadAfter3Days
  ArchiveThreadAfter7Days
}

fn thread_auto_archive_duration_to_json(
  thread_auto_archive_duration: ThreadAutoArchiveDuration,
) -> Json {
  case thread_auto_archive_duration {
    ArchiveThreadAfter1Hour -> json.int(60)
    ArchiveThreadAfter1Day -> json.int(1440)
    ArchiveThreadAfter3Days -> json.int(4320)
    ArchiveThreadAfter7Days -> json.int(10_080)
  }
}

fn thread_auto_archive_duration_decoder() -> Decoder(ThreadAutoArchiveDuration) {
  use variant <- decode.then(decode.int)
  case variant {
    60 -> decode.success(ArchiveThreadAfter1Hour)
    1440 -> decode.success(ArchiveThreadAfter1Day)
    4320 -> decode.success(ArchiveThreadAfter3Days)
    10_080 -> decode.success(ArchiveThreadAfter7Days)
    _ -> decode.failure(ArchiveThreadAfter1Hour, "ThreadAutoArchiveDuration")
  }
}

pub type CategoryChannel {
  CategoryChannel(id: Snowflake(CategoryChannel))
}

fn category_channel_decoder() -> Decoder(CategoryChannel) {
  use id <- decode.field("id", snowflake_decoder())
  decode.success(CategoryChannel(id:))
}

pub type AnnouncementChannel {
  AnnouncementChannel(
    id: Snowflake(AnnouncementChannel),
    topic: Option(String),
    is_nsfw: Bool,
    /// Is `None` if there are no messages in the channel.
    last_message_id: Option(Snowflake(Message)),
    /// Is `None` in some gateway events and if there are no pinned messages.
    last_pin_timestamp: Option(Timestamp),
    default_thread_auto_archive_duration: ThreadAutoArchiveDuration,
    /// Is `None` if the channel isn't in a category.
    parent_id: Option(Snowflake(CategoryChannel)),
  )
}

fn announcement_channel_decoder() -> Decoder(AnnouncementChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use topic <- decode.optional_field(
    "topic",
    None,
    decode.optional(decode.string),
  )
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use last_pin_timestamp <- decode.optional_field(
    "last_pin_timestamp",
    None,
    decode.optional(rfc3339_decoder()),
  )
  use default_thread_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    thread_auto_archive_duration_decoder(),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  decode.success(AnnouncementChannel(
    id:,
    topic:,
    is_nsfw:,
    last_message_id:,
    last_pin_timestamp:,
    default_thread_auto_archive_duration:,
    parent_id:,
  ))
}

pub type StageChannel {
  StageChannel(
    id: Snowflake(StageChannel),
    is_nsfw: Bool,
    /// Is `None` if no messages have been sent in the stage channel adjacent text channel.
    last_message_id: Option(Snowflake(Message)),
    /// Bitrate in bits per second.
    bitrate: Int,
    user_limit: Option(Int),
    /// The amount of time between a user has to wait between sending a message in the stage channel adjacent text channel.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    /// Voice Region ID for the voice channel.
    /// Automatically assigned if `None`.
    rtc_region_id: Option(String),
    video_quality_mode: VideoQualityMode,
    /// Is `None` if the channel isn't in a category.
    parent_id: Option(Snowflake(CategoryChannel)),
  )
}

fn stage_channel_decoder() -> Decoder(StageChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use is_nsfw <- decode.field("nsfw", decode.bool)
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use bitrate <- decode.field("bitrate", decode.int)
  use user_limit <- decode.optional_field(
    "user_limit",
    None,
    decode.optional(decode.int),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use rtc_region_id <- decode.optional_field(
    "rtc_region",
    None,
    decode.optional(decode.string),
  )
  use video_quality_mode <- decode.field(
    "video_quality_mode",
    video_quality_mode_decoder(),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  decode.success(StageChannel(
    id:,
    is_nsfw:,
    last_message_id:,
    bitrate:,
    user_limit:,
    rtc_region_id:,
    rate_limit_per_user:,
    video_quality_mode:,
    parent_id:,
  ))
}

pub fn thread_id_to_channel_id(id: Snowflake(Thread)) -> Snowflake(Channel) {
  Snowflake(id.id)
}

pub type ForumChannel {
  ForumChannel(
    id: Snowflake(ForumChannel),
    topic: Option(String),
    /// The amount of time between a user has to wait between creating threads.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    last_thread_id: Option(Snowflake(Thread)),
    parent_id: Option(Snowflake(CategoryChannel)),
    default_thread_auto_archive_duration: ThreadAutoArchiveDuration,
    flags: List(ForumChannelFlag),
    available_tags: List(ForumTag),
    default_reaction: Option(DefaultForumReaction),
    default_thread_rate_limit_per_user: Duration,
    default_sort_order: ForumSortOrder,
    default_layout: ForumLayout,
  )
}

fn forum_channel_decoder() -> Decoder(ForumChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use topic <- decode.optional_field(
    "topic",
    None,
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use last_thread_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use default_thread_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    thread_auto_archive_duration_decoder(),
  )
  use flags <- decode.field("flags", flags_decoder(bits_forum_channel_flags()))
  use available_tags <- decode.field(
    "available_tags",
    decode.list(forum_tag_decoder()),
  )
  use default_reaction <- decode.optional_field(
    "default_reaction_emoji",
    None,
    decode.optional(default_forum_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.field(
    "default_thread_rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    forum_sort_order_decoder(),
  )
  use default_layout <- decode.field(
    "default_forum_layout",
    forum_layout_decoder(),
  )
  decode.success(ForumChannel(
    id:,
    topic:,
    rate_limit_per_user:,
    last_thread_id:,
    parent_id:,
    default_thread_auto_archive_duration:,
    flags:,
    available_tags:,
    default_reaction:,
    default_thread_rate_limit_per_user:,
    default_sort_order:,
    default_layout:,
  ))
}

pub type MediaChannel {
  MediaChannel(
    id: Snowflake(MediaChannel),
    topic: Option(String),
    /// The amount of time between a user has to wait between creating threads.
    /// 
    /// Between 0 and 21600 seconds.
    ///
    /// Bots and members with the `AllowBypassingSlowmode` permission are exempt from slowmode.
    rate_limit_per_user: Duration,
    last_thread_id: Option(Snowflake(Thread)),
    parent_id: Option(Snowflake(CategoryChannel)),
    default_thread_auto_archive_duration: ThreadAutoArchiveDuration,
    flags: List(MediaChannelFlag),
    available_tags: List(ForumTag),
    default_reaction: Option(DefaultForumReaction),
    default_thread_rate_limit_per_user: Duration,
    default_sort_order: ForumSortOrder,
  )
}

fn media_channel_decoder() -> Decoder(MediaChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use topic <- decode.optional_field(
    "topic",
    None,
    decode.optional(decode.string),
  )
  use rate_limit_per_user <- decode.field(
    "rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use last_thread_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use parent_id <- decode.optional_field(
    "parent_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use default_thread_auto_archive_duration <- decode.field(
    "default_auto_archive_duration",
    thread_auto_archive_duration_decoder(),
  )
  use flags <- decode.field("flags", flags_decoder(bits_media_channel_flags()))
  use available_tags <- decode.field(
    "available_tags",
    decode.list(forum_tag_decoder()),
  )
  use default_reaction <- decode.field(
    "default_reaction_emoji",
    decode.optional(default_forum_reaction_decoder()),
  )
  use default_thread_rate_limit_per_user <- decode.field(
    "default_thread_rate_limit_per_user",
    decode.map(decode.int, duration.seconds),
  )
  use default_sort_order <- decode.field(
    "default_sort_order",
    forum_sort_order_decoder(),
  )
  decode.success(MediaChannel(
    id:,
    topic:,
    rate_limit_per_user:,
    last_thread_id:,
    parent_id:,
    default_thread_auto_archive_duration:,
    flags:,
    available_tags:,
    default_reaction:,
    default_thread_rate_limit_per_user:,
    default_sort_order:,
  ))
}

pub type ForumLayout {
  /// An admin hasn't specified a default forum layout.
  ForumLayoutUnspecified
  ListForumLayout
  GalleryForumLayout
}

fn forum_layout_to_json(layout: ForumLayout) -> Json {
  json.int(case layout {
    ForumLayoutUnspecified -> 0
    ListForumLayout -> 1
    GalleryForumLayout -> 2
  })
}

fn forum_layout_decoder() -> Decoder(ForumLayout) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(ForumLayoutUnspecified)
    1 -> decode.success(ListForumLayout)
    2 -> decode.success(GalleryForumLayout)
    _ -> decode.failure(ForumLayoutUnspecified, "ForumLayout")
  }
}

pub type ForumSortOrder {
  ForumSortOrderUnspecified
  SortForumPostsByActivity
  /// From newest to oldest
  SortForumPostsByCreationTime
}

fn forum_sort_order_decoder() -> Decoder(ForumSortOrder) {
  use variant <- decode.then(decode.optional(decode.int))
  case variant {
    Some(0) -> decode.success(SortForumPostsByActivity)
    Some(1) -> decode.success(SortForumPostsByCreationTime)
    None -> decode.success(ForumSortOrderUnspecified)
    _ -> decode.failure(ForumSortOrderUnspecified, "ForumSortOrder")
  }
}

fn forum_sort_order_to_json(order: ForumSortOrder) -> Json {
  case order {
    ForumSortOrderUnspecified -> json.null()
    SortForumPostsByActivity -> json.int(0)
    SortForumPostsByCreationTime -> json.int(1)
  }
}

pub type ForumChannelFlag {
  ForumChannelRequiresTags
}

fn bits_forum_channel_flags() -> List(#(Int, ForumChannelFlag)) {
  [#(int.bitwise_shift_left(1, 4), ForumChannelRequiresTags)]
}

pub type MediaChannelFlag {
  MediaChannelRequiresTags
  MediaChannelHidesMediaDownloadOptions
}

fn bits_media_channel_flags() -> List(#(Int, MediaChannelFlag)) {
  [
    #(int.bitwise_shift_left(1, 4), MediaChannelRequiresTags),
    #(int.bitwise_shift_left(1, 15), MediaChannelHidesMediaDownloadOptions),
  ]
}

pub type DefaultForumReaction {
  CustomDefaultForumReaction(id: Snowflake(CustomEmoji))
  StandardDefaultForumReaction(character: String)
}

fn default_forum_reaction_decoder() -> Decoder(DefaultForumReaction) {
  decode.one_of(
    {
      use id <- decode.field("emoji_id", snowflake_decoder())
      decode.success(CustomDefaultForumReaction(id:))
    },
    or: [
      {
        use character <- decode.field("emoji_name", decode.string)
        decode.success(StandardDefaultForumReaction(character:))
      },
    ],
  )
}

fn default_forum_reaction_to_json(reaction: DefaultForumReaction) -> Json {
  json.object([
    case reaction {
      CustomDefaultForumReaction(id:) -> #("emoji_id", snowflake_to_json(id))
      StandardDefaultForumReaction(character:) -> #(
        "emoji_name",
        json.string(character),
      )
    },
  ])
}

fn forum_tag_emoji_to_json(emoji: ForumTagEmoji) -> Json {
  json.object([
    case emoji {
      CustomForumTagEmoji(id:) -> #("emoji_id", snowflake_to_json(id))
      StandardForumTagEmoji(character:) -> #(
        "emoji_name",
        json.string(character),
      )
    },
  ])
}

// Get rid of me!! Use actual messages
pub type Message

/// Permission overwrites are used to grant/deny specific permissions to members
/// (personally or per-role) in specific channels.
///
/// The order of importance for permission overwrites:
/// 1. User-based allow overwrites
/// 2. User-based deny overwrites
/// 3. Role-based allow overwrites
/// 4. Role-based deny overwrites
/// 5. @everyone allow overwrites
/// 6. @everyone deny overwrites
/// 7. Guild-level role permissions
/// 8. Guild-level @everyone permissions
pub type PermissionOverwrite {
  RolePermissionOverwrite(
    role_id: Snowflake(Role),
    allow: List(Permission),
    deny: List(Permission),
  )
  UserPermissionOverwrite(
    user_id: Snowflake(User),
    allow: List(Permission),
    deny: List(Permission),
  )
}

fn permission_overwrite_to_json(overwrite: PermissionOverwrite) -> Json {
  case overwrite {
    RolePermissionOverwrite(role_id:, allow:, deny:) ->
      json.object([
        #("type", json.int(0)),
        #("id", snowflake_to_json(role_id)),
        #("allow", permissions_to_json(allow)),
        #("deny", permissions_to_json(deny)),
      ])
    UserPermissionOverwrite(user_id:, allow:, deny:) ->
      json.object([
        #("type", json.int(1)),
        #("id", snowflake_to_json(user_id)),
        #("allow", permissions_to_json(allow)),
        #("deny", permissions_to_json(deny)),
      ])
  }
}

fn permission_overwrite_decoder() -> Decoder(PermissionOverwrite) {
  use variant <- decode.field("type", decode.int)
  use allow <- decode.field("allow", permissions_decoder())
  use deny <- decode.field("deny", permissions_decoder())

  case variant {
    0 -> {
      use role_id <- decode.field("id", snowflake_decoder())
      decode.success(RolePermissionOverwrite(role_id:, allow:, deny:))
    }
    1 -> {
      use user_id <- decode.field("id", snowflake_decoder())
      decode.success(UserPermissionOverwrite(user_id:, allow:, deny:))
    }
    _ ->
      decode.failure(
        RolePermissionOverwrite(Snowflake(0), [], []),
        "PermissionOverwrite",
      )
  }
}

/// Returns the ID of the `@everyone` role for a specific guild.
pub fn get_everyone_role_id(
  of_guild_with_id id: Snowflake(Guild),
) -> Snowflake(Role) {
  // the @everyone role has the same ID as the guild
  id
  |> snowflake_to_int
  |> new_snowflake
}

pub type Guild {
  Guild(
    id: Snowflake(Guild),
    name: String,
    /// Image hash of the guild icon.
    ///
    /// An icon is the picture shown in the server list.
    ///
    /// Is `None` when the guild doesn't have an icon.
    icon_hash: Option(ImageHash),
    /// Image hash of the guild splash.
    ///
    /// A splash is the picture shown when a user joins a guild, at the "Accept Invite" UI.
    ///
    /// Is `None` when the guild doesn't have a splash. 
    splash_hash: Option(ImageHash),
    /// Image hash of the guild discovery splash.
    ///
    /// A discovery splash is the picture shown when a user clicks on a guild in the "Server Discovery" UI.
    ///
    ///  Is `None` when the guild isn't discoverable or doesn't have a discovery splash.
    discovery_splash_hash: Option(ImageHash),
    owner_id: Snowflake(User),
    /// The "AFK channel" is the channel to which inactive voice channel users are moved.
    /// 
    /// Is `None` when the guild doesn't have a configured AFK channel.
    afk_channel_id: Option(Snowflake(Channel)),
    /// The time of inactivity after a voice channel user is marked as AFK in this guild.
    afk_timeout: AfkTimeout,
    /// Whether the "server widget" is enabled.
    /// The server widget is a feature allowing guild advertisements on websites.
    is_widget_enabled: Bool,
    /// The channel to which the widget will generate an invite to.
    /// 
    /// Is `None` if the widget was configured to not generate invites or is disabled.
    widget_channel_id: Option(Snowflake(Channel)),
    /// The verification level required for a guild member to be able to communicate in a guild.
    required_verification_level: GuildMemberVerificationLevel,
    /// The default setting regarding sending push notifications to members' devices.
    /// 
    /// Note that this can be overriden on a per-member basis.
    default_message_notification_setting: GuildDefaultMessageNotificationSetting,
    explicit_content_filter_setting: GuildExplicitContentFilterSetting,
    roles: List(Role),
    /// List of the guild's custom emojis.
    emojis: List(CustomEmoji),
    features: List(GuildFeature),
    /// MFA = multi-factor authentication
    required_mfa_level: GuildRequiredMfaLevel,
    /// Application ID of the guild creator if it is created by a bot.
    application_id: Option(Snowflake(Application)),
    /// The system channel is the channel where certain notifications, such as on-boost messages are sent.
    ///
    ///  Is `None` if the guild does not use system messages.
    system_channel_id: Option(Snowflake(Channel)),
    system_channel_flags: List(GuildSystemChannelFlag),
    /// Is `None` if the guild doesn't have a rules channel.
    rules_channel_id: Option(Snowflake(Channel)),
    /// The maximum number of presences for the guild.
    ///
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
    /// The guild's server boost benefit tier.
    premium_tier: GuildPremiumTier,
    /// The guild's current amount of active server boosts.
    premium_subscription_count: Int,
    /// Is present for all guilds, but only community guilds have the ability to change it.
    ///
    /// Defaults to `en-US` if not selected by the guild's admins. 
    preferred_locale: Locale,
    /// ID of the channel where admins and moderators of a Community guild receive notices from Discord.
    ///
    /// Is `None` if the guild isn't a community guild.
    public_updates_channel_id: Option(Snowflake(Channel)),
    /// The maximum amount of webcam-sharing users in a voice channel for this guild.
    max_video_channel_users: Int,
    /// The maximum amount of webcam-sharing users in a stage channel for this guild.
    max_stage_video_channel_users: Int,
    /// Is only present in the `Invite.guild` field.
    welcome_screen: Option(GuildWelcomeScreen),
    nsfw_level: GuildNsfwLevel,
    /// Is `None` in many circumstances, it's best to always check for this field's presence.
    stickers: Option(List(GuildSticker)),
    /// Whether the guild has the boost progress bar enabled.
    is_premium_progress_bar_enabled: Bool,
    /// ID of the channel where moderators of Community guilds receive safety alerts from Discord.
    /// Is `None` if the guild isn't a community guild.
    safety_alerts_channel_id: Option(Snowflake(Channel)),
    /// Is `None` if there is no active incident.
    incidents_data: Option(GuildIncidentsData),
  )
}

fn guild_decoder() -> Decoder(Guild) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(image_hash_decoder()))
  use splash_hash <- decode.field(
    "splash",
    decode.optional(image_hash_decoder()),
  )
  use discovery_splash_hash <- decode.field(
    "discovery_splash",
    decode.optional(image_hash_decoder()),
  )
  use owner_id <- decode.field("owner_id", snowflake_decoder())
  use afk_channel_id <- decode.field(
    "afk_channel_id",
    decode.optional(snowflake_decoder()),
  )
  use afk_timeout <- decode.field("afk_timeout", afk_timeout_decoder())
  use is_widget_enabled <- decode.optional_field(
    "widget_enabled",
    False,
    decode.bool,
  )
  use widget_channel_id <- decode.optional_field(
    "widget_channel_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use required_verification_level <- decode.field(
    "verification_level",
    guild_member_verification_level_decoder(),
  )
  use default_message_notification_setting <- decode.field(
    "default_message_notifications",
    guild_default_message_notification_setting_decoder(),
  )
  use explicit_content_filter_setting <- decode.field(
    "explicit_content_filter",
    guild_explicit_content_filter_setting_decoder(),
  )
  use roles <- decode.field("roles", decode.list(role_decoder()))
  use emojis <- decode.field("emojis", decode.list(custom_emoji_decoder()))
  use features <- decode.field("features", guild_features_decoder())
  use required_mfa_level <- decode.field(
    "mfa_level",
    guild_required_mfa_level_decoder(),
  )
  use application_id <- decode.field(
    "application_id",
    decode.optional(snowflake_decoder()),
  )
  use system_channel_id <- decode.field(
    "system_channel_id",
    decode.optional(snowflake_decoder()),
  )
  use system_channel_flags <- decode.field(
    "system_channel_flags",
    flags_decoder(bits_guild_system_channel_flags()),
  )
  use rules_channel_id <- decode.field(
    "rules_channel_id",
    decode.optional(snowflake_decoder()),
  )
  use max_presences <- decode.optional_field(
    "max_presences",
    None,
    decode.optional(decode.int),
  )
  use max_members <- decode.optional_field(
    "max_members",
    None,
    decode.optional(decode.int),
  )
  use vanity_url_code <- decode.field(
    "vanity_url_code",
    decode.optional(decode.string),
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use banner_hash <- decode.field(
    "banner",
    decode.optional(image_hash_decoder()),
  )
  use premium_tier <- decode.field("premium_tier", guild_premium_tier_decoder())
  use premium_subscription_count <- decode.field(
    "premium_subscription_count",
    decode.int,
  )
  use preferred_locale <- decode.field("preferred_locale", locale_decoder())
  use public_updates_channel_id <- decode.field(
    "public_updates_channel_id",
    decode.optional(snowflake_decoder()),
  )
  use max_video_channel_users <- decode.field(
    "max_video_channel_users",
    decode.int,
  )
  use max_stage_video_channel_users <- decode.field(
    "max_stage_video_channel_users",
    decode.int,
  )
  use welcome_screen <- decode.optional_field(
    "welcome_screen",
    None,
    decode.optional(guild_welcome_screen_decoder()),
  )
  use nsfw_level <- decode.field("nsfw_level", guild_nsfw_level_decoder())
  use stickers <- decode.field(
    "stickers",
    decode.optional(decode.list(guild_sticker_decoder())),
  )
  use is_premium_progress_bar_enabled <- decode.field(
    "premium_progress_bar_enabled",
    decode.bool,
  )
  use safety_alerts_channel_id <- decode.field(
    "safety_alerts_channel_id",
    decode.optional(snowflake_decoder()),
  )
  use incidents_data <- decode.field(
    "incidents_data",
    decode.optional(guild_incidents_data_decoder()),
  )
  decode.success(Guild(
    id:,
    name:,
    icon_hash:,
    splash_hash:,
    discovery_splash_hash:,
    owner_id:,
    afk_channel_id:,
    afk_timeout:,
    is_widget_enabled:,
    widget_channel_id:,
    required_verification_level:,
    default_message_notification_setting:,
    explicit_content_filter_setting:,
    roles:,
    emojis:,
    features:,
    required_mfa_level:,
    application_id:,
    system_channel_id:,
    system_channel_flags:,
    rules_channel_id:,
    max_presences:,
    max_members:,
    vanity_url_code:,
    description:,
    banner_hash:,
    premium_tier:,
    premium_subscription_count:,
    preferred_locale:,
    public_updates_channel_id:,
    max_video_channel_users:,
    max_stage_video_channel_users:,
    welcome_screen:,
    nsfw_level:,
    stickers:,
    is_premium_progress_bar_enabled:,
    safety_alerts_channel_id:,
    incidents_data:,
  ))
}

pub type GuildIncidentsData {
  GuildIncidentsData(
    /// When the ability to join the guild using an invite will be restored.
    invites_disabled_until: Option(Timestamp),
    /// When the ability to send first-time DMs to guild members will be restored.
    dms_disabled_until: Option(Timestamp),
    /// When Discord detected a DM spam campaign targeting the guild.
    dm_spam_detected_at: Option(Timestamp),
    /// When Discord detected a raid targeting the guild.
    raid_detected_at: Option(Timestamp),
  )
}

fn guild_incidents_data_decoder() -> Decoder(GuildIncidentsData) {
  use invites_disabled_until <- decode.field(
    "invites_disabled_until",
    decode.optional(rfc3339_decoder()),
  )
  use dms_disabled_until <- decode.field(
    "dms_disabled_until",
    decode.optional(rfc3339_decoder()),
  )
  use dm_spam_detected_at <- decode.field(
    "dm_spam_detected_at",
    decode.optional(rfc3339_decoder()),
  )
  use raid_detected_at <- decode.field(
    "raid_detected_at",
    decode.optional(rfc3339_decoder()),
  )
  decode.success(GuildIncidentsData(
    invites_disabled_until:,
    dms_disabled_until:,
    dm_spam_detected_at:,
    raid_detected_at:,
  ))
}

pub type Sticker {
  /// Stickers available on all guilds to every user.
  StickerStandardType(StandardSticker)
  /// Stickers available:
  /// * in the guild of registration for that guild's members
  /// * in all guilds for Nitro subscribers who are also members of the guild of registration
  StickerGuildType(GuildSticker)
}

pub type StandardSticker {
  StandardSticker(
    id: Snowflake(StandardSticker),
    /// ID of the pack from which this sticker comes from.
    pack_id: Snowflake(StickerPack),
    name: String,
    /// Is `None` if the sticker doesn't have a description.
    description: Option(String),
    /// Auto-complete/suggestion tags (keywords).
    tags: String,
    format_type: StickerFormatType,
    /// A value used to sort more important stickers in the client.
    /// If `None`, sorted alphabetically. (I assume)
    sort_value: Option(Int),
  )
}

pub type GuildSticker {
  GuildSticker(
    id: Snowflake(GuildSticker),
    name: String,
    /// Is `None` if the sticker doesn't have a description.
    description: Option(String),
    /// Auto-complete/suggestion tags (keywords).
    tags: String,
    format_type: StickerFormatType,
    /// Is `False` when a guild loses its premium tier, reducing its sticker capacity and removing the sticker.
    is_available: Bool,
    guild_id: Snowflake(Guild),
    uploader: User,
  )
}

fn guild_sticker_decoder() -> Decoder(GuildSticker) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use tags <- decode.field("tags", decode.string)
  use format_type <- decode.field("format_type", sticker_format_type_decoder())
  use is_available <- decode.optional_field("available", True, decode.bool)
  use guild_id <- decode.field("guild_id", snowflake_decoder())
  use uploader <- decode.field("user", user_decoder())
  decode.success(GuildSticker(
    id:,
    name:,
    description:,
    tags:,
    format_type:,
    is_available:,
    guild_id:,
    uploader:,
  ))
}

/// Used for the `get_sticker` function.
pub fn guild_sticker_id_to_sticker_id(
  id: Snowflake(GuildSticker),
) -> Snowflake(Sticker) {
  id
  |> snowflake_to_int
  |> new_snowflake
}

/// Used for the `get_sticker` function.
pub fn standard_sticker_id_to_sticker_id(
  id: Snowflake(StandardSticker),
) -> Snowflake(Sticker) {
  id
  |> snowflake_to_int
  |> new_snowflake
}

pub type StickerFormatType {
  PngSticker
  ApngSticker
  LottieSticker
  GifSticker
}

fn sticker_format_type_decoder() -> Decoder(StickerFormatType) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(PngSticker)
    2 -> decode.success(ApngSticker)
    3 -> decode.success(LottieSticker)
    4 -> decode.success(GifSticker)
    _ -> decode.failure(PngSticker, "StickerFormatType")
  }
}

pub type StickerPack

pub type GuildNsfwLevel {
  /// Unrated.
  DefaultGuildNsfwLevel
  /// Has explicit content.
  ExplicitGuild
  /// Safe-for-work.
  SafeGuild
  /// Guild is restricted to adults.
  AgeRestrictedGuild
}

fn guild_nsfw_level_decoder() -> Decoder(GuildNsfwLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(DefaultGuildNsfwLevel)
    1 -> decode.success(ExplicitGuild)
    2 -> decode.success(SafeGuild)
    3 -> decode.success(AgeRestrictedGuild)
    _ -> decode.failure(DefaultGuildNsfwLevel, "GuildNsfwLevel")
  }
}

pub type GuildWelcomeScreen {
  GuildWelcomeScreen(
    /// The guild description shown in the welcome screen.
    /// Is `None` if the guild hasn't configured a description.
    description: Option(String),
    /// The channels shown in the welcome screen. Up to 5.
    welcome_channels: List(GuildWelcomeScreenChannel),
  )
}

fn guild_welcome_screen_decoder() -> Decoder(GuildWelcomeScreen) {
  use description <- decode.field("description", decode.optional(decode.string))
  use welcome_channels <- decode.field(
    "welcome_channels",
    decode.list(guild_welcome_screen_channel_decoder()),
  )
  decode.success(GuildWelcomeScreen(description:, welcome_channels:))
}

pub type GuildWelcomeScreenChannel {
  GuildWelcomeScreenChannel(
    id: Snowflake(Channel),
    description: String,
    emoji: Option(GuildWelcomeScreenChannelEmoji),
  )
}

fn guild_welcome_screen_channel_to_json(
  channel: GuildWelcomeScreenChannel,
) -> Json {
  [
    #("id", snowflake_to_json(channel.id)),
    #("description", json.string(channel.description)),
  ]
  |> list.append(case channel.emoji {
    Some(emoji) ->
      case emoji {
        StandardGuildWelcomeScreenChannelEmoji(character) -> [
          #("emoji_name", json.string(character)),
        ]
        CustomGuildWelcomeScreenChannelEmoji(id, name) -> [
          #("emoji_id", snowflake_to_json(id)),
          #("emoji_name", json.string(name)),
        ]
      }
    None -> []
  })
  |> json.object
}

pub type GuildWelcomeScreenChannelEmoji {
  StandardGuildWelcomeScreenChannelEmoji(character: String)
  CustomGuildWelcomeScreenChannelEmoji(id: Snowflake(Emoji), name: String)
}

pub fn new_guild_welcome_screen_channel(
  with_id id: Snowflake(Channel),
  description description: String,
) -> GuildWelcomeScreenChannel {
  GuildWelcomeScreenChannel(id:, description:, emoji: None)
}

pub fn guild_welcome_screen_channel_with_emoji(
  channel: GuildWelcomeScreenChannel,
  emoji: GuildWelcomeScreenChannelEmoji,
) -> GuildWelcomeScreenChannel {
  GuildWelcomeScreenChannel(..channel, emoji: Some(emoji))
}

fn guild_welcome_screen_channel_decoder() -> Decoder(GuildWelcomeScreenChannel) {
  use id <- decode.field("channel_id", snowflake_decoder())
  use description <- decode.field("description", decode.string)
  use emoji_id <- decode.optional_field(
    "emoji_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use emoji_name <- decode.optional_field(
    "emoji_name",
    None,
    decode.optional(decode.string),
  )

  let emoji = case emoji_id, emoji_name {
    Some(id), Some(name) ->
      Some(CustomGuildWelcomeScreenChannelEmoji(id:, name:))
    None, Some(character) ->
      Some(StandardGuildWelcomeScreenChannelEmoji(character:))
    _, _ -> None
  }

  decode.success(GuildWelcomeScreenChannel(id:, description:, emoji:))
}

pub type GuildApproximateCounts {
  GuildApproximateCounts(
    approximate_member_count: Int,
    approximate_presence_count: Int,
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

fn guild_premium_tier_decoder() -> Decoder(GuildPremiumTier) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildWithoutPremium)
    1 -> decode.success(GuildPremiumTier1)
    2 -> decode.success(GuildPremiumTier2)
    3 -> decode.success(GuildPremiumTier3)
    _ -> decode.failure(GuildWithoutPremium, "GuildPremiumTier")
  }
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

fn bits_guild_system_channel_flags() -> List(#(Int, GuildSystemChannelFlag)) {
  [
    #(int.bitwise_shift_left(1, 0), GuildSystemChannelWithoutJoinNotifications),
    #(
      int.bitwise_shift_left(1, 1),
      GuildSystemChannelWithoutPremiumNotifications,
    ),
    #(
      int.bitwise_shift_left(1, 2),
      GuildSystemChannelWithoutGuildReminderNotifications,
    ),
    #(
      int.bitwise_shift_left(1, 3),
      GuildSystemChannelWithoutJoinNotificationStickerReplyButtons,
    ),
    #(
      int.bitwise_shift_left(1, 4),
      GuildSystemChannelWithoutRoleSubscriptionPurchaseNotifications,
    ),
    #(
      int.bitwise_shift_left(1, 5),
      GuildSystemChannelWithoutRoleSubscriptionPurchaseNotificationStickerReplyButtons,
    ),
  ]
}

pub type Application {
  Application(
    id: Snowflake(Application),
    name: String,
    icon_hash: Option(ImageHash),
    /// Appears in a bot's biography.
    description: String,
    /// List of RPC origin URLs, if RPC is enabled.
    rpc_origins: Option(List(String)),
    /// If `False`, only the owner can add the app to guilds.
    is_bot_public: Bool,
    /// If `True`, the bot will only join a guild upon completion of the full OAuth2 code grant flow.
    bot_requires_code_grant: Bool,
    /// Is `None` if there's no bot associated with the app.
    bot: Option(User),
    /// The app's Terms of Service.
    /// 
    /// Is `None` if the developer didn't specify any Terms of Service.
    terms_of_service_url: Option(String),
    /// The app's Privacy Policy.
    /// 
    /// Is `None` if the developer didn't specify any Privacy Policy.
    privacy_policy_url: Option(String),
    owner: ApplicationOwner,
    // Hex-encoded key for verification in interactions and the GameSDK's GetTicket.
    verify_key: String,
    /// Guild associated with the app - for example, a developer support server.
    guild: Option(Guild),
    /// If this app is a game sold on Discord, this field will be the ID of the Game SKU.
    primary_sku_id: Option(Snowflake(Sku)),
    /// If this app is a game sold on Discord, this field will be the URL slug that links to the store page.
    slug: Option(String),
    /// Default rich presence invite cover image.
    cover_image_hash: Option(ImageHash),
    flags: List(ApplicationFlag),
    /// Approximately, how many guilds has the app been added to?
    ///
    /// Is `None` if not computed yet.
    approximate_guild_count: Option(Int),
    /// Approximately, how many users installed the app?
    ///
    /// Is `None` if not computed yet.
    approximate_user_install_count: Option(Int),
    /// Approximately, how many users have completed OAuth2 authorizations for the app?
    ///
    /// Is `None` if not computed yet.
    approximate_user_authorization_count: Option(Int),
    /// OAuth2 redirect URIs.
    redirect_uris: List(String),
    /// The URL for webhook-based interactions.
    interactions_endpoint_url: Option(String),
    /// The URL for verification to link an app to a user's Discord profile.
    role_connections_verification_url: Option(String),
    /// The URL for webhook-based events.
    webhook_events_url: Option(String),
    webhook_events_status: ApplicationWebhookEventStatus,
    /// The types of events the application is subscribed to (if any)
    webhook_events_types: Option(List(String)),
    /// A list of maximum 5 tags describing the application.
    tags: List(String),
    /// Installation settings for the default in-app authorization link.
    in_app_installation_settings: Option(ApplicationInstallationSettings),
    /// Default installation settings for guild installation.
    guild_installation_settings: Option(ApplicationInstallationSettings),
    /// Default installation settings for user installation.
    user_installation_settings: Option(ApplicationInstallationSettings),
    /// Custom authorization URL.
    custom_installation_url: Option(String),
  )
}

fn application_decoder() -> Decoder(Application) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(image_hash_decoder()))
  use description <- decode.field("description", decode.string)
  use rpc_origins <- decode.optional_field(
    "rpc_origins",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use is_bot_public <- decode.field("bot_public", decode.bool)
  use bot_requires_code_grant <- decode.field(
    "bot_require_code_grant",
    decode.bool,
  )
  use bot <- decode.optional_field("bot", None, decode.optional(user_decoder()))
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
  use owner <- decode.then(application_owner_decoder())
  use verify_key <- decode.field("verify_key", decode.string)
  use guild <- decode.optional_field(
    "guild",
    None,
    decode.optional(guild_decoder()),
  )
  use primary_sku_id <- decode.optional_field(
    "primary_sku_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use cover_image_hash <- decode.optional_field(
    "cover_image",
    None,
    decode.optional(image_hash_decoder()),
  )
  use flags <- decode.optional_field(
    "flags",
    [],
    flags_decoder(bits_application_flags()),
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
  use approximate_user_authorization_count <- decode.optional_field(
    "approximate_user_authorization_count",
    None,
    decode.optional(decode.int),
  )
  use redirect_uris <- decode.optional_field(
    "redirect_uris",
    [],
    decode.list(decode.string),
  )
  use interactions_endpoint_url <- decode.optional_field(
    "interactions_endpoint_url",
    None,
    decode.optional(decode.string),
  )
  use role_connections_verification_url <- decode.optional_field(
    "role_connections_verification_url",
    None,
    decode.optional(decode.string),
  )
  use webhook_events_url <- decode.optional_field(
    "events_webhooks_url",
    None,
    decode.optional(decode.string),
  )
  use webhook_events_status <- decode.optional_field(
    "events_webhooks_status",
    ApplicationWebhookEventsDisabled,
    application_webhook_event_status_decoder(),
  )
  use webhook_events_types <- decode.optional_field(
    "event_webhooks_types",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use tags <- decode.optional_field("tags", [], decode.list(decode.string))
  use in_app_installation_settings <- decode.optional_field(
    "install_params",
    None,
    decode.optional(application_installation_settings_decoder()),
  )
  use guild_installation_settings <- decode.then(decode.optionally_at(
    ["integration_types_config", "0", "oauth2_install_params"],
    None,
    decode.optional(application_installation_settings_decoder()),
  ))
  use user_installation_settings <- decode.then(decode.optionally_at(
    ["integration_types_config", "1", "oauth2_install_params"],
    None,
    decode.optional(application_installation_settings_decoder()),
  ))
  use custom_installation_url <- decode.optional_field(
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
    bot_requires_code_grant:,
    bot:,
    terms_of_service_url:,
    privacy_policy_url:,
    owner:,
    verify_key:,
    guild:,
    primary_sku_id:,
    slug:,
    cover_image_hash:,
    flags:,
    approximate_guild_count:,
    approximate_user_install_count:,
    approximate_user_authorization_count:,
    redirect_uris:,
    interactions_endpoint_url:,
    role_connections_verification_url:,
    webhook_events_url:,
    webhook_events_status:,
    webhook_events_types:,
    tags:,
    in_app_installation_settings:,
    guild_installation_settings:,
    user_installation_settings:,
    custom_installation_url:,
  ))
}

fn application_owner_decoder() -> Decoder(ApplicationOwner) {
  let user_decoder = {
    use user <- decode.field("owner", user_decoder())
    decode.success(ApplicationOwnerUser(user:))
  }

  let team_decoder = {
    use team <- decode.field("team", developer_team_decoder())
    decode.success(ApplicationOwnerTeam(team:))
  }

  decode.one_of(user_decoder, or: [team_decoder])
}

/// Describes variable values during application installation.
pub type ApplicationInstallationSettings {
  ApplicationInstallationSettings(
    /// The OAuth2 scopes the app will be installed with.
    scopes: List(String),
    /// The permissions the app will be installed with.
    permissions: List(Permission),
  )
}

fn application_installation_settings_decoder() -> Decoder(
  ApplicationInstallationSettings,
) {
  use scopes <- decode.field("scopes", decode.list(decode.string))
  use permissions <- decode.field("permissions", permissions_decoder())
  decode.success(ApplicationInstallationSettings(scopes:, permissions:))
}

pub type ApplicationWebhookEventStatus {
  /// The application isn't receiving webhook events
  ApplicationWebhookEventsDisabled
  /// The application's receiving webhook events
  ApplicationWebhookEventsEnabled
  /// The application's webhook events were disabled by Discord (usually due to inactivity)
  ApplicationWebhookEventsDisabledByDiscord
}

fn application_webhook_event_status_decoder() -> Decoder(
  ApplicationWebhookEventStatus,
) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(ApplicationWebhookEventsDisabled)
    2 -> decode.success(ApplicationWebhookEventsEnabled)
    3 -> decode.success(ApplicationWebhookEventsDisabledByDiscord)
    _ ->
      decode.failure(
        ApplicationWebhookEventsDisabled,
        "ApplicationWebhookEventStatus",
      )
  }
}

pub type ApplicationFlag {
  /// The application was awarded a badge for creating an auto moderation rule
  ApplicationCreatedAutoModerationRule
  /// The application is approved for the privileged presence intent. (100+ guilds)
  ApplicationApprovedForPresenceIntent
  /// The application is temporarily approved for the privileged presence intent (0-99 guilds)
  ApplicationTemporarilyApprovedForPresenceIntent
  /// The application is approved for the privileged guild members intent. (100+ guilds)
  ApplicationApprovedForGuildMembersIntent
  /// The application is temporarily approved for the privileged guild members intent (0-99 guilds)
  ApplicationTemporarilyApprovedForGuildMembersIntent
  /// Indicates unusual growth of an app that prevents verification.
  ApplicationGrowsUnusuallyFast
  /// The application is embedded within the Discord client (unavailable publicly)
  ApplicationIsEmbedded
  /// The application is approved for the privileged message content intent. (100+ guilds)
  ApplicationApprovedForMessageContentIntent
  /// The application is temporarily approved for the privileged message content intent (0-99 guilds)
  ApplicationTemporarilyApprovedForMessageContentIntent
  /// The application was awarded a badge for creating a global command
  ApplicationRegisteredGlobalCommand
}

fn bits_application_flags() -> List(#(Int, ApplicationFlag)) {
  [
    #(int.bitwise_shift_left(1, 6), ApplicationCreatedAutoModerationRule),
    #(int.bitwise_shift_left(1, 12), ApplicationApprovedForPresenceIntent),
    #(
      int.bitwise_shift_left(1, 13),
      ApplicationTemporarilyApprovedForPresenceIntent,
    ),
    #(int.bitwise_shift_left(1, 14), ApplicationApprovedForGuildMembersIntent),
    #(
      int.bitwise_shift_left(1, 15),
      ApplicationTemporarilyApprovedForGuildMembersIntent,
    ),
    #(int.bitwise_shift_left(1, 16), ApplicationGrowsUnusuallyFast),
    #(int.bitwise_shift_left(1, 17), ApplicationIsEmbedded),
    #(int.bitwise_shift_left(1, 18), ApplicationApprovedForMessageContentIntent),
    #(
      int.bitwise_shift_left(1, 19),
      ApplicationTemporarilyApprovedForMessageContentIntent,
    ),
    #(int.bitwise_shift_left(1, 23), ApplicationRegisteredGlobalCommand),
  ]
}

pub type ApplicationOwner {
  ApplicationOwnerUser(user: User)
  ApplicationOwnerTeam(team: DeveloperTeam)
}

pub type DeveloperTeam {
  DeveloperTeam(
    id: Snowflake(DeveloperTeam),
    members: List(DeveloperTeamMember),
    icon_hash: Option(ImageHash),
    name: String,
    owner_id: Snowflake(User),
  )
}

fn developer_team_decoder() -> Decoder(DeveloperTeam) {
  use id <- decode.field("id", snowflake_decoder())
  use members <- decode.field(
    "members",
    decode.list(developer_team_member_decoder()),
  )
  use icon_hash <- decode.field("icon", decode.optional(image_hash_decoder()))
  use name <- decode.field("name", decode.string)
  use owner_id <- decode.field("owner_user_id", snowflake_decoder())
  decode.success(DeveloperTeam(id:, members:, icon_hash:, name:, owner_id:))
}

pub type DeveloperTeamMember {
  DeveloperTeamMember(
    user: User,
    role: DeveloperTeamMemberRole,
    team_id: Snowflake(DeveloperTeam),
    membership_state: DeveloperTeamMembershipState,
  )
}

fn developer_team_member_decoder() -> Decoder(DeveloperTeamMember) {
  use user <- decode.field("user", user_decoder())
  use role <- decode.field("role", developer_team_member_role_decoder())
  use team_id <- decode.field("team_id", snowflake_decoder())
  use membership_state <- decode.field(
    "membership_state",
    developer_team_membership_state_decoder(),
  )
  decode.success(DeveloperTeamMember(user:, role:, team_id:, membership_state:))
}

pub type DeveloperTeamMemberRole {
  /// Owners and admins have the admin role.
  ///
  /// Use the [`DeveloperTeam.owner_id`](#DeveloperTeam) property to determine who is the owner of the team.
  DeveloperTeamAdmin
  DeveloperTeamDeveloper
  DeveloperTeamReadOnlyAccess
}

fn developer_team_member_role_decoder() -> Decoder(DeveloperTeamMemberRole) {
  use variant <- decode.then(decode.string)
  case variant {
    "admin" -> decode.success(DeveloperTeamAdmin)
    "developer" -> decode.success(DeveloperTeamDeveloper)
    "read_only" -> decode.success(DeveloperTeamReadOnlyAccess)
    _ -> decode.failure(DeveloperTeamAdmin, "DeveloperTeamMemberRole")
  }
}

pub type DeveloperTeamMembershipState {
  /// The developer was invited to the team and accepted the invite.
  DeveloperIsAccepted
  /// The developer was invited to the team and has not accepted the invite (yet).
  DeveloperIsInvited
}

fn developer_team_membership_state_decoder() -> Decoder(
  DeveloperTeamMembershipState,
) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(DeveloperIsInvited)
    2 -> decode.success(DeveloperIsAccepted)
    _ -> decode.failure(DeveloperIsAccepted, "DeveloperTeamMembershipState")
  }
}

pub type GuildRequiredMfaLevel {
  GuildDoesNotRequireMfa
  GuildRequiresMfaForModerationActions
}

fn guild_required_mfa_level_decoder() -> Decoder(GuildRequiredMfaLevel) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildDoesNotRequireMfa)
    1 -> decode.success(GuildRequiresMfaForModerationActions)
    _ -> decode.failure(GuildDoesNotRequireMfa, "GuildRequiredMfaLevel")
  }
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
      "ANIMATED_BANNER" -> Ok(GuildCanUseAnimatedBanner)
      "ANIMATED_ICON" -> Ok(GuildCanUseAnimatedIcon)
      "APPLICATION_COMMAND_PERMISSIONS_V2" ->
        Ok(GuildUsesOldPermissionConfigurationBehavior)
      "AUTO_MODERATION" -> Ok(GuildCreatedAutoModerationRules)
      "BANNER" -> Ok(GuildCanUseBanner)
      "COMMUNITY" -> Ok(GuildIsCommunity)
      "CREATOR_MONETIZABLE_PROVISIONAL" -> Ok(GuildUsesMonetization)
      "CREATOR_STORE_PAGE" -> Ok(GuildUsesRoleSubscriptionPromoPage)
      "DEVELOPER_SUPPORT_SERVER" -> Ok(GuildIsDeveloperSupportServer)
      "DISCOVERABLE" -> Ok(GuildIsDiscoverable)
      "FEATURABLE" -> Ok(GuildIsFeaturable)
      "INVITES_DISABLED" -> Ok(GuildHasPausedInvites)
      "INVITE_SPLASH" -> Ok(GuildCanUseInviteSplash)
      "MEMBER_VERIFICATION_GATE_ENABLED" -> Ok(GuildUsesMembershipScreening)
      "MORE_SOUNDBOARD" -> Ok(GuildHasMoreSoundboardSoundSlots)
      "MORE_STICKERS" -> Ok(GuildHasMoreStickerSlots)
      "NEWS" -> Ok(GuildCanCreateAnnouncementChannels)
      "PARTNERED" -> Ok(GuildIsPartnered)
      "PREVIEW_ENABLED" -> Ok(GuildCanBePreviewed)
      "RAID_ALERTS_DISABLED" -> Ok(GuildDisabledRaidAlerts)
      "ROLE_ICONS" -> Ok(GuildCanUseRoleIcons)
      "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE" ->
        Ok(GuildHasPurchasableRoleSubscriptions)
      "ROLE_SUBSCRIPTIONS_ENABLED" -> Ok(GuildUsesRoleSubscriptions)
      "SOUNDBOARD" -> Ok(GuildCreatedSoundboardSounds)
      "TICKETED_EVENTS_ENABLED" -> Ok(GuildUsesTicketedEvents)
      "VANITY_URL" -> Ok(GuildCanUseVanityUrl)
      "VIP_REGIONS" -> Ok(GuildCanUse384KbpsVoiceBitrate)
      "WELCOME_SCREEN_ENABLED" -> Ok(GuildUsesWelcomeScreen)
      "GUESTS_ENABLED" -> Ok(GuildCanUseGuestInvites)
      "GUILD_TAGS" -> Ok(GuildCanUseGuildTags)
      "ENHANCED_ROLE_COLORS" -> Ok(GuildCanUseEnhancedRoleColours)
      _ -> Error(Nil)
    }
  })
  |> list.filter_map(function.identity)
  |> decode.success
}

// REACTIONS: DO NOT USE THIS OBJECT, IT WILL NOT HAVE THE NAME FIELD
pub type Emoji {
  EmojiUnicode(character: String)
  EmojiCustom(emoji: CustomEmoji)
  EmojiApplication(emoji: ApplicationEmoji)
}

fn emoji_decoder() -> Decoder(Emoji) {
  use id <- decode.field("id", decode.optional(snowflake_decoder()))

  case id {
    Some(_id) ->
      decode.one_of(decode.map(custom_emoji_decoder(), EmojiCustom), or: [
        decode.map(application_emoji_decoder(), EmojiApplication),
      ])
    None -> {
      use character <- decode.field("name", decode.string)
      decode.success(EmojiUnicode(character:))
    }
  }
}

pub type CustomEmoji {
  CustomEmoji(
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

pub type ApplicationEmoji {
  ApplicationEmoji(
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

fn application_emoji_decoder() -> Decoder(ApplicationEmoji) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use allowed_roles_ids <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(of: snowflake_decoder())),
  )
  use creator <- decode.field("user", user_decoder())
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

  decode.success(ApplicationEmoji(
    id:,
    name:,
    creator:,
    allowed_roles_ids:,
    requires_colons:,
    is_integration_managed:,
    is_animated:,
    is_available:,
  ))
}

fn custom_emoji_decoder() -> Decoder(CustomEmoji) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use allowed_roles_ids <- decode.optional_field(
    "roles",
    None,
    decode.optional(decode.list(of: snowflake_decoder())),
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
  decode.success(CustomEmoji(
    id:,
    name:,
    allowed_roles_ids:,
    requires_colons:,
    is_integration_managed:,
    is_animated:,
    is_available:,
  ))
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

fn guild_member_verification_level_decoder() -> Decoder(
  GuildMemberVerificationLevel,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NoGuildMemberVerification)
    1 -> decode.success(LowGuildMemberVerification)
    2 -> decode.success(MediumGuildMemberVerification)
    3 -> decode.success(HighGuildMemberVerification)
    4 -> decode.success(VeryHighGuildMemberVerification)
    _ ->
      decode.failure(NoGuildMemberVerification, "GuildMemberVerificationLevel")
  }
}

pub type GuildDefaultMessageNotificationSetting {
  /// By default, notifications will be sent for all messages in the guild.
  NotifyForAllMessages
  /// By default, notifications will be sent only for messages in which the user was mentioned.
  NotifyOnlyForMentions
}

fn guild_default_message_notification_setting_decoder() -> Decoder(
  GuildDefaultMessageNotificationSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(NotifyForAllMessages)
    1 -> decode.success(NotifyOnlyForMentions)
    _ ->
      decode.failure(
        NotifyForAllMessages,
        "GuildDefaultMessageNotificationSetting",
      )
  }
}

pub type GuildExplicitContentFilterSetting {
  /// Media will not be scanned for explicit content.
  GuildExplicitContentFilterDisabled
  /// Only media sent by members who do not have any roles will be scanned for explicit content.
  GuildExplicitContentFilterForMembersWithoutRoles
  /// Media sent by all members will be scanned for explicit content.
  GuildExplicitContentFilterForAllMembers
}

fn guild_explicit_content_filter_setting_decoder() -> Decoder(
  GuildExplicitContentFilterSetting,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(GuildExplicitContentFilterDisabled)
    1 -> decode.success(GuildExplicitContentFilterForMembersWithoutRoles)
    2 -> decode.success(GuildExplicitContentFilterForAllMembers)
    _ ->
      decode.failure(
        GuildExplicitContentFilterDisabled,
        "GuildExplicitContentFilterSetting",
      )
  }
}

pub fn get_guild(
  token token: Token,
  id id: Snowflake(Guild),
) -> Result(Guild, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(id),
    method: http.Get,
  )
  |> send_request(decode_with: guild_decoder())
}

/// Returns a guild object along with its approximate member and presence counts.
pub fn get_guild_with_counts(
  token token: Token,
  id id: Snowflake(Guild),
) -> Result(#(Guild, GuildApproximateCounts), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(id),
    method: http.Get,
  )
  |> request.set_query([#("with_counts", "true")])
  |> send_request(decode_with: {
    use guild <- decode.then(guild_decoder())
    use approximate_member_count <- decode.field(
      "approximate_member_count",
      decode.int,
    )
    use approximate_presence_count <- decode.field(
      "approximate_presence_count",
      decode.int,
    )

    decode.success(#(
      guild,
      GuildApproximateCounts(
        approximate_member_count:,
        approximate_presence_count:,
      ),
    ))
  })
}

/// Represents an offline guild, or a guild whose information has not been provided
/// through the Guild Create events during the gateway connection initiation.
pub type UnavailableGuild {
  UnavailableGuild(id: Snowflake(Guild), is_unavailable: Bool)
}

pub type GuildPreview {
  GuildPreview(
    id: Snowflake(Guild),
    name: String,
    icon_hash: Option(ImageHash),
    splash_hash: Option(ImageHash),
    discovery_splash_hash: Option(ImageHash),
    emojis: List(CustomEmoji),
    features: List(GuildFeature),
    approximate_member_count: Int,
    approximate_presence_count: Int,
    description: Option(String),
    stickers: List(GuildSticker),
  )
}

fn guild_preview_decoder() -> Decoder(GuildPreview) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(image_hash_decoder()))
  use splash_hash <- decode.field(
    "splash",
    decode.optional(image_hash_decoder()),
  )
  use discovery_splash_hash <- decode.field(
    "discovery_splash",
    decode.optional(image_hash_decoder()),
  )
  use emojis <- decode.field("emojis", decode.list(custom_emoji_decoder()))
  use features <- decode.field("features", guild_features_decoder())
  use approximate_member_count <- decode.field(
    "approximate_member_count",
    decode.int,
  )
  use approximate_presence_count <- decode.field(
    "approximate_presence_count",
    decode.int,
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use stickers <- decode.field("stickers", decode.list(guild_sticker_decoder()))
  decode.success(GuildPreview(
    id:,
    name:,
    icon_hash:,
    splash_hash:,
    discovery_splash_hash:,
    emojis:,
    features:,
    approximate_member_count:,
    approximate_presence_count:,
    description:,
    stickers:,
  ))
}

/// Returns a guild preview object. Is useful for receiving information about discoverable
/// guilds, when the current user isn't a member of one of those guilds.
pub fn get_guild_preview(
  token token: Token,
  id id: Snowflake(Guild),
) -> Result(GuildPreview, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(id) <> "/preview",
    method: http.Get,
  )
  |> send_request(decode_with: guild_preview_decoder())
}

/// Look into the `(new_)modify_guild_*` functions to use this type using a builder pattern.
pub opaque type ModifyGuild {
  ModifyGuild(
    name: Option(String),
    member_verification_level: Modification(GuildMemberVerificationLevel),
    default_message_notification_setting: Modification(
      GuildDefaultMessageNotificationSetting,
    ),
    explicit_content_filter_setting: Modification(
      GuildExplicitContentFilterSetting,
    ),
    afk_channel_id: Modification(Snowflake(Channel)),
    afk_timeout: Option(AfkTimeout),
    icon: Modification(ImageData),
    splash: Modification(ImageData),
    discovery_splash: Modification(ImageData),
    banner: Modification(ImageData),
    system_channel_id: Modification(Snowflake(Channel)),
    system_channel_flags: Option(List(GuildSystemChannelFlag)),
    rules_channel_id: Modification(Snowflake(Channel)),
    public_updates_channel_id: Modification(Snowflake(Channel)),
    preferred_locale: Modification(Locale),
    features: Option(List(GuildFeature)),
    description: Modification(String),
    is_premium_progress_bar_enabled: Option(Bool),
    safety_alerts_channel_id: Modification(Snowflake(Channel)),
  )
}

pub fn new_modify_guild() -> ModifyGuild {
  ModifyGuild(
    None,
    Skip,
    Skip,
    Skip,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    Skip,
    Skip,
    None,
    Skip,
    Skip,
    Skip,
    None,
    Skip,
    None,
    Skip,
  )
}

pub fn modify_guild_name(modify: ModifyGuild, new name: String) -> ModifyGuild {
  ModifyGuild(..modify, name: Some(name))
}

pub fn modify_guild_member_verification_level(
  modify: ModifyGuild,
  new level: GuildMemberVerificationLevel,
) -> ModifyGuild {
  ModifyGuild(..modify, member_verification_level: Modify(level))
}

/// Resets the guild's member verification level back to default.
pub fn reset_guild_member_verification_level(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, member_verification_level: Delete)
}

pub fn modify_guild_default_message_notification_setting(
  modify: ModifyGuild,
  new setting: GuildDefaultMessageNotificationSetting,
) -> ModifyGuild {
  ModifyGuild(..modify, default_message_notification_setting: Modify(setting))
}

/// Resets the guild's default message notification setting back to default.
pub fn reset_guild_default_message_notification_setting(
  modify: ModifyGuild,
) -> ModifyGuild {
  ModifyGuild(..modify, default_message_notification_setting: Delete)
}

pub fn modify_guild_explicit_content_filter_setting(
  modify: ModifyGuild,
  new setting: GuildExplicitContentFilterSetting,
) -> ModifyGuild {
  ModifyGuild(..modify, explicit_content_filter_setting: Modify(setting))
}

/// Resets the guild's explicit content filter setting back to default.
pub fn reset_guild_explicit_content_filter_setting(
  modify: ModifyGuild,
) -> ModifyGuild {
  ModifyGuild(..modify, explicit_content_filter_setting: Delete)
}

pub fn modify_guild_afk_channel(
  modify: ModifyGuild,
  new_id id: Snowflake(Channel),
) -> ModifyGuild {
  ModifyGuild(..modify, afk_channel_id: Modify(id))
}

/// Unsets the guild's AFK channel.
///
/// This will not delete the channel, just make the guild not have an AFK channel.
pub fn unset_guild_afk_channel(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, afk_channel_id: Delete)
}

/// Represents the time after which an AFK person will be moved to an AFK channel, if one is present.
pub type AfkTimeout {
  /// After 1 minute.
  AfkTimeout60Seconds
  /// After 5 minutes.
  AfkTimeout300Seconds
  /// After 15 minutes.
  AfkTimeout900Seconds
  /// After 30 minutes.
  AfkTimeout1800Seconds
  /// After 60 minutes.
  AfkTimeout3600Seconds
}

fn afk_timeout_decoder() -> Decoder(AfkTimeout) {
  use variant <- decode.then(decode.int)
  case variant {
    60 -> decode.success(AfkTimeout60Seconds)
    300 -> decode.success(AfkTimeout300Seconds)
    900 -> decode.success(AfkTimeout900Seconds)
    1800 -> decode.success(AfkTimeout1800Seconds)
    3600 -> decode.success(AfkTimeout3600Seconds)
    _ -> decode.failure(AfkTimeout60Seconds, "AfkTimeout")
  }
}

pub fn modify_guild_afk_timeout(
  modify: ModifyGuild,
  new timeout: AfkTimeout,
) -> ModifyGuild {
  ModifyGuild(..modify, afk_timeout: Some(timeout))
}

/// The icon must have a resolution of 1024x1024.
///
/// It can only be animated if the guild has the `GuildCanUseAnimatedIcon` feature.
pub fn modify_guild_icon(
  modify: ModifyGuild,
  new icon: ImageData,
) -> ModifyGuild {
  ModifyGuild(..modify, icon: Modify(icon))
}

pub fn delete_guild_icon(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, icon: Delete)
}

/// The splash must be a PNG/JPEG image with a 16:9 aspect ratio.
///
/// The guild must have the `GuildCanUseInviteSplash` feature.
pub fn modify_guild_splash(
  modify: ModifyGuild,
  new splash: ImageData,
) -> ModifyGuild {
  ModifyGuild(..modify, splash: Modify(splash))
}

pub fn delete_guild_splash(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, splash: Delete)
}

/// The splash must be a PNG/JPEG image with a 16:9 aspect ratio.
///
/// The guild must have the `GuildIsDiscoverable` feature.
pub fn modify_guild_discovery_splash(
  modify: ModifyGuild,
  new splash: ImageData,
) -> ModifyGuild {
  ModifyGuild(..modify, discovery_splash: Modify(splash))
}

pub fn delete_guild_discovery_splash(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, discovery_splash: Delete)
}

/// If not animated, the banner must be a PNG/JPEG image with a 16:9 aspect ratio.
///
/// If animated, the banner must be a GIF image with a 16:9 aspect ratio
/// and the guild must have the `GuildCanUseAnimatedBanner` feature.
/// 
/// In all cases, the guild must have the `GuildCanUseBanner` feature.
pub fn modify_guild_banner(
  modify: ModifyGuild,
  new banner: ImageData,
) -> ModifyGuild {
  ModifyGuild(..modify, banner: Modify(banner))
}

pub fn delete_guild_banner(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, banner: Delete)
}

pub fn modify_guild_system_channel(
  modify: ModifyGuild,
  new_id id: Snowflake(Channel),
) -> ModifyGuild {
  ModifyGuild(..modify, system_channel_id: Modify(id))
}

/// Makes the guild not have a system channel anymore.
///
/// This will not delete the channel.
pub fn unset_guild_system_channel(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, system_channel_id: Delete)
}

pub fn modify_guild_system_channel_flags(
  modify: ModifyGuild,
  new flags: List(GuildSystemChannelFlag),
) -> ModifyGuild {
  ModifyGuild(..modify, system_channel_flags: Some(flags))
}

pub fn modify_guild_rules_channel(
  modify: ModifyGuild,
  new_id id: Snowflake(Channel),
) -> ModifyGuild {
  ModifyGuild(..modify, rules_channel_id: Modify(id))
}

/// Makes the guild not have a rules channel anymore.
///
/// This will not delete the channel.
pub fn unset_guild_rules_channel(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, rules_channel_id: Delete)
}

pub fn modify_guild_public_updates_channel(
  modify: ModifyGuild,
  new_id id: Snowflake(Channel),
) -> ModifyGuild {
  ModifyGuild(..modify, public_updates_channel_id: Modify(id))
}

/// Makes the guild not have a public updates channel anymore.
///
/// This will not delete the channel.
pub fn unset_guild_public_updates_channel(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, public_updates_channel_id: Delete)
}

pub type Locale {
  IndonesianLocale
  DanishLocale
  GermanLocale
  EnglishUkLocale
  EnglishUsLocale
  SpanishSpainLocale
  SpanishLatamLocale
  FrenchLocale
  CroatianLocale
  ItalianLocale
  LithuanianLocale
  HungarianLocale
  DutchLocale
  NorwegianLocale
  PolishLocale
  PortugueseBrazilLocale
  RomanianRomaniaLocale
  FinnishLocale
  SwedishLocale
  VietnameseLocale
  TurkishLocale
  CzechLocale
  GreekLocale
  BulgarianLocale
  RussianLocale
  UkrainianLocale
  HindiLocale
  ThaiLocale
  ChineseChinaLocale
  JapaneseLocale
  ChineseTaiwanLocale
  KoreanLocale
}

fn locale_to_json(locale: Locale) -> Json {
  case locale {
    IndonesianLocale -> json.string("id")
    DanishLocale -> json.string("da")
    GermanLocale -> json.string("de")
    EnglishUkLocale -> json.string("en-GB")
    EnglishUsLocale -> json.string("en-US")
    SpanishSpainLocale -> json.string("es-ES")
    SpanishLatamLocale -> json.string("es-419")
    FrenchLocale -> json.string("fr")
    CroatianLocale -> json.string("hr")
    ItalianLocale -> json.string("it")
    LithuanianLocale -> json.string("lt")
    HungarianLocale -> json.string("hu")
    DutchLocale -> json.string("nl")
    NorwegianLocale -> json.string("no")
    PolishLocale -> json.string("pl")
    PortugueseBrazilLocale -> json.string("pt-BR")
    RomanianRomaniaLocale -> json.string("ro")
    FinnishLocale -> json.string("fi")
    SwedishLocale -> json.string("sv-SE")
    VietnameseLocale -> json.string("vi")
    TurkishLocale -> json.string("tr")
    CzechLocale -> json.string("cs")
    GreekLocale -> json.string("el")
    BulgarianLocale -> json.string("bg")
    RussianLocale -> json.string("ru")
    UkrainianLocale -> json.string("uk")
    HindiLocale -> json.string("hi")
    ThaiLocale -> json.string("th")
    ChineseChinaLocale -> json.string("zh-CN")
    JapaneseLocale -> json.string("ja")
    ChineseTaiwanLocale -> json.string("zh-TW")
    KoreanLocale -> json.string("ko")
  }
}

fn locale_decoder() -> Decoder(Locale) {
  use variant <- decode.then(decode.string)
  case variant {
    "id" -> decode.success(IndonesianLocale)
    "da" -> decode.success(DanishLocale)
    "de" -> decode.success(GermanLocale)
    "en-GB" -> decode.success(EnglishUkLocale)
    "en-US" -> decode.success(EnglishUsLocale)
    "es-ES" -> decode.success(SpanishSpainLocale)
    "es-419" -> decode.success(SpanishLatamLocale)
    "fr" -> decode.success(FrenchLocale)
    "hr" -> decode.success(CroatianLocale)
    "it" -> decode.success(ItalianLocale)
    "lt" -> decode.success(LithuanianLocale)
    "hu" -> decode.success(HungarianLocale)
    "nl" -> decode.success(DutchLocale)
    "no" -> decode.success(NorwegianLocale)
    "pl" -> decode.success(PolishLocale)
    "pt-BR" -> decode.success(PortugueseBrazilLocale)
    "ro" -> decode.success(RomanianRomaniaLocale)
    "fi" -> decode.success(FinnishLocale)
    "sv-SE" -> decode.success(SwedishLocale)
    "vi" -> decode.success(VietnameseLocale)
    "tr" -> decode.success(TurkishLocale)
    "cs" -> decode.success(CzechLocale)
    "el" -> decode.success(GreekLocale)
    "bg" -> decode.success(BulgarianLocale)
    "ru" -> decode.success(RussianLocale)
    "uk" -> decode.success(UkrainianLocale)
    "hi" -> decode.success(HindiLocale)
    "th" -> decode.success(ThaiLocale)
    "zh-CN" -> decode.success(ChineseChinaLocale)
    "ja" -> decode.success(JapaneseLocale)
    "zh-TW" -> decode.success(ChineseTaiwanLocale)
    "ko" -> decode.success(KoreanLocale)
    _ -> decode.failure(IndonesianLocale, "Locale")
  }
}

pub fn modify_guild_preferred_locale(
  modify: ModifyGuild,
  new preferred_locale: Locale,
) -> ModifyGuild {
  ModifyGuild(..modify, preferred_locale: Modify(preferred_locale))
}

/// Modifies the guild's features to the provided list. 
///
/// You can only modify the following features:
/// * `GuildIsCommunity` - requires the `AdministratorPermission` permission
/// * `GuildIsDiscoverable` - requires the `AdministratorPermission` permission. The guild must also satisfy all the discovery requirements.
/// * `GuildHasPausedInvites` - requires the `AllowManagingGuild` permission
/// * `GuildDisabledRaidAlerts` - requires the `AllowManagingGuild` permission
///
/// NOTE: **All** enabled features, mutable and immutable, must be provided.
pub fn modify_guild_features(
  modify: ModifyGuild,
  new features: List(GuildFeature),
) -> ModifyGuild {
  ModifyGuild(..modify, features: Some(features))
}

pub fn modify_guild_description(
  modify: ModifyGuild,
  new description: String,
) -> ModifyGuild {
  ModifyGuild(..modify, description: Modify(description))
}

pub fn delete_guild_description(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, description: Delete)
}

pub fn enable_guild_premium_progress_bar(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, is_premium_progress_bar_enabled: Some(True))
}

pub fn disable_guild_premium_progress_bar(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, is_premium_progress_bar_enabled: Some(False))
}

pub fn modify_guild_safety_alerts_channel(
  modify: ModifyGuild,
  new_id id: Snowflake(Channel),
) -> ModifyGuild {
  ModifyGuild(..modify, safety_alerts_channel_id: Modify(id))
}

/// Makes the guild not have a safety alerts channel anymore.
///
/// This will not delete the channel.
pub fn unset_guild_safety_alerts_channel(modify: ModifyGuild) -> ModifyGuild {
  ModifyGuild(..modify, safety_alerts_channel_id: Delete)
}

fn optional_to_json(
  option: Option(a),
  name: String,
  encoder: fn(a) -> Json,
) -> Result(#(String, Json), Nil) {
  case option {
    Some(data) -> Ok(#(name, encoder(data)))
    None -> Error(Nil)
  }
}

fn modify_guild_to_json(modify: ModifyGuild) -> Json {
  [
    optional_to_json(modify.name, "name", json.string),
    modification_to_json(
      modify.member_verification_level,
      "verification_level",
      guild_member_verification_level_to_json,
    ),
    modification_to_json(
      modify.default_message_notification_setting,
      "default_message_notifications",
      guild_default_message_notification_setting_to_json,
    ),
    modification_to_json(
      modify.explicit_content_filter_setting,
      "explicit_content_filter",
      guild_explicit_content_filter_setting_to_json,
    ),
    modification_to_json(
      modify.afk_channel_id,
      "afk_channel_id",
      snowflake_to_json,
    ),
    optional_to_json(modify.afk_timeout, "afk_timeout", afk_timeout_to_json),
    modification_to_json(modify.icon, "icon", image_data_to_json),
    modification_to_json(modify.splash, "splash", image_data_to_json),
    modification_to_json(
      modify.discovery_splash,
      "discovery_splash",
      image_data_to_json,
    ),
    modification_to_json(modify.banner, "banner", image_data_to_json),
    modification_to_json(
      modify.system_channel_id,
      "system_channel_id",
      snowflake_to_json,
    ),
    optional_to_json(
      modify.system_channel_flags,
      "system_channel_flags",
      flags_to_json(_, bits_guild_system_channel_flags()),
    ),
    modification_to_json(
      modify.rules_channel_id,
      "rules_channel_id",
      snowflake_to_json,
    ),
    modification_to_json(
      modify.public_updates_channel_id,
      "public_updates_channel_id",
      snowflake_to_json,
    ),
    modification_to_json(
      modify.preferred_locale,
      "preferred_locale",
      locale_to_json,
    ),
    optional_to_json(modify.features, "features", json.array(
      _,
      guild_feature_to_json,
    )),
    modification_to_json(modify.description, "description", json.string),
    optional_to_json(
      modify.is_premium_progress_bar_enabled,
      "premium_progress_bar_enabled",
      json.bool,
    ),
    modification_to_json(
      modify.safety_alerts_channel_id,
      "safety_alerts_channel_id",
      snowflake_to_json,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

fn guild_feature_to_json(feature: GuildFeature) -> Json {
  case feature {
    GuildCanUseAnimatedBanner -> "ANIMATED_BANNER"
    GuildCanUseAnimatedIcon -> "ANIMATED_ICON"
    GuildUsesOldPermissionConfigurationBehavior ->
      "APPLICATION_COMMAND_PERMISSIONS_V2"
    GuildCreatedAutoModerationRules -> "AUTO_MODERATION"
    GuildCanUseBanner -> "BANNER"
    GuildIsCommunity -> "COMMUNITY"
    GuildUsesMonetization -> "CREATOR_MONETIZABLE_PROVISIONAL"
    GuildUsesRoleSubscriptionPromoPage -> "CREATOR_STORE_PAGE"
    GuildIsDeveloperSupportServer -> "DEVELOPER_SUPPORT_SERVER"
    GuildIsDiscoverable -> "DISCOVERABLE"
    GuildIsFeaturable -> "FEATURABLE"
    GuildHasPausedInvites -> "INVITES_DISABLED"
    GuildCanUseInviteSplash -> "INVITE_SPLASH"
    GuildUsesMembershipScreening -> "MEMBER_VERIFICATION_GATE_ENABLED"
    GuildHasMoreSoundboardSoundSlots -> "MORE_SOUNDBOARD"
    GuildHasMoreStickerSlots -> "MORE_STICKERS"
    GuildCanCreateAnnouncementChannels -> "NEWS"
    GuildIsPartnered -> "PARTNERED"
    GuildCanBePreviewed -> "PREVIEW_ENABLED"
    GuildDisabledRaidAlerts -> "RAID_ALERTS_DISABLED"
    GuildCanUseRoleIcons -> "ROLE_ICONS"
    GuildHasPurchasableRoleSubscriptions ->
      "ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE"
    GuildUsesRoleSubscriptions -> "ROLE_SUBSCRIPTIONS_ENABLED"
    GuildCreatedSoundboardSounds -> "SOUNDBOARD"
    GuildUsesTicketedEvents -> "TICKETED_EVENTS_ENABLED"
    GuildCanUseVanityUrl -> "VANITY_URL"
    GuildIsVerified -> "VERIFIED"
    GuildCanUse384KbpsVoiceBitrate -> "VIP_REGIONS"
    GuildUsesWelcomeScreen -> "WELCOME_SCREEN"
    GuildCanUseGuestInvites -> "GUESTS_ENABLED"
    GuildCanUseGuildTags -> "GUILD_TAGS"
    GuildCanUseEnhancedRoleColours -> "ENHANCED_ROLE_COLORS"
  }
  |> json.string
}

fn afk_timeout_to_json(afk_timeout: AfkTimeout) -> Json {
  case afk_timeout {
    AfkTimeout60Seconds -> 60
    AfkTimeout300Seconds -> 300
    AfkTimeout900Seconds -> 900
    AfkTimeout1800Seconds -> 1800
    AfkTimeout3600Seconds -> 3600
  }
  |> json.int
}

fn guild_explicit_content_filter_setting_to_json(
  setting: GuildExplicitContentFilterSetting,
) -> Json {
  case setting {
    GuildExplicitContentFilterDisabled -> 0
    GuildExplicitContentFilterForMembersWithoutRoles -> 1
    GuildExplicitContentFilterForAllMembers -> 2
  }
  |> json.int
}

fn guild_default_message_notification_setting_to_json(
  setting: GuildDefaultMessageNotificationSetting,
) -> Json {
  case setting {
    NotifyForAllMessages -> 0
    NotifyOnlyForMentions -> 1
  }
  |> json.int
}

fn guild_member_verification_level_to_json(
  level: GuildMemberVerificationLevel,
) -> Json {
  case level {
    NoGuildMemberVerification -> 0
    LowGuildMemberVerification -> 1
    MediumGuildMemberVerification -> 2
    HighGuildMemberVerification -> 3
    VeryHighGuildMemberVerification -> 4
  }
  |> json.int
}

/// Requires the `AllowManagingGuild` permission.
pub fn modify_guild(
  token token: Token,
  id id: Snowflake(Guild),
  using modify: ModifyGuild,
  reason reason: Option(String),
) -> Result(Guild, RestError) {
  let body =
    modify
    |> modify_guild_to_json
    |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(id),
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_decoder())
}

fn channel_decoder() -> Decoder(Channel) {
  use id <- decode.field("id", snowflake_decoder())
  use type_ <- decode.field("type", decode.int)
  use data <- decode.then(case type_ {
    1 -> decode.map(dm_channel_decoder(), ChannelDm)
    10 | 11 | 12 -> decode.map(thread_decoder(), ChannelThread)
    0 | 2 | 4 | 5 | 13 | 15 | 16 ->
      decode.map(guild_channel_decoder(), ChannelGuild)
    _ ->
      decode.failure(
        ChannelGuild(GuildChannel(
          Snowflake(0),
          ChannelCategory(CategoryChannel(Snowflake(0))),
          [],
          None,
          0,
          "",
        )),
        "ChannelData",
      )
  })

  decode.success(Channel(id:, data:))
}

fn dm_channel_decoder() -> Decoder(DmChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use last_message_id <- decode.optional_field(
    "last_message_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use recipient <- decode.field("recipients", decode.at([0], user_decoder()))
  use last_pin_timestamp <- decode.optional_field(
    "last_pin_timestamp",
    None,
    decode.optional(rfc3339_decoder()),
  )

  decode.success(DmChannel(
    id:,
    last_message_id:,
    recipient:,
    last_pin_timestamp:,
  ))
}

/// Returns all the channels of a guild, excluding threads.
pub fn get_guild_channels(
  token token: Token,
  guild_id guild_id: Snowflake(Guild),
) -> Result(List(GuildChannel), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Get,
  )
  |> send_request(decode_with: decode.list(of: guild_channel_decoder()))
}

pub opaque type CreateTextChannel {
  CreateTextChannel(
    name: String,
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
    parent_id: Option(Snowflake(CategoryChannel)),
    is_nsfw: Option(Bool),
    default_thread_auto_archive_duration: Option(ThreadAutoArchiveDuration),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

fn create_text_channel_to_json(create: CreateTextChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(0))),
    optional_to_json(create.topic, "topic", json.string),
    optional_to_json(
      create.rate_limit_per_user,
      "rate_limit_per_user",
      duration_to_json_seconds,
    ),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
    optional_to_json(create.parent_id, "parent_id", snowflake_to_json),
    optional_to_json(create.is_nsfw, "nsfw", json.bool),
    optional_to_json(
      create.default_thread_auto_archive_duration,
      "default_auto_archive_duration",
      thread_auto_archive_duration_to_json,
    ),
    optional_to_json(
      create.default_thread_rate_limit_per_user,
      "default_thread_rate_limit_per_user",
      duration_to_json_seconds,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

fn duration_to_json_seconds(duration: Duration) -> Json {
  duration
  |> duration.to_seconds
  |> float.round
  |> json.int
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_text_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateTextChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_text_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_channel_decoder())
}

/// Requires the `AllowManagingChannels` permission.
pub fn new_create_text_channel(named name: String) -> CreateTextChannel {
  CreateTextChannel(name, None, None, None, None, None, None, None, None)
}

pub fn create_text_channel_with_topic(
  create: CreateTextChannel,
  topic: String,
) -> CreateTextChannel {
  CreateTextChannel(..create, topic: Some(topic))
}

/// The rate limit per user is the amount of time a user has to wait between sending messages.
pub fn create_text_channel_with_rate_limit_per_user(
  create: CreateTextChannel,
  rate_limit_per_user: Duration,
) -> CreateTextChannel {
  CreateTextChannel(..create, rate_limit_per_user: Some(rate_limit_per_user))
}

/// Channels without a specified position will automatically be assigned one at the bottom of their category/channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_text_channel_at_position(
  create: CreateTextChannel,
  position: Int,
) -> CreateTextChannel {
  CreateTextChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
pub fn create_text_channel_with_permission_overwrites(
  create: CreateTextChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateTextChannel {
  CreateTextChannel(..create, permission_overwrites: Some(overwrites))
}

/// Puts the channel in a category.
/// Channels without a parent ID will not be in a category, and will rather be independent in the server list.
pub fn create_text_channel_with_parent_id(
  create: CreateTextChannel,
  parent_id: Snowflake(CategoryChannel),
) -> CreateTextChannel {
  CreateTextChannel(..create, parent_id: Some(parent_id))
}

/// Creates an age-restricted text channel.
pub fn create_nsfw_text_channel(create: CreateTextChannel) -> CreateTextChannel {
  CreateTextChannel(..create, is_nsfw: Some(True))
}

/// Controls the default amount of time after which inactive threads are archived in the channel.
pub fn create_text_channel_with_thread_auto_archive_duration(
  create: CreateTextChannel,
  duration: ThreadAutoArchiveDuration,
) -> CreateTextChannel {
  CreateTextChannel(
    ..create,
    default_thread_auto_archive_duration: Some(duration),
  )
}

/// The default thread rate limit per user. This value gets copied to every thread and does not live-update.
pub fn create_text_channel_with_thread_rate_limit_per_user(
  create: CreateTextChannel,
  rate_limit_per_user: Duration,
) -> CreateTextChannel {
  CreateTextChannel(
    ..create,
    default_thread_rate_limit_per_user: Some(rate_limit_per_user),
  )
}

pub opaque type CreateVoiceChannel {
  CreateVoiceChannel(
    name: String,
    rate_limit_per_user: Option(Duration),
    bitrate: Option(Int),
    user_limit: Option(Int),
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
    parent_id: Option(Snowflake(CategoryChannel)),
    is_nsfw: Option(Bool),
    rtc_region_id: Option(String),
    video_quality_mode: Option(VideoQualityMode),
  )
}

fn create_voice_channel_to_json(create: CreateVoiceChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(2))),
    optional_to_json(
      create.rate_limit_per_user,
      "rate_limit_per_user",
      duration_to_json_seconds,
    ),
    optional_to_json(create.bitrate, "bitrate", json.int),
    optional_to_json(create.user_limit, "user_limit", json.int),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
    optional_to_json(create.parent_id, "parent_id", snowflake_to_json),
    optional_to_json(create.is_nsfw, "nsfw", json.bool),
    optional_to_json(create.rtc_region_id, "rtc_region", json.string),
    optional_to_json(
      create.video_quality_mode,
      "video_quality_mode",
      video_quality_mode_to_json,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_voice_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateVoiceChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_voice_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_channel_decoder())
}

pub fn new_create_voice_channel(named name: String) -> CreateVoiceChannel {
  CreateVoiceChannel(name, None, None, None, None, None, None, None, None, None)
}

/// The rate limit per user amount of time that a user has to wait between sending messages in the voice-channel attached text channel.
pub fn create_voice_channel_with_rate_limit_per_user(
  create: CreateVoiceChannel,
  limit: Duration,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, rate_limit_per_user: Some(limit))
}

/// Bitrate is expressed in bits per second.
///
/// Maximum bitrate for every premium tier:
/// * No premium tier - `96000`
/// * Premium tier 1 - `128000`
/// * Premium tier 2 - `256000`
/// * Premium tier 3 - `384000`
///
/// Additionally, servers with the `GuildCanUse384KbpsVoiceBitrate` can specify the bitrate up to `384000`. 
pub fn create_voice_channel_with_bitrate(
  create: CreateVoiceChannel,
  bitrate: Int,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, bitrate: Some(bitrate))
}

pub fn create_voice_channel_with_user_limit(
  create: CreateVoiceChannel,
  user_limit: Int,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, user_limit: Some(user_limit))
}

/// Channels without a specified position will automatically be assigned one at the bottom of their category/channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_voice_channel_at_position(
  create: CreateVoiceChannel,
  position: Int,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
pub fn create_voice_channel_with_permission_overwrites(
  create: CreateVoiceChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, permission_overwrites: Some(overwrites))
}

/// Puts the channel in a category.
/// Channels without a parent ID will not be in a category, and will rather be independent in the server list.
pub fn create_voice_channel_with_parent_id(
  create: CreateVoiceChannel,
  parent_id: Snowflake(CategoryChannel),
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, parent_id: Some(parent_id))
}

/// Creates an age-restricted voice channel.
pub fn create_nsfw_voice_channel(
  create: CreateVoiceChannel,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, is_nsfw: Some(True))
}

/// Manually sets the voice channel's region.
pub fn create_voice_channel_with_rtc_region_id(
  create: CreateVoiceChannel,
  id: String,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, rtc_region_id: Some(id))
}

pub fn create_voice_channel_with_video_quality_mode(
  create: CreateVoiceChannel,
  mode: VideoQualityMode,
) -> CreateVoiceChannel {
  CreateVoiceChannel(..create, video_quality_mode: Some(mode))
}

pub opaque type CreateCategoryChannel {
  CreateCategoryChannel(
    name: String,
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
  )
}

fn create_category_channel_to_json(create: CreateCategoryChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(4))),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_category_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateCategoryChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_category_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request.set_body(body)
  |> request_with_reason(reason)
  |> send_request(decode_with: guild_channel_decoder())
}

pub fn new_create_category_channel(named name: String) -> CreateCategoryChannel {
  CreateCategoryChannel(name, None, None)
}

/// Channels without a specified position will automatically be assigned one at the bottom of their channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_category_channel_at_position(
  create: CreateCategoryChannel,
  position: Int,
) -> CreateCategoryChannel {
  CreateCategoryChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
/// Channels can sync their permissions to their category channels.
pub fn create_category_channel_with_permission_overwrites(
  create: CreateCategoryChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateCategoryChannel {
  CreateCategoryChannel(..create, permission_overwrites: Some(overwrites))
}

pub opaque type CreateStageChannel {
  CreateStageChannel(
    name: String,
    rate_limit_per_user: Option(Duration),
    bitrate: Option(Int),
    user_limit: Option(Int),
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
    parent_id: Option(Snowflake(CategoryChannel)),
    is_nsfw: Option(Bool),
    rtc_region_id: Option(String),
    video_quality_mode: Option(VideoQualityMode),
  )
}

fn create_stage_channel_to_json(create: CreateStageChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(13))),
    optional_to_json(
      create.rate_limit_per_user,
      "rate_limit_per_user",
      duration_to_json_seconds,
    ),
    optional_to_json(create.bitrate, "bitrate", json.int),
    optional_to_json(create.user_limit, "user_limit", json.int),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
    optional_to_json(create.parent_id, "parent_id", snowflake_to_json),
    optional_to_json(create.is_nsfw, "nsfw", json.bool),
    optional_to_json(create.rtc_region_id, "rtc_region", json.string),
    optional_to_json(
      create.video_quality_mode,
      "video_quality_mode",
      video_quality_mode_to_json,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_stage_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateStageChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_stage_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_channel_decoder())
}

pub fn new_create_stage_channel(named name: String) -> CreateStageChannel {
  CreateStageChannel(name, None, None, None, None, None, None, None, None, None)
}

/// The rate limit per user amount of time that a user has to wait between sending messages in the stage-channel attached text channel.
pub fn create_stage_channel_with_rate_limit_per_user(
  create: CreateStageChannel,
  limit: Duration,
) -> CreateStageChannel {
  CreateStageChannel(..create, rate_limit_per_user: Some(limit))
}

/// Bitrate is expressed in bits per second.
///
/// Maximum bitrate for every premium tier:
/// * No premium tier - `96000`
/// * Premium tier 1 - `128000`
/// * Premium tier 2 - `256000`
/// * Premium tier 3 - `384000`
///
/// Additionally, servers with the `GuildCanUse384KbpsstageBitrate` can specify the bitrate up to `384000`. 
pub fn create_stage_channel_with_bitrate(
  create: CreateStageChannel,
  bitrate: Int,
) -> CreateStageChannel {
  CreateStageChannel(..create, bitrate: Some(bitrate))
}

pub fn create_stage_channel_with_user_limit(
  create: CreateStageChannel,
  user_limit: Int,
) -> CreateStageChannel {
  CreateStageChannel(..create, user_limit: Some(user_limit))
}

/// Channels without a specified position will automatically be assigned one at the bottom of their category/channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_stage_channel_at_position(
  create: CreateStageChannel,
  position: Int,
) -> CreateStageChannel {
  CreateStageChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
pub fn create_stage_channel_with_permission_overwrites(
  create: CreateStageChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateStageChannel {
  CreateStageChannel(..create, permission_overwrites: Some(overwrites))
}

/// Puts the channel in a category.
/// Channels without a parent ID will not be in a category, and will rather be independent in the server list.
pub fn create_stage_channel_with_parent_id(
  create: CreateStageChannel,
  parent_id: Snowflake(CategoryChannel),
) -> CreateStageChannel {
  CreateStageChannel(..create, parent_id: Some(parent_id))
}

/// Creates an age-restricted stage channel.
pub fn create_nsfw_stage_channel(
  create: CreateStageChannel,
) -> CreateStageChannel {
  CreateStageChannel(..create, is_nsfw: Some(True))
}

/// Manually sets the stage channel's region.
pub fn create_stage_channel_with_rtc_region_id(
  create: CreateStageChannel,
  id: String,
) -> CreateStageChannel {
  CreateStageChannel(..create, rtc_region_id: Some(id))
}

pub fn create_stage_channel_with_video_quality_mode(
  create: CreateStageChannel,
  mode: VideoQualityMode,
) -> CreateStageChannel {
  CreateStageChannel(..create, video_quality_mode: Some(mode))
}

pub opaque type CreateForumChannel {
  CreateForumChannel(
    name: String,
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
    parent_id: Option(Snowflake(CategoryChannel)),
    is_nsfw: Option(Bool),
    default_thread_auto_archive_duration: Option(ThreadAutoArchiveDuration),
    default_reaction: Option(DefaultForumReaction),
    available_tags: Option(List(ForumTag)),
    default_sort_order: Option(ForumSortOrder),
    default_layout: Option(ForumLayout),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

fn create_forum_channel_to_json(create: CreateForumChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(15))),
    optional_to_json(create.topic, "topic", json.string),
    optional_to_json(
      create.rate_limit_per_user,
      "rate_limit_per_user",
      duration_to_json_seconds,
    ),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
    optional_to_json(create.parent_id, "parent_id", snowflake_to_json),
    optional_to_json(create.is_nsfw, "nsfw", json.bool),
    optional_to_json(
      create.default_thread_auto_archive_duration,
      "default_auto_archive_duration",
      thread_auto_archive_duration_to_json,
    ),
    optional_to_json(
      create.default_reaction,
      "default_reaction_emoji",
      default_forum_reaction_to_json,
    ),
    optional_to_json(create.available_tags, "available_tags", json.array(
      _,
      forum_tag_to_json,
    )),
    optional_to_json(
      create.default_sort_order,
      "default_sort_order",
      forum_sort_order_to_json,
    ),
    optional_to_json(
      create.default_layout,
      "default_forum_layout",
      forum_layout_to_json,
    ),
    optional_to_json(
      create.default_thread_rate_limit_per_user,
      "default_thread_rate_limit_per_user",
      duration_to_json_seconds,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_forum_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateForumChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_forum_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_channel_decoder())
}

pub fn new_create_forum_channel(named name: String) -> CreateForumChannel {
  CreateForumChannel(
    name,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  )
}

pub fn create_forum_channel_with_topic(
  create: CreateForumChannel,
  topic: String,
) -> CreateForumChannel {
  CreateForumChannel(..create, topic: Some(topic))
}

/// The rate limit per user is the amount of time a user has to wait between sending messages.
pub fn create_forum_channel_with_rate_limit_per_user(
  create: CreateForumChannel,
  limit: Duration,
) -> CreateForumChannel {
  CreateForumChannel(..create, rate_limit_per_user: Some(limit))
}

/// Channels without a specified position will automatically be assigned one at the bottom of their category/channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_forum_channel_at_position(
  create: CreateForumChannel,
  position: Int,
) -> CreateForumChannel {
  CreateForumChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
pub fn create_forum_channel_with_permission_overwrites(
  create: CreateForumChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateForumChannel {
  CreateForumChannel(..create, permission_overwrites: Some(overwrites))
}

/// Puts the channel in a category.
/// Channels without a parent ID will not be in a category, and will rather be independent in the server list.
pub fn create_forum_channel_with_parent_id(
  create: CreateForumChannel,
  parent_id: Snowflake(CategoryChannel),
) -> CreateForumChannel {
  CreateForumChannel(..create, parent_id: Some(parent_id))
}

/// Controls the default amount of time after which inactive threads are archived in the channel.
pub fn create_forum_channel_with_thread_auto_archive_duration(
  create: CreateForumChannel,
  duration: ThreadAutoArchiveDuration,
) -> CreateForumChannel {
  CreateForumChannel(
    ..create,
    default_thread_auto_archive_duration: Some(duration),
  )
}

/// Controls the default reaction shown in the thread preview.
pub fn create_forum_channel_with_default_reaction(
  create: CreateForumChannel,
  reaction: DefaultForumReaction,
) -> CreateForumChannel {
  CreateForumChannel(..create, default_reaction: Some(reaction))
}

pub fn create_forum_channel_with_tags(
  create: CreateForumChannel,
  tags: List(ForumTag),
) -> CreateForumChannel {
  CreateForumChannel(..create, available_tags: Some(tags))
}

/// Controls the default layout the channel is shown in.
pub fn create_forum_channel_with_default_layout(
  create: CreateForumChannel,
  layout: ForumLayout,
) -> CreateForumChannel {
  CreateForumChannel(..create, default_layout: Some(layout))
}

/// Controls the default order of sorting the threads in the forum.
pub fn create_forum_channel_with_default_sort_order(
  create: CreateForumChannel,
  order: ForumSortOrder,
) -> CreateForumChannel {
  CreateForumChannel(..create, default_sort_order: Some(order))
}

/// The default thread rate limit per user. This value gets copied to every thread and does not live-update.
pub fn create_forum_channel_with_thread_rate_limit_per_user(
  create: CreateForumChannel,
  limit: Duration,
) -> CreateForumChannel {
  CreateForumChannel(..create, default_thread_rate_limit_per_user: Some(limit))
}

pub opaque type CreateMediaChannel {
  CreateMediaChannel(
    name: String,
    topic: Option(String),
    rate_limit_per_user: Option(Duration),
    position: Option(Int),
    permission_overwrites: Option(List(PermissionOverwrite)),
    parent_id: Option(Snowflake(CategoryChannel)),
    is_nsfw: Option(Bool),
    default_thread_auto_archive_duration: Option(ThreadAutoArchiveDuration),
    default_reaction: Option(DefaultForumReaction),
    available_tags: Option(List(ForumTag)),
    default_sort_order: Option(ForumSortOrder),
    default_thread_rate_limit_per_user: Option(Duration),
  )
}

fn create_media_channel_to_json(create: CreateMediaChannel) -> Json {
  [
    Ok(#("name", json.string(create.name))),
    Ok(#("type", json.int(16))),
    optional_to_json(create.topic, "topic", json.string),
    optional_to_json(
      create.rate_limit_per_user,
      "rate_limit_per_user",
      duration_to_json_seconds,
    ),
    optional_to_json(create.position, "position", json.int),
    optional_to_json(
      create.permission_overwrites,
      "permission_overwrites",
      json.array(_, permission_overwrite_to_json),
    ),
    optional_to_json(create.parent_id, "parent_id", snowflake_to_json),
    optional_to_json(create.is_nsfw, "nsfw", json.bool),
    optional_to_json(
      create.default_thread_auto_archive_duration,
      "default_auto_archive_duration",
      thread_auto_archive_duration_to_json,
    ),
    optional_to_json(
      create.default_reaction,
      "default_reaction_emoji",
      default_forum_reaction_to_json,
    ),
    optional_to_json(create.available_tags, "available_tags", json.array(
      _,
      forum_tag_to_json,
    )),
    optional_to_json(
      create.default_sort_order,
      "default_sort_order",
      forum_sort_order_to_json,
    ),
    optional_to_json(
      create.default_thread_rate_limit_per_user,
      "default_thread_rate_limit_per_user",
      duration_to_json_seconds,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn create_media_channel(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateMediaChannel,
  reason reason: Option(String),
) -> Result(GuildChannel, RestError) {
  let body = create |> create_media_channel_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_channel_decoder())
}

pub fn new_create_media_channel(named name: String) -> CreateMediaChannel {
  CreateMediaChannel(
    name,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
    None,
  )
}

pub fn create_media_channel_with_topic(
  create: CreateMediaChannel,
  topic: String,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, topic: Some(topic))
}

/// The rate limit per user is the amount of time a user has to wait between sending messages.
pub fn create_media_channel_with_rate_limit_per_user(
  create: CreateMediaChannel,
  limit: Duration,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, rate_limit_per_user: Some(limit))
}

/// Channels without a specified position will automatically be assigned one at the bottom of their category/channel list.
/// Channels with the same position are sorted by ID (new channel will be lower)
pub fn create_media_channel_at_position(
  create: CreateMediaChannel,
  position: Int,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, position: Some(position))
}

/// You can only allow/deny permissions if your bot has those permissions.
/// Setting the `AllowManagingRoles` permission requires your bot to have the `AdministratorPermission`.
pub fn create_media_channel_with_permission_overwrites(
  create: CreateMediaChannel,
  overwrites: List(PermissionOverwrite),
) -> CreateMediaChannel {
  CreateMediaChannel(..create, permission_overwrites: Some(overwrites))
}

/// Puts the channel in a category.
/// Channels without a parent ID will not be in a category, and will rather be independent in the server list.
pub fn create_media_channel_with_parent_id(
  create: CreateMediaChannel,
  parent_id: Snowflake(CategoryChannel),
) -> CreateMediaChannel {
  CreateMediaChannel(..create, parent_id: Some(parent_id))
}

/// Controls the default amount of time after which inactive threads are archived in the channel.
pub fn create_media_channel_with_thread_auto_archive_duration(
  create: CreateMediaChannel,
  duration: ThreadAutoArchiveDuration,
) -> CreateMediaChannel {
  CreateMediaChannel(
    ..create,
    default_thread_auto_archive_duration: Some(duration),
  )
}

/// Controls the default reaction shown in the thread preview.
pub fn create_media_channel_with_default_reaction(
  create: CreateMediaChannel,
  reaction: DefaultForumReaction,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, default_reaction: Some(reaction))
}

pub fn create_media_channel_with_tags(
  create: CreateMediaChannel,
  tags: List(ForumTag),
) -> CreateMediaChannel {
  CreateMediaChannel(..create, available_tags: Some(tags))
}

/// Controls the default order of sorting the threads in the media.
pub fn create_media_channel_with_default_sort_order(
  create: CreateMediaChannel,
  order: ForumSortOrder,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, default_sort_order: Some(order))
}

/// The default thread rate limit per user. This value gets copied to every thread and does not live-update.
pub fn create_media_channel_with_thread_rate_limit_per_user(
  create: CreateMediaChannel,
  limit: Duration,
) -> CreateMediaChannel {
  CreateMediaChannel(..create, default_thread_rate_limit_per_user: Some(limit))
}

pub opaque type ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(
    id: Snowflake(GuildChannel),
    position: Modification(Int),
    sync_permissions: Option(Bool),
    parent_id: Modification(Snowflake(CategoryChannel)),
  )
}

pub fn new_modify_guild_channel_position(
  of_channel_with_id id: Snowflake(GuildChannel),
) -> ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(id, Skip, None, Skip)
}

pub fn modify_guild_channel_position(
  modify: ModifyGuildChannelPosition,
  new position: Int,
) -> ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(..modify, position: Modify(position))
}

/// Resets the channel's position back to the default - will put the channel at the bottom of the category/channel list.
pub fn unset_guild_channel_position(
  modify: ModifyGuildChannelPosition,
) -> ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(..modify, position: Delete)
}

/// `sync_permissions` - whether to sync the permission overwrites with the new parent.
pub fn modify_guild_channel_parent_id(
  modify: ModifyGuildChannelPosition,
  new parent_id: Snowflake(CategoryChannel),
  sync_permissions sync_permissions: Bool,
) -> ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(
    ..modify,
    parent_id: Modify(parent_id),
    sync_permissions: Some(sync_permissions),
  )
}

/// Makes the channel independent of a category, putting it by itself in the channel list.
pub fn unset_guild_channel_parent_id(
  modify: ModifyGuildChannelPosition,
) -> ModifyGuildChannelPosition {
  ModifyGuildChannelPosition(..modify, parent_id: Delete)
}

fn modify_guild_channel_position_to_json(
  modify: ModifyGuildChannelPosition,
) -> Json {
  [
    Ok(#("id", snowflake_to_json(modify.id))),
    modification_to_json(modify.position, "position", json.int),
    optional_to_json(modify.sync_permissions, "lock_permissions", json.bool),
    modification_to_json(modify.parent_id, "parent_id", snowflake_to_json),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingChannels` permission.
pub fn modify_guild_channel_positions(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using modify: List(ModifyGuildChannelPosition),
) -> Result(Nil, RestError) {
  let body =
    modify
    |> json.array(modify_guild_channel_position_to_json)
    |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/channels",
    method: http.Patch,
  )
  |> request.set_body(body)
  |> send_no_content_request
}

pub type ThreadMember {
  ThreadMember(
    thread_id: Snowflake(Thread),
    user_id: Snowflake(User),
    /// When the member last joined the thread.
    joined_at: Timestamp,
  )
}

fn thread_member_decoder() -> Decoder(ThreadMember) {
  use thread_id <- decode.field("id", snowflake_decoder())
  use user_id <- decode.field("user_id", snowflake_decoder())
  use joined_at <- decode.field("join_timestamp", rfc3339_decoder())
  decode.success(ThreadMember(thread_id:, user_id:, joined_at:))
}

pub type GetAllActiveGuildThreadsResponse {
  GetAllActiveGuildThreadsResponse(
    /// The active threads. Sorted by `id` in descending order.
    threads: List(Thread),
    /// The thread member object for each thread the current user has joined.
    members: List(ThreadMember),
  )
}

fn get_all_active_guild_threads_response_decoder() -> Decoder(
  GetAllActiveGuildThreadsResponse,
) {
  use threads <- decode.field("threads", decode.list(thread_decoder()))
  use members <- decode.field("members", decode.list(thread_member_decoder()))
  decode.success(GetAllActiveGuildThreadsResponse(threads:, members:))
}

pub fn get_all_active_threads(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GetAllActiveGuildThreadsResponse, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/threads/active",
    method: http.Get,
  )
  |> send_request(decode_with: get_all_active_guild_threads_response_decoder())
}

pub fn get_guild_member(
  token token: Token,
  with_id user_id: Snowflake(User),
  in_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildMember, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/members/"
      <> snowflake_to_string(user_id),
    method: http.Get,
  )
  |> send_request(decode_with: guild_member_decoder())
}

pub opaque type GetGuildMembersOptions {
  GetGuildMembersOptions(limit: Option(Int), after: Option(Snowflake(User)))
}

pub fn new_get_guild_members_options() -> GetGuildMembersOptions {
  GetGuildMembersOptions(None, None)
}

/// Used for pagination. The parameter should be the highest user ID in the previous page.
pub fn get_guild_members_after_id(
  options: GetGuildMembersOptions,
  id: Snowflake(User),
) -> GetGuildMembersOptions {
  GetGuildMembersOptions(..options, after: Some(id))
}

/// The maximum limit is 1000 members. The API will not return more than that.
pub fn get_guild_members_with_limit(
  options: GetGuildMembersOptions,
  limit: Int,
) -> GetGuildMembersOptions {
  GetGuildMembersOptions(..options, limit: Some(int.clamp(limit, 1, 1000)))
}

/// used for query parameters
fn optional_to_string(
  option: Option(a),
  name: String,
  encoder: fn(a) -> String,
) -> Result(#(String, String), Nil) {
  case option {
    Some(data) -> Ok(#(name, encoder(data)))
    None -> Error(Nil)
  }
}

/// Requires the `GuildMembersIntent` privileged intent.
///
/// By default, will return one member. The maximum limit is 1000.
pub fn get_guild_members(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  options options: Option(GetGuildMembersOptions),
) -> Result(List(GuildMember), RestError) {
  let query = case options {
    None -> []
    Some(options) ->
      [
        optional_to_string(options.limit, "limit", int.to_string),
        optional_to_string(options.after, "after", snowflake_to_string),
      ]
      |> list.filter_map(function.identity)
  }

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/members",
    method: http.Get,
  )
  |> request.set_query(query)
  |> send_request(decode_with: decode.list(of: guild_member_decoder()))
}

/// The API will respond with one member for limits smaller than 1, and with 1000 members for limits larger than 1000.
pub fn search_guild_members(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  search_query query: String,
  limit limit: Int,
) -> Result(List(GuildMember), RestError) {
  let query = [
    #("query", query),
    #("limit", int.to_string(int.clamp(limit, 1, 1000))),
  ]

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/members/search",
    method: http.Get,
  )
  |> request.set_query(query)
  |> send_request(decode_with: decode.list(of: guild_member_decoder()))
}

pub opaque type ModifyGuildMember {
  ModifyGuildMember(
    nick: Modification(String),
    roles: Modification(List(Snowflake(Role))),
    is_mute: Modification(Bool),
    is_deaf: Modification(Bool),
    channel_id: Modification(Snowflake(MovableChannel)),
    communication_disabled_until: Modification(Timestamp),
    flags: Modification(List(GuildMemberFlag)),
  )
}

/// A movable channel is either a voice channel or a stage channel. (because you can move members to and from it)
pub type MovableChannel

pub fn voice_channel_id_to_movable_channel_id(
  id: Snowflake(VoiceChannel),
) -> Snowflake(MovableChannel) {
  Snowflake(id.id)
}

pub fn stage_channel_id_to_movable_channel_id(
  id: Snowflake(StageChannel),
) -> Snowflake(MovableChannel) {
  Snowflake(id.id)
}

pub fn new_modify_guild_member() -> ModifyGuildMember {
  ModifyGuildMember(Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

/// Requires the `AllowManagingNicknames` permission.
pub fn modify_guild_member_nick(
  modify: ModifyGuildMember,
  new nick: String,
) -> ModifyGuildMember {
  ModifyGuildMember(..modify, nick: Modify(nick))
}

/// Requires the `AllowManagingNicknames` permission.
pub fn delete_guild_member_nick(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, nick: Delete)
}

/// Requires the `AllowManagingRoles` permission.
///
/// Supply the function with all of the member's future roles.
pub fn modify_guild_member_roles(
  modify: ModifyGuildMember,
  new_roles_ids roles: List(Snowflake(Role)),
) -> ModifyGuildMember {
  ModifyGuildMember(..modify, roles: Modify(roles))
}

/// Requires the `AllowManagingRoles` permission.
/// 
/// Does not actually delete the roles - only removes them from the member.
pub fn delete_guild_member_roles(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, roles: Delete)
}

/// Requires the `AllowMutingMembersInVoiceChannels` permission.
///
/// Denies the user's permission to speak in all the guild's voice channels.
/// 
/// Will return a bad request if the user is not in a voice channel.
pub fn mute_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, is_mute: Modify(True))
}

/// Requires the `AllowMutingMembersInVoiceChannels` permission.
///
/// Allows the user to speak in all the guild's voice channels.
/// 
/// Will return a bad request if the user is not in a voice channel.
pub fn unmute_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, is_mute: Modify(False))
}

/// Requires the `AllowDeafeningMembersInVoiceChannels` permission.
///
/// Denies the user's permission to listen and speak in all the guild's voice channels.
/// 
/// Will return a bad request if the user is not in a voice channel.
pub fn deafen_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, is_deaf: Modify(True))
}

/// Requires the `AllowDeafeningMembersInVoiceChannels` permission.
///
/// Allows the user to listen in all the guild's voice channels, and, if they were previously muted because of a server-wide deafen, allows them to speak.
///
/// Will return a bad request if the user is not in a voice channel.
pub fn undeafen_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, is_deaf: Modify(False))
}

/// Requires the `AllowMovingMembersBetweenVoiceChannels` permission and the `AllowConnectingToVoiceChannels` permission for that voice channel.
///
/// Will return a bad request if the user is not in a voice channel.
pub fn move_guild_member(
  modify: ModifyGuildMember,
  to channel_id: Snowflake(MovableChannel),
) -> ModifyGuildMember {
  ModifyGuildMember(..modify, channel_id: Modify(channel_id))
}

/// Requires the `AllowMovingMembersBetweenVoiceChannels` permission and the `AllowConnectingToVoiceChannels` permission for that voice channel.
///
/// Will return a bad request if the user is not in a voice channel.
pub fn disconnect_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, channel_id: Delete)
}

/// Requires the `AllowModeratingMembers` permission.
///
/// The timeout can be issued for a maximum of 28 days.
/// 
/// Will override all previous timeouts.
///
/// Will return a `Forbidden (403)` status code if the member has the `AdministratorPermission` or is the guild's owner.
pub fn timeout_guild_member(
  modify: ModifyGuildMember,
  until timestamp: Timestamp,
) -> ModifyGuildMember {
  ModifyGuildMember(..modify, communication_disabled_until: Modify(timestamp))
}

/// Requires the `AllowModeratingMembers` permission.
pub fn untimeout_guild_member(modify: ModifyGuildMember) -> ModifyGuildMember {
  ModifyGuildMember(..modify, communication_disabled_until: Delete)
}

/// You can only add or remove the `GuildMemberBypassesVerificationFlag`.
///
/// Supply the function with all of the future flags.
///
/// Requires one of the following permissions:
/// * `AllowManagingGuild`
/// * `AllowManagingRoles`
/// * `AllowModeratingMembers` + `AllowKickingMembers` + `AllowBanningMembers`
pub fn modify_guild_member_flags(
  modify: ModifyGuildMember,
  new flags: List(GuildMemberFlag),
) -> ModifyGuildMember {
  ModifyGuildMember(..modify, flags: Modify(flags))
}

fn modify_guild_member_to_json(modify: ModifyGuildMember) -> Json {
  [
    modification_to_json(modify.nick, "nick", json.string),
    modification_to_json(modify.roles, "roles", json.array(_, snowflake_to_json)),
    modification_to_json(modify.is_mute, "mute", json.bool),
    modification_to_json(modify.is_deaf, "deaf", json.bool),
    modification_to_json(modify.channel_id, "channel_id", snowflake_to_json),
    modification_to_json(
      modify.communication_disabled_until,
      "communication_disabled_until",
      timestamp_to_json,
    ),
    modification_to_json(modify.flags, "flags", flags_to_json(
      _,
      bits_guild_member_flags(),
    )),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

fn timestamp_to_json(timestamp: Timestamp) -> Json {
  timestamp
  |> timestamp.to_rfc3339(duration.seconds(0))
  |> json.string
}

pub fn modify_guild_member(
  token token: Token,
  with_id user_id: Snowflake(User),
  in_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyGuildMember,
  reason reason: Option(String),
) -> Result(GuildMember, RestError) {
  let body = modify |> modify_guild_member_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/members/"
      <> snowflake_to_string(user_id),
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_member_decoder())
}

pub opaque type ModifyCurrentMember {
  ModifyCurrentMember(
    nick: Modification(String),
    banner: Modification(ImageData),
    avatar: Modification(ImageData),
    bio: Modification(String),
  )
}

pub fn new_modify_current_member() -> ModifyCurrentMember {
  ModifyCurrentMember(Skip, Skip, Skip, Skip)
}

/// Requires the `AllowChangingOwnNickname` permission.
pub fn modify_current_member_nick(
  modify: ModifyCurrentMember,
  new nick: String,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, nick: Modify(nick))
}

/// Requires the `AllowChangingOwnNickname` permission.
pub fn delete_current_member_nick(
  modify: ModifyCurrentMember,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, nick: Delete)
}

/// Modifies your per-guild banner.
pub fn modify_current_member_banner(
  modify: ModifyCurrentMember,
  new banner: ImageData,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, banner: Modify(banner))
}

/// Modifies your per-guild banner.
pub fn delete_current_member_banner(
  modify: ModifyCurrentMember,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, banner: Delete)
}

/// Modifies your per-guild avatar.
pub fn modify_current_member_avatar(
  modify: ModifyCurrentMember,
  new avatar: ImageData,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, avatar: Modify(avatar))
}

/// Modifies your per-guild avatar.
pub fn delete_current_member_avatar(
  modify: ModifyCurrentMember,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, avatar: Delete)
}

/// Modifies your per-guild bio.
pub fn modify_current_member_bio(
  modify: ModifyCurrentMember,
  new bio: String,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, bio: Modify(bio))
}

/// Modifies your per-guild bio.
pub fn delete_current_member_bio(
  modify: ModifyCurrentMember,
) -> ModifyCurrentMember {
  ModifyCurrentMember(..modify, bio: Delete)
}

fn modify_current_member_to_json(modify: ModifyCurrentMember) -> Json {
  [
    modification_to_json(modify.nick, "nick", json.string),
    modification_to_json(modify.banner, "banner", image_data_to_json),
    modification_to_json(modify.avatar, "avatar", image_data_to_json),
    modification_to_json(modify.bio, "bio", json.string),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

pub fn modify_current_member(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyCurrentMember,
  reason reason: Option(String),
) -> Result(GuildMember, RestError) {
  let body = modify |> modify_current_member_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/members/@me",
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_member_decoder())
}

/// Requires the `AllowManagingRoles` permission.
pub fn add_guild_member_role(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  to_member_with_id user_id: Snowflake(User),
  with_id role_id: Snowflake(Role),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/members/"
      <> snowflake_to_string(user_id)
      <> "/roles/"
      <> snowflake_to_string(role_id),
    method: http.Put,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

/// Requires the `AllowManagingRoles` permission.
/// 
/// Doesn't actually delete the role, only removes it from the user's profile.
pub fn delete_guild_member_role(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  from_member_with_id user_id: Snowflake(User),
  with_id role_id: Snowflake(Role),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/members/"
      <> snowflake_to_string(user_id)
      <> "/roles/"
      <> snowflake_to_string(role_id),
    method: http.Delete,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

/// Requires the `AllowKickingMembers` permission
pub fn kick_guild_member(
  token token: Token,
  with_id user_id: Snowflake(User),
  from_guild_with_id guild_id: Snowflake(Guild),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/members/"
      <> snowflake_to_string(user_id),
    method: http.Delete,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

pub type GuildBan {
  GuildBan(reason: Option(String), user: User)
}

fn guild_ban_decoder() -> Decoder(GuildBan) {
  use reason <- decode.field("reason", decode.optional(decode.string))
  use user <- decode.field("user", user_decoder())
  decode.success(GuildBan(reason:, user:))
}

pub opaque type GetGuildBansOptions {
  GetGuildBansOptions(
    limit: Option(Int),
    before: Option(Snowflake(User)),
    after: Option(Snowflake(User)),
  )
}

pub fn new_get_guild_bans_options() -> GetGuildBansOptions {
  GetGuildBansOptions(None, None, None)
}

/// Between 1-1000 bans.
pub fn get_guild_bans_with_limit(
  options: GetGuildBansOptions,
  limit: Int,
) -> GetGuildBansOptions {
  GetGuildBansOptions(..options, limit: Some(int.clamp(limit, 1, 1000)))
}

/// Used for pagination. Takes priority over `get_guild_bans_after_id`.
pub fn get_guild_bans_before_id(
  options: GetGuildBansOptions,
  id: Snowflake(User),
) -> GetGuildBansOptions {
  GetGuildBansOptions(..options, before: Some(id))
}

/// Used for pagination. The parameter should be the highest user ID in the previous page.
pub fn get_guild_bans_after_id(
  options: GetGuildBansOptions,
  id: Snowflake(User),
) -> GetGuildBansOptions {
  GetGuildBansOptions(..options, after: Some(id))
}

fn get_guild_bans_options_to_query(
  options: GetGuildBansOptions,
) -> List(#(String, String)) {
  [
    optional_to_string(options.limit, "limit", int.to_string),
    optional_to_string(options.before, "before", snowflake_to_string),
    optional_to_string(options.after, "after", snowflake_to_string),
  ]
  |> list.filter_map(function.identity)
}

/// Requires the `AllowBanningMembers` permission.
pub fn get_guild_bans(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  options options: Option(GetGuildBansOptions),
) -> Result(List(GuildBan), RestError) {
  let query = case options {
    Some(options) -> options |> get_guild_bans_options_to_query
    None -> []
  }

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/bans",
    method: http.Get,
  )
  |> request.set_query(query)
  |> send_request(decode_with: decode.list(of: guild_ban_decoder()))
}

/// Requires the `AllowBanningMembers` permission.
pub fn get_guild_ban(
  token token: Token,
  of_user_with_id user_id: Snowflake(Guild),
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildBan, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/bans/"
      <> snowflake_to_string(user_id),
    method: http.Get,
  )
  |> send_request(decode_with: guild_ban_decoder())
}

/// Requires the `AllowBanningMembers` permission.
/// 
/// `delete_messages_since` will delete the messages the user has sent in the guild that are at most 7 days old.
pub fn ban_guild_member(
  token token: Token,
  with_id user_id: Snowflake(User),
  from_guild_with_id guild_id: Snowflake(Guild),
  delete_messages_since delete_messages_since: Option(Duration),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  let json = case delete_messages_since {
    Some(duration) -> [
      #("delete_message_seconds", duration_to_json_seconds(duration)),
    ]
    None -> []
  }

  let body = json |> json.object |> json.to_string

  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/bans/"
      <> snowflake_to_string(user_id),
    method: http.Put,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_no_content_request
}

// not really a guild member if you're banned, are you?
//
// might rename this, if you read through this code and have a better idea then make an issue
// i'll happily deprecate this function (i don't wanna use remove_guild_ban because i don't think it fits ban_guild_member)
/// Requires the `AllowBanningMembers` permission.
pub fn unban_guild_member(
  token token: Token,
  with_id user_id: Snowflake(User),
  from_guild_with_id guild_id: Snowflake(Guild),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/bans/"
      <> snowflake_to_string(user_id),
    method: http.Delete,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

pub type BulkGuildBanResponse {
  BulkGuildBanResponse(
    banned_users: List(Snowflake(User)),
    failed_users: List(Snowflake(User)),
  )
}

fn bulk_guild_ban_response_decoder() -> Decoder(BulkGuildBanResponse) {
  use banned_users <- decode.field(
    "banned_users",
    decode.list(snowflake_decoder()),
  )
  use failed_users <- decode.field(
    "failed_users",
    decode.list(snowflake_decoder()),
  )
  decode.success(BulkGuildBanResponse(banned_users:, failed_users:))
}

/// Requires the `AllowBanningMembers` and `AllowManagingGuild` permissions.
pub fn bulk_guild_ban(
  token token: Token,
  users_with_ids user_ids: List(Snowflake(User)),
  from_guild_with_id guild_id: Snowflake(Guild),
  delete_messages_since delete_messages_since: Option(Duration),
  reason reason: Option(String),
) -> Result(BulkGuildBanResponse, RestError) {
  let body =
    [
      Ok(#("user_ids", json.array(user_ids, snowflake_to_json))),
      optional_to_json(
        delete_messages_since,
        "delete_message_seconds",
        duration_to_json_seconds,
      ),
    ]
    |> list.filter_map(function.identity)
    |> json.object
    |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/bulk-ban",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: bulk_guild_ban_response_decoder())
}

pub fn get_guild_roles(
  token token: Token,
  of_guild_with_id guild_id: Snowflake(Guild),
) -> Result(List(Role), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/roles",
    method: http.Get,
  )
  |> send_request(decode_with: decode.list(of: role_decoder()))
}

pub fn get_role(
  token token: Token,
  with_id role_id: Snowflake(Role),
  from_guild_with_id guild_id: Snowflake(Guild),
) -> Result(Role, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/roles/"
      <> snowflake_to_string(role_id),
    method: http.Get,
  )
  |> send_request(decode_with: role_decoder())
}

/// Returns a Dict of (role_id, member_count)
pub fn get_role_member_counts(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(Dict(Snowflake(Role), Int), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/roles/member-counts",
    method: http.Get,
  )
  |> send_request(decode_with: decode.dict(snowflake_decoder(), decode.int))
}

pub opaque type CreateRole {
  CreateRole(
    name: Option(String),
    permissions: Option(List(Permission)),
    colours: Option(RoleColours),
    is_hoisted: Option(Bool),
    icon: Option(ImageData),
    unicode_emoji: Option(String),
    is_mentionable: Option(Bool),
  )
}

fn create_role_to_json(create: CreateRole) -> Json {
  [
    optional_to_json(create.name, "name", json.string),
    optional_to_json(create.permissions, "permissions", permissions_to_json),
    optional_to_json(create.colours, "colors", role_colours_to_json),
    optional_to_json(create.is_hoisted, "hoist", json.bool),
    optional_to_json(create.icon, "icon", image_data_to_json),
    optional_to_json(create.unicode_emoji, "unicode_emoji", json.string),
    optional_to_json(create.is_mentionable, "mentionable", json.bool),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Defaults:
/// * name: "new role"
/// * permissions: the same as the guild @everyone permissions
/// * colours: { primary: 0, secondary: null, tertiary: null }
/// * is_hoisted: false
/// * icon: null
/// * unicode_emoji: null
/// * is_mentionable: false
pub fn new_create_role() -> CreateRole {
  CreateRole(None, None, None, None, None, None, None)
}

pub fn create_role_with_name(create: CreateRole, name: String) -> CreateRole {
  CreateRole(..create, name: Some(name))
}

/// Controls the role's guild-wide permissions.
pub fn create_role_with_permissions(
  create: CreateRole,
  permissions: List(Permission),
) -> CreateRole {
  CreateRole(..create, permissions: Some(permissions))
}

pub fn create_role_with_colours(
  create: CreateRole,
  colours: RoleColours,
) -> CreateRole {
  CreateRole(..create, colours: Some(colours))
}

pub fn new_role_colours() -> RoleColours {
  RoleColours(colour.black, None, None)
}

pub fn role_colours_with_primary_colour(
  colours: RoleColours,
  colour: Colour,
) -> RoleColours {
  RoleColours(..colours, primary_colour: colour)
}

pub fn role_colours_with_secondary_colour(
  colours: RoleColours,
  colour: Colour,
) -> RoleColours {
  RoleColours(..colours, secondary_colour: Some(colour))
}

pub fn role_colours_with_tertiary_colour(
  colours: RoleColours,
  colour: Colour,
) -> RoleColours {
  RoleColours(..colours, tertiary_colour: Some(colour))
}

/// Controls whether the role is shown separately in the sidebar.
pub fn create_hoisted_role(create: CreateRole) -> CreateRole {
  CreateRole(..create, is_hoisted: Some(True))
}

/// Requires the `GuildCanUseRoleIcons` feature.
pub fn create_role_with_icon(create: CreateRole, icon: ImageData) -> CreateRole {
  CreateRole(..create, icon: Some(icon))
}

/// Requires the `GuildCanUseRoleIcons` feature.
/// 
/// Accepts a unicode emoji character (e.g. 🔨)
pub fn create_role_with_unicode_emoji(
  create: CreateRole,
  emoji: String,
) -> CreateRole {
  CreateRole(..create, unicode_emoji: Some(emoji))
}

/// Allows everyone the mention the role.
pub fn create_mentionable_role(create: CreateRole) -> CreateRole {
  CreateRole(..create, is_mentionable: Some(True))
}

/// Requires the `AllowManagingRoles` permission.
pub fn create_role(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using create: CreateRole,
  reason reason: Option(String),
) -> Result(Role, RestError) {
  let body = create |> create_role_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/roles",
    method: http.Post,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: role_decoder())
}

/// See the [`move_role`](#move_role) and [`delete_role_position`](#delete_role_position) functions.
pub opaque type ModifyRolePosition {
  ModifyRolePosition(id: Snowflake(Role), position: Modification(Int))
}

fn modify_role_position_to_json(modify: ModifyRolePosition) -> Json {
  [
    Ok(#("id", snowflake_to_json(modify.id))),
    modification_to_json(modify.position, "position", json.int),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Roles with the same position are sorted by ID.
pub fn move_role(
  with_id id: Snowflake(Role),
  to_position position: Int,
) -> ModifyRolePosition {
  ModifyRolePosition(id:, position: Modify(position))
}

/// Roles with the same position are sorted by ID.
pub fn delete_role_position(
  of_role_with_id id: Snowflake(Role),
) -> ModifyRolePosition {
  ModifyRolePosition(id:, position: Delete)
}

/// Requires the `AllowManagingRoles` permission.
/// Returns all of the guild's roles.
pub fn modify_role_positions(
  token token: Token,
  in_guild_with_id guild_id: Snowflake(Guild),
  using modify: List(ModifyRolePosition),
  reason reason: Option(String),
) -> Result(List(Role), RestError) {
  let body =
    modify
    |> json.array(modify_role_position_to_json)
    |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/roles",
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: decode.list(of: role_decoder()))
}

pub opaque type ModifyRole {
  ModifyRole(
    name: Modification(String),
    permissions: Modification(List(Permission)),
    colours: Modification(RoleColours),
    is_hoisted: Modification(Bool),
    icon: Modification(ImageData),
    unicode_emoji: Modification(String),
    is_mentionable: Modification(Bool),
  )
}

fn modify_role_to_json(modify: ModifyRole) -> Json {
  [
    modification_to_json(modify.name, "name", json.string),
    modification_to_json(modify.permissions, "permissions", permissions_to_json),
    modification_to_json(modify.colours, "colors", role_colours_to_json),
    modification_to_json(modify.is_hoisted, "hoist", json.bool),
    modification_to_json(modify.icon, "icon", image_data_to_json),
    modification_to_json(modify.unicode_emoji, "unicode_emoji", json.string),
    modification_to_json(modify.is_mentionable, "mentionable", json.bool),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

pub fn new_modify_role() -> ModifyRole {
  ModifyRole(Skip, Skip, Skip, Skip, Skip, Skip, Skip)
}

pub fn modify_role_name(modify: ModifyRole, new name: String) -> ModifyRole {
  ModifyRole(..modify, name: Modify(name))
}

/// Resets the role's name to "new name".
pub fn delete_role_name(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, name: Delete)
}

/// Controls the role's guild-wide permissions.
/// Supply the function with all the future permissions.
pub fn modify_role_permissions(
  modify: ModifyRole,
  new permissions: List(Permission),
) -> ModifyRole {
  ModifyRole(..modify, permissions: Modify(permissions))
}

pub fn modify_role_colours(
  modify: ModifyRole,
  new colours: RoleColours,
) -> ModifyRole {
  ModifyRole(..modify, colours: Modify(colours))
}

pub fn delete_role_colours(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, colours: Delete)
}

/// Makes the role separate from others in the sidebar.
pub fn hoist_role(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, is_hoisted: Modify(True))
}

/// Makes the role no longer separate from others in the sidebar.
pub fn unhoist_role(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, is_hoisted: Modify(False))
}

/// Requires the `GuildCanUseRoleIcons` feature.
pub fn modify_role_icon(modify: ModifyRole, new icon: ImageData) -> ModifyRole {
  ModifyRole(..modify, icon: Modify(icon))
}

pub fn delete_role_icon(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, icon: Delete)
}

/// Requires the `GuildCanUseRoleIcons` feature.
pub fn modify_role_unicode_emoji(
  modify: ModifyRole,
  new unicode_emoji: String,
) -> ModifyRole {
  ModifyRole(..modify, unicode_emoji: Modify(unicode_emoji))
}

pub fn delete_role_unicode_emoji(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, unicode_emoji: Delete)
}

/// Allows everyone to mention the role.
pub fn modify_role_as_mentionable(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, is_mentionable: Modify(True))
}

/// Does not allow everyone to mention the role.
pub fn modify_role_as_unmentionable(modify: ModifyRole) -> ModifyRole {
  ModifyRole(..modify, is_mentionable: Modify(False))
}

/// Requires the `AllowManagingRoles` permission.
pub fn modify_role(
  token token: Token,
  with_id role_id: Snowflake(Role),
  in_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyRole,
  reason reason: Option(String),
) -> Result(Role, RestError) {
  let body = modify |> modify_role_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/roles/"
      <> snowflake_to_string(role_id),
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: role_decoder())
}

/// Requires the `AllowManagingRoles` permission.
pub fn delete_role(
  token token: Token,
  with_id role_id: Snowflake(Role),
  from_guild_with_id guild_id: Snowflake(Guild),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/roles/"
      <> snowflake_to_string(role_id),
    method: http.Delete,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

/// Requires the `AllowManagingGuild` and `AllowKickingMembers` permissions.
///
/// Returns the amount of members that would be kicked if a prune starts.
///
/// Pruning will, by default, only kick members with no roles. Include any roles which you count as prunable.
///
/// The minimum number of days is 1 and the maximum number of days is 30. Numbers not within these bounds will return the closest result (1 or 30 days)
pub fn get_guild_prunable_count(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  required_inactive_days days: Int,
  include_roles_with_ids include_roles: List(Snowflake(Role)),
) -> Result(Int, RestError) {
  let query = [
    #("days", int.to_string(int.clamp(days, 1, 30))),
    #(
      "include_roles",
      string.join(
        include_roles
          |> list.map(snowflake_to_string),
        ",",
      ),
    ),
  ]

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/prune",
    method: http.Get,
  )
  |> request.set_query(query)
  |> send_request(decode_with: decode.field(
    "pruned",
    decode.int,
    decode.success,
  ))
}

pub opaque type PruneGuild {
  PruneGuild(
    days: Option(Int),
    compute_prune_count: Bool,
    include_roles: Option(List(Snowflake(Role))),
  )
}

fn prune_guild_to_json(prune: PruneGuild) -> Json {
  [
    Ok(#("compute_prune_count", json.bool(prune.compute_prune_count))),
    optional_to_json(prune.days, "days", json.int),
    optional_to_json(prune.include_roles, "include_roles", json.array(
      _,
      snowflake_to_json,
    )),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Defaults:
/// * days: 7
/// * include_roles: None
pub fn new_prune_guild() -> PruneGuild {
  PruneGuild(None, False, None)
}

/// The minimum number of days is 1 and the maximum number of days is 30. Numbers not within these bounds will kick the closest amount of time (1 or 30 days).
pub fn prune_guild_with_required_inactive_days(
  prune: PruneGuild,
  days: Int,
) -> PruneGuild {
  PruneGuild(..prune, days: Some(int.clamp(days, 1, 30)))
}

/// Pruning will, by default, only kick members with no roles. Include any roles which you count as prunable.
pub fn prune_guild_with_included_roles(
  prune: PruneGuild,
  roles: List(Snowflake(Role)),
) -> PruneGuild {
  PruneGuild(..prune, include_roles: Some(roles))
}

/// Not recommended for large guilds, use [`prune_guild`](#prune_guild) instead.
/// 
/// Requires the `AllowManagingGuild` and `AllowKickingMembers` permissions.
/// 
/// Kicks inactive members based on the provided options.
///
/// Returns the amount of members who have been kicked. 
pub fn prune_guild_with_count(
  token token: Token,
  with_id guild_id: Snowflake(Guild),
  using prune: PruneGuild,
  reason reason: Option(String),
) -> Result(Int, RestError) {
  let prune = PruneGuild(..prune, compute_prune_count: True)

  let body = prune |> prune_guild_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/prune",
    method: http.Post,
  )
  |> request.set_body(body)
  |> request_with_reason(reason)
  |> send_request(decode_with: decode.field(
    "pruned",
    decode.int,
    decode.success,
  ))
}

/// Requires the `AllowManagingGuild` and `AllowKickingMembers` permissions.
/// 
/// Kicks inactive members based on the provided options.
pub fn prune_guild(
  token token: Token,
  with_id guild_id: Snowflake(Guild),
  using prune: PruneGuild,
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  let prune = PruneGuild(..prune, compute_prune_count: False)

  let body = prune |> prune_guild_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/prune",
    method: http.Post,
  )
  |> request.set_body(body)
  |> request_with_reason(reason)
  |> send_no_content_request
}

pub type VoiceRegion {
  VoiceRegion(
    id: String,
    name: String,
    /// Whether the region is the closest one to the current user.
    is_optimal: Bool,
    /// Avoid connecting to deprecated regions.
    is_deprecated: Bool,
    /// Whether the region is a custom one (used for Discord events)
    is_custom: Bool,
  )
}

fn voice_region_decoder() -> Decoder(VoiceRegion) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use is_optimal <- decode.field("optimal", decode.bool)
  use is_deprecated <- decode.field("deprecated", decode.bool)
  use is_custom <- decode.field("custom", decode.bool)
  decode.success(VoiceRegion(
    id:,
    name:,
    is_optimal:,
    is_deprecated:,
    is_custom:,
  ))
}

/// Unlike the similar [`get_voice_regions`](#get_voice_regions), this returns VIP regions if the guild is VIP-enabled.
pub fn get_guild_voice_regions(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(List(VoiceRegion), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/regions",
    method: http.Get,
  )
  |> send_request(decode_with: decode.list(of: voice_region_decoder()))
}

pub type Invite {
  Invite(
    /// Every invite has an unique ID (code), which is used in the link.
    ///
    /// Example: <https://discord.gg/Fm8Pwmy> -> `Fm8Pwmy` is the code!
    /// 
    /// Prepend `https://discord.gg/` to the code to create an invite link!
    code: String,
    guild: Guild,
    /// Some invites point to guild channels.
    channel: Option(GuildChannel),
    /// Auto-generated invites aren't made by users.
    inviter: Option(User),
    /// Some invites point to an activity - such as a stream.
    target: Option(InviteTarget),
    expiration: Option(Timestamp),
    /// Some invites point to a scheduled event.
    scheduled_event: Option(ScheduledEvent),
    flags: List(InviteFlag),
    /// The roles that are automatically given to a user which accepts the invite. 
    automatically_awarded_roles: List(InviteRole),
    metadata: Option(InviteMetadata),
  )
}

fn invite_decoder() -> Decoder(Invite) {
  use code <- decode.field("code", decode.string)
  use guild <- decode.field("guild", guild_decoder())
  use channel <- decode.field(
    "channel",
    decode.optional(guild_channel_decoder()),
  )
  use inviter <- decode.optional_field(
    "inviter",
    None,
    decode.optional(user_decoder()),
  )
  use target <- decode.then(invite_target_decoder())
  use expiration <- decode.field(
    "expires_at",
    decode.optional(rfc3339_decoder()),
  )
  use scheduled_event <- decode.field(
    "guild_scheduled_event",
    decode.optional(scheduled_event_decoder()),
  )
  use flags <- decode.field("flags", flags_decoder(bits_invite_flags()))
  use automatically_awarded_roles <- decode.field(
    "roles",
    decode.list(invite_role_decoder()),
  )
  use metadata <- decode.then(invite_metadata_decoder())
  decode.success(Invite(
    code:,
    guild:,
    channel:,
    inviter:,
    target:,
    expiration:,
    scheduled_event:,
    flags:,
    automatically_awarded_roles:,
    metadata:,
  ))
}

/// A partial role object for invites.
pub type InviteRole {
  InviteRole(
    id: Snowflake(Role),
    name: String,
    /// Position of this role in the hierarchy.
    /// Roles with the same position are sorted by ID.
    position: Int,
    colours: RoleColours,
    icon_hash: Option(ImageHash),
    unicode_emoji: Option(String),
  )
}

fn invite_role_decoder() -> Decoder(InviteRole) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use position <- decode.field("position", decode.int)
  use colours <- decode.field("colors", role_colours_decoder())
  use icon_hash <- decode.optional_field(
    "icon",
    None,
    decode.optional(image_hash_decoder()),
  )
  use unicode_emoji <- decode.optional_field(
    "unicode_emoji",
    None,
    decode.optional(decode.string),
  )
  decode.success(InviteRole(
    id:,
    name:,
    position:,
    colours:,
    icon_hash:,
    unicode_emoji:,
  ))
}

pub type InviteMetadata {
  InviteMetadata(
    /// How many times has the invite been used?
    uses: Int,
    /// How many times can the invite be used?
    max_uses: Int,
    /// Duration after which the invite expires.
    max_age: Duration,
    grants_temporary_membership: Bool,
    creation: Timestamp,
  )
}

fn invite_metadata_decoder() -> Decoder(Option(InviteMetadata)) {
  use uses <- decode.optional_field("uses", None, decode.optional(decode.int))

  case uses {
    Some(uses) -> {
      use max_uses <- decode.field("max_uses", decode.int)
      use max_age <- decode.field(
        "max_age",
        decode.map(decode.int, duration.seconds),
      )
      use grants_temporary_membership <- decode.field("temporary", decode.bool)
      use creation <- decode.field("created_at", rfc3339_decoder())
      decode.success(
        Some(InviteMetadata(
          uses:,
          max_uses:,
          max_age:,
          grants_temporary_membership:,
          creation:,
        )),
      )
    }
    None -> decode.success(None)
  }
}

pub type InviteFlag {
  InviteIsGuestInvite
}

fn bits_invite_flags() -> List(#(Int, InviteFlag)) {
  [#(int.bitwise_shift_left(1, 0), InviteIsGuestInvite)]
}

pub type ScheduledEvent {
  ScheduledEvent(
    id: Snowflake(ScheduledEvent),
    guild_id: Snowflake(Guild),
    location: ScheduledEventLocation,
    /// Is `None` for events created before October 25th, 2021
    creator: Option(User),
    name: String,
    description: Option(String),
    /// Match on the `location` to check the scheduled end time.
    /// Only external events are guaranteed to have an end time.
    scheduled_start_time: Timestamp,
    status: ScheduledEventStatus,
    /// How many users are subscribed to the event?
    ///
    /// It is undisclosed when this field is `None`
    user_count: Option(Int),
    cover_image_hash: Option(ImageHash),
    /// The definition for how often this event should happen.
    recurrence_rule: Option(ScheduledEventRecurrenceRule),
  )
}

fn scheduled_event_decoder() -> Decoder(ScheduledEvent) {
  use id <- decode.field("id", snowflake_decoder())
  use guild_id <- decode.field("guild_id", snowflake_decoder())
  use location <- decode.then(scheduled_event_location_decoder())
  use creator <- decode.optional_field(
    "creator",
    None,
    decode.optional(user_decoder()),
  )
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use scheduled_start_time <- decode.field(
    "scheduled_start_time",
    rfc3339_decoder(),
  )
  use status <- decode.field("status", scheduled_event_status_decoder())
  use user_count <- decode.optional_field(
    "user_count",
    None,
    decode.optional(decode.int),
  )
  use cover_image_hash <- decode.optional_field(
    "image",
    None,
    decode.optional(image_hash_decoder()),
  )
  use recurrence_rule <- decode.field(
    "recurrence_rule",
    decode.optional(scheduled_event_recurrence_rule_decoder()),
  )
  decode.success(ScheduledEvent(
    id:,
    guild_id:,
    location:,
    creator:,
    name:,
    description:,
    scheduled_start_time:,
    status:,
    user_count:,
    cover_image_hash:,
    recurrence_rule:,
  ))
}

pub fn stage_channel_id_to_guild_channel_id(
  id: Snowflake(StageChannel),
) -> Snowflake(GuildChannel) {
  Snowflake(id.id)
}

pub fn stage_channel_id_to_channel_id(
  id: Snowflake(StageChannel),
) -> Snowflake(Channel) {
  Snowflake(id.id)
}

pub fn voice_channel_id_to_guild_channel_id(
  id: Snowflake(VoiceChannel),
) -> Snowflake(GuildChannel) {
  Snowflake(id.id)
}

pub fn voice_channel_id_to_channel_id(
  id: Snowflake(VoiceChannel),
) -> Snowflake(Channel) {
  Snowflake(id.id)
}

pub type ScheduledEventLocation {
  ScheduledEventInStageChannel(
    channel_id: Snowflake(StageChannel),
    /// The type of this field is dependent on the location, hence why you must first match on the location.
    scheduled_end_time: Option(Timestamp),
  )
  ScheduledEventInVoiceChannel(
    channel_id: Snowflake(VoiceChannel),
    /// The type of this field is dependent on the location, hence why you must first match on the location.
    scheduled_end_time: Option(Timestamp),
  )
  ExternalScheduledEvent(
    /// Where will the event be held?
    location: String,
    /// The type of this field is dependent on the location, hence why you must first match on the location.
    scheduled_end_time: Timestamp,
  )
}

fn scheduled_event_location_decoder() -> Decoder(ScheduledEventLocation) {
  use entity_type <- decode.field("entity_type", decode.int)

  case entity_type {
    1 -> {
      use channel_id <- decode.field("channel_id", snowflake_decoder())
      use scheduled_end_time <- decode.field(
        "scheduled_end_time",
        decode.optional(rfc3339_decoder()),
      )
      decode.success(ScheduledEventInStageChannel(
        channel_id:,
        scheduled_end_time:,
      ))
    }
    2 -> {
      use channel_id <- decode.field("channel_id", snowflake_decoder())
      use scheduled_end_time <- decode.field(
        "scheduled_end_time",
        decode.optional(rfc3339_decoder()),
      )
      decode.success(ScheduledEventInVoiceChannel(
        channel_id:,
        scheduled_end_time:,
      ))
    }
    3 -> {
      use location <- decode.subfield(
        ["entity_metadata", "location"],
        decode.string,
      )
      use scheduled_end_time <- decode.field(
        "scheduled_end_time",
        rfc3339_decoder(),
      )
      decode.success(ExternalScheduledEvent(location:, scheduled_end_time:))
    }
    _ ->
      decode.failure(
        ScheduledEventInStageChannel(Snowflake(0), None),
        "ScheduledEventLocation",
      )
  }
}

pub type ScheduledEventStatus {
  /// The event is planned to happen.
  ScheduledEventIsPlanned
  /// The event is happening.
  ScheduledEventIsActive
  /// The event has happened.
  ScheduledEventIsCompleted
  /// The event was cancelled.
  ScheduledEventIsCancelled
}

fn scheduled_event_status_decoder() -> Decoder(ScheduledEventStatus) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(ScheduledEventIsPlanned)
    2 -> decode.success(ScheduledEventIsActive)
    3 -> decode.success(ScheduledEventIsCompleted)
    4 -> decode.success(ScheduledEventIsCancelled)
    _ -> decode.failure(ScheduledEventIsPlanned, "ScheduledEventStatus")
  }
}

pub type InviteTarget {
  StreamInvite(streaming_user: User)
  EmbeddedApplicationInvite(application: Application)
}

fn invite_target_decoder() -> Decoder(Option(InviteTarget)) {
  use type_ <- decode.optional_field(
    "target_type",
    None,
    decode.optional(decode.int),
  )
  case type_ {
    Some(1) -> {
      use streaming_user <- decode.field("target_user", user_decoder())
      decode.success(Some(StreamInvite(streaming_user:)))
    }
    Some(2) -> {
      use application <- decode.field(
        "target_application",
        application_decoder(),
      )
      decode.success(Some(EmbeddedApplicationInvite(application:)))
    }
    Some(_) ->
      decode.failure(
        Some(
          StreamInvite(User(
            Snowflake(0),
            "",
            "",
            None,
            None,
            False,
            False,
            None,
            None,
            None,
            None,
            None,
            [],
            None,
            [],
            None,
            None,
            None,
          )),
        ),
        "InviteTarget",
      )
    None -> decode.success(None)
  }
}

/// Describes how often an event recurs.
///
/// Important! System limitations: <https://docs.discord.com/developers/resources/guild-scheduled-event#system-limitations>
pub type ScheduledEventRecurrenceRule {
  ScheduledEventRecurrenceRule(
    start: Timestamp,
    end: Option(Timestamp),
    frequency: ScheduledEventRecurrenceRuleFrequency,
    /// On which weekdays should the event recur?
    ///
    /// Example: Every Thursday.
    every_weekday: Option(List(Weekday)),
    /// On which weekdays of specific weeks of the month should the event recur?
    /// 
    /// Example: Every Thursday of the 3rd week of the month.
    every_nth_weekday: Option(List(ScheduledEventRecurrenceRuleNthWeekday)),
    /// In which months should the event recur?
    ///
    /// Example: Every October. 
    every_month: Option(List(calendar.Month)),
    /// On which days of the month should the event recur?
    ///
    /// Example: On the 27th day of the month.
    every_month_day: Option(List(Int)),
    /// On which day of the year should the event recur?
    ///
    /// Example: On the 67th day of the year.
    every_year_day: Option(List(Int)),
    /// How many times does the event recur before it stops?
    count: Option(Int),
  )
}

fn scheduled_event_recurrence_rule_decoder() -> Decoder(
  ScheduledEventRecurrenceRule,
) {
  use start <- decode.field("start", rfc3339_decoder())
  use end <- decode.field("end", decode.optional(rfc3339_decoder()))
  use frequency <- decode.then(
    scheduled_event_recurrence_rule_frequency_decoder(),
  )
  use every_weekday <- decode.field(
    "by_weekday",
    decode.optional(decode.list(weekday_decoder())),
  )
  use every_nth_weekday <- decode.field(
    "by_n_weekday",
    decode.optional(
      decode.list(scheduled_event_recurrence_rule_nth_weekday_decoder()),
    ),
  )
  use every_month <- decode.field(
    "by_month",
    decode.optional(decode.list(month_decoder())),
  )
  use every_month_day <- decode.field(
    "by_month_day",
    decode.optional(decode.list(decode.int)),
  )
  use every_year_day <- decode.field(
    "by_year_day",
    decode.optional(decode.list(decode.int)),
  )
  use count <- decode.field("count", decode.optional(decode.int))
  decode.success(ScheduledEventRecurrenceRule(
    start:,
    end:,
    frequency:,
    every_weekday:,
    every_nth_weekday:,
    every_month:,
    every_month_day:,
    every_year_day:,
    count:,
  ))
}

fn weekday_decoder() -> Decoder(Weekday) {
  use weekday <- decode.then(decode.int)
  case weekday {
    0 -> decode.success(weekday.Monday)
    1 -> decode.success(weekday.Tuesday)
    2 -> decode.success(weekday.Wednesday)
    3 -> decode.success(weekday.Thursday)
    4 -> decode.success(weekday.Friday)
    5 -> decode.success(weekday.Saturday)
    6 -> decode.success(weekday.Sunday)
    _ -> decode.failure(weekday.Monday, "Weekday")
  }
}

fn month_decoder() -> Decoder(calendar.Month) {
  use month <- decode.then(decode.int)
  case month {
    1 -> decode.success(calendar.January)
    2 -> decode.success(calendar.February)
    3 -> decode.success(calendar.March)
    4 -> decode.success(calendar.April)
    5 -> decode.success(calendar.May)
    6 -> decode.success(calendar.June)
    7 -> decode.success(calendar.July)
    8 -> decode.success(calendar.August)
    9 -> decode.success(calendar.September)
    10 -> decode.success(calendar.October)
    11 -> decode.success(calendar.November)
    12 -> decode.success(calendar.December)
    _ -> decode.failure(calendar.January, "Month")
  }
}

/// `interval` describes the spacing between events.
/// 
/// For example, `ScheduledEventRecursWeekly(interval: 2)` means "every two weeks".
pub type ScheduledEventRecurrenceRuleFrequency {
  ScheduledEventRecursYearly(interval: Int)
  ScheduledEventRecursMonthly(interval: Int)
  ScheduledEventRecursWeekly(interval: Int)
  ScheduledEventRecursDaily(interval: Int)
}

fn scheduled_event_recurrence_rule_frequency_decoder() -> Decoder(
  ScheduledEventRecurrenceRuleFrequency,
) {
  use interval <- decode.field("interval", decode.int)
  use frequency <- decode.field("frequency", decode.int)

  case frequency {
    0 -> decode.success(ScheduledEventRecursYearly(interval:))
    1 -> decode.success(ScheduledEventRecursMonthly(interval:))
    2 -> decode.success(ScheduledEventRecursWeekly(interval:))
    3 -> decode.success(ScheduledEventRecursDaily(interval:))
    _ ->
      decode.failure(
        ScheduledEventRecursYearly(0),
        "ScheduledEventRecurrenceRuleFrequency",
      )
  }
}

pub type ScheduledEventRecurrenceRuleNthWeekday {
  ScheduledEventRecurrenceRuleNthWeekday(
    /// On which week of the month should the event recur? (1-5)
    n: Int,
    /// On which day of the `n`th should the event recur?
    day: Weekday,
  )
}

fn scheduled_event_recurrence_rule_nth_weekday_decoder() -> Decoder(
  ScheduledEventRecurrenceRuleNthWeekday,
) {
  use n <- decode.field("n", decode.int)
  use day <- decode.field("day", weekday_decoder())
  decode.success(ScheduledEventRecurrenceRuleNthWeekday(n:, day:))
}

/// Requires the `AllowManagingGuild` or `AllowViewingAuditLog` permission.
///
/// Will include metadata with the `AllowManagingGuild` permission.
pub fn get_guild_invites(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(List(Invite), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/invites",
    method: http.Get,
  )
  |> send_request(decode_with: decode.list(invite_decoder()))
}

/// Discord has some integrations with YouTube/Twitch for member/subscriber-only guilds.
///
/// Additionally, a guild may also be integrated with a Discord bot.
pub type GuildIntegration {
  GuildIntegration(
    id: Snowflake(GuildIntegration),
    name: String,
    is_enabled: Bool,
    account: GuildIntegrationAccount,
    /// The user who added the integration.
    ///
    /// Some older integrations do not have an attached user, most will though.
    integrator: Option(User),
    data: GuildIntegrationData,
  )
}

fn guild_integration_decoder() -> Decoder(GuildIntegration) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use is_enabled <- decode.field("enabled", decode.bool)
  use account <- decode.field("account", guild_integration_account_decoder())
  use integrator <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  use data <- decode.then(guild_integration_data_decoder())
  decode.success(GuildIntegration(
    id:,
    name:,
    is_enabled:,
    account:,
    integrator:,
    data:,
  ))
}

fn guild_integration_data_decoder() -> Decoder(GuildIntegrationData) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "twitch" | "youtube" ->
      decode.map(guild_social_integration_decoder(), GuildIntegrationSocial)
    "discord" ->
      decode.map(
        guild_discord_bot_integration_decoder(),
        GuildIntegrationDiscordBot,
      )
    "guild_subscription" -> decode.success(GuildIntegrationGuildSubscription)
    _ ->
      decode.failure(GuildIntegrationGuildSubscription, "GuildIntegrationData")
  }
}

pub type GuildIntegrationData {
  GuildIntegrationDiscordBot(data: GuildDiscordBotIntegration)
  GuildIntegrationSocial(data: GuildSocialIntegration)
  // i've got no idea what a "guild subscription" is
  GuildIntegrationGuildSubscription
}

pub type GuildDiscordBotIntegration {
  GuildDiscordBotIntegration(
    application: GuildIntegrationApplication,
    /// OAuth2 scopes the application has been authorized for.
    scopes: List(String),
  )
}

fn guild_discord_bot_integration_decoder() -> Decoder(
  GuildDiscordBotIntegration,
) {
  use application <- decode.field(
    "application",
    guild_integration_application_decoder(),
  )
  use scopes <- decode.field("scopes", decode.list(decode.string))
  decode.success(GuildDiscordBotIntegration(application:, scopes:))
}

/// The account is the integration's pseudo-user.
pub type GuildIntegrationAccount {
  GuildIntegrationAccount(id: Snowflake(User), name: String)
}

fn guild_integration_account_decoder() -> Decoder(GuildIntegrationAccount) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  decode.success(GuildIntegrationAccount(id:, name:))
}

/// Partial application object used by guild integrations.
pub type GuildIntegrationApplication {
  GuildIntegrationApplication(
    id: Snowflake(Application),
    name: String,
    icon_hash: Option(ImageHash),
    description: String,
    bot: Option(User),
  )
}

fn guild_integration_application_decoder() -> Decoder(
  GuildIntegrationApplication,
) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use icon_hash <- decode.field("icon", decode.optional(image_hash_decoder()))
  use description <- decode.field("description", decode.string)
  use bot <- decode.optional_field("bot", None, decode.optional(user_decoder()))
  decode.success(GuildIntegrationApplication(
    id:,
    name:,
    icon_hash:,
    description:,
    bot:,
  ))
}

/// A social integration is an integration between a Discord guild and Youtube/Twitch.
///
/// It's used to make subscriber-only guilds/roles.
///
/// Vocabulary:
/// - Subscriber - A paid supporter of a YouTube/Twitch channel (Twitch subscriber/YouTube channel member)
pub type GuildSocialIntegration {
  GuildSocialIntegration(
    data: GuildSocialIntegrationData,
    is_syncing: Bool,
    /// Role given to subscribers (not required)
    subscriber_role_id: Option(Snowflake(Role)),
    /// What to do after a subscription expires
    subscription_expiration_behavior: GuildSocialIntegrationSubscriptionExpirationBehavior,
    /// Grace period before acting on an expiration
    subscription_expiration_grace_period: Duration,
    last_sync_timestamp: Option(Timestamp),
    subscriber_count: Int,
    is_revoked: Bool,
  )
}

fn guild_social_integration_decoder() -> Decoder(GuildSocialIntegration) {
  use data <- decode.then(guild_social_integration_data_decoder())
  use is_syncing <- decode.field("syncing", decode.bool)
  use subscriber_role_id <- decode.optional_field(
    "role_id",
    None,
    decode.optional(snowflake_decoder()),
  )
  use subscription_expiration_behavior <- decode.field(
    "expire_behavior",
    guild_social_integration_subscription_expiration_behavior_decoder(),
  )
  use subscription_expiration_grace_period <- decode.optional_field(
    "expire_grace_period",
    duration.seconds(0),
    days_decoder(),
  )
  use last_sync_timestamp <- decode.optional_field(
    "synced_at",
    None,
    decode.optional(rfc3339_decoder()),
  )
  use subscriber_count <- decode.field("subscriber_count", decode.int)
  use is_revoked <- decode.field("revoked", decode.bool)
  decode.success(GuildSocialIntegration(
    data:,
    is_syncing:,
    subscriber_role_id:,
    subscription_expiration_behavior:,
    subscription_expiration_grace_period:,
    last_sync_timestamp:,
    subscriber_count:,
    is_revoked:,
  ))
}

fn days_decoder() -> Decoder(Duration) {
  use days <- decode.then(decode.int)
  decode.success(duration.hours(days * 24))
}

pub type GuildSocialIntegrationData {
  // no specific data :(
  YoutubeGuildIntegration
  TwitchGuildIntegration(is_syncing_emoticons: Bool)
}

fn guild_social_integration_data_decoder() -> Decoder(
  GuildSocialIntegrationData,
) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "youtube" -> decode.success(YoutubeGuildIntegration)
    "twitch" -> {
      use is_syncing_emoticons <- decode.field("enable_emoticons", decode.bool)
      decode.success(TwitchGuildIntegration(is_syncing_emoticons:))
    }
    _ -> decode.failure(YoutubeGuildIntegration, "GuildSocialIntegrationData")
  }
}

pub type GuildSocialIntegrationSubscriptionExpirationBehavior {
  /// Remove the subscriber-only role when the subscription expires.
  RemoveRoleOnSubscriptionExpiration
  /// Kick the ex-subscriber from the guild when the subscription expires.
  KickOnSubscriptionExpiration
}

fn guild_social_integration_subscription_expiration_behavior_decoder() -> Decoder(
  GuildSocialIntegrationSubscriptionExpirationBehavior,
) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(RemoveRoleOnSubscriptionExpiration)
    1 -> decode.success(KickOnSubscriptionExpiration)
    _ ->
      decode.failure(
        RemoveRoleOnSubscriptionExpiration,
        "GuildSocialIntegrationSubscriptionExpirationBehavior",
      )
  }
}

/// Requires the `AllowManagingGuild` permission.
///
/// Returns a maximum of 50 integrations. If a guild has more, they cannot be accessed.
pub fn get_guild_integrations(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(List(GuildIntegration), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/integrations",
    method: http.Get,
  )
  |> send_request(decode_with: decode.list(of: guild_integration_decoder()))
}

/// Requires the `AllowManagingGuild` permission.
///
/// Deletes any associated webhooks and kicks the associated bot (if there is one).
pub fn delete_guild_integration(
  token token: Token,
  with_id integration_id: Snowflake(GuildIntegration),
  from_guild_with_id guild_id: Snowflake(Guild),
  reason reason: Option(String),
) -> Result(Nil, RestError) {
  new_request(
    token:,
    to: "/guilds/"
      <> snowflake_to_string(guild_id)
      <> "/integrations/"
      <> snowflake_to_string(integration_id),
    method: http.Delete,
  )
  |> request_with_reason(reason)
  |> send_no_content_request
}

/// A guild's settings pertaining to the website widget.
pub type GuildWidgetSettings {
  GuildWidgetSettings(is_enabled: Bool, channel_id: Option(Snowflake(Channel)))
}

fn guild_widget_settings_decoder() -> Decoder(GuildWidgetSettings) {
  use is_enabled <- decode.field("enabled", decode.bool)
  use channel_id <- decode.field(
    "channel_id",
    decode.optional(snowflake_decoder()),
  )
  decode.success(GuildWidgetSettings(is_enabled:, channel_id:))
}

/// Requires the `AllowManagingGuild` permission.
pub fn get_guild_widget_settings(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildWidgetSettings, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/widget",
    method: http.Get,
  )
  |> send_request(decode_with: guild_widget_settings_decoder())
}

pub opaque type ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(
    is_enabled: Option(Bool),
    channel_id: Modification(Snowflake(Channel)),
  )
}

pub fn new_modify_guild_widget_settings() -> ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(None, Skip)
}

pub fn enable_guild_widget(
  modify: ModifyGuildWidgetSettings,
) -> ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(..modify, is_enabled: Some(True))
}

pub fn disable_guild_widget(
  modify: ModifyGuildWidgetSettings,
) -> ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(..modify, is_enabled: Some(False))
}

pub fn modify_guild_widget_channel_id(
  modify: ModifyGuildWidgetSettings,
  new id: Snowflake(Channel),
) -> ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(..modify, channel_id: Modify(id))
}

pub fn unset_guild_widget_channel_id(
  modify: ModifyGuildWidgetSettings,
) -> ModifyGuildWidgetSettings {
  ModifyGuildWidgetSettings(..modify, channel_id: Delete)
}

fn modify_guild_widget_settings_to_json(
  modify: ModifyGuildWidgetSettings,
) -> Json {
  [
    optional_to_json(modify.is_enabled, "enabled", json.bool),
    modification_to_json(modify.channel_id, "channel_id", snowflake_to_json),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

/// Requires the `AllowManagingGuild` permission.
pub fn modify_guild_widget_settings(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyGuildWidgetSettings,
  reason reason: Option(String),
) -> Result(GuildWidgetSettings, RestError) {
  let body = modify |> modify_guild_widget_settings_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/widget",
    method: http.Patch,
  )
  |> request.set_body(body)
  |> request_with_reason(reason)
  |> send_request(decode_with: guild_widget_settings_decoder())
}

pub type GuildWidget {
  GuildWidget(
    guild_id: Snowflake(Guild),
    guild_name: String,
    instant_invite_url: Option(String),
    /// Contains voice and stage channels which are accessible by @everyone
    channels: List(GuildWidgetChannel),
    users: List(GuildWidgetUser),
    /// Amount of online members in the guild.
    presence_count: Int,
  )
}

fn guild_widget_decoder() -> Decoder(GuildWidget) {
  use guild_id <- decode.field("id", snowflake_decoder())
  use guild_name <- decode.field("name", decode.string)
  use instant_invite_url <- decode.field(
    "instant_invite",
    decode.optional(decode.string),
  )
  use channels <- decode.field(
    "channels",
    decode.list(guild_widget_channel_decoder()),
  )
  use users <- decode.field("members", decode.list(guild_widget_user_decoder()))
  use presence_count <- decode.field("presence_count", decode.int)
  decode.success(GuildWidget(
    guild_id:,
    guild_name:,
    instant_invite_url:,
    channels:,
    users:,
    presence_count:,
  ))
}

/// A partial user object used in guild widgets.
/// 
/// Includes the user's status + a specific avatar URL.
pub type GuildWidgetUser {
  GuildWidgetUser(
    id: Snowflake(User),
    username: String,
    /// Mostly deprecated. Only bots have discriminators nowadays.
    /// 
    /// Users will very likely have their discriminator set to `0`.
    /// 
    /// Used in the past when usernames weren't user-specific.
    /// 
    /// Doesn't include the `#` prefix.
    discriminator: String,
    avatar_hash: Option(ImageHash),
    status: UserStatus,
    avatar_url: Option(String),
  )
}

fn guild_widget_user_decoder() -> Decoder(GuildWidgetUser) {
  use id <- decode.field("id", snowflake_decoder())
  use username <- decode.field("username", decode.string)
  use discriminator <- decode.field("discriminator", decode.string)
  use avatar_hash <- decode.optional_field(
    "avatar",
    None,
    decode.optional(image_hash_decoder()),
  )
  use status <- decode.field("status", user_status_decoder())
  use avatar_url <- decode.optional_field(
    "avatar_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(GuildWidgetUser(
    id:,
    username:,
    discriminator:,
    avatar_hash:,
    status:,
    avatar_url:,
  ))
}

/// A partial channel object used in guild widgets.
///
/// Represents an `@everyone`-accessible voice or stage channel.
pub type GuildWidgetChannel {
  GuildWidgetChannel(
    id: Snowflake(GuildChannel),
    name: String,
    /// Channels with the same position are sorted by ID.
    position: Int,
  )
}

fn guild_widget_channel_decoder() -> Decoder(GuildWidgetChannel) {
  use id <- decode.field("id", snowflake_decoder())
  use name <- decode.field("name", decode.string)
  use position <- decode.field("position", decode.int)
  decode.success(GuildWidgetChannel(id:, name:, position:))
}

pub type UserStatus {
  /// Green circle icon displayed in the client.
  UserIsOnline
  /// Red do-not-disturb icon displayed in the client.
  UserIsNotToBeDisturbed
  /// Yellow crescent moon icon displayed in the client.
  UserIsIdle
  /// Looks offline in the client, is actually online.
  ///
  /// Gray empty circle icon displayed in the client.
  UserIsInvisible
  /// Gray empty circle icon displayed in the client.
  UserIsOffline
}

fn user_status_decoder() -> Decoder(UserStatus) {
  use variant <- decode.then(decode.string)
  case variant {
    "online" -> decode.success(UserIsOnline)
    "dnd" -> decode.success(UserIsNotToBeDisturbed)
    "idle" -> decode.success(UserIsIdle)
    "invisible" -> decode.success(UserIsInvisible)
    "offline" -> decode.success(UserIsOffline)
    _ -> decode.failure(UserIsOnline, "UserStatus")
  }
}

// I don't know how useful this actually is - this library is erlang-only and this seems like a lustre job
//
// (unless you use HTMX)
/// Useful for creating custom website widgets.
pub fn get_guild_widget(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildWidget, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/widget.json",
    method: http.Get,
  )
  |> send_request(decode_with: guild_widget_decoder())
}

pub type GuildVanityInvite {
  GuildVanityInvite(
    /// Prepend `https://discord.gg/` to the code to create an invite link!
    code: String,
    /// How many times the invite has been used.
    uses: Int,
  )
}

fn guild_vanity_invite_decoder() -> Decoder(Option(GuildVanityInvite)) {
  use code <- decode.field("code", decode.optional(decode.string))

  case code {
    Some(code) -> {
      use uses <- decode.field("uses", decode.int)
      decode.success(Some(GuildVanityInvite(code:, uses:)))
    }
    None -> decode.success(None)
  }
}

/// Requires the `AllowManagingGuild` permission.
///
/// Use [`Guild.vanity_url_code`](#Guild) to get the vanity URL code without this permission.
///
/// This endpoint is only necessary to get the use count. Returns `Ok(None)` if the guild can have a vanity URL but doesn't.
pub fn get_guild_vanity_invite(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(Option(GuildVanityInvite), RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/vanity-url",
    method: http.Get,
  )
  |> send_request(decode_with: guild_vanity_invite_decoder())
}

/// Requires the `AllowManagingGuild` permission if the welcome screen is disabled.
pub fn get_guild_welcome_screen(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildWelcomeScreen, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/welcome-screen",
    method: http.Get,
  )
  |> send_request(decode_with: guild_welcome_screen_decoder())
}

pub opaque type ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(
    is_enabled: Modification(Bool),
    welcome_channels: Modification(List(GuildWelcomeScreenChannel)),
    description: Modification(String),
  )
}

fn modify_guild_welcome_screen_to_json(modify: ModifyGuildWelcomeScreen) -> Json {
  [
    modification_to_json(modify.is_enabled, "enabled", json.bool),
    modification_to_json(
      modify.welcome_channels,
      "welcome_channels",
      json.array(_, guild_welcome_screen_channel_to_json),
    ),
    modification_to_json(modify.description, "description", json.string),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

pub fn new_modify_guild_welcome_screen() -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(Skip, Skip, Skip)
}

pub fn enable_guild_welcome_screen(
  modify: ModifyGuildWelcomeScreen,
) -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(..modify, is_enabled: Modify(True))
}

pub fn disable_guild_welcome_screen(
  modify: ModifyGuildWelcomeScreen,
) -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(..modify, is_enabled: Modify(False))
}

pub fn modify_guild_welcome_screen_channels(
  modify: ModifyGuildWelcomeScreen,
  new channels: List(GuildWelcomeScreenChannel),
) -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(..modify, welcome_channels: Modify(channels))
}

pub fn modify_guild_welcome_screen_description(
  modify: ModifyGuildWelcomeScreen,
  new description: String,
) -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(..modify, description: Modify(description))
}

pub fn delete_guild_welcome_screen_description(
  modify: ModifyGuildWelcomeScreen,
) -> ModifyGuildWelcomeScreen {
  ModifyGuildWelcomeScreen(..modify, description: Delete)
}

/// Requires the `AllowManagingGuild` permission.
pub fn modify_guild_welcome_screen(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyGuildWelcomeScreen,
  reason reason: Option(String),
) -> Result(GuildWelcomeScreen, RestError) {
  let body = modify |> modify_guild_welcome_screen_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/welcome-screen",
    method: http.Patch,
  )
  |> request.set_body(body)
  |> request_with_reason(reason)
  |> send_request(decode_with: guild_welcome_screen_decoder())
}

pub type GuildOnboarding {
  GuildOnboarding(
    guild_id: Snowflake(Guild),
    prompts: List(GuildOnboardingPrompt),
    /// IDs of the channels that members get opted-into automatically.
    default_channel_ids: List(Snowflake(Channel)),
    is_enabled: Bool,
    mode: GuildOnboardingMode,
  )
}

fn guild_onboarding_decoder() -> Decoder(GuildOnboarding) {
  use guild_id <- decode.field("guild_id", snowflake_decoder())
  use prompts <- decode.field(
    "prompts",
    decode.list(guild_onboarding_prompt_decoder()),
  )
  use default_channel_ids <- decode.field(
    "default_channel_ids",
    decode.list(snowflake_decoder()),
  )
  use is_enabled <- decode.field("enabled", decode.bool)
  use mode <- decode.field("mode", guild_onboarding_mode_decoder())
  decode.success(GuildOnboarding(
    guild_id:,
    prompts:,
    default_channel_ids:,
    is_enabled:,
    mode:,
  ))
}

pub type GuildOnboardingMode {
  /// Assigns only default channels.
  DefaultOnboardingMode
  /// Asks pre-join questions to add people to channels & roles based on their answers.
  AdvancedOnboardingMode
}

fn guild_onboarding_mode_decoder() -> Decoder(GuildOnboardingMode) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(DefaultOnboardingMode)
    1 -> decode.success(AdvancedOnboardingMode)
    _ -> decode.failure(DefaultOnboardingMode, "GuildOnboardingMode")
  }
}

pub type GuildOnboardingPrompt {
  GuildOnboardingPrompt(
    id: Snowflake(GuildOnboardingPrompt),
    type_: GuildOnboardingPromptType,
    options: List(GuildOnboardingPromptOption),
    title: String,
    is_single_select: Bool,
    is_required: Bool,
    /// If `False`, the prompt will only appear in the "Channels & Roles" tab.
    is_present_in_onboarding_flow: Bool,
  )
}

fn guild_onboarding_prompt_decoder() -> Decoder(GuildOnboardingPrompt) {
  use id <- decode.field("id", snowflake_decoder())
  use type_ <- decode.field("type", guild_onboarding_prompt_type_decoder())
  use options <- decode.field(
    "options",
    decode.list(guild_onboarding_prompt_option_decoder()),
  )
  use title <- decode.field("title", decode.string)
  use is_single_select <- decode.field("single_select", decode.bool)
  use is_required <- decode.field("required", decode.bool)
  use is_present_in_onboarding_flow <- decode.field(
    "in_onboarding",
    decode.bool,
  )
  decode.success(GuildOnboardingPrompt(
    id:,
    type_:,
    options:,
    title:,
    is_single_select:,
    is_required:,
    is_present_in_onboarding_flow:,
  ))
}

pub type GuildOnboardingPromptType {
  MultipleChoiceGuildOnboardingPrompt
  DropdownGuildOnboardingPrompt
}

fn guild_onboarding_prompt_type_decoder() -> Decoder(GuildOnboardingPromptType) {
  use variant <- decode.then(decode.int)
  case variant {
    0 -> decode.success(MultipleChoiceGuildOnboardingPrompt)
    1 -> decode.success(DropdownGuildOnboardingPrompt)
    _ ->
      decode.failure(
        MultipleChoiceGuildOnboardingPrompt,
        "GuildOnboardingPromptType",
      )
  }
}

pub type GuildOnboardingPromptOption {
  GuildOnboadingPromptOption(
    id: Snowflake(GuildOnboardingPromptOption),
    /// The channels the user will be added to if they select this option.
    channel_ids: List(Snowflake(Channel)),
    /// The roles the user will be awarded if they select this option.
    role_ids: List(Snowflake(Role)),
    emoji: Option(Emoji),
    title: String,
    description: Option(String),
  )
}

fn guild_onboarding_prompt_option_decoder() -> Decoder(
  GuildOnboardingPromptOption,
) {
  use id <- decode.field("id", snowflake_decoder())
  use channel_ids <- decode.field(
    "channel_ids",
    decode.list(snowflake_decoder()),
  )
  use role_ids <- decode.field("role_ids", decode.list(snowflake_decoder()))
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(emoji_decoder()),
  )
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(GuildOnboadingPromptOption(
    id:,
    channel_ids:,
    role_ids:,
    emoji:,
    title:,
    description:,
  ))
}

pub fn get_guild_onboarding(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
) -> Result(GuildOnboarding, RestError) {
  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/onboarding",
    method: http.Get,
  )
  |> send_request(decode_with: guild_onboarding_decoder())
}

// Modify Guild Onboarding was left unimplemented here due to doubts as to whether one has to reuse prompts or if they can be created
// (i'm lazy and this probably won't be used)

pub opaque type ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(
    invites_disabled_until: Modification(Timestamp),
    dms_disabled_until: Modification(Timestamp),
  )
}

fn modify_guild_incidents_data_to_json(modify: ModifyGuildIncidentsData) -> Json {
  [
    modification_to_json(
      modify.invites_disabled_until,
      "invites_disabled_until",
      timestamp_to_json,
    ),
    modification_to_json(
      modify.dms_disabled_until,
      "dms_disabled_until",
      timestamp_to_json,
    ),
  ]
  |> list.filter_map(function.identity)
  |> json.object
}

pub fn new_modify_guild_incidents_data() -> ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(Skip, Skip)
}

/// Disable invites in response to an incident.
///
/// You can only disable invites for up to 24 hours.
pub fn disable_guild_invites(
  modify: ModifyGuildIncidentsData,
  until timestamp: Timestamp,
) -> ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(..modify, invites_disabled_until: Modify(timestamp))
}

/// Enable guild invites after they were disabled in response to an incident.
pub fn enable_guild_invites(
  modify: ModifyGuildIncidentsData,
) -> ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(..modify, invites_disabled_until: Delete)
}

/// Disable DMs between guild members as a response to an incident.
///
/// You can only disable DMs for up to 24 hours.
pub fn disable_guild_dms(
  modify: ModifyGuildIncidentsData,
  until timestamp: Timestamp,
) -> ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(..modify, dms_disabled_until: Modify(timestamp))
}

/// Enable DMs between guild members after they were disabled in response to an incident.
pub fn enable_guild_dms(
  modify: ModifyGuildIncidentsData,
) -> ModifyGuildIncidentsData {
  ModifyGuildIncidentsData(..modify, dms_disabled_until: Delete)
}

/// Requires the `AllowManagingGuild` permission.
pub fn modify_guild_incidents_data(
  token token: Token,
  for_guild_with_id guild_id: Snowflake(Guild),
  using modify: ModifyGuildIncidentsData,
) -> Result(GuildIncidentsData, RestError) {
  let body = modify |> modify_guild_incidents_data_to_json |> json.to_string

  new_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(guild_id) <> "/incident-actions",
    method: http.Put,
  )
  |> request.set_body(body)
  |> send_request(decode_with: guild_incidents_data_decoder())
}

/// Do not use this endpoint as means of notifying everyone in a server about something.
///
/// DMs should be initiated by user action - for example, interactions.
///
/// Even then, if you create a significant amount of DMs too quickly, your bot may be quarantined.
pub fn create_dm_channel(
  token token: Token,
  to_user_with_id user_id: Snowflake(User),
) -> Result(DmChannel, RestError) {
  let body =
    [#("recipient_id", snowflake_to_json(user_id))]
    |> json.object
    |> json.to_string

  new_request(token:, to: "/users/@me/channels", method: http.Post)
  |> request.set_body(body)
  |> send_request(decode_with: dm_channel_decoder())
}

pub fn get_channel(
  token token: Token,
  with_id channel_id: Snowflake(Channel),
) -> Result(Channel, RestError) {
  new_request(
    token:,
    to: "/channels/" <> snowflake_to_string(channel_id),
    method: http.Get,
  )
  |> send_request(decode_with: channel_decoder())
}
