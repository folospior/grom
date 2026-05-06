-module(stratus).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/stratus.gleam").
-export([continue/1, with_selector/2, stop/0, stop_abnormal/1, initialised/1, new/2, selecting/2, new_with_initialiser/2, on_message/2, with_connect_timeout/2, on_close/2, to_user_message/1, send_text_message/2, send_binary_message/2, send_ping/2, get_custom_code/1, get_custom_body/1, close/2, close_custom/3, start/1, supervised/1]).
-export_type([connection/0, socket_reason/0, custom_close_error/0, next/2, internal_message/1, message/1, builder/2, initialised/2, state/2, close_reason/0, custom_close_reason/0, handshake_error/0, handshake_response/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-opaque connection() :: {connection,
        stratus@internal@socket:socket(),
        stratus@internal@transport:transport(),
        gleam@option:option(gramps@websocket@compression:context())}.

-type socket_reason() :: socket_closed |
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

-type custom_close_error() :: {socket_fail, socket_reason()} | invalid_code.

-opaque next(HEJ, HEK) :: {continue,
        HEJ,
        gleam@option:option(gleam@erlang@process:selector(HEK))} |
    normal_stop |
    {abnormal_stop, binary()}.

-opaque internal_message(HEL) :: {user_message, HEL} |
    {err, socket_reason()} |
    {data, bitstring()} |
    {closed, close_reason()} |
    {ready, bitstring()} |
    shutdown.

-type message(HEM) :: {text, binary()} | {binary, bitstring()} | {user, HEM}.

-opaque builder(HEN, HEO) :: {builder,
        gleam@http@request:request(binary()),
        integer(),
        fun(() -> {ok, initialised(HEN, HEO)} | {error, binary()}),
        fun((HEN, message(HEO), connection()) -> next(HEN, HEO)),
        fun((HEN, close_reason()) -> nil)}.

-type initialised(HEP, HEQ) :: {initialised,
        HEP,
        gleam@option:option(gleam@erlang@process:selector(HEQ))}.

-type state(HER, HES) :: {state,
        bitstring(),
        gleam@option:option(gramps@websocket:frame()),
        gleam@erlang@process:subject(internal_message(HES)),
        stratus@internal@socket:socket(),
        HER,
        gleam@option:option(gramps@websocket@compression:compression())}.

-type close_reason() :: not_provided |
    {normal, bitstring()} |
    {going_away, bitstring()} |
    {protocol_error, bitstring()} |
    {unexpected_data_type, bitstring()} |
    {inconsistent_data_type, bitstring()} |
    {policy_violation, bitstring()} |
    {message_too_big, bitstring()} |
    {missing_extensions, bitstring()} |
    {unexpected_condition, bitstring()} |
    {custom, custom_close_reason()}.

-opaque custom_close_reason() :: {custom_close_reason, integer(), bitstring()}.

-type handshake_error() :: {sock, socket_reason()} |
    {protocol, bitstring()} |
    {upgrade_failed, gleam@http@response:response(bitstring())}.

-type handshake_response() :: {handshake_response,
        stratus@internal@socket:socket(),
        gleam@http@response:response(bitstring()),
        bitstring()}.

-file("src/stratus.gleam", 81).
-spec convert_socket_reason(stratus@internal@socket:socket_reason()) -> socket_reason().
convert_socket_reason(Reason) ->
    case Reason of
        badarg ->
            badarg;

        closed ->
            socket_closed;

        eaddrinuse ->
            eaddrinuse;

        eaddrnotavail ->
            eaddrnotavail;

        eafnosupport ->
            eafnosupport;

        ealready ->
            ealready;

        econnaborted ->
            econnaborted;

        econnrefused ->
            econnrefused;

        econnreset ->
            econnreset;

        edestaddrreq ->
            edestaddrreq;

        ehostdown ->
            ehostdown;

        ehostunreach ->
            ehostunreach;

        einprogress ->
            einprogress;

        eisconn ->
            eisconn;

        emsgsize ->
            emsgsize;

        enetdown ->
            enetdown;

        enetunreach ->
            enetunreach;

        enopkg ->
            enopkg;

        enoprotoopt ->
            enoprotoopt;

        enotconn ->
            enotconn;

        enotsock ->
            enotsock;

        enotty ->
            enotty;

        eproto ->
            eproto;

        eprotonosupport ->
            eprotonosupport;

        eprototype ->
            eprototype;

        esocktnosupport ->
            esocktnosupport;

        etimedout ->
            etimedout;

        ewouldblock ->
            ewouldblock;

        exbadport ->
            exbadport;

        exbadseq ->
            exbadseq;

        terminated ->
            terminated;

        timeout ->
            timeout
    end.

-file("src/stratus.gleam", 118).
-spec from_socket_message(stratus@internal@socket:socket_message()) -> internal_message(any()).
from_socket_message(Msg) ->
    case Msg of
        {data, Bits} ->
            {data, Bits};

        {err, Reason} ->
            {err, convert_socket_reason(Reason)}
    end.

-file("src/stratus.gleam", 131).
-spec continue(HEV) -> next(HEV, any()).
continue(State) ->
    {continue, State, none}.

-file("src/stratus.gleam", 135).
-spec with_selector(next(HEZ, HFA), gleam@erlang@process:selector(HFA)) -> next(HEZ, HFA).
with_selector(Next, Selector) ->
    case Next of
        {continue, State, _} ->
            {continue, State, {some, Selector}};

        _ ->
            Next
    end.

-file("src/stratus.gleam", 145).
-spec stop() -> next(any(), any()).
stop() ->
    normal_stop.

-file("src/stratus.gleam", 149).
-spec stop_abnormal(binary()) -> next(any(), any()).
stop_abnormal(Reason) ->
    {abnormal_stop, Reason}.

-file("src/stratus.gleam", 204).
-spec initialised(HFT) -> initialised(HFT, any()).
initialised(State) ->
    {initialised, State, none}.

-file("src/stratus.gleam", 187).
?DOC(
    " This creates a builder to set up a WebSocket actor. This will use default\n"
    " values for the connection initialization timeout, and provide an empty\n"
    " function to be called when the server closes the connection. If you want to\n"
    " customize either of those, see the helper functions `with_connect_timeout`\n"
).
-spec new(gleam@http@request:request(binary()), HFP) -> builder(HFP, any()).
new(Req, State) ->
    {builder,
        Req,
        5000,
        fun() -> {ok, initialised(State)} end,
        fun(State@1, _, _) -> continue(State@1) end,
        fun(_, _) -> nil end}.

-file("src/stratus.gleam", 208).
-spec selecting(initialised(HFX, any()), gleam@erlang@process:selector(HGB)) -> initialised(HFX, HGB).
selecting(Initialised, Selector) ->
    {initialised, erlang:element(2, Initialised), {some, Selector}}.

-file("src/stratus.gleam", 215).
-spec new_with_initialiser(
    gleam@http@request:request(binary()),
    fun(() -> {ok, initialised(HGG, HGH)} | {error, binary()})
) -> builder(HGG, HGH).
new_with_initialiser(Req, Init) ->
    {builder,
        Req,
        5000,
        Init,
        fun(State, _, _) -> continue(State) end,
        fun(_, _) -> nil end}.

-file("src/stratus.gleam", 228).
-spec on_message(
    builder(HGO, HGP),
    fun((HGO, message(HGP), connection()) -> next(HGO, HGP))
) -> builder(HGO, HGP).
on_message(Builder, On_message) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        On_message,
        erlang:element(6, Builder)}.

-file("src/stratus.gleam", 240).
?DOC(
    " This sets the maximum amount of time you are willing to wait for both\n"
    " connecting to the server and receiving the upgrade response.  This means\n"
    " that it may take up to `timeout * 2` to begin sending or receiving messages.\n"
    " This value defaults to 5 seconds.\n"
).
-spec with_connect_timeout(builder(HGX, HGY), integer()) -> builder(HGX, HGY).
with_connect_timeout(Builder, Timeout) ->
    {builder,
        erlang:element(2, Builder),
        Timeout,
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder)}.

