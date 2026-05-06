-record(pool, {
    handler :: fun((any(), glisten@internal@handler:loop_message(any()), glisten@internal@handler:connection(any())) -> glisten@internal@handler:next(any(), glisten@internal@handler:loop_message(any()))),
    pool_count :: integer(),
    name :: gleam@erlang@process:name(gleam@otp@factory_supervisor:message(glisten@socket:socket(), gleam@erlang@process:subject(glisten@internal@handler:message(any())))),
    on_init :: fun((glisten@internal@handler:connection(any())) -> {any(),
        gleam@option:option(gleam@erlang@process:selector(any()))}),
    on_close :: gleam@option:option(fun((any()) -> nil)),
    transport :: glisten@transport:transport(),
    active_state :: glisten@socket@options:active_state()
}).
