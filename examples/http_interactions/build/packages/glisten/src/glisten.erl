-module(glisten).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/glisten.gleam").
-export([convert_ip_address/1, get_server_info/2, ip_address_to_string/1, get_connection_info/1, send/2, continue/1, with_selector/2, stop/0, stop_abnormal/1, convert_next/1, map_selector/2, new/2, with_close/2, with_pool_size/2, with_http2/1, with_ipv6/1, with_tls/3, with_active_state/2, with_listener_name/2, with_connection_factory_name/2, start/2, bind/2, supervised/2]).
-export_type([message/1, ip_address/0, connection_info/0, connection/1, next/2, builder/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type message(GOO) :: {packet, bitstring()} | {user, GOO}.

-type ip_address() :: {ip_v4, integer(), integer(), integer(), integer()} |
    {ip_v6,
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer()}.

-type connection_info() :: {connection_info, integer(), ip_address()}.

-type connection(GOP) :: {connection,
        glisten@socket:socket(),
        glisten@transport:transport(),
        gleam@erlang@process:subject(glisten@internal@handler:message(GOP))}.

-opaque next(GOQ, GOR) :: {continue,
        GOQ,
        gleam@option:option(gleam@erlang@process:selector(GOR))} |
    normal_stop |
    {abnormal_stop, binary()}.

-opaque builder(GOS, GOT) :: {builder,
        glisten@socket@options:interface(),
        fun((connection(GOT)) -> {GOS,
            gleam@option:option(gleam@erlang@process:selector(GOT))}),
        fun((GOS, message(GOT), connection(GOT)) -> next(GOS, message(GOT))),
        gleam@option:option(fun((GOS) -> nil)),
        integer(),
        boolean(),
        boolean(),
        gleam@option:option(glisten@socket@options:tls_certs()),
        gleam@option:option(gleam@erlang@process:name(glisten@internal@listener:message())),
        gleam@option:option(gleam@erlang@process:name(gleam@otp@factory_supervisor:message(glisten@socket:socket(), gleam@erlang@process:subject(glisten@internal@handler:message(GOT))))),
        glisten@socket@options:active_state()}.

-file("src/glisten.gleam", 68).
?DOC(false).
-spec convert_ip_address(glisten@socket@options:ip_address()) -> ip_address().
convert_ip_address(Ip) ->
    case Ip of
        {ip_v4, A, B, C, D} ->
            {ip_v4, A, B, C, D};

        {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H} ->
            {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H}
    end.

-file("src/glisten.gleam", 48).
?DOC(" Returns the user-provided port or the OS-assigned value if 0 was provided.\n").
-spec get_server_info(
    gleam@erlang@process:name(glisten@internal@listener:message()),
    integer()
) -> connection_info().
get_server_info(Listener, Timeout) ->
    Listener@1 = gleam@erlang@process:named_subject(Listener),
    State = gleam@erlang@process:call(
        Listener@1,
        Timeout,
        fun(Field@0) -> {info, Field@0} end
    ),
    {connection_info,
        erlang:element(3, State),
        convert_ip_address(erlang:element(4, State))}.

-file("src/glisten.gleam", 97).
-spec join_ipv6_fields(list(integer())) -> binary().
join_ipv6_fields(Fields) ->
    _pipe = gleam@list:map(Fields, fun gleam@int:to_base16/1),
    gleam@string:join(_pipe, <<":"/utf8>>).

-file("src/glisten.gleam", 106).
?DOC(
    " Finds the longest sequence of consecutive all-zero fields in an IPv6.\n"
    " If the address contains multiple runs of all-zero fields of the same size,\n"
    " it is the leftmost that is compressed.\n"
    "\n"
    " This returns the start & end indices of the compressed zeros.\n"
).
-spec ipv6_zeros(list(integer()), integer(), integer(), integer(), integer()) -> {ok,
        {integer(), integer()}} |
    {error, nil}.
ipv6_zeros(Fields, Pos, Len, Max_start, Max_len) ->
    case Fields of
        [] when Max_len > 1 ->
            {ok, {Max_start, Max_start + Max_len}};

        [] ->
            {error, nil};

        [X | Xs] when X =:= 0 ->
            Len@1 = Len + 1,
            case Len@1 > Max_len of
                true ->
                    ipv6_zeros(Xs, Pos + 1, Len@1, (Pos + 1) - Len@1, Len@1);

                false ->
                    ipv6_zeros(Xs, Pos + 1, Len@1, Max_start, Max_len)
            end;

        [_ | Xs@1] ->
            ipv6_zeros(Xs@1, Pos + 1, 0, Max_start, Max_len)
    end.

-file("src/glisten.gleam", 77).
?DOC(
    " Convenience function for convert an `IpAddress` type into a string. It will\n"
    " convert IPv6 addresses to the canonical short-hand (ie. loopback is ::1).\n"
).
-spec ip_address_to_string(ip_address()) -> binary().
ip_address_to_string(Address) ->
    case Address of
        {ip_v4, A, B, C, D} ->
            _pipe = [A, B, C, D],
            _pipe@1 = gleam@list:map(_pipe, fun erlang:integer_to_binary/1),
            gleam@string:join(_pipe@1, <<"."/utf8>>);

        {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H} ->
            Fields = [A@1, B@1, C@1, D@1, E, F, G, H],
            _pipe@2 = case ipv6_zeros(Fields, 0, 0, 0, 0) of
                {error, _} ->
                    join_ipv6_fields(Fields);

                {ok, {Start, End}} ->
                    <<<<(join_ipv6_fields(gleam@list:take(Fields, Start)))/binary,
                            "::"/utf8>>/binary,
                        (join_ipv6_fields(gleam@list:drop(Fields, End)))/binary>>
            end,
            string:lowercase(_pipe@2)
    end.

-file("src/glisten.gleam", 127).
?DOC(
    " Tries to read the IP address and port of a connected client.  It will\n"
    " return valid IPv4 or IPv6 addresses, attempting to return the most relevant\n"
    " one for the client.\n"
).
-spec get_connection_info(connection(any())) -> {ok, connection_info()} |
    {error, nil}.
get_connection_info(Conn) ->
    _pipe = glisten@transport:peername(
        erlang:element(3, Conn),
        erlang:element(2, Conn)
    ),
    gleam@result:map(
        _pipe,
        fun(Pair) ->
            {connection_info,
                erlang:element(2, Pair),
                convert_ip_address(erlang:element(1, Pair))}
        end
    ).

-file("src/glisten.gleam", 135).
?DOC(" Sends a BytesTree message over the socket using the active transport\n").
-spec send(connection(any()), gleam@bytes_tree:bytes_tree()) -> {ok, nil} |
    {error, glisten@socket:socket_reason()}.
send(Conn, Msg) ->
    glisten@transport:send(
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        Msg
    ).

-file("src/glisten.gleam", 148).
-spec continue(GPT) -> next(GPT, any()).
continue(State) ->
    {continue, State, none}.

-file("src/glisten.gleam", 152).
-spec with_selector(next(GPX, GPY), gleam@erlang@process:selector(GPY)) -> next(GPX, GPY).
with_selector(Next, Selector) ->
    case Next of
        {continue, State, _} ->
            {continue, State, {some, Selector}};

        Stop ->
            Stop
    end.

-file("src/glisten.gleam", 162).
-spec stop() -> next(any(), any()).
stop() ->
    normal_stop.

-file("src/glisten.gleam", 166).
-spec stop_abnormal(binary()) -> next(any(), any()).
stop_abnormal(Reason) ->
    {abnormal_stop, Reason}.

-file("src/glisten.gleam", 171).
?DOC(false).
-spec convert_next(next(GQM, GQN)) -> glisten@internal@handler:next(GQM, GQN).
convert_next(Next) ->
    case Next of
        {continue, State, Selector} ->
            {continue, State, Selector};

        normal_stop ->
            normal_stop;

        {abnormal_stop, Reason} ->
            {abnormal_stop, Reason}
    end.

-file("src/glisten.gleam", 182).
?DOC(false).
-spec map_selector(next(GQS, GQT), fun((GQT) -> GQW)) -> next(GQS, GQW).
map_selector(Next, Mapper) ->
    case Next of
        {continue, State, {some, Selector}} ->
            {continue,
                State,
                {some, gleam_erlang_ffi:map_selector(Selector, Mapper)}};

        {continue, State@1, none} ->
            {continue, State@1, none};

        {abnormal_stop, Reason} ->
            {abnormal_stop, Reason};

        normal_stop ->
            normal_stop
    end.

-file("src/glisten.gleam", 222).
-spec map_user_selector(gleam@erlang@process:selector(message(GQZ))) -> gleam@erlang@process:selector(glisten@internal@handler:loop_message(GQZ)).
map_user_selector(Selector) ->
    gleam_erlang_ffi:map_selector(Selector, fun(Value) -> case Value of
                {packet, Msg} ->
                    {packet, Msg};

                {user, Msg@1} ->
                    {custom, Msg@1}
            end end).

-file("src/glisten.gleam", 233).
-spec convert_loop(
    fun((GRE, message(GRF), connection(GRF)) -> next(GRE, message(GRF)))
) -> fun((GRE, glisten@internal@handler:loop_message(GRF), glisten@internal@handler:connection(GRF)) -> glisten@internal@handler:next(GRE, glisten@internal@handler:loop_message(GRF))).
convert_loop(Loop) ->
    fun(Data, Msg, Conn) ->
        Conn@1 = {connection,
            erlang:element(3, Conn),
            erlang:element(4, Conn),
            erlang:element(5, Conn)},
        Message = case Msg of
            {packet, Msg@1} ->
                {packet, Msg@1};

            {custom, Msg@2} ->
                {user, Msg@2}
        end,
        case Loop(Data, Message, Conn@1) of
            {continue, Data@1, Selector} ->
                case Selector of
                    {some, Selector@1} ->
                        _pipe = glisten@internal@handler:continue(Data@1),
                        glisten@internal@handler:with_selector(
                            _pipe,
                            map_user_selector(Selector@1)
                        );

                    _ ->
                        glisten@internal@handler:continue(Data@1)
                end;

            normal_stop ->
                glisten@internal@handler:stop();

            {abnormal_stop, Reason} ->
                glisten@internal@handler:stop_abnormal(Reason)
        end
    end.

-file("src/glisten.gleam", 257).
-spec convert_on_init(
    fun((connection(GRK)) -> {GRM,
        gleam@option:option(gleam@erlang@process:selector(GRK))})
) -> fun((glisten@internal@handler:connection(GRK)) -> {GRM,
    gleam@option:option(gleam@erlang@process:selector(GRK))}).
convert_on_init(On_init) ->
    fun(Conn) ->
        Connection = {connection,
            erlang:element(3, Conn),
            erlang:element(4, Conn),
            erlang:element(5, Conn)},
        On_init(Connection)
    end.

-file("src/glisten.gleam", 276).
?DOC(
    " Create a new handler for each connection.  The required arguments mirror the\n"
    " `actor.start` API from `gleam_otp`.  The default pool is 10 accceptor\n"
    " processes.\n"
).
-spec new(
    fun((connection(GRS)) -> {GRU,
        gleam@option:option(gleam@erlang@process:selector(GRS))}),
    fun((GRU, message(GRS), connection(GRS)) -> next(GRU, message(GRS)))
) -> builder(GRU, GRS).
new(On_init, Loop) ->
    {builder,
        loopback,
        On_init,
        Loop,
        none,
        10,
        false,
        false,
        none,
        none,
        none,
        once}.

-file("src/glisten.gleam", 297).
?DOC(" Adds a function to the handler to be called when the connection is closed.\n").
-spec with_close(builder(GSB, GSC), fun((GSB) -> nil)) -> builder(GSB, GSC).
with_close(Builder, On_close) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        {some, On_close},
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 305).
?DOC(" Modify the size of the acceptor pool\n").
-spec with_pool_size(builder(GSH, GSI), integer()) -> builder(GSH, GSI).
with_pool_size(Builder, Size) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        Size,
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 316).
?DOC(false).
-spec with_http2(builder(GSN, GSO)) -> builder(GSN, GSO).
with_http2(Builder) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        true,
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 344).
?DOC(
    " By default, `glisten` listens on `localhost` only over IPv4.  With an IPv4\n"
    " address, you can call this builder method to also serve over IPv6 on that\n"
    " interface.  If it is not supported, your application will crash.  If you\n"
    " call this with an IPv6 interface specified, it will have no effect.\n"
).
-spec with_ipv6(builder(GSZ, GTA)) -> builder(GSZ, GTA).
with_ipv6(Builder) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        true,
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 351).
?DOC(" To use TLS, provide a path to a certficate and key file.\n").
-spec with_tls(builder(GTF, GTG), binary(), binary()) -> builder(GTF, GTG).
with_tls(Builder, Cert, Key) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        {some, {cert_key_files, Cert, Key}},
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 361).
?DOC(
    " Set the server's `ActiveState` for flow control of received packets.\n"
    " Default is `Once`. Allowed are `Once`, `Active` and `Count(n)` where n > 1.\n"
).
-spec with_active_state(
    builder(GTL, GTM),
    glisten@socket@options:active_state()
) -> builder(GTL, GTM).
with_active_state(Builder, Active_state) ->
    case Active_state of
        once ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                erlang:element(7, Builder),
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder),
                erlang:element(11, Builder),
                Active_state};

        active ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                erlang:element(7, Builder),
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder),
                erlang:element(11, Builder),
                Active_state};

        {count, N} when N > 1 ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                erlang:element(7, Builder),
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder),
                erlang:element(11, Builder),
                Active_state};

        {count, _} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Count shall be greater than 1"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"glisten"/utf8>>,
                    function => <<"with_active_state"/utf8>>,
                    line => 369});

        passive ->
            erlang:error(#{gleam_error => panic,
                    message => <<"You cannot set the server's `ActiveState` to `Passive`"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"glisten"/utf8>>,
                    function => <<"with_active_state"/utf8>>,
                    line => 371})
    end.