-file("src/stratus.gleam", 253).
?DOC(
    " You can provide a function to be called when the connection is closed. This\n"
    " function receives the last value for the state of the WebSocket.\n"
    "\n"
    " NOTE:  If you manually call `stratus.close`, this function will not be\n"
    " called. I'm unsure right now if this is a bug or working as intended. But\n"
    " you will be in the loop with the state value handy.\n"
).
-spec on_close(builder(HHD, HHE), fun((HHD, close_reason()) -> nil)) -> builder(HHD, HHE).
on_close(Builder, On_close) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        On_close}.

-file("src/stratus.gleam", 617).
?DOC(
    " The `Subject` returned from `start` is an opaque type.  In order to\n"
    " send custom messages to your process, you can do this mapping.\n"
    "\n"
    " For example:\n"
    " ```gleam\n"
    "   // using `process.send`\n"
    "   MyMessage(some_data)\n"
    "   |> stratus.to_user_message\n"
    "   |> process.send(stratus_subject, _)\n"
    "   // using `process.call`\n"
    "   process.call(stratus_subject, fn(subj) {\n"
    "     stratus.to_user_message(MyMessage(some_data, subj))\n"
    "   })\n"
    " ```\n"
).
-spec to_user_message(HII) -> internal_message(HII).
to_user_message(User_message) ->
    {user_message, User_message}.

-file("src/stratus.gleam", 625).
?DOC(
    " From within the actor loop, this is how you send a WebSocket text frame.\n"
    " This must be valid UTF-8, so it is a `String`.\n"
).
-spec send_text_message(connection(), binary()) -> {ok, nil} |
    {error, socket_reason()}.
send_text_message(Conn, Msg) ->
    Frame = gramps@websocket:encode_text_frame(
        Msg,
        erlang:element(4, Conn),
        {some, crypto:strong_rand_bytes(4)}
    ),
    _pipe = stratus@internal@transport:send(
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        Frame
    ),
    gleam@result:map_error(_pipe, fun convert_socket_reason/1).

-file("src/stratus.gleam", 640).
?DOC(" From within the actor loop, this is how you send a WebSocket text frame.\n").
-spec send_binary_message(connection(), bitstring()) -> {ok, nil} |
    {error, socket_reason()}.
send_binary_message(Conn, Msg) ->
    Frame = gramps@websocket:encode_binary_frame(
        Msg,
        erlang:element(4, Conn),
        {some, crypto:strong_rand_bytes(4)}
    ),
    _pipe = stratus@internal@transport:send(
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        Frame
    ),
    gleam@result:map_error(_pipe, fun convert_socket_reason/1).

-file("src/stratus.gleam", 655).
?DOC(" Send a ping frame with some data.\n").
-spec send_ping(connection(), bitstring()) -> {ok, nil} |
    {error, socket_reason()}.
send_ping(Conn, Data) ->
    Size = erlang:byte_size(Data),
    Mask = case Size of
        0 ->
            {some, <<0:4>>};

        _ ->
            {some, crypto:strong_rand_bytes(4)}
    end,
    Frame = gramps@websocket:encode_ping_frame(Data, Mask),
    _pipe = stratus@internal@transport:send(
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        Frame
    ),
    gleam@result:map_error(_pipe, fun convert_socket_reason/1).

