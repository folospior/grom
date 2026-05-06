-module(stratus@internal@transport).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/stratus/internal/transport.gleam").
-export([connect/5, send/3, 'receive'/3, receive_timeout/4, shutdown/3, set_opts/3]).
-export_type([transport/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type transport() :: tcp | ssl.

-file("src/stratus/internal/transport.gleam", 14).
?DOC(false).
-spec connect(
    transport(),
    gleam@erlang@charlist:charlist(),
    integer(),
    list({gleam@erlang@atom:atom_(), gleam@dynamic:dynamic_()}),
    integer()
) -> {ok, stratus@internal@socket:socket()} |
    {error, stratus@internal@socket:socket_reason()}.
connect(Transport, Host, Port, Options, Timeout) ->
    case Transport of
        ssl ->
            ssl:connect(Host, Port, Options, Timeout);

        tcp ->
            gen_tcp:connect(Host, Port, Options, Timeout)
    end.

-file("src/stratus/internal/transport.gleam", 27).
?DOC(false).
-spec send(
    transport(),
    stratus@internal@socket:socket(),
    gleam@bytes_tree:bytes_tree()
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
send(Transport, Socket, Data) ->
    case Transport of
        ssl ->
            stratus_ffi:ssl_send(Socket, Data);

        tcp ->
            stratus_ffi:tcp_send(Socket, Data)
    end.

-file("src/stratus/internal/transport.gleam", 38).
?DOC(false).
-spec 'receive'(transport(), stratus@internal@socket:socket(), integer()) -> {ok,
        bitstring()} |
    {error, stratus@internal@socket:socket_reason()}.
'receive'(Transport, Socket, Length) ->
    case Transport of
        ssl ->
            ssl:recv(Socket, Length);

        tcp ->
            gen_tcp:recv(Socket, Length)
    end.

-file("src/stratus/internal/transport.gleam", 49).
?DOC(false).
-spec receive_timeout(
    transport(),
    stratus@internal@socket:socket(),
    integer(),
    integer()
) -> {ok, bitstring()} | {error, stratus@internal@socket:socket_reason()}.
receive_timeout(Transport, Socket, Length, Timeout) ->
    case Transport of
        ssl ->
            ssl:recv(Socket, Length, Timeout);

        tcp ->
            gen_tcp:recv(Socket, Length, Timeout)
    end.

-file("src/stratus/internal/transport.gleam", 61).
?DOC(false).
-spec shutdown(
    transport(),
    stratus@internal@socket:socket(),
    stratus@internal@socket:shutdown()
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
shutdown(Transport, Socket, How) ->
    case Transport of
        ssl ->
            stratus_ffi:ssl_shutdown(Socket, How);

        tcp ->
            stratus_ffi:tcp_shutdown(Socket, How)
    end.

-file("src/stratus/internal/transport.gleam", 72).
?DOC(false).
-spec set_opts(
    transport(),
    stratus@internal@socket:socket(),
    list({gleam@erlang@atom:atom_(), gleam@dynamic:dynamic_()})
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
set_opts(Transport, Socket, Opts) ->
    case Transport of
        tcp ->
            stratus_ffi:tcp_set_opts(Socket, Opts);

        ssl ->
            stratus_ffi:ssl_set_opts(Socket, Opts)
    end.
