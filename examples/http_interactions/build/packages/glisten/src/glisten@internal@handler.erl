-module(glisten@internal@handler).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/glisten/internal/handler.gleam").
-export([continue/1, with_selector/2, stop/0, stop_abnormal/1, start/1]).
-export_type([internal_message/0, message/1, loop_message/1, loop_state/2, connection/1, next/2, handler/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type internal_message() :: close |
    ready |
    {receive_message, bitstring()} |
    closed |
    passive |
    {socket_error, glisten@socket:socket_reason()}.

-type message(FRA) :: {internal, internal_message()} | {user, FRA}.

-type loop_message(FRB) :: {packet, bitstring()} | {custom, FRB}.

-type loop_state(FRC, FRD) :: {loop_state,
        {ok, {glisten@socket@options:ip_address(), integer()}} | {error, nil},
        glisten@socket:socket(),
        gleam@erlang@process:subject(message(FRD)),
        glisten@transport:transport(),
        FRC}.

-type connection(FRE) :: {connection,
        {ok, {glisten@socket@options:ip_address(), integer()}} | {error, nil},
        glisten@socket:socket(),
        glisten@transport:transport(),
        gleam@erlang@process:subject(message(FRE))}.

-type next(FRF, FRG) :: {continue,
        FRF,
        gleam@option:option(gleam@erlang@process:selector(FRG))} |
    normal_stop |
    {abnormal_stop, binary()}.

-type handler(FRH, FRI) :: {handler,
        glisten@socket:socket(),
        fun((FRH, loop_message(FRI), connection(FRI)) -> next(FRH, loop_message(FRI))),
        fun((connection(FRI)) -> {FRH,
            gleam@option:option(gleam@erlang@process:selector(FRI))}),
        gleam@option:option(fun((FRH) -> nil)),
        glisten@transport:transport(),
        glisten@socket@options:active_state()}.

-file("src/glisten/internal/handler.gleam", 65).
?DOC(false).
-spec continue(FRV) -> next(FRV, any()).
continue(State) ->
    {continue, State, none}.

-file("src/glisten/internal/handler.gleam", 69).
?DOC(false).
-spec with_selector(next(FRZ, FSA), gleam@erlang@process:selector(FSA)) -> next(FRZ, FSA).
with_selector(Next, Selector) ->
    case Next of
        {continue, State, _} ->
            {continue, State, {some, Selector}};

        Stop ->
            Stop
    end.

-file("src/glisten/internal/handler.gleam", 79).
?DOC(false).
-spec stop() -> next(any(), any()).
stop() ->
    normal_stop.

-file("src/glisten/internal/handler.gleam", 83).
?DOC(false).
-spec stop_abnormal(binary()) -> next(any(), any()).
stop_abnormal(Reason) ->
    {abnormal_stop, Reason}.

-file("src/glisten/internal/handler.gleam", 104).
?DOC(false).
-spec start(handler(any(), FSP)) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(message(FSP)))} |
    {error, gleam@otp@actor:start_error()}.