-file("src/stratus.gleam", 695).
-spec get_custom_code(custom_close_reason()) -> integer().
get_custom_code(Reason) ->
    erlang:element(2, Reason).

-file("src/stratus.gleam", 699).
-spec get_custom_body(custom_close_reason()) -> bitstring().
get_custom_body(Reason) ->
    erlang:element(3, Reason).

-file("src/stratus.gleam", 703).
-spec from_websocket_close_reason(gramps@websocket:close_reason()) -> close_reason().
from_websocket_close_reason(Reason) ->
    case Reason of
        not_provided ->
            not_provided;

        {going_away, Body} ->
            {going_away, Body};

        {inconsistent_data_type, Body@1} ->
            {inconsistent_data_type, Body@1};

        {message_too_big, Body@2} ->
            {message_too_big, Body@2};

        {missing_extensions, Body@3} ->
            {missing_extensions, Body@3};

        {normal, Body@4} ->
            {normal, Body@4};

        {policy_violation, Body@5} ->
            {policy_violation, Body@5};

        {protocol_error, Body@6} ->
            {protocol_error, Body@6};

        {unexpected_condition, Body@7} ->
            {unexpected_condition, Body@7};

        {unexpected_data_type, Body@8} ->
            {unexpected_data_type, Body@8};

        {custom_close_reason, Code, Body@9} ->
            {custom, {custom_close_reason, Code, Body@9}}
    end.

-file("src/stratus.gleam", 499).
-spec handle_frame(
    builder(HHX, HHY),
    state(HHX, HHY),
    connection(),
    gramps@websocket:frame()
) -> next(state(HHX, HHY), internal_message(HHY)).
handle_frame(Builder, State, Conn, Frame) ->
    case Frame of
        {data, {text_frame, Data}} ->
            Str@1 = case gleam@bit_array:to_string(Data) of
                {ok, Str} -> Str;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"stratus"/utf8>>,
                                function => <<"handle_frame"/utf8>>,
                                line => 507,
                                value => _assert_fail,
                                start => 15119,
                                'end' => 15165,
                                pattern_start => 15130,
                                pattern_end => 15137})
            end,
            Res = exception_ffi:rescue(
                fun() ->
                    (erlang:element(5, Builder))(
                        erlang:element(6, State),
                        {text, Str@1},
                        Conn
                    )
                end
            ),
            case Res of
                {ok, {continue, User_state, User_selector}} ->
                    New_state = {state,
                        erlang:element(2, State),
                        erlang:element(3, State),
                        erlang:element(4, State),
                        erlang:element(5, State),
                        User_state,
                        erlang:element(7, State)},
                    case User_selector of
                        {some, User_selector@1} ->
                            Selector = begin
                                _pipe = User_selector@1,
                                _pipe@1 = gleam_erlang_ffi:map_selector(
                                    _pipe,
                                    fun(Field@0) -> {user_message, Field@0} end
                                ),
                                gleam_erlang_ffi:merge_selector(
                                    _pipe@1,
                                    gleam_erlang_ffi:map_selector(
                                        stratus@internal@socket:selector(),
                                        fun(Msg) ->
                                            Msg@2 = case Msg of
                                                {ok, Msg@1} -> Msg@1;
                                                _assert_fail@1 ->
                                                    erlang:error(
                                                            #{gleam_error => let_assert,
                                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                file => <<?FILEPATH/utf8>>,
                                                                module => <<"stratus"/utf8>>,
                                                                function => <<"handle_frame"/utf8>>,
                                                                line => 523,
                                                                value => _assert_fail@1,
                                                                start => 15760,
                                                                'end' => 15784,
                                                                pattern_start => 15771,
                                                                pattern_end => 15778}
                                                        )
                                            end,
                                            from_socket_message(Msg@2)
                                        end
                                    )
                                )
                            end,
                            {continue, New_state, {some, Selector}};

                        _ ->
                            continue(New_state)
                    end;

                {ok, normal_stop} ->
                    normal_stop;

                {ok, {abnormal_stop, Reason}} ->
                    {abnormal_stop, Reason};

                {error, Reason@1} ->
                    logging:log(
                        error,
                        <<"Caught error in user handler: "/utf8,
                            (gleam@string:inspect(Reason@1))/binary>>
                    ),
                    continue(State)
            end;

        {data, {binary_frame, Data@1}} ->
            Res@1 = exception_ffi:rescue(
                fun() ->
                    (erlang:element(5, Builder))(
                        erlang:element(6, State),
                        {binary, Data@1},
                        Conn
                    )
                end
            ),
            case Res@1 of
                {ok, {continue, User_state@1, User_selector@2}} ->
                    New_state@1 = {state,
                        erlang:element(2, State),
                        erlang:element(3, State),
                        erlang:element(4, State),
                        erlang:element(5, State),
                        User_state@1,
                        erlang:element(7, State)},
                    case User_selector@2 of
                        {some, User_selector@3} ->
                            Selector@1 = begin
                                _pipe@2 = User_selector@3,
                                _pipe@3 = gleam_erlang_ffi:map_selector(
                                    _pipe@2,
                                    fun(Field@0) -> {user_message, Field@0} end
                                ),
                                gleam_erlang_ffi:merge_selector(
                                    _pipe@3,
                                    gleam_erlang_ffi:map_selector(
                                        stratus@internal@socket:selector(),
                                        fun(Msg@3) ->
                                            Msg@5 = case Msg@3 of
                                                {ok, Msg@4} -> Msg@4;
                                                _assert_fail@2 ->
                                                    erlang:error(
                                                            #{gleam_error => let_assert,
                                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                file => <<?FILEPATH/utf8>>,
                                                                module => <<"stratus"/utf8>>,
                                                                function => <<"handle_frame"/utf8>>,
                                                                line => 559,
                                                                value => _assert_fail@2,
                                                                start => 16942,
                                                                'end' => 16966,
                                                                pattern_start => 16953,
                                                                pattern_end => 16960}
                                                        )
                                            end,
                                            from_socket_message(Msg@5)
                                        end
                                    )
                                )
                            end,
                            {continue, New_state@1, {some, Selector@1}};

                        _ ->
                            continue(New_state@1)
                    end;

                {ok, normal_stop} ->
                    normal_stop;

                {ok, {abnormal_stop, Reason@2}} ->
                    {abnormal_stop, Reason@2};

                {error, Reason@3} ->
                    logging:log(
                        error,
                        <<"Caught error in user handler: "/utf8,
                            (gleam@string:inspect(Reason@3))/binary>>
                    ),
                    continue(State)
            end;

        {control, {ping_frame, Payload}} ->
            Mask = {some, <<0:4/unit:8>>},
            Frame@1 = gramps@websocket:encode_pong_frame(Payload, Mask),
            _ = stratus@internal@transport:send(
                erlang:element(3, Conn),
                erlang:element(2, Conn),
                Frame@1
            ),
            continue(State);

        {control, {pong_frame, _}} ->
            continue(State);

        {control, {close_frame, Reason@4}} ->
            logging:log(
                debug,
                <<"WebSocket closing: "/utf8,
                    (gleam@string:inspect(Reason@4))/binary>>
            ),
            (erlang:element(6, Builder))(
                erlang:element(6, State),
                from_websocket_close_reason(Reason@4)
            ),
            normal_stop;

        {continuation, _, _} ->
            continue(State)
    end.

