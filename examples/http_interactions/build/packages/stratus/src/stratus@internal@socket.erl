-module(stratus@internal@socket).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/stratus/internal/socket.gleam").
-export([convert_options/1, get_certs/0, get_custom_matcher/0, selector/0]).
-export_type([socket/0, socket_reason/0, receive_mode/0, packet_type/0, options/0, shutdown/0, socket_message/0, erlang_socket_message/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type socket() :: any().

-type socket_reason() :: closed |
    timeout |
    badarg |
    terminated |
    eaddrinuse |
    eaddrnotavail |
    eafnosupport |
    ealready |
    econnaborted |
    econnrefused |
    econnreset |
    edestaddrreq |
    ehostdown |
    ehostunreach |
    einprogress |
    eisconn |
    emsgsize |
    enetdown |
    enetunreach |
    enopkg |
    enoprotoopt |
    enotconn |
    enotty |
    enotsock |
    eproto |
    eprotonosupport |
    eprototype |
    esocktnosupport |
    etimedout |
    ewouldblock |
    exbadport |
    exbadseq.

-type receive_mode() :: {count, integer()} | once | pull | all.

-type packet_type() :: binary | list.

-type options() :: {'receive', receive_mode()} |
    {packets_of, packet_type()} |
    {send_timeout, integer()} |
    {send_timeout_close, boolean()} |
    {reuseaddr, boolean()} |
    {nodelay, boolean()} |
    {cacerts, gleam@dynamic:dynamic_()} |
    {customize_hostname_check, gleam@dynamic:dynamic_()}.

-type shutdown() :: read | write | read_write.

-type socket_message() :: {data, bitstring()} | {err, socket_reason()}.

-type erlang_socket_message() :: ssl |
    ssl_closed |
    ssl_error |
    tcp |
    tcp_closed |
    tcp_error.

-file("src/stratus/internal/socket.gleam", 81).
?DOC(false).
-spec convert_options(list(options())) -> list({gleam@erlang@atom:atom_(),
    gleam@dynamic:dynamic_()}).
convert_options(Options) ->
    Active = erlang:binary_to_atom(<<"active"/utf8>>),
    gleam@list:map(Options, fun(Opt) -> case Opt of
                {'receive', {count, Count}} ->
                    {Active, gleam_stdlib:identity(Count)};

                {'receive', once} ->
                    {Active,
                        gleam@function:identity(
                            erlang:binary_to_atom(<<"once"/utf8>>)
                        )};

                {'receive', pull} ->
                    {Active, gleam_stdlib:identity(false)};

                {'receive', all} ->
                    {Active, gleam_stdlib:identity(true)};

                {packets_of, binary} ->
                    {erlang:binary_to_atom(<<"mode"/utf8>>),
                        gleam@function:identity(binary)};

                {packets_of, list} ->
                    {erlang:binary_to_atom(<<"mode"/utf8>>),
                        gleam@function:identity(list)};

                {cacerts, Data} ->
                    {erlang:binary_to_atom(<<"cacerts"/utf8>>), Data};

                {nodelay, Bool} ->
                    {erlang:binary_to_atom(<<"nodelay"/utf8>>),
                        gleam_stdlib:identity(Bool)};

                {reuseaddr, Bool@1} ->
                    {erlang:binary_to_atom(<<"reuseaddr"/utf8>>),
                        gleam_stdlib:identity(Bool@1)};

                {send_timeout, Int} ->
                    {erlang:binary_to_atom(<<"send_timeout"/utf8>>),
                        gleam_stdlib:identity(Int)};

                {send_timeout_close, Bool@2} ->
                    {erlang:binary_to_atom(<<"send_timeout_close"/utf8>>),
                        gleam_stdlib:identity(Bool@2)};

                {customize_hostname_check, Funcs} ->
                    {erlang:binary_to_atom(<<"customize_hostname_check"/utf8>>),
                        Funcs}
            end end).

-file("src/stratus/internal/socket.gleam", 168).
?DOC(false).
-spec get_certs() -> gleam@dynamic:dynamic_().
get_certs() ->
    public_key:cacerts_get().

-file("src/stratus/internal/socket.gleam", 171).
?DOC(false).
-spec get_custom_matcher() -> options().
get_custom_matcher() ->
    stratus_ffi:custom_sni_matcher().

-file("src/stratus/internal/socket.gleam", 127).
?DOC(false).
-spec selector() -> gleam@erlang@process:selector({ok, socket_message()} |
    {error, list(gleam@dynamic@decode:decode_error())}).
selector() ->
    _pipe = gleam_erlang_ffi:new_selector(),
    _pipe@2 = gleam@erlang@process:select_record(
        _pipe,
        tcp,
        2,
        fun(Data) ->
            _pipe@1 = begin
                gleam@dynamic@decode:field(
                    2,
                    {decoder, fun gleam@dynamic@decode:decode_bit_array/1},
                    fun(Msg) -> gleam@dynamic@decode:success({data, Msg}) end
                )
            end,
            gleam@dynamic@decode:run(Data, _pipe@1)
        end
    ),
    _pipe@4 = gleam@erlang@process:select_record(
        _pipe@2,
        ssl,
        2,
        fun(Data@1) ->
            _pipe@3 = begin
                gleam@dynamic@decode:field(
                    2,
                    {decoder, fun gleam@dynamic@decode:decode_bit_array/1},
                    fun(Msg@1) ->
                        gleam@dynamic@decode:success({data, Msg@1})
                    end
                )
            end,
            gleam@dynamic@decode:run(Data@1, _pipe@3)
        end
    ),
    _pipe@5 = gleam@erlang@process:select_record(
        _pipe@4,
        ssl_closed,
        1,
        fun(_) -> {ok, {err, closed}} end
    ),
    _pipe@6 = gleam@erlang@process:select_record(
        _pipe@5,
        tcp_closed,
        1,
        fun(_) -> {ok, {err, closed}} end
    ),
    _pipe@8 = gleam@erlang@process:select_record(
        _pipe@6,
        tcp_error,
        2,
        fun(Data@2) ->
            _pipe@7 = begin
                gleam@dynamic@decode:field(
                    2,
                    gleam@erlang@atom:decoder(),
                    fun(Reason) ->
                        case stratus_ffi:parse_known_socket_reason(Reason) of
                            {ok, Reason@1} ->
                                gleam@dynamic@decode:success({err, Reason@1});

                            {error, _} ->
                                gleam@dynamic@decode:failure(
                                    {err, badarg},
                                    <<"SocketReason"/utf8>>
                                )
                        end
                    end
                )
            end,
            gleam@dynamic@decode:run(Data@2, _pipe@7)
        end
    ),
    gleam@erlang@process:select_record(
        _pipe@8,
        ssl_error,
        2,
        fun(Data@3) ->
            _pipe@9 = begin
                gleam@dynamic@decode:field(
                    2,
                    gleam@erlang@atom:decoder(),
                    fun(Reason@2) ->
                        case stratus_ffi:parse_known_socket_reason(Reason@2) of
                            {ok, Reason@3} ->
                                gleam@dynamic@decode:success({err, Reason@3});

                            {error, _} ->
                                gleam@dynamic@decode:failure(
                                    {err, badarg},
                                    <<"SocketReason"/utf8>>
                                )
                        end
                    end
                )
            end,
            gleam@dynamic@decode:run(Data@3, _pipe@9)
        end
    ).