start(Handler) ->
    _pipe@18 = gleam@otp@actor:new_with_initialiser(
        1000,
        fun(Subject) ->
            Client_ip = begin
                _pipe = glisten@transport:peername(
                    erlang:element(6, Handler),
                    erlang:element(2, Handler)
                ),
                gleam@result:replace_error(_pipe, nil)
            end,
            Connection = {connection,
                Client_ip,
                erlang:element(2, Handler),
                erlang:element(6, Handler),
                Subject},
            {Initial_state, User_selector} = (erlang:element(4, Handler))(
                Connection
            ),
            Base_selector = begin
                _pipe@1 = gleam_erlang_ffi:new_selector(),
                gleam@erlang@process:select(_pipe@1, Subject)
            end,
            Selector = begin
                _pipe@2 = gleam_erlang_ffi:new_selector(),
                _pipe@3 = gleam@erlang@process:select_record(
                    _pipe@2,
                    erlang:binary_to_atom(<<"tcp"/utf8>>),
                    2,
                    fun(Record) ->
                        {receive_message, glisten_ffi:socket_data(Record)}
                    end
                ),
                _pipe@4 = gleam@erlang@process:select_record(
                    _pipe@3,
                    erlang:binary_to_atom(<<"ssl"/utf8>>),
                    2,
                    fun(Record@1) ->
                        {receive_message, glisten_ffi:socket_data(Record@1)}
                    end
                ),
                _pipe@5 = gleam@erlang@process:select_record(
                    _pipe@4,
                    erlang:binary_to_atom(<<"ssl_closed"/utf8>>),
                    1,
                    fun(_) -> closed end
                ),
                _pipe@6 = gleam@erlang@process:select_record(
                    _pipe@5,
                    erlang:binary_to_atom(<<"tcp_closed"/utf8>>),
                    1,
                    fun(_) -> closed end
                ),
                _pipe@7 = gleam@erlang@process:select_record(
                    _pipe@6,
                    erlang:binary_to_atom(<<"ssl_passive"/utf8>>),
                    1,
                    fun(_) -> passive end
                ),
                _pipe@8 = gleam@erlang@process:select_record(
                    _pipe@7,
                    erlang:binary_to_atom(<<"tcp_passive"/utf8>>),
                    1,
                    fun(_) -> passive end
                ),
                _pipe@9 = gleam@erlang@process:select_record(
                    _pipe@8,
                    erlang:binary_to_atom(<<"tcp_error"/utf8>>),
                    2,
                    fun(Record@2) ->
                        {socket_error, glisten_ffi:socket_data(Record@2)}
                    end
                ),
                _pipe@10 = gleam@erlang@process:select_record(
                    _pipe@9,
                    erlang:binary_to_atom(<<"ssl_error"/utf8>>),
                    2,
                    fun(Record@3) ->
                        {socket_error, glisten_ffi:socket_data(Record@3)}
                    end
                ),
                _pipe@11 = gleam_erlang_ffi:map_selector(
                    _pipe@10,
                    fun(Field@0) -> {internal, Field@0} end
                ),
                gleam_erlang_ffi:merge_selector(_pipe@11, Base_selector)
            end,
            Selector@1 = case User_selector of
                {some, Sel} ->
                    _pipe@12 = Sel,
                    _pipe@13 = gleam_erlang_ffi:map_selector(
                        _pipe@12,
                        fun(Field@0) -> {user, Field@0} end
                    ),
                    gleam_erlang_ffi:merge_selector(Selector, _pipe@13);

                _ ->
                    Selector
            end,
            _pipe@14 = {loop_state,
                Client_ip,
                erlang:element(2, Handler),
                Subject,
                erlang:element(6, Handler),
                Initial_state},
            _pipe@15 = gleam@otp@actor:initialised(_pipe@14),
            _pipe@16 = gleam@otp@actor:selecting(_pipe@15, Selector@1),
            _pipe@17 = gleam@otp@actor:returning(_pipe@16, Subject),
            {ok, _pipe@17}
        end
    ),
    _pipe@19 = gleam@otp@actor:on_message(
        _pipe@18,
        fun(State, Msg) ->
            Connection@1 = {connection,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(5, State),
                erlang:element(4, State)},
            case Msg of
                {internal, closed} ->
                    case glisten@transport:close(
                        erlang:element(5, State),
                        erlang:element(3, State)
                    ) of
                        {ok, nil} ->
                            _ = case erlang:element(5, Handler) of
                                {some, On_close} ->
                                    On_close(erlang:element(6, State));

                                _ ->
                                    nil
                            end,
                            gleam@otp@actor:stop();

                        {error, Err} ->
                            gleam@otp@actor:stop_abnormal(
                                glisten@socket:reason_to_string(Err)
                            )
                    end;

                {internal, close} ->
                    case glisten@transport:close(
                        erlang:element(5, State),
                        erlang:element(3, State)
                    ) of
                        {ok, nil} ->
                            _ = case erlang:element(5, Handler) of
                                {some, On_close} ->
                                    On_close(erlang:element(6, State));

                                _ ->
                                    nil
                            end,
                            gleam@otp@actor:stop();

                        {error, Err} ->
                            gleam@otp@actor:stop_abnormal(
                                glisten@socket:reason_to_string(Err)
                            )
                    end;

                {internal, ready} ->
                    case glisten@transport:handshake(
                        erlang:element(5, State),
                        erlang:element(3, State)
                    ) of
                        {error, _} ->
                            gleam@otp@actor:stop_abnormal(
                                <<"Failed to handshake socket"/utf8>>
                            );

                        {ok, _} ->
                            case glisten@transport:set_buffer_size(
                                erlang:element(5, State),
                                erlang:element(3, State)
                            ) of
                                {ok, _} ->
                                    nil;

                                {error, _} ->
                                    logging:log(
                                        warning,
                                        <<"Failed to read `recbuf` size"/utf8>>
                                    )
                            end,
                            Options = [{active_mode, erlang:element(7, Handler)}],
                            case glisten@transport:set_opts(
                                erlang:element(5, State),
                                erlang:element(3, State),
                                Options
                            ) of
                                {ok, _} ->
                                    gleam@otp@actor:continue(State);

                                {error, _} ->
                                    gleam@otp@actor:stop_abnormal(
                                        <<"Failed to set socket active"/utf8>>
                                    )
                            end
                    end;

                {user, Msg@1} ->
                    Msg@2 = {custom, Msg@1},
                    Res = glisten_ffi:rescue(
                        fun() ->
                            (erlang:element(3, Handler))(
                                erlang:element(6, State),
                                Msg@2,
                                Connection@1
                            )
                        end
                    ),
                    case Res of
                        {ok, {continue, Next_state, _}} when erlang:element(
                            7,
                            Handler
                        ) =:= once ->
                            case glisten@transport:set_opts(
                                erlang:element(5, State),
                                erlang:element(3, State),
                                [{active_mode, once}]
                            ) of
                                {ok, nil} ->
                                    gleam@otp@actor:continue(
                                        {loop_state,
                                            erlang:element(2, State),
                                            erlang:element(3, State),
                                            erlang:element(4, State),
                                            erlang:element(5, State),
                                            Next_state}
                                    );

                                {error, _} ->
                                    gleam@otp@actor:stop()
                            end;

                        {ok, {continue, Next_state@1, _}} ->
                            gleam@otp@actor:continue(
                                {loop_state,
                                    erlang:element(2, State),
                                    erlang:element(3, State),
                                    erlang:element(4, State),
                                    erlang:element(5, State),
                                    Next_state@1}
                            );

                        {ok, normal_stop} ->
                            gleam@otp@actor:stop();

                        {ok, {abnormal_stop, Reason}} ->
                            gleam@otp@actor:stop_abnormal(Reason);

                        {error, Reason@1} ->
                            logging:log(
                                error,
                                <<"Caught error in user handler: "/utf8,
                                    (gleam@string:inspect(Reason@1))/binary>>
                            ),
                            gleam@otp@actor:continue(State)
                    end;

                {internal, {receive_message, Msg@3}} ->
                    Msg@4 = {packet, Msg@3},
                    Res@1 = glisten_ffi:rescue(
                        fun() ->
                            (erlang:element(3, Handler))(
                                erlang:element(6, State),
                                Msg@4,
                                Connection@1
                            )
                        end
                    ),
                    case Res@1 of
                        {ok, {continue, Next_state@2, _}} when erlang:element(
                            7,
                            Handler
                        ) =:= once ->
                            case glisten@transport:set_opts(
                                erlang:element(5, State),
                                erlang:element(3, State),
                                [{active_mode, once}]
                            ) of
                                {ok, nil} ->
                                    gleam@otp@actor:continue(
                                        {loop_state,
                                            erlang:element(2, State),
                                            erlang:element(3, State),
                                            erlang:element(4, State),
                                            erlang:element(5, State),
                                            Next_state@2}
                                    );

                                {error, _} ->
                                    gleam@otp@actor:stop()
                            end;

                        {ok, {continue, Next_state@3, _}} ->
                            gleam@otp@actor:continue(
                                {loop_state,
                                    erlang:element(2, State),
                                    erlang:element(3, State),
                                    erlang:element(4, State),
                                    erlang:element(5, State),
                                    Next_state@3}
                            );

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

                {internal, passive} ->
                    Options@1 = [{active_mode, erlang:element(7, Handler)}],
                    case glisten@transport:set_opts(
                        erlang:element(5, State),
                        erlang:element(3, State),
                        Options@1
                    ) of
                        {ok, _} ->
                            gleam@otp@actor:continue(State);

                        {error, _} ->
                            gleam@otp@actor:stop_abnormal(
                                <<"Failed to set socket active"/utf8>>
                            )
                    end;

                {internal, {socket_error, Reason@4}} ->
                    gleam@otp@actor:stop_abnormal(
                        <<"Received socket error "/utf8,
                            (glisten@socket:reason_to_string(Reason@4))/binary>>
                    )
            end
        end
    ),
    gleam@otp@actor:start(_pipe@19).
