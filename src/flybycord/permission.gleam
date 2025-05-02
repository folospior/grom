import gleam/dynamic/decode
import gleam/int
import gleam/list

// TYPES -----------------------------------------------------------------------

pub type Permission {
  CreateInstantInvite
  KickMembers
  BanMembers
  Administrator
  ManageChannels
  ManageGuild
  AddReactions
  ViewAuditLog
  PrioritySpeaker
  Stream
  ViewChannel
  SendMessages
  SendTtsMessages
  ManageMessages
  EmbedLinks
  AttachFiles
  ReadMessageHistory
  MentionEveryone
  UseExternalEmojis
  ViewGuildInsights
  Connect
  Speak
  MuteMembers
  DeafenMembers
  MoveMembers
  UseVoiceActivityDetection
  ChangeNickname
  ManageNicknames
  ManageRoles
  ManageWebhooks
  ManageGuildExpressions
  UseApplicationCommands
  RequestToSpeak
  ManageEvents
  ManageThreads
  CreatePublicThreads
  CreatePrivateThreads
  UseExternalStickers
  SendMessagesInThreads
  UseEmbeddedActivities
  ModerateMembers
  ViewCreatorMonetizationAnalytics
  UseSoundboard
  CreateGuildExpressions
  CreateEvents
  UseExternalSounds
  SendVoiceMessages
  SendPolls
  UseExternalApps
}

// FLAGS -----------------------------------------------------------------------

fn permissions_bits() -> List(#(Int, Permission)) {
  [
    #(int.bitwise_shift_left(1, 0), CreateInstantInvite),
    #(int.bitwise_shift_left(1, 1), KickMembers),
    #(int.bitwise_shift_left(1, 2), BanMembers),
    #(int.bitwise_shift_left(1, 3), Administrator),
    #(int.bitwise_shift_left(1, 4), ManageChannels),
    #(int.bitwise_shift_left(1, 5), ManageGuild),
    #(int.bitwise_shift_left(1, 6), AddReactions),
    #(int.bitwise_shift_left(1, 7), ViewAuditLog),
    #(int.bitwise_shift_left(1, 8), PrioritySpeaker),
    #(int.bitwise_shift_left(1, 9), Stream),
    #(int.bitwise_shift_left(1, 10), ViewChannel),
    #(int.bitwise_shift_left(1, 11), SendMessages),
    #(int.bitwise_shift_left(1, 12), SendTtsMessages),
    #(int.bitwise_shift_left(1, 13), ManageMessages),
    #(int.bitwise_shift_left(1, 14), EmbedLinks),
    #(int.bitwise_shift_left(1, 15), AttachFiles),
    #(int.bitwise_shift_left(1, 16), ReadMessageHistory),
    #(int.bitwise_shift_left(1, 17), MentionEveryone),
    #(int.bitwise_shift_left(1, 18), UseExternalEmojis),
    #(int.bitwise_shift_left(1, 19), ViewGuildInsights),
    #(int.bitwise_shift_left(1, 20), Connect),
    #(int.bitwise_shift_left(1, 21), Speak),
    #(int.bitwise_shift_left(1, 22), MuteMembers),
    #(int.bitwise_shift_left(1, 23), DeafenMembers),
    #(int.bitwise_shift_left(1, 24), MoveMembers),
    #(int.bitwise_shift_left(1, 25), UseVoiceActivityDetection),
    #(int.bitwise_shift_left(1, 26), ChangeNickname),
    #(int.bitwise_shift_left(1, 27), ManageNicknames),
    #(int.bitwise_shift_left(1, 28), ManageRoles),
    #(int.bitwise_shift_left(1, 29), ManageWebhooks),
    #(int.bitwise_shift_left(1, 30), ManageGuildExpressions),
    #(int.bitwise_shift_left(1, 31), UseApplicationCommands),
    #(int.bitwise_shift_left(1, 32), RequestToSpeak),
    #(int.bitwise_shift_left(1, 33), ManageEvents),
    #(int.bitwise_shift_left(1, 34), ManageThreads),
    #(int.bitwise_shift_left(1, 35), CreatePublicThreads),
    #(int.bitwise_shift_left(1, 36), CreatePrivateThreads),
    #(int.bitwise_shift_left(1, 37), UseExternalStickers),
    #(int.bitwise_shift_left(1, 38), SendMessagesInThreads),
    #(int.bitwise_shift_left(1, 39), UseEmbeddedActivities),
    #(int.bitwise_shift_left(1, 40), ModerateMembers),
    #(int.bitwise_shift_left(1, 41), ViewCreatorMonetizationAnalytics),
    #(int.bitwise_shift_left(1, 42), UseSoundboard),
    #(int.bitwise_shift_left(1, 43), CreateGuildExpressions),
    #(int.bitwise_shift_left(1, 44), CreateEvents),
    #(int.bitwise_shift_left(1, 45), UseExternalSounds),
    #(int.bitwise_shift_left(1, 46), SendVoiceMessages),
    #(int.bitwise_shift_left(1, 49), SendPolls),
    #(int.bitwise_shift_left(1, 50), UseExternalApps),
  ]
}

// DECODERS --------------------------------------------------------------------

@internal
pub fn decoder() -> decode.Decoder(List(Permission)) {
  use permissions <- decode.then(decode.string)
  let permissions = permissions |> int.parse

  case permissions {
    Ok(permissions) -> {
      permissions_bits()
      |> list.filter_map(fn(item) {
        let #(bit, permission) = item
        case int.bitwise_and(permissions, bit) != 0 {
          True -> Ok(permission)
          False -> Error(Nil)
        }
      })
      |> decode.success
    }
    Error(_) -> decode.failure([], "Permission")
  }
}

// FUNCTIONS -------------------------------------------------------------------

@internal
pub fn to_string(permissions: List(Permission)) -> String {
  permissions_bits()
  |> list.filter_map(fn(item) {
    let #(bit, flag) = item
    let is_in_permissions =
      permissions
      |> list.any(fn(permission) { flag == permission })

    case is_in_permissions {
      True -> Ok(bit)
      False -> Error(Nil)
    }
  })
  |> int.sum
  |> int.to_string
}
