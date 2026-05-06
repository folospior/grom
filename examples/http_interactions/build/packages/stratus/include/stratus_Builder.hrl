-record(builder, {
    request :: gleam@http@request:request(binary()),
    connect_timeout :: integer(),
    init :: fun(() -> {ok, stratus:initialised(any(), any())} |
        {error, binary()}),
    loop :: fun((any(), stratus:message(any()), stratus:connection()) -> stratus:next(any(), any())),
    on_close :: fun((any(), stratus:close_reason()) -> nil)
}).