-file("src/glisten.gleam", 376).
?DOC(false).
-spec with_listener_name(
    builder(GTR, GTS),
    gleam@erlang@process:name(glisten@internal@listener:message())
) -> builder(GTR, GTS).
with_listener_name(Builder, Listener_name) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        {some, Listener_name},
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 384).
?DOC(false).
-spec with_connection_factory_name(
    builder(GTY, GTZ),
    gleam@erlang@process:name(gleam@otp@factory_supervisor:message(glisten@socket:socket(), gleam@erlang@process:subject(glisten@internal@handler:message(GTZ))))
) -> builder(GTY, GTZ).
with_connection_factory_name(Builder, Connection_factory_name) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        {some, Connection_factory_name},
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 394).
?DOC(" Start the TCP server with the given handler on the provided port\n").
-spec start(builder(any(), any()), integer()) -> {ok,
        gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, gleam@otp@actor:start_error()}.
start(Builder, Port) ->
    Listener_name = gleam@option:unwrap(
        erlang:element(10, Builder),
        gleam_erlang_ffi:new_name(<<"glisten_listener"/utf8>>)
    ),
    Connection_supervisor = gleam@option:unwrap(
        erlang:element(11, Builder),
        gleam_erlang_ffi:new_name(<<"glisten_connection_supervisor"/utf8>>)
    ),
    Options = begin
        _pipe = [{ip, erlang:element(2, Builder)}],
        _pipe@1 = lists:append(_pipe, case erlang:element(8, Builder) of
                true ->
                    [ipv6];

                false ->
                    []
            end),
        _pipe@2 = lists:append(_pipe@1, case erlang:element(9, Builder) of
                {some, Opts} ->
                    [{cert_key_config, Opts}];

                _ ->
                    []
            end),
        lists:append(
            _pipe@2,
            case {erlang:element(9, Builder), erlang:element(7, Builder)} of
                {{some, _}, true} ->
                    [{alpn_preferred_protocols,
                            [<<"h2"/utf8>>, <<"http/1.1"/utf8>>]}];

                {{some, _}, false} ->
                    [{alpn_preferred_protocols, [<<"http/1.1"/utf8>>]}];

                {none, _} ->
                    []
            end
        )
    end,
    Transport = case erlang:element(9, Builder) of
        {some, _} ->
            ssl;

        _ ->
            tcp
    end,
    _pipe@3 = {pool,
        convert_loop(erlang:element(4, Builder)),
        erlang:element(6, Builder),
        Connection_supervisor,
        convert_on_init(erlang:element(3, Builder)),
        erlang:element(5, Builder),
        Transport,
        erlang:element(12, Builder)},
    glisten@internal@acceptor:start_pool(
        _pipe@3,
        Transport,
        Port,
        Options,
        Listener_name
    ).

