-module(glisten@internal@acceptor).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/glisten/internal/acceptor.gleam").
-export([start/3, start_pool/5]).
-export_type([acceptor_message/0, acceptor_error/0, acceptor_state/0, pool/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type acceptor_message() :: {accept_connection, glisten@socket:listen_socket()}.

-type acceptor_error() :: {accept_error, glisten@socket:socket_reason()} |
    {handler_error, gleam@otp@actor:start_error()} |
    {control_error, gleam@erlang@atom:atom_()}.

-type acceptor_state() :: {acceptor_state,
        gleam@erlang@process:subject(acceptor_message()),
        gleam@option:option(glisten@socket:socket()),
        glisten@transport:transport()}.

-type pool(GIL, GIM) :: {pool,
        fun((GIL, glisten@internal@handler:loop_message(GIM), glisten@internal@handler:connection(GIM)) -> glisten@internal@handler:next(GIL, glisten@internal@handler:loop_message(GIM))),
        integer(),
        gleam@erlang@process:name(gleam@otp@factory_supervisor:message(glisten@socket:socket(), gleam@erlang@process:subject(glisten@internal@handler:message(GIM)))),
        fun((glisten@internal@handler:connection(GIM)) -> {GIL,
            gleam@option:option(gleam@erlang@process:selector(GIM))}),
        gleam@option:option(fun((GIL) -> nil)),
        glisten@transport:transport(),
        glisten@socket@options:active_state()}.

-file("src/glisten/internal/acceptor.gleam", 39).
?DOC(false).
-spec start(
    pool(any(), GIO),
    gleam@erlang@process:name(glisten@internal@listener:message()),
    gleam@erlang@process:name(gleam@otp@factory_supervisor:message(glisten@socket:socket(), gleam@erlang@process:subject(glisten@internal@handler:message(GIO))))
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(acceptor_message()))} |
    {error, gleam@otp@actor:start_error()}.
start(Pool, Listener_name, Connection_supervisor) ->
    _pipe@5 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(Subject) ->
            Listener = gleam@erlang@process:named_subject(Listener_name),
            State = gleam@erlang@process:call(
                Listener,
                750,
                fun(Field@0) -> {info, Field@0} end
            ),
            gleam@erlang@process:send(
                Subject,
                {accept_connection, erlang:element(2, State)}
            ),
            _pipe = {acceptor_state, Subject, none, erlang:element(7, Pool)},
            _pipe@1 = gleam@otp@actor:initialised(_pipe),
            _pipe@2 = gleam@otp@actor:returning(_pipe@1, Subject),
            _pipe@4 = gleam@otp@actor:selecting(
                _pipe@2,
                begin
                    _pipe@3 = gleam_erlang_ffi:new_selector(),
                    gleam@erlang@process:select(_pipe@3, Subject)
                end
            ),
            {ok, _pipe@4}
        end
    ),
    _pipe@9 = gleam@otp@actor:on_message(
        _pipe@5,
        fun(State@1, Msg) ->
            {acceptor_state, Sender, _, _} = State@1,
            case Msg of
                {accept_connection, Listener@1} ->
                    Res = begin
                        gleam@result:'try'(
                            begin
                                _pipe@6 = glisten@transport:accept(
                                    erlang:element(4, State@1),
                                    Listener@1
                                ),
                                gleam@result:map_error(
                                    _pipe@6,
                                    fun(Field@0) -> {accept_error, Field@0} end
                                )
                            end,
                            fun(Sock) ->
                                Connection_factory = gleam@otp@factory_supervisor:get_by_name(
                                    Connection_supervisor
                                ),
                                case gleam@otp@factory_supervisor:start_child(
                                    Connection_factory,
                                    Sock
                                ) of
                                    {ok, Start} ->
                                        _pipe@7 = glisten@transport:controlling_process(
                                            erlang:element(4, State@1),
                                            Sock,
                                            erlang:element(2, Start)
                                        ),
                                        _pipe@8 = gleam@result:map_error(
                                            _pipe@7,
                                            fun(Field@0) -> {control_error, Field@0} end
                                        ),
                                        gleam@result:map(
                                            _pipe@8,
                                            fun(_) ->
                                                gleam@erlang@process:send(
                                                    erlang:element(3, Start),
                                                    {internal, ready}
                                                )
                                            end
                                        );

                                    {error, Reason} ->
                                        {error, {handler_error, Reason}}
                                end
                            end
                        )
                    end,
                    case Res of
                        {error, Reason@1} ->
                            Msg@1 = case Reason@1 of
                                {accept_error, Reason@2} ->
                                    <<"acceptor failed: "/utf8,
                                        (glisten@socket:reason_to_string(
                                            Reason@2
                                        ))/binary>>;

                                {handler_error, init_timeout} ->
                                    <<"init timed out"/utf8>>;

                                {handler_error, {init_failed, Reason@3}} ->
                                    <<"init failed: "/utf8, Reason@3/binary>>;

                                {handler_error, {init_exited, normal}} ->
                                    <<"init exited normally"/utf8>>;

                                {handler_error, {init_exited, killed}} ->
                                    <<"init killed"/utf8>>;

                                {handler_error, {init_exited, {abnormal, _}}} ->
                                    <<"init exited abnormally"/utf8>>;

                                {control_error, Reason@4} ->
                                    <<"could not control socket: "/utf8,
                                        (erlang:atom_to_binary(Reason@4))/binary>>
                            end,
                            logging:log(
                                error,
                                <<"Failed to accept/start handler: "/utf8,
                                    Msg@1/binary>>
                            ),
                            gleam@otp@actor:stop_abnormal(
                                <<"Failed to accept/start handler"/utf8>>
                            );

                        _ ->
                            gleam@otp@actor:send(
                                Sender,
                                {accept_connection, Listener@1}
                            ),
                            gleam@otp@actor:continue(State@1)
                    end
            end
        end
    ),
    gleam@otp@actor:start(_pipe@9).

