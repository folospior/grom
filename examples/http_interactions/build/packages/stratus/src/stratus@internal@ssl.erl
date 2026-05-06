-module(stratus@internal@ssl).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/stratus/internal/ssl.gleam").
-export([connect/4, shutdown/2, send/2, 'receive'/2, receive_timeout/3, set_opts/2, start/0, controlling_process/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/stratus/internal/ssl.gleam", 9).
?DOC(false).
-spec connect(
    gleam@erlang@charlist:charlist(),
    integer(),
    list({gleam@erlang@atom:atom_(), gleam@dynamic:dynamic_()}),
    integer()
) -> {ok, stratus@internal@socket:socket()} |
    {error, stratus@internal@socket:socket_reason()}.
connect(Address, Port, Options, Timeout) ->
    ssl:connect(Address, Port, Options, Timeout).

-file("src/stratus/internal/ssl.gleam", 17).
?DOC(false).
-spec shutdown(
    stratus@internal@socket:socket(),
    stratus@internal@socket:shutdown()
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
shutdown(Socket, How) ->
    stratus_ffi:ssl_shutdown(Socket, How).

-file("src/stratus/internal/ssl.gleam", 20).
?DOC(false).
-spec send(stratus@internal@socket:socket(), gleam@bytes_tree:bytes_tree()) -> {ok,
        nil} |
    {error, stratus@internal@socket:socket_reason()}.
send(Socket, Packet) ->
    stratus_ffi:ssl_send(Socket, Packet).

-file("src/stratus/internal/ssl.gleam", 23).
?DOC(false).
-spec 'receive'(stratus@internal@socket:socket(), integer()) -> {ok,
        bitstring()} |
    {error, stratus@internal@socket:socket_reason()}.
'receive'(Socket, Length) ->
    ssl:recv(Socket, Length).

-file("src/stratus/internal/ssl.gleam", 26).
?DOC(false).
-spec receive_timeout(stratus@internal@socket:socket(), integer(), integer()) -> {ok,
        bitstring()} |
    {error, stratus@internal@socket:socket_reason()}.
receive_timeout(Socket, Length, Timeout) ->
    ssl:recv(Socket, Length, Timeout).

-file("src/stratus/internal/ssl.gleam", 33).
?DOC(false).
-spec set_opts(
    stratus@internal@socket:socket(),
    list({gleam@erlang@atom:atom_(), gleam@dynamic:dynamic_()})
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
set_opts(Socket, Opts) ->
    stratus_ffi:ssl_set_opts(Socket, Opts).

-file("src/stratus/internal/ssl.gleam", 39).
?DOC(false).
-spec start() -> {ok, nil} | {error, nil}.
start() ->
    stratus_ffi:ssl_start().

-file("src/stratus/internal/ssl.gleam", 42).
?DOC(false).
-spec controlling_process(
    stratus@internal@socket:socket(),
    gleam@erlang@process:pid_()
) -> {ok, nil} | {error, stratus@internal@socket:socket_reason()}.
controlling_process(Socket, New_owner) ->
    stratus_ffi:ssl_controlling_process(Socket, New_owner).