-file("src/glisten.gleam", 326).
?DOC(
    " This sets the interface for `glisten` to listen on. It accepts the following\n"
    " strings:  \"localhost\", valid IPv4 addresses (i.e. \"127.0.0.1\"), and valid\n"
    " IPv6 addresses (i.e. \"::1\"). If an invalid value is provided, this will\n"
    " panic.\n"
).
-spec bind(builder(GST, GSU), binary()) -> builder(GST, GSU).
bind(Builder, Interface) ->
    Address@1 = case {Interface,
        glisten_ffi:parse_address(unicode:characters_to_list(Interface))} of
        {<<"0.0.0.0"/utf8>>, _} ->
            any;

        {<<"localhost"/utf8>>, _} ->
            loopback;

        {<<"127.0.0.1"/utf8>>, _} ->
            loopback;

        {_, {ok, Address}} ->
            {address, Address};

        {_, {error, _}} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Invalid interface provided:  must be a valid IPv4/IPv6 address, or \"localhost\""/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"glisten"/utf8>>,
                    function => <<"bind"/utf8>>,
                    line => 335})
    end,
    {builder,
        Address@1,
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder),
        erlang:element(11, Builder),
        erlang:element(12, Builder)}.

-file("src/glisten.gleam", 443).
?DOC(
    " Helper method for building a child specification for use in a supervision\n"
    " tree.\n"
).
-spec supervised(builder(any(), any()), integer()) -> gleam@otp@supervision:child_specification(gleam@otp@static_supervisor:supervisor()).
supervised(Handler, Port) ->
    gleam@otp@supervision:supervisor(fun() -> start(Handler, Port) end).
