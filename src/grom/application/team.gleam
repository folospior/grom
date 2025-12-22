import gleam/dynamic/decode
import gleam/http/request.{type Request}
import gleam/option.{type Option}
import grom/internal/rest
import grom/user.{type User}

// TYPES -----------------------------------------------------------------------

pub type Team {
  Team(
    id: String,
    icon_hash: Option(String),
    members: List(Member),
    name: String,
    owner_user_id: String,
  )
}

pub type Member {
  Member(
    user: User,
    role: MemberRole,
    team_id: String,
    membership_state: MembershipState,
  )
}

pub type MemberRole {
  Admin
  Developer
  ReadOnly
}

pub type MembershipState {
  Invited
  Accepted
}

pub type IconFormat {
  PngIcon
  JpegIcon
  WebpIcon
}

// DECODER ---------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(Team) {
  use id <- decode.field("id", decode.string)
  use icon_hash <- decode.field("icon_hash", decode.optional(decode.string))
  use members <- decode.field("members", decode.list(member_decoder()))
  use name <- decode.field("name", decode.string)
  use owner_user_id <- decode.field("owner_user_id", decode.string)
  decode.success(Team(id:, icon_hash:, members:, name:, owner_user_id:))
}

@internal
pub fn member_decoder() -> decode.Decoder(Member) {
  use user <- decode.field("user", user.decoder())
  use role <- decode.field("role", member_role_decoder())
  use team_id <- decode.field("team_id", decode.string)
  use membership_state <- decode.field(
    "membership_state",
    membership_state_decoder(),
  )
  decode.success(Member(user:, role:, team_id:, membership_state:))
}

@internal
pub fn member_role_decoder() -> decode.Decoder(MemberRole) {
  use variant <- decode.then(decode.string)
  case variant {
    "admin" -> decode.success(Admin)
    "developer" -> decode.success(Developer)
    "read_only" -> decode.success(ReadOnly)
    _ -> decode.failure(ReadOnly, "MemberRole")
  }
}

@internal
pub fn membership_state_decoder() -> decode.Decoder(MembershipState) {
  use variant <- decode.then(decode.int)
  case variant {
    1 -> decode.success(Invited)
    2 -> decode.success(Accepted)
    _ -> decode.failure(Invited, "MembershipState")
  }
}

// PUBLIC API FUNCTIONS --------------------------------------------------------

pub fn icon_request(
  id id: String,
  hash icon: String,
  format format: IconFormat,
) -> Request(String) {
  let extension = case format {
    PngIcon -> ".png"
    JpegIcon -> ".jpeg"
    WebpIcon -> ".webp"
  }

  rest.new_cdn_request(
    to: "/team-icons/" <> id <> "/" <> icon <> extension,
    query: [],
  )
}