-file("src/stratus.gleam", 720).
-spec to_websocket_close_reason(close_reason()) -> gramps@websocket:close_reason().
to_websocket_close_reason(Reason) ->
    case Reason of
        not_provided ->
            not_provided;

        {going_away, Body} ->
            {going_away, Body};

        {inconsistent_data_type, Body@1} ->
            {inconsistent_data_type, Body@1};

        {message_too_big, Body@2} ->
            {message_too_big, Body@2};

        {missing_extensions, Body@3} ->
            {missing_extensions, Body@3};

        {normal, Body@4} ->
            {normal, Body@4};

        {policy_violation, Body@5} ->
            {policy_violation, Body@5};

        {protocol_error, Body@6} ->
            {protocol_error, Body@6};

        {unexpected_condition, Body@7} ->
            {unexpected_condition, Body@7};

        {unexpected_data_type, Body@8} ->
            {unexpected_data_type, Body@8};

        {custom, {custom_close_reason, Code, Body@9}} ->
            {custom_close_reason, Code, Body@9}
    end.

-file("src/stratus.gleam", 752).
-spec close(connection(), close_reason()) -> {ok, nil} |
    {error, socket_reason()}.
close(Conn, Reason) ->
    Reason@1 = to_websocket_close_reason(Reason),
    Mask = crypto:strong_rand_bytes(4),
    Frame = gramps@websocket:encode_close_frame(Reason@1, {some, Mask}),
    _pipe = stratus@internal@transport:send(
        erlang:element(3, Conn),
        erlang:element(2, Conn),
        Frame
    ),
    gleam@result:map_error(_pipe, fun convert_socket_reason/1).

-file("src/stratus.gleam", 738).
?DOC(" Closes the connection with a custom close code between 1000 and 4999.\n").
-spec close_custom(connection(), integer(), bitstring()) -> {ok, nil} |
    {error, custom_close_error()}.
close_custom(Conn, Code, Body) ->
    gleam@bool:guard(
        (Code >= 5000) orelse (Code < 1000),
        {error, invalid_code},
        fun() ->
            _pipe = close(Conn, {custom, {custom_close_reason, Code, Body}}),
            gleam@result:map_error(
                _pipe,
                fun(Field@0) -> {socket_fail, Field@0} end
            )
        end
    ).

