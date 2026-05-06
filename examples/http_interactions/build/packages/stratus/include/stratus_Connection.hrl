-record(connection, {
    socket :: stratus@internal@socket:socket(),
    transport :: stratus@internal@transport:transport(),
    context :: gleam@option:option(gramps@websocket@compression:context())
}).
