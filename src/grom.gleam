import gleam/bit_array
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
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
import gleam/time/timestamp.{type Timestamp}
import gleam_community/colour.{type Colour}
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
/// In the future, this will be extended to also support bearer tokens.
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
    /// Discord hasn't disclosed when this field could be `None`. 
    locale: Option(Locale),
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

pub fn get_current_user(token token: Token) -> Result(User, RestError) {
  new_api_request(token:, to: "/users/@me", method: http.Get)
  |> send_request(decode_with: user_decoder())
}

pub fn get_user(
  token token: Token,
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

  new_api_request(token:, to: "/users/@me", method: http.Patch)
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
    modify_option_to_json(modify.username, "username", json.string),
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
  new_api_request(
    token:,
    to: "/users/@me/guilds/" <> snowflake_to_string(guild_id) <> "/member",
    method: http.Get,
  )
  |> send_request(decode_with: guild_member_decoder())
}

pub fn leave_guild(
  token token: Token,
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
    afk_timeout: AfkTimeout,
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
    /// List of the guild's custom emojis.
    emojis: List(CustomEmoji),
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
    /// The guild's server boost benefit tier.
    premium_tier: GuildPremiumTier,
    /// The guild's current amount of active server boosts.
    premium_subscription_count: Int,
    /// Is present for all guilds, but only community guilds have the ability to change it.
    /// Defaults to `en-US` if not selected by the guild's admins. 
    preferred_locale: Locale,
    /// ID of the channel where admins and moderators of a Community guild receive notices from Discord.
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
    /// ID of the chanel where moderators of Community guilds receive safety alerts from Discord.
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
  /// * in the guild of registratrion for that guild's members
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
    /// ID of the channel's associated emoji, if the emoji is custom.
    emoji_id: Option(Snowflake(Emoji)),
    /// The emoji's name if custom, or its unicode character if standard.
    /// Is `None` if the channel doesn't have an associated emoji.
    emoji_name: Option(String),
  )
}

fn guild_welcome_screen_channel_decoder() -> Decoder(GuildWelcomeScreenChannel) {
  use id <- decode.field("channel_id", snowflake_decoder())
  use description <- decode.field("description", decode.string)
  use emoji_id <- decode.field("emoji_id", decode.optional(snowflake_decoder()))
  use emoji_name <- decode.field("emoji_name", decode.optional(decode.string))
  decode.success(GuildWelcomeScreenChannel(
    id:,
    description:,
    emoji_id:,
    emoji_name:,
  ))
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

// TODO: GET RID OF ME! USE ACTUAL APPLICATIONS
pub type Application

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
  EmojiUnicode(character: String)
  EmojiCustom(CustomEmoji)
  EmojiApplication(ApplicationEmoji)
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
  new_api_request(
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
  new_api_request(
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
  new_api_request(
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

fn modify_option_to_json(
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
    modify_option_to_json(modify.name, "name", json.string),
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
    modify_option_to_json(
      modify.afk_timeout,
      "afk_timeout",
      afk_timeout_to_json,
    ),
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
    modify_option_to_json(
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
    modify_option_to_json(modify.features, "features", json.array(
      _,
      guild_feature_to_json,
    )),
    modification_to_json(modify.description, "description", json.string),
    modify_option_to_json(
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
  because reason: Option(String),
) -> Result(Guild, RestError) {
  let body =
    modify
    |> modify_guild_to_json
    |> json.to_string

  new_api_request(
    token:,
    to: "/guilds/" <> snowflake_to_string(id),
    method: http.Patch,
  )
  |> request_with_reason(reason)
  |> request.set_body(body)
  |> send_request(decode_with: guild_decoder())
}