-file("src/stratus.gleam", 764).
-spec make_upgrade(gleam@http@request:request(binary())) -> gleam@bytes_tree:bytes_tree().
make_upgrade(Req) ->
    User_headers = case erlang:element(3, Req) of
        [] ->
            <<""/utf8>>;

        _ ->
            _pipe = erlang:element(3, Req),
            _pipe@1 = gleam@list:filter(
                _pipe,
                fun(Pair) ->
                    {Key, _} = Pair,
                    ((((Key /= <<"host"/utf8>>) andalso (Key /= <<"upgrade"/utf8>>))
                    andalso (Key /= <<"connection"/utf8>>))
                    andalso (Key /= <<"sec-websocket-key"/utf8>>))
                    andalso (Key /= <<"sec-websocket-version"/utf8>>)
                end
            ),
            _pipe@2 = gleam@list:map(
                _pipe@1,
                fun(Pair@1) ->
                    {Key@1, Value} = Pair@1,
                    <<<<Key@1/binary, ": "/utf8>>/binary, Value/binary>>
                end
            ),
            _pipe@3 = gleam@string:join(_pipe@2, <<"\r\n"/utf8>>),
            gleam@string:append(_pipe@3, <<"\r\n"/utf8>>)
    end,
    Path@1 = case erlang:element(8, Req) of
        <<""/utf8>> ->
            <<"/"/utf8>>;

        Path ->
            Path
    end,
    Query = begin
        _pipe@4 = Req,
        _pipe@5 = gleam@http@request:get_query(_pipe@4),
        _pipe@6 = gleam@result:map(_pipe@5, fun gleam@uri:query_to_string/1),
        (fun(Str) -> case Str of
                {ok, <<""/utf8>>} ->
                    <<""/utf8>>;

                {ok, Str@1} ->
                    <<"?"/utf8, Str@1/binary>>;

                _ ->
                    <<""/utf8>>
            end end)(_pipe@6)
    end,
    Port@1 = begin
        _pipe@7 = erlang:element(7, Req),
        _pipe@8 = gleam@option:map(
            _pipe@7,
            fun(Port) ->
                <<":"/utf8, (erlang:integer_to_binary(Port))/binary>>
            end
        ),
        gleam@option:unwrap(_pipe@8, <<""/utf8>>)
    end,
    _pipe@9 = gleam@bytes_tree:new(),
    _pipe@10 = gleam@bytes_tree:append_string(
        _pipe@9,
        <<<<<<"GET "/utf8, Path@1/binary>>/binary, Query/binary>>/binary,
            " HTTP/1.1\r\n"/utf8>>
    ),
    _pipe@11 = gleam@bytes_tree:append_string(
        _pipe@10,
        <<<<<<"host: "/utf8, (erlang:element(6, Req))/binary>>/binary,
                Port@1/binary>>/binary,
            "\r\n"/utf8>>
    ),
    _pipe@12 = gleam@bytes_tree:append_string(
        _pipe@11,
        <<"upgrade: websocket\r\n"/utf8>>
    ),
    _pipe@13 = gleam@bytes_tree:append_string(
        _pipe@12,
        <<"connection: upgrade\r\n"/utf8>>
    ),
    _pipe@14 = gleam@bytes_tree:append_string(
        _pipe@13,
        <<<<"sec-websocket-key: "/utf8,
                (gramps@websocket:make_client_key())/binary>>/binary,
            "\r\n"/utf8>>
    ),
    _pipe@15 = gleam@bytes_tree:append_string(
        _pipe@14,
        <<"sec-websocket-version: 13\r\n"/utf8>>
    ),
    _pipe@16 = gleam@bytes_tree:append_string(
        _pipe@15,
        <<"sec-websocket-extensions: permessage-deflate\r\n"/utf8>>
    ),
    _pipe@17 = gleam@bytes_tree:append_string(_pipe@16, User_headers),
    gleam@bytes_tree:append_string(_pipe@17, <<"\r\n"/utf8>>).

-file("src/stratus.gleam", 927).
-spec read_body(
    stratus@internal@transport:transport(),
    stratus@internal@socket:socket(),
    integer(),
    integer(),
    bitstring()
) -> {ok, {bitstring(), bitstring()}} | {error, socket_reason()}.
read_body(Transport, Socket, Timeout, Length, Body) ->
    case Body of
        <<Data:Length/binary, Rest/bitstring>> ->
            {ok, {Data, Rest}};

        _ ->
            case stratus@internal@transport:receive_timeout(
                Transport,
                Socket,
                0,
                Timeout
            ) of
                {ok, Data@1} ->
                    read_body(
                        Transport,
                        Socket,
                        Timeout,
                        Length,
                        <<Body/bitstring, Data@1/bitstring>>
                    );

                {error, Reason} ->
                    {error, convert_socket_reason(Reason)}
            end
    end.

-file("src/stratus.gleam", 837).
-spec perform_handshake(
    gleam@http@request:request(binary()),
    stratus@internal@transport:transport(),
    integer()
) -> {ok, handshake_response()} | {error, handshake_error()}.
perform_handshake(Req, Transport, Timeout) ->
    Certs = case erlang:element(5, Req) of
        https ->
            case stratus_ffi:ssl_start() of
                {ok, _} -> nil;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"stratus"/utf8>>,
                                function => <<"perform_handshake"/utf8>>,
                                line => 844,
                                value => _assert_fail,
                                start => 25185,
                                'end' => 25217,
                                pattern_start => 25196,
                                pattern_end => 25203})
            end,
            [{cacerts, public_key:cacerts_get()},
                stratus_ffi:custom_sni_matcher()];

        http ->
            []
    end,
    Opts = stratus@internal@socket:convert_options(
        lists:append(
            [{packets_of, binary},
                {send_timeout, 30000},
                {send_timeout_close, true},
                {reuseaddr, true},
                {nodelay, true}],
            [{'receive', pull} | Certs]
        )
    ),
    Port = gleam@option:lazy_unwrap(
        erlang:element(7, Req),
        fun() -> case Transport of
                ssl ->
                    443;

                tcp ->
                    80
            end end
    ),
    logging:log(
        debug,
        <<<<<<"Making request to "/utf8, (erlang:element(6, Req))/binary>>/binary,
                " at "/utf8>>/binary,
            (erlang:integer_to_binary(Port))/binary>>
    ),
    gleam@result:'try'(
        gleam@result:map_error(
            stratus@internal@transport:connect(
                Transport,
                unicode:characters_to_list(erlang:element(6, Req)),
                Port,
                Opts,
                Timeout
            ),
            fun(Err) -> {sock, convert_socket_reason(Err)} end
        ),
        fun(Socket) ->
            Upgrade_req = make_upgrade(Req),
            gleam@result:'try'(
                gleam@result:map_error(
                    stratus@internal@transport:send(
                        Transport,
                        Socket,
                        Upgrade_req
                    ),
                    fun(Err@1) -> {sock, convert_socket_reason(Err@1)} end
                ),
                fun(_) ->
                    logging:log(
                        debug,
                        <<"Sent upgrade request, waiting "/utf8,
                            (erlang:integer_to_binary(Timeout))/binary>>
                    ),
                    gleam@result:'try'(
                        gleam@result:map_error(
                            stratus@internal@transport:receive_timeout(
                                Transport,
                                Socket,
                                0,
                                Timeout
                            ),
                            fun(Err@2) ->
                                {sock, convert_socket_reason(Err@2)}
                            end
                        ),
                        fun(Resp) -> _pipe = Resp,
                            _pipe@1 = gramps@http:read_response(_pipe),
                            _pipe@2 = gleam@result:map_error(
                                _pipe@1,
                                fun(_) -> {protocol, Resp} end
                            ),
                            _pipe@6 = gleam@result:'try'(
                                _pipe@2,
                                fun(Pair) ->
                                    {Resp@1, Body} = Pair,
                                    Body_size = begin
                                        _pipe@3 = erlang:element(3, Resp@1),
                                        _pipe@4 = gleam@list:key_find(
                                            _pipe@3,
                                            <<"content-length"/utf8>>
                                        ),
                                        _pipe@5 = gleam@result:'try'(
                                            _pipe@4,
                                            fun gleam_stdlib:parse_int/1
                                        ),
                                        gleam@result:unwrap(_pipe@5, 0)
                                    end,
                                    case read_body(
                                        Transport,
                                        Socket,
                                        Timeout,
                                        Body_size,
                                        Body
                                    ) of
                                        {ok, {Body@1, Rest}} ->
                                            {ok,
                                                {gleam@http@response:set_body(
                                                        Resp@1,
                                                        Body@1
                                                    ),
                                                    Rest}};

                                        {error, Reason} ->
                                            {error, {sock, Reason}}
                                    end
                                end
                            ),
                            gleam@result:'try'(
                                _pipe@6,
                                fun(Pair@1) ->
                                    {Resp@2, Buffer} = Pair@1,
                                    case erlang:element(2, Resp@2) of
                                        101 ->
                                            {ok,
                                                {handshake_response,
                                                    Socket,
                                                    Resp@2,
                                                    Buffer}};

                                        _ ->
                                            {error, {upgrade_failed, Resp@2}}
                                    end
                                end
                            ) end
                    )
                end
            )
        end
    ).

