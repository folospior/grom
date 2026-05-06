-module(mist@internal@handler).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mist/internal/handler.gleam").
-export([new_state/1, init/1, with_func/2]).
-export_type([handler_error/0, state/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type handler_error() :: {invalid_request, mist@internal@http:decode_error()} |
    not_found.

-type state() :: {http1,
        mist@internal@http@handler:state(),
        gleam@erlang@process:subject(mist@internal@http2@stream:send_message())} |
    {http2, mist@internal@http2@handler:state()}.

-file("src/mist/internal/handler.gleam", 31).
?DOC(false).
-spec new_state(
    gleam@erlang@process:subject(mist@internal@http2@stream:send_message())
) -> state().
new_state(Subj) ->
    {http1, mist@internal@http@handler:initial_state(), Subj}.

-file("src/mist/internal/handler.gleam", 35).
?DOC(false).
-spec init(any()) -> {state(),
    gleam@option:option(gleam@erlang@process:selector(mist@internal@http2@stream:send_message()))}.
init(_) ->
    Subj = gleam@erlang@process:new_subject(),
    Selector = begin
        _pipe = gleam_erlang_ffi:new_selector(),
        gleam@erlang@process:select(_pipe, Subj)
    end,
    {new_state(Subj), {some, Selector}}.

-file("src/mist/internal/handler.gleam", 44).
?DOC(false).
-spec with_func(
    fun((gleam@http@request:request(mist@internal@http:connection())) -> gleam@http@response:response(mist@internal@http:response_data())),
    gleam@erlang@process:name(gleam@otp@factory_supervisor:message(fun(() -> {ok,
            gleam@otp@actor:started(gleam@erlang@process:pid_())} |
        {error, gleam@otp@actor:start_error()}), gleam@erlang@process:pid_()))
) -> fun((state(), glisten:message(mist@internal@http2@stream:send_message()), glisten:connection(mist@internal@http2@stream:send_message())) -> glisten:next(state(), glisten:message(mist@internal@http2@stream:send_message()))).
with_func(Handler, Factory_name) ->
    fun(State, Msg, Conn) ->
        Sender = erlang:element(4, Conn),
        Conn@1 = {connection,
            {initial, <<>>},
            erlang:element(2, Conn),
            erlang:element(3, Conn),
            Factory_name},
        Result = case {Msg, State} of
            {{user, {send, _, _}}, {http1, _, _}} ->
                {error,
                    {error,
                        <<"Attempted to send HTTP/2 response without upgrade"/utf8>>}};

            {{user, {send, Id, Resp}}, {http2, State@1}} ->
                _pipe@2 = case erlang:element(4, Resp) of
                    {bytes, Bytes} ->
                        _pipe = Resp,
                        _pipe@1 = gleam@http@response:set_body(_pipe, Bytes),
                        mist@internal@http2:send_bytes_tree(
                            _pipe@1,
                            Conn@1,
                            erlang:element(7, State@1),
                            Id
                        );

                    {file, _, _, _} ->
                        {error, <<"File sending unsupported over HTTP/2"/utf8>>};

                    websocket ->
                        {error, <<"WebSocket unsupported for HTTP/2"/utf8>>};

                    chunked ->
                        {error,
                            <<"Chunked encoding not supported for HTTP/2"/utf8>>};

                    server_sent_events ->
                        {error,
                            <<"Server-Sent Events unsupported for HTTP/2"/utf8>>}
                end,
                _pipe@3 = gleam@result:map(
                    _pipe@2,
                    fun(Context) ->
                        {http2,
                            mist@internal@http2@handler:send_hpack_context(
                                State@1,
                                Context
                            )}
                    end
                ),
                gleam@result:map_error(
                    _pipe@3,
                    fun(Err) ->
                        logging:log(
                            debug,
                            <<"Error sending HTTP/2 data: "/utf8, Err/binary>>
                        ),
                        {error, Err}
                    end
                );

            {{packet, Msg@1}, {http1, State@2, Self}} ->
                _ = case erlang:element(2, State@2) of
                    {some, T} ->
                        gleam@erlang@process:cancel_timer(T);

                    _ ->
                        timer_not_found
                end,
                _pipe@4 = Msg@1,
                _pipe@5 = mist@internal@http:parse_request(_pipe@4, Conn@1),
                _pipe@10 = gleam@result:map_error(
                    _pipe@5,
                    fun(Err@1) -> case Err@1 of
                            discard_packet ->
                                {ok, nil};

                            malformed_request ->
                                Msg@2 = <<"Received malformed HTTP request"/utf8>>,
                                logging:log(warning, Msg@2),
                                {error, Msg@2};

                            invalid_method ->
                                Msg@3 = <<"Received invalid HTTP method"/utf8>>,
                                logging:log(warning, Msg@3),
                                {error, Msg@3};

                            invalid_path ->
                                Msg@4 = <<"Received invalid HTTP path"/utf8>>,
                                logging:log(warning, Msg@4),
                                {error, Msg@4};

                            unknown_header ->
                                Msg@5 = <<"Received unknown HTTP header"/utf8>>,
                                logging:log(warning, Msg@5),
                                {error, Msg@5};

                            unknown_method ->
                                Msg@6 = <<"Received unknown HTTP method"/utf8>>,
                                logging:log(warning, Msg@6),
                                {error, Msg@6};

                            invalid_body ->
                                Msg@7 = <<"Received invalid HTTP body"/utf8>>,
                                logging:log(warning, Msg@7),
                                {error, Msg@7};

                            no_host_header ->
                                Msg@8 = <<"Missing HTTP `host` header"/utf8>>,
                                logging:log(warning, Msg@8),
                                _ = begin
                                    _pipe@6 = gleam@http@response:new(400),
                                    _pipe@7 = gleam@http@response:prepend_header(
                                        _pipe@6,
                                        <<"connection"/utf8>>,
                                        <<"close"/utf8>>
                                    ),
                                    _pipe@8 = gleam@http@response:set_body(
                                        _pipe@7,
                                        gleam@bytes_tree:new()
                                    ),
                                    _pipe@9 = mist@internal@encoder:to_bytes_tree(
                                        _pipe@8,
                                        <<"1.1"/utf8>>
                                    ),
                                    glisten@transport:send(
                                        erlang:element(4, Conn@1),
                                        erlang:element(3, Conn@1),
                                        _pipe@9
                                    )
                                end,
                                {ok, nil};

                            invalid_http_version ->
                                Msg@9 = <<"Received invalid HTTP version"/utf8>>,
                                logging:log(warning, Msg@9),
                                {error, Msg@9}
                        end end
                ),
                gleam@result:'try'(_pipe@10, fun(Req) -> case Req of
                            {http1_request, Req@1, Version} ->
                                _pipe@11 = mist@internal@http@handler:call(
                                    Req@1,
                                    Handler,
                                    Sender,
                                    Version
                                ),
                                gleam@result:map(
                                    _pipe@11,
                                    fun(New_state) ->
                                        {http1, New_state, Self}
                                    end
                                );

                            {upgrade, Data} ->
                                _pipe@12 = mist@internal@http2@handler:upgrade(
                                    Data,
                                    Conn@1,
                                    Self
                                ),
                                _pipe@13 = gleam@result:map(
                                    _pipe@12,
                                    fun(Field@0) -> {http2, Field@0} end
                                ),
                                gleam@result:map_error(
                                    _pipe@13,
                                    fun(Field@0) -> {error, Field@0} end
                                )
                        end end);

            {{packet, Msg@10}, {http2, State@3}} ->
                _pipe@14 = State@3,
                _pipe@15 = mist@internal@http2@handler:append_data(
                    _pipe@14,
                    Msg@10
                ),
                _pipe@16 = mist@internal@http2@handler:call(
                    _pipe@15,
                    Conn@1,
                    Handler
                ),
                gleam@result:map(_pipe@16, fun(Field@0) -> {http2, Field@0} end)
        end,
        case Result of
            {ok, Value} ->
                glisten:continue(Value);

            {error, {ok, _}} ->
                glisten:stop();

            {error, {error, Reason}} ->
                glisten:stop_abnormal(Reason)
        end
    end.
