import gleam/int

// TYPES -----------------------------------------------------------------------

pub type Intent {
  Guilds
  GuildMembers
  GuildModeration
  GuildExpressions
  GuildIntegrations
  GuildWebhooks
  GuildInvites
  GuildVoiceStates
  GuildPresences
  GuildMessages
  GuildMessageReactions
  GuildMessageTyping
  DirectMessages
  DirectMessageReactions
  DirectMessageTyping
  MessageContent
  GuildScheduledEvents
  AutoModerationConfiguration
  AutoModerationExecution
  GuildMessagePolls
  DirectMessagePolls
}

// CONSTANTS -------------------------------------------------------------------

pub const all = [
  Guilds,
  GuildMembers,
  GuildModeration,
  GuildExpressions,
  GuildIntegrations,
  GuildWebhooks,
  GuildInvites,
  GuildVoiceStates,
  GuildPresences,
  GuildMessages,
  GuildMessageReactions,
  GuildMessageTyping,
  DirectMessages,
  DirectMessageReactions,
  DirectMessageTyping,
  MessageContent,
  GuildScheduledEvents,
  AutoModerationConfiguration,
  AutoModerationExecution,
  GuildMessagePolls,
  DirectMessagePolls,
]

pub const all_unprivileged = [
  Guilds,
  GuildModeration,
  GuildExpressions,
  GuildIntegrations,
  GuildWebhooks,
  GuildInvites,
  GuildVoiceStates,
  GuildMessages,
  GuildMessageReactions,
  GuildMessageTyping,
  DirectMessages,
  DirectMessageReactions,
  DirectMessageTyping,
  GuildScheduledEvents,
  AutoModerationConfiguration,
  AutoModerationExecution,
  GuildMessagePolls,
  DirectMessagePolls,
]

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_intents() -> List(#(Int, Intent)) {
  [
    #(int.bitwise_shift_left(1, 0), Guilds),
    #(int.bitwise_shift_left(1, 1), GuildMembers),
    #(int.bitwise_shift_left(1, 2), GuildModeration),
    #(int.bitwise_shift_left(1, 3), GuildExpressions),
    #(int.bitwise_shift_left(1, 4), GuildIntegrations),
    #(int.bitwise_shift_left(1, 5), GuildWebhooks),
    #(int.bitwise_shift_left(1, 6), GuildInvites),
    #(int.bitwise_shift_left(1, 7), GuildVoiceStates),
    #(int.bitwise_shift_left(1, 8), GuildPresences),
    #(int.bitwise_shift_left(1, 9), GuildMessages),
    #(int.bitwise_shift_left(1, 10), GuildMessageReactions),
    #(int.bitwise_shift_left(1, 11), GuildMessageTyping),
    #(int.bitwise_shift_left(1, 12), DirectMessages),
    #(int.bitwise_shift_left(1, 13), DirectMessageReactions),
    #(int.bitwise_shift_left(1, 14), DirectMessageTyping),
    #(int.bitwise_shift_left(1, 15), MessageContent),
    #(int.bitwise_shift_left(1, 16), GuildScheduledEvents),
    #(int.bitwise_shift_left(1, 20), AutoModerationConfiguration),
    #(int.bitwise_shift_left(1, 21), AutoModerationExecution),
    #(int.bitwise_shift_left(1, 24), GuildMessagePolls),
    #(int.bitwise_shift_left(1, 25), DirectMessagePolls),
  ]
}