-file("src/stratus.gleam", 947).
-spec close_contexts(
    gleam@option:option(gramps@websocket@compression:compression())
) -> nil.
close_contexts(Contexts) ->
    case Contexts of
        {some, Compression} ->
            gramps@websocket@compression:close(erlang:element(3, Compression)),
            gramps@websocket@compression:close(erlang:element(2, Compression)),
            nil;

        _ ->
            nil
    end.

-file("src/stratus.gleam", 281).
?DOC(
    " This opens the WebSocket connection with the provided `Builder`. It makes\n"
    " some assumptions about the request if you do not provide it.  It will use\n"
    " ports 80 or 443 for `ws` or `wss` respectively.\n"
    "\n"
    " It will open the connection and perform the WebSocket handshake. If this\n"
    " fails, the actor will fail to start with the given reason as a string value.\n"
    "\n"
    " After that, received messages will be passed to your loop, and you can use\n"
    " the helper functions to send messages to the server. The `close` method will\n"
    " send a close frame and end the connection.\n"
).
-spec start(builder(any(), HHK)) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(internal_message(HHK)))} |
    {error, gleam@otp@actor:start_error()}.
start(Builder) ->
    Transport = case erlang:element(5, erlang:element(2, Builder)) of
        https ->
            ssl;

        _ ->
            tcp
    end,
    Timeout = erlang:element(3, Builder) + 100,
    _pipe@12 = gleam@otp@actor:new_with_initialiser(
        Timeout,
        fun(Subject) ->
            Started_selector = gleam@erlang@process:select(
                gleam_erlang_ffi:new_selector(),
                Subject
            ),
            Handshake_result = begin
                _pipe = perform_handshake(
                    erlang:element(2, Builder),
                    Transport,
                    erlang:element(3, Builder)
                ),
                gleam@result:map_error(
                    _pipe,
                    fun(Reason) ->
                        Msg = case Reason of
                            {upgrade_failed, Resp} ->
                                <<"WebSocket handshake failed with status "/utf8,
                                    (erlang:integer_to_binary(
                                        erlang:element(2, Resp)
                                    ))/binary>>;

                            Reason@1 ->
                                <<"WebSocket handshake failed: "/utf8,
                                    (gleam@string:inspect(Reason@1))/binary>>
                        end,
                        logging:log(error, Msg),
                        Msg
                    end
                )
            end,
            gleam@result:'try'(
                Handshake_result,
                fun(Handshake_response) ->
                    logging:log(debug, <<"Handshake successful"/utf8>>),
                    Extensions = begin
                        _pipe@1 = erlang:element(3, Handshake_response),
                        _pipe@2 = gleam@http@response:get_header(
                            _pipe@1,
                            <<"sec-websocket-extensions"/utf8>>
                        ),
                        _pipe@3 = gleam@result:map(
                            _pipe@2,
                            fun(_capture) ->
                                gleam@string:split(_capture, <<"; "/utf8>>)
                            end
                        ),
                        gleam@result:unwrap(_pipe@3, [])
                    end,
                    Context_takeovers = gramps@websocket:get_context_takeovers(
                        Extensions
                    ),
                    logging:log(debug, <<"Calling user initializer"/utf8>>),
                    gleam@result:'try'(
                        (erlang:element(4, Builder))(),
                        fun(_use0) ->
                            {initialised, User_state, User_selector} = _use0,
                            Selector@1 = case User_selector of
                                {some, Selector} ->
                                    _pipe@4 = Selector,
                                    _pipe@5 = gleam_erlang_ffi:map_selector(
                                        _pipe@4,
                                        fun(Field@0) -> {user_message, Field@0} end
                                    ),
                                    _pipe@6 = gleam_erlang_ffi:merge_selector(
                                        _pipe@5,
                                        Started_selector
                                    ),
                                    gleam_erlang_ffi:merge_selector(
                                        _pipe@6,
                                        gleam_erlang_ffi:map_selector(
                                            stratus@internal@socket:selector(),
                                            fun(Msg@1) ->
                                                Msg@3 = case Msg@1 of
                                                    {ok, Msg@2} -> Msg@2;
                                                    _assert_fail ->
                                                        erlang:error(
                                                                #{gleam_error => let_assert,
                                                                    message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                    file => <<?FILEPATH/utf8>>,
                                                                    module => <<"stratus"/utf8>>,
                                                                    function => <<"start"/utf8>>,
                                                                    line => 331,
                                                                    value => _assert_fail,
                                                                    start => 9676,
                                                                    'end' => 9700,
                                                                    pattern_start => 9687,
                                                                    pattern_end => 9694}
                                                            )
                                                end,
                                                from_socket_message(Msg@3)
                                            end
                                        )
                                    );

                                _ ->
                                    _pipe@7 = Started_selector,
                                    gleam_erlang_ffi:merge_selector(
                                        _pipe@7,
                                        gleam_erlang_ffi:map_selector(
                                            stratus@internal@socket:selector(),
                                            fun(Msg@4) ->
                                                Msg@6 = case Msg@4 of
                                                    {ok, Msg@5} -> Msg@5;
                                                    _assert_fail@1 ->
                                                        erlang:error(
                                                                #{gleam_error => let_assert,
                                                                    message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                    file => <<?FILEPATH/utf8>>,
                                                                    module => <<"stratus"/utf8>>,
                                                                    function => <<"start"/utf8>>,
                                                                    line => 340,
                                                                    value => _assert_fail@1,
                                                                    start => 9913,
                                                                    'end' => 9937,
                                                                    pattern_start => 9924,
                                                                    pattern_end => 9931}
                                                            )
                                                end,
                                                from_socket_message(Msg@6)
                                            end
                                        )
                                    )
                            end,
                            Context = case gramps@websocket:has_deflate(
                                Extensions
                            ) of
                                true ->
                                    {some,
                                        gramps@websocket@compression:init(
                                            Context_takeovers
                                        )};

                                false ->
                                    none
                            end,
                            gleam@erlang@process:send(
                                Subject,
                                {ready, erlang:element(4, Handshake_response)}
                            ),
                            _pipe@8 = {state,
                                <<>>,
                                none,
                                Subject,
                                erlang:element(2, Handshake_response),
                                User_state,
                                Context},
                            _pipe@9 = gleam@otp@actor:initialised(_pipe@8),
                            _pipe@10 = gleam@otp@actor:selecting(
                                _pipe@9,
                                Selector@1
                            ),
                            _pipe@11 = gleam@otp@actor:returning(
                                _pipe@10,
                                Subject
                            ),
                            {ok, _pipe@11}
                        end
                    )
                end
            )
        end
    ),
    _pipe@18 = gleam@otp@actor:on_message(
        _pipe@12,
        fun(State, Message) -> case Message of
                {ready, Buffer} ->
                    _ = case Buffer of
                        <<>> ->
                            nil;

                        Data ->
                            gleam@erlang@process:send(
                                erlang:element(4, State),
                                {data, Data}
                            )
                    end,
                    case stratus@internal@transport:set_opts(
                        Transport,
                        erlang:element(5, State),
                        stratus@internal@socket:convert_options(
                            [{'receive', once}]
                        )
                    ) of
                        {ok, _} -> nil;
                        _assert_fail@2 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"stratus"/utf8>>,
                                        function => <<"start"/utf8>>,
                                        line => 370,
                                        value => _assert_fail@2,
                                        start => 10704,
                                        'end' => 10866,
                                        pattern_start => 10715,
                                        pattern_end => 10720})
                    end,
                    gleam@otp@actor:continue(State);

                {user_message, User_message} ->
                    Conn = {connection,
                        erlang:element(5, State),
                        Transport,
                        gleam@option:map(
                            erlang:element(7, State),
                            fun(Context@1) -> erlang:element(3, Context@1) end
                        )},
                    Res = exception_ffi:rescue(
                        fun() ->
                            (erlang:element(5, Builder))(
                                erlang:element(6, State),
                                {user, User_message},
                                Conn
                            )
                        end
                    ),
                    case Res of
                        {ok, {continue, User_state@1, User_selector@1}} ->
                            New_state = {state,
                                erlang:element(2, State),
                                erlang:element(3, State),
                                erlang:element(4, State),
                                erlang:element(5, State),
                                User_state@1,
                                erlang:element(7, State)},
                            case User_selector@1 of
                                {some, User_selector@2} ->
                                    Selector@2 = begin
                                        _pipe@13 = User_selector@2,
                                        _pipe@14 = gleam_erlang_ffi:map_selector(
                                            _pipe@13,
                                            fun(Field@0) -> {user_message, Field@0} end
                                        ),
                                        gleam_erlang_ffi:merge_selector(
                                            _pipe@14,
                                            gleam_erlang_ffi:map_selector(
                                                stratus@internal@socket:selector(
                                                    
                                                ),
                                                fun(Msg@7) ->
                                                    Msg@9 = case Msg@7 of
                                                        {ok, Msg@8} -> Msg@8;
                                                        _assert_fail@3 ->
                                                            erlang:error(
                                                                    #{gleam_error => let_assert,
                                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                        file => <<?FILEPATH/utf8>>,
                                                                        module => <<"stratus"/utf8>>,
                                                                        function => <<"start"/utf8>>,
                                                                        line => 400,
                                                                        value => _assert_fail@3,
                                                                        start => 11755,
                                                                        'end' => 11779,
                                                                        pattern_start => 11766,
                                                                        pattern_end => 11773}
                                                                )
                                                    end,
                                                    from_socket_message(Msg@9)
                                                end
                                            )
                                        )
                                    end,
                                    _pipe@15 = New_state,
                                    _pipe@16 = gleam@otp@actor:continue(
                                        _pipe@15
                                    ),
                                    gleam@otp@actor:with_selector(
                                        _pipe@16,
                                        Selector@2
                                    );

                                _ ->
                                    gleam@otp@actor:continue(New_state)
                            end;

                        {ok, normal_stop} ->
                            gleam@otp@actor:stop();

                        {ok, {abnormal_stop, Reason@2}} ->
                            gleam@otp@actor:stop_abnormal(Reason@2);

                        {error, Reason@3} ->
                            logging:log(
                                error,
                                <<"Caught error in user handler: "/utf8,
                                    (gleam@string:inspect(Reason@3))/binary>>
                            ),
                            gleam@otp@actor:continue(State)
                    end;

                {err, Reason@4} ->
                    close_contexts(erlang:element(7, State)),
                    gleam@otp@actor:stop_abnormal(
                        gleam@string:inspect(Reason@4)
                    );

                {data, Bits} ->
                    Conn@1 = {connection,
                        erlang:element(5, State),
                        Transport,
                        gleam@option:map(
                            erlang:element(7, State),
                            fun(Context@2) -> erlang:element(3, Context@2) end
                        )},
                    {Frames, Rest} = gramps@websocket:decode_many_frames(
                        gleam@bit_array:append(erlang:element(2, State), Bits),
                        gleam@option:map(
                            erlang:element(7, State),
                            fun(Context@3) -> erlang:element(2, Context@3) end
                        ),
                        []
                    ),
                    Frames@1 = gramps@websocket:aggregate_frames(
                        Frames,
                        erlang:element(3, State),
                        []
                    ),
                    _pipe@17 = case Frames@1 of
                        {error, nil} ->
                            continue(State);

                        {ok, Frames@2} ->
                            gleam@list:fold_until(
                                Frames@2,
                                continue(State),
                                fun(Acc, Frame) ->
                                    Prev_state@1 = case Acc of
                                        {continue, Prev_state, _} -> Prev_state;
                                        _assert_fail@4 ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"stratus"/utf8>>,
                                                        function => <<"start"/utf8>>,
                                                        line => 444,
                                                        value => _assert_fail@4,
                                                        start => 13208,
                                                        'end' => 13256,
                                                        pattern_start => 13219,
                                                        pattern_end => 13250}
                                                )
                                    end,
                                    case handle_frame(
                                        Builder,
                                        Prev_state@1,
                                        Conn@1,
                                        Frame
                                    ) of
                                        {continue, _, _} = Next ->
                                            {continue, Next};

                                        Err ->
                                            {stop, Err}
                                    end
                                end
                            )
                    end,
                    (fun(Next@1) -> case Next@1 of
                            {continue, State@1, Selector@3} ->
                                case stratus@internal@transport:set_opts(
                                    Transport,
                                    erlang:element(5, State@1),
                                    stratus@internal@socket:convert_options(
                                        [{'receive', once}]
                                    )
                                ) of
                                    {ok, _} -> nil;
                                    _assert_fail@5 ->
                                        erlang:error(
                                                #{gleam_error => let_assert,
                                                    message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                    file => <<?FILEPATH/utf8>>,
                                                    module => <<"stratus"/utf8>>,
                                                    function => <<"start"/utf8>>,
                                                    line => 455,
                                                    value => _assert_fail@5,
                                                    start => 13577,
                                                    'end' => 13769,
                                                    pattern_start => 13588,
                                                    pattern_end => 13593}
                                            )
                                end,
                                Next@2 = gleam@otp@actor:continue(
                                    {state,
                                        Rest,
                                        erlang:element(3, State@1),
                                        erlang:element(4, State@1),
                                        erlang:element(5, State@1),
                                        erlang:element(6, State@1),
                                        erlang:element(7, State@1)}
                                ),
                                case Selector@3 of
                                    {some, Selector@4} ->
                                        gleam@otp@actor:with_selector(
                                            Next@2,
                                            Selector@4
                                        );

                                    _ ->
                                        Next@2
                                end;

                            normal_stop ->
                                close_contexts(erlang:element(7, State)),
                                gleam@otp@actor:stop();

                            {abnormal_stop, Reason@5} ->
                                close_contexts(erlang:element(7, State)),
                                gleam@otp@actor:stop_abnormal(Reason@5)
                        end end)(_pipe@17);

                {closed, Reason@6} ->
                    logging:log(debug, <<"Received closed frame"/utf8>>),
                    (erlang:element(6, Builder))(
                        erlang:element(6, State),
                        Reason@6
                    ),
                    close_contexts(erlang:element(7, State)),
                    gleam@otp@actor:stop();

                shutdown ->
                    logging:log(debug, <<"Received shutdown messag"/utf8>>),
                    close_contexts(erlang:element(7, State)),
                    gleam@otp@actor:stop()
            end end
    ),
    gleam@otp@actor:start(_pipe@18).

-file("src/stratus.gleam", 495).
-spec supervised(builder(any(), HHT)) -> gleam@otp@supervision:child_specification(gleam@erlang@process:subject(internal_message(HHT))).
supervised(Builder) ->
    gleam@otp@supervision:worker(fun() -> start(Builder) end).