-file("src/glisten/internal/acceptor.gleam", 133).
?DOC(false).
-spec start_pool(
    pool(any(), any()),
    glisten@transport:transport(),
    integer(),
    list(glisten@socket@options:tcp_option()),
    gleam@erlang@process:name(glisten@internal@listener:message())
) -> {ok, gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, gleam@otp@actor:start_error()}.
start_pool(Pool, Transport, Port, Options, Listener_name) ->
    _pipe = gleam@otp@static_supervisor:new(one_for_one),
    _pipe@1 = gleam@otp@static_supervisor:add(
        _pipe,
        gleam@otp@supervision:worker(
            fun() ->
                glisten@internal@listener:start(
                    Port,
                    Transport,
                    Options,
                    Listener_name
                )
            end
        )
    ),
    _pipe@4 = gleam@otp@static_supervisor:add(
        _pipe@1,
        gleam@otp@supervision:supervisor(
            fun() -> _pipe@2 = gleam@otp@static_supervisor:new(one_for_one),
                _pipe@3 = gleam@int:range(
                    0,
                    erlang:element(3, Pool),
                    _pipe@2,
                    fun(Sup, _) ->
                        gleam@otp@static_supervisor:add(
                            Sup,
                            gleam@otp@supervision:worker(
                                fun() ->
                                    start(
                                        Pool,
                                        Listener_name,
                                        erlang:element(4, Pool)
                                    )
                                end
                            )
                        )
                    end
                ),
                gleam@otp@static_supervisor:start(_pipe@3) end
        )
    ),
    _pipe@8 = gleam@otp@static_supervisor:add(
        _pipe@4,
        begin
            _pipe@5 = gleam@otp@factory_supervisor:worker_child(
                fun(Socket) ->
                    glisten@internal@handler:start(
                        {handler,
                            Socket,
                            erlang:element(2, Pool),
                            erlang:element(5, Pool),
                            erlang:element(6, Pool),
                            erlang:element(7, Pool),
                            erlang:element(8, Pool)}
                    )
                end
            ),
            _pipe@6 = gleam@otp@factory_supervisor:named(
                _pipe@5,
                erlang:element(4, Pool)
            ),
            _pipe@7 = gleam@otp@factory_supervisor:restart_strategy(
                _pipe@6,
                temporary
            ),
            gleam@otp@factory_supervisor:supervised(_pipe@7)
        end
    ),
    gleam@otp@static_supervisor:start(_pipe@8).
