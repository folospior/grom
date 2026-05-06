-record(connection, {
    body :: mist@internal@http:body(),
    socket :: glisten@socket:socket(),
    transport :: glisten@transport:transport(),
    factory_name :: gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
            gleam@otp@actor:started(gleam@erlang@process:pid_())} |
        {error, gleam@otp@actor:start_error()}), gleam@erlang@process:pid_()))
}).
