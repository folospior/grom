-module(mist).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/mist.gleam").
-export([continue/1, with_selector/2, stop/0, stop_abnormal/1, ip_address_to_string/1, connection_info_to_string/1, get_connection_info/1, send_file/3, read_body/2, stream/1, new/1, port/2, read_request_body/3, after_start/2, bind/2, with_ipv6/1, with_tls/3, start/1, supervised/1, websocket/4, send_binary_frame/2, send_text_frame/2, event/1, event_id/2, event_name/2, event_retry/2, server_sent_events/4, send_event/2, chunk_continue/1, chunk_stop/0, chunk_stop_abnormal/1, send_chunk/2, chunked/4]).
-export_type([next/2, ip_address/0, connection_info/0, response_data/0, file_error/0, read_error/0, chunk/0, chunk_state/0, tls_options/0, builder/2, port_/0, websocket_message/1, s_s_e_connection/0, s_s_e_event/0, chunk_next/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-opaque next(LWW, LWX) :: {continue,
        LWW,
        gleam@option:option(gleam@erlang@process:selector(LWX))} |
    normal_stop |
    {abnormal_stop, binary()}.

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

-type response_data() :: websocket |
    {bytes, gleam@bytes_tree:bytes_tree()} |
    chunked |
    {file, mist@internal@file:file_descriptor(), integer(), integer()} |
    server_sent_events.

-type file_error() :: is_dir | no_access | no_entry | unknown_file_error.

-type read_error() :: excess_body | malformed_body.

-type chunk() :: {chunk,
        bitstring(),
        fun((integer()) -> {ok, chunk()} | {error, read_error()})} |
    done.

-type chunk_state() :: {chunk_state,
        mist@internal@buffer:buffer(),
        mist@internal@buffer:buffer(),
        boolean()}.

-type tls_options() :: {cert_key_files, binary(), binary()}.

-opaque builder(LWY, LWZ) :: {builder,
        integer(),
        fun((gleam@http@request:request(LWY)) -> gleam@http@response:response(LWZ)),
        fun((integer(), gleam@http:scheme(), ip_address()) -> nil),
        binary(),
        boolean(),
        gleam@option:option(tls_options())}.

-type port_() :: assigned | {provided, integer()}.

-type websocket_message(LXA) :: {text, binary()} |
    {binary, bitstring()} |
    closed |
    shutdown |
    {custom, LXA}.

-opaque s_s_e_connection() :: {s_s_e_connection,
        mist@internal@http:connection()}.

-opaque s_s_e_event() :: {s_s_e_event,
        gleam@option:option(binary()),
        gleam@option:option(binary()),
        gleam@option:option(integer()),
        gleam@string_tree:string_tree()}.

-type chunk_next(LXB) :: {chunk_continue, LXB} |
    chunk_stop |
    {chunk_abort, binary()}.

-file("src/mist.gleam", 53).
-spec continue(LXC) -> next(LXC, any()).
continue(State) ->
    {continue, State, none}.

-file("src/mist.gleam", 57).
-spec with_selector(next(LXG, LXH), gleam@erlang@process:selector(LXH)) -> next(LXG, LXH).
with_selector(Next, Selector) ->
    case Next of
        {continue, State, _} ->
            {continue, State, {some, Selector}};

        _ ->
            Next
    end.

-file("src/mist.gleam", 67).
-spec stop() -> next(any(), any()).
stop() ->
    normal_stop.

-file("src/mist.gleam", 71).
-spec stop_abnormal(binary()) -> next(any(), any()).
stop_abnormal(Reason) ->
    {abnormal_stop, Reason}.

-file("src/mist.gleam", 75).
-spec convert_next(next(LXV, LXW)) -> mist@internal@next:next(LXV, LXW).
convert_next(Next) ->
    case Next of
        {continue, State, Selector} ->
            {continue, State, Selector};

        normal_stop ->
            normal_stop;

        {abnormal_stop, Reason} ->
            {abnormal_stop, Reason}
    end.

-file("src/mist.gleam", 99).
-spec to_mist_ip_address(glisten:ip_address()) -> ip_address().
to_mist_ip_address(Ip) ->
    case Ip of
        {ip_v4, A, B, C, D} ->
            {ip_v4, A, B, C, D};

        {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H} ->
            {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H}
    end.

-file("src/mist.gleam", 106).
-spec to_glisten_ip_address(ip_address()) -> glisten:ip_address().
to_glisten_ip_address(Ip) ->
    case Ip of
        {ip_v4, A, B, C, D} ->
            {ip_v4, A, B, C, D};

        {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H} ->
            {ip_v6, A@1, B@1, C@1, D@1, E, F, G, H}
    end.

-file("src/mist.gleam", 95).
?DOC(
    " Convenience function for printing the `IpAddress` type. It will convert the\n"
    " IPv6 loopback to the short-hand `::1`.\n"
).
-spec ip_address_to_string(ip_address()) -> binary().
ip_address_to_string(Address) ->
    glisten:ip_address_to_string(to_glisten_ip_address(Address)).

-file("src/mist.gleam", 117).
-spec connection_info_to_string(connection_info()) -> binary().
connection_info_to_string(Connection_info) ->
    case erlang:element(3, Connection_info) of
        {ip_v6, A, B, C, D, E, F, G, H} ->
            Blocks = begin
                _pipe = [A, B, C, D, E, F, G, H],
                _pipe@1 = gleam@list:map(_pipe, fun erlang:integer_to_binary/1),
                gleam@string:join(_pipe@1, <<":"/utf8>>)
            end,
            <<<<<<"["/utf8, Blocks/binary>>/binary, "]:"/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(2, Connection_info)))/binary>>;

        {ip_v4, A@1, B@1, C@1, D@1} ->
            Blocks@1 = begin
                _pipe@2 = [A@1, B@1, C@1, D@1],
                _pipe@3 = gleam@list:map(
                    _pipe@2,
                    fun erlang:integer_to_binary/1
                ),
                gleam@string:join(_pipe@3, <<"."/utf8>>)
            end,
            <<<<Blocks@1/binary, ":"/utf8>>/binary,
                (erlang:integer_to_binary(erlang:element(2, Connection_info)))/binary>>
    end.

-file("src/mist.gleam", 139).
?DOC(" Tries to get the IP address and port of a connected client.\n").
-spec get_connection_info(mist@internal@http:connection()) -> {ok,
        connection_info()} |
    {error, nil}.
get_connection_info(Conn) ->
    _pipe = glisten@transport:peername(
        erlang:element(4, Conn),
        erlang:element(3, Conn)
    ),
    gleam@result:map(
        _pipe,
        fun(Pair) ->
            {connection_info,
                erlang:element(2, Pair),
                begin
                    _pipe@1 = erlang:element(1, Pair),
                    _pipe@2 = glisten:convert_ip_address(_pipe@1),
                    to_mist_ip_address(_pipe@2)
                end}
        end
    ).

-file("src/mist.gleam", 175).
-spec convert_file_errors(mist@internal@file:file_error()) -> file_error().
convert_file_errors(Err) ->
    case Err of
        is_dir ->
            is_dir;

        no_access ->
            no_access;

        no_entry ->
            no_entry;

        unknown_file_error ->
            unknown_file_error
    end.

-file("src/mist.gleam", 189).
?DOC(
    " To respond with a file using Erlang's `sendfile`, use this function\n"
    " with the specified offset and limit (optional). It will attempt to open the\n"
    " file for reading, get its file size, and then send the file.  If the read\n"
    " errors, this will return the relevant `FileError`. Generally, this will be\n"
    " more memory efficient than manually doing this process with `mist.Bytes`.\n"
).
-spec send_file(binary(), integer(), gleam@option:option(integer())) -> {ok,
        response_data()} |
    {error, file_error()}.
send_file(Path, Offset, Limit) ->
    _pipe = Path,
    _pipe@1 = gleam_stdlib:identity(_pipe),
    _pipe@2 = mist@internal@file:stat(_pipe@1),
    _pipe@3 = gleam@result:map_error(_pipe@2, fun convert_file_errors/1),
    gleam@result:map(
        _pipe@3,
        fun(Stat) ->
            Length = case Limit of
                {some, Value} when (Value + Offset) > erlang:element(3, Stat) ->
                    erlang:element(3, Stat) - Offset;

                {some, Value@1} ->
                    Value@1;

                none ->
                    erlang:element(3, Stat) - Offset
            end,
            {file, erlang:element(2, Stat), Offset, Length}
        end
    ).

-file("src/mist.gleam", 220).
?DOC(
    " The request body is not pulled from the socket until requested. The\n"
    " `content-length` header is used to determine whether the socket is read\n"
    " from or not. The read may also fail, and a `ReadError` is raised.\n"
).
-spec read_body(
    gleam@http@request:request(mist@internal@http:connection()),
    integer()
) -> {ok, gleam@http@request:request(bitstring())} | {error, read_error()}.
read_body(Req, Max_body_limit) ->
    _pipe = Req,
    _pipe@1 = gleam@http@request:get_header(_pipe, <<"content-length"/utf8>>),
    _pipe@2 = gleam@result:'try'(_pipe@1, fun gleam_stdlib:parse_int/1),
    _pipe@3 = gleam@result:unwrap(_pipe@2, 0),
    (fun(Content_length) -> case Content_length of
            Value when Value =< Max_body_limit ->
                _pipe@4 = mist@internal@http:read_body(Req),
                gleam@result:replace_error(_pipe@4, malformed_body);

            _ ->
                {error, excess_body}
        end end)(_pipe@3).

-file("src/mist.gleam", 249).
-spec do_stream(
    gleam@http@request:request(mist@internal@http:connection()),
    mist@internal@buffer:buffer()
) -> fun((integer()) -> {ok, chunk()} | {error, read_error()}).
do_stream(Req, Buffer) ->
    fun(Size) ->
        Socket = erlang:element(3, erlang:element(4, Req)),
        Transport = erlang:element(4, erlang:element(4, Req)),
        Byte_size = erlang:byte_size(erlang:element(3, Buffer)),
        case {erlang:element(2, Buffer), Byte_size} of
            {0, 0} ->
                {ok, done};

            {0, _} ->
                {Data, Rest} = mist@internal@buffer:slice(Buffer, Size),
                {ok,
                    {chunk,
                        Data,
                        do_stream(Req, mist@internal@buffer:new(Rest))}};

            {_, Buffer_size} when Buffer_size >= Size ->
                {Data@1, Rest@1} = mist@internal@buffer:slice(Buffer, Size),
                New_buffer = {buffer, erlang:element(2, Buffer), Rest@1},
                {ok, {chunk, Data@1, do_stream(Req, New_buffer)}};

            {_, _} ->
                _pipe = mist@internal@http:read_data(
                    Socket,
                    Transport,
                    mist@internal@buffer:empty(),
                    invalid_body
                ),
                _pipe@1 = gleam@result:replace_error(_pipe, malformed_body),
                gleam@result:map(
                    _pipe@1,
                    fun(Data@2) ->
                        Fetched_data = erlang:byte_size(Data@2),
                        New_buffer@1 = {buffer,
                            gleam@int:max(
                                0,
                                erlang:element(2, Buffer) - Fetched_data
                            ),
                            gleam@bit_array:append(
                                erlang:element(3, Buffer),
                                Data@2
                            )},
                        {New_data, Rest@2} = mist@internal@buffer:slice(
                            New_buffer@1,
                            Size
                        ),
                        {chunk,
                            New_data,
                            do_stream(
                                Req,
                                {buffer,
                                    erlang:element(2, New_buffer@1),
                                    Rest@2}
                            )}
                    end
                )
        end
    end.

-file("src/mist.gleam", 314).
-spec fetch_chunks_until(
    glisten@socket:socket(),
    glisten@transport:transport(),
    chunk_state(),
    integer()
) -> {ok, {bitstring(), chunk_state()}} | {error, read_error()}.
fetch_chunks_until(Socket, Transport, State, Byte_size) ->
    Data_size = erlang:byte_size(erlang:element(3, erlang:element(2, State))),
    case {erlang:element(4, State), Data_size} of
        {_, Size} when Size >= Byte_size ->
            {Value, Rest} = mist@internal@buffer:slice(
                erlang:element(2, State),
                Byte_size
            ),
            {ok,
                {Value,
                    {chunk_state,
                        mist@internal@buffer:new(Rest),
                        erlang:element(3, State),
                        erlang:element(4, State)}}};

        {true, _} ->
            {ok,
                {erlang:element(3, erlang:element(2, State)),
                    {chunk_state,
                        erlang:element(2, State),
                        erlang:element(3, State),
                        true}}};

        {false, _} ->
            case mist@internal@http:parse_chunk(
                erlang:element(3, erlang:element(3, State))
            ) of
                complete ->
                    Updated_state = {chunk_state,
                        erlang:element(2, State),
                        mist@internal@buffer:empty(),
                        true},
                    fetch_chunks_until(
                        Socket,
                        Transport,
                        Updated_state,
                        Byte_size
                    );

                {chunk, <<>>, Next_buffer} ->
                    _pipe = mist@internal@http:read_data(
                        Socket,
                        Transport,
                        Next_buffer,
                        invalid_body
                    ),
                    _pipe@1 = gleam@result:replace_error(_pipe, malformed_body),
                    gleam@result:'try'(
                        _pipe@1,
                        fun(New_data) ->
                            Updated_state@1 = {chunk_state,
                                erlang:element(2, State),
                                mist@internal@buffer:new(New_data),
                                erlang:element(4, State)},
                            fetch_chunks_until(
                                Socket,
                                Transport,
                                Updated_state@1,
                                Byte_size
                            )
                        end
                    );

                {chunk, Data, Next_buffer@1} ->
                    Updated_state@2 = {chunk_state,
                        mist@internal@buffer:append(
                            erlang:element(2, State),
                            Data
                        ),
                        Next_buffer@1,
                        erlang:element(4, State)},
                    fetch_chunks_until(
                        Socket,
                        Transport,
                        Updated_state@2,
                        Byte_size
                    )
            end
    end.

-file("src/mist.gleam", 294).
-spec do_stream_chunked(
    gleam@http@request:request(mist@internal@http:connection()),
    chunk_state()
) -> fun((integer()) -> {ok, chunk()} | {error, read_error()}).
do_stream_chunked(Req, State) ->
    Socket = erlang:element(3, erlang:element(4, Req)),
    Transport = erlang:element(4, erlang:element(4, Req)),
    fun(Size) -> case fetch_chunks_until(Socket, Transport, State, Size) of
            {ok, {Data, {chunk_state, _, _, true}}} ->
                {ok, {chunk, Data, fun(_) -> {ok, done} end}};

            {ok, {Data@1, State@1}} ->
                {ok, {chunk, Data@1, do_stream_chunked(Req, State@1)}};

            {error, _} ->
                {error, malformed_body}
        end end.

-file("src/mist.gleam", 366).
?DOC(
    " Rather than explicitly reading either the whole body (optionally up to\n"
    " `N` bytes), this function allows you to consume a stream of the request\n"
    " body. Any errors reading the body will propagate out, or `Chunk`s will be\n"
    " emitted. This provides a `consume` method to attempt to grab the next\n"
    " `size` chunk from the socket.\n"
).
-spec stream(gleam@http@request:request(mist@internal@http:connection())) -> {ok,
        fun((integer()) -> {ok, chunk()} | {error, read_error()})} |
    {error, read_error()}.
stream(Req) ->
    Continue = begin
        _pipe = Req,
        _pipe@1 = mist@internal@http:handle_continue(_pipe),
        gleam@result:replace_error(_pipe@1, malformed_body)
    end,
    gleam@result:map(
        Continue,
        fun(_) ->
            Is_chunked = case gleam@http@request:get_header(
                Req,
                <<"transfer-encoding"/utf8>>
            ) of
                {ok, <<"chunked"/utf8>>} ->
                    true;

                _ ->
                    false
            end,
            Data@1 = case erlang:element(2, erlang:element(4, Req)) of
                {initial, Data} -> Data;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"mist"/utf8>>,
                                function => <<"stream"/utf8>>,
                                line => 381,
                                value => _assert_fail,
                                start => 11891,
                                'end' => 11936,
                                pattern_start => 11902,
                                pattern_end => 11920})
            end,
            case Is_chunked of
                true ->
                    State = {chunk_state,
                        mist@internal@buffer:new(<<>>),
                        mist@internal@buffer:new(Data@1),
                        false},
                    do_stream_chunked(Req, State);

                false ->
                    Content_length = begin
                        _pipe@2 = Req,
                        _pipe@3 = gleam@http@request:get_header(
                            _pipe@2,
                            <<"content-length"/utf8>>
                        ),
                        _pipe@4 = gleam@result:'try'(
                            _pipe@3,
                            fun gleam_stdlib:parse_int/1
                        ),
                        gleam@result:unwrap(_pipe@4, 0)
                    end,
                    Initial_size = erlang:byte_size(Data@1),
                    Buffer = {buffer,
                        gleam@int:max(0, Content_length - Initial_size),
                        Data@1},
                    do_stream(Req, Buffer)
            end
        end
    ).

-file("src/mist.gleam", 422).
?DOC(
    " Create a new `mist` handler with a given function. The default port is\n"
    " 4000.\n"
).
-spec new(
    fun((gleam@http@request:request(LYX)) -> gleam@http@response:response(LYZ))
) -> builder(LYX, LYZ).
new(Handler) ->
    {builder,
        4000,
        Handler,
        fun(Port, Scheme, Interface) ->
            Address = case Interface of
                {ip_v6, _, _, _, _, _, _, _, _} ->
                    <<<<"["/utf8, (ip_address_to_string(Interface))/binary>>/binary,
                        "]"/utf8>>;

                _ ->
                    ip_address_to_string(Interface)
            end,
            Message = <<<<<<<<<<"Listening on "/utf8,
                                (gleam@http:scheme_to_string(Scheme))/binary>>/binary,
                            "://"/utf8>>/binary,
                        Address/binary>>/binary,
                    ":"/utf8>>/binary,
                (erlang:integer_to_binary(Port))/binary>>,
            gleam_stdlib:println(Message)
        end,
        <<"localhost"/utf8>>,
        false,
        none}.

-file("src/mist.gleam", 447).
?DOC(" Assign a different listening port to the service.\n").
-spec port(builder(LZD, LZE), integer()) -> builder(LZD, LZE).
port(Builder, Port) ->
    {builder,
        Port,
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/mist.gleam", 454).
?DOC(
    " This function allows for implicitly reading the body of requests up\n"
    " to a given size. If the size is too large, or the read fails, the provided\n"
    " `failure_response` will be sent back as the response.\n"
).
-spec read_request_body(
    builder(bitstring(), LZJ),
    integer(),
    gleam@http@response:response(LZJ)
) -> builder(mist@internal@http:connection(), LZJ).
read_request_body(Builder, Bytes_limit, Failure_response) ->
    Handler = fun(Request) -> case read_body(Request, Bytes_limit) of
            {ok, Request@1} ->
                (erlang:element(3, Builder))(Request@1);

            {error, _} ->
                Failure_response
        end end,
    {builder,
        erlang:element(2, Builder),
        Handler,
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/mist.gleam", 470).
?DOC(
    " Override the default function to be called after the service starts. The\n"
    " default is to log a message with the listening port.\n"
).
-spec after_start(
    builder(LZP, LZQ),
    fun((integer(), gleam@http:scheme(), ip_address()) -> nil)
) -> builder(LZP, LZQ).
after_start(Builder, After_start) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        After_start,
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/mist.gleam", 481).
?DOC(
    " Specify an interface to listen on. This is a string that can have the\n"
    " following values: \"localhost\", a valid IPv4 address (i.e. \"127.0.0.1\"), or\n"
    " a valid IPv6 address (i.e. \"::1\"). An invalid value will cause the\n"
    " application to crash.\n"
).
-spec bind(builder(LZV, LZW), binary()) -> builder(LZV, LZW).
bind(Builder, Interface) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        Interface,
        erlang:element(6, Builder),
        erlang:element(7, Builder)}.

-file("src/mist.gleam", 490).
?DOC(
    " By default, `mist` will listen on `localhost` over IPv4. If you specify an\n"
    " IPv4 address to bind to, it will still only serve over IPv4. Calling this\n"
    " function will listen on both IPv4 and IPv6 for the given interface. If it is\n"
    " not supported, your application will crash. If you provide an IPv6 address\n"
    " to `mist.bind`, this function will have no effect.\n"
).
-spec with_ipv6(builder(MAB, MAC)) -> builder(MAB, MAC).
with_ipv6(Builder) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        true,
        erlang:element(7, Builder)}.

-file("src/mist.gleam", 495).
?DOC(" Use HTTPS with the provided certificate and key files.\n").
-spec with_tls(builder(MAH, MAI), binary(), binary()) -> builder(MAH, MAI).
with_tls(Builder, Cert, Key) ->
    Certfile = mist_ffi:file_open(gleam_stdlib:identity(Cert)),
    Keyfile = mist_ffi:file_open(gleam_stdlib:identity(Key)),
    _ = case {Certfile, Keyfile} of
        {{error, _}, {error, _}} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Certificate and key file not found"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"mist"/utf8>>,
                    function => <<"with_tls"/utf8>>,
                    line => 504});

        {{ok, _}, {error, _}} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Key file not found"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"mist"/utf8>>,
                    function => <<"with_tls"/utf8>>,
                    line => 505});

        {{error, _}, {ok, _}} ->
            erlang:error(#{gleam_error => panic,
                    message => <<"Certificate file not found"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"mist"/utf8>>,
                    function => <<"with_tls"/utf8>>,
                    line => 506});

        {{ok, _}, {ok, _}} ->
            nil
    end,
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        {some, {cert_key_files, Cert, Key}}}.

-file("src/mist.gleam", 513).
-spec convert_body_types(gleam@http@response:response(response_data())) -> gleam@http@response:response(mist@internal@http:response_data()).
convert_body_types(Resp) ->
    New_body = case erlang:element(4, Resp) of
        websocket ->
            websocket;

        {bytes, Data} ->
            {bytes, Data};

        {file, Descriptor, Offset, Length} ->
            {file, Descriptor, Offset, Length};

        chunked ->
            chunked;

        server_sent_events ->
            server_sent_events
    end,
    gleam@http@response:set_body(Resp, New_body).

-file("src/mist.gleam", 532).
?DOC(" Start a `mist` service with the provided builder.\n").
-spec start(builder(mist@internal@http:connection(), response_data())) -> {ok,
        gleam@otp@actor:started(gleam@otp@static_supervisor:supervisor())} |
    {error, gleam@otp@actor:start_error()}.
start(Builder) ->
    Listener_name = gleam_erlang_ffi:new_name(<<"glisten_listener"/utf8>>),
    Factory_name = gleam_erlang_ffi:new_name(<<"mist_factory_supervisor"/utf8>>),
    _pipe = gleam@otp@static_supervisor:new(one_for_one),
    _pipe@10 = gleam@otp@static_supervisor:add(
        _pipe,
        gleam@otp@supervision:supervisor(
            fun() ->
                _pipe@1 = fun(Req) ->
                    convert_body_types((erlang:element(3, Builder))(Req))
                end,
                _pipe@2 = mist@internal@handler:with_func(_pipe@1, Factory_name),
                _pipe@3 = glisten:new(fun mist@internal@handler:init/1, _pipe@2),
                _pipe@4 = glisten:bind(_pipe@3, erlang:element(5, Builder)),
                _pipe@5 = (fun(Handler) -> case erlang:element(6, Builder) of
                        true ->
                            glisten:with_ipv6(Handler);

                        false ->
                            Handler
                    end end)(_pipe@4),
                _pipe@7 = (fun(Handler@1) -> case erlang:element(7, Builder) of
                        {some, {cert_key_files, Certfile, Keyfile}} ->
                            _pipe@6 = Handler@1,
                            glisten:with_tls(_pipe@6, Certfile, Keyfile);

                        _ ->
                            Handler@1
                    end end)(_pipe@5),
                _pipe@8 = glisten:with_listener_name(_pipe@7, Listener_name),
                _pipe@9 = glisten:start(_pipe@8, erlang:element(2, Builder)),
                gleam@result:map(
                    _pipe@9,
                    fun(Server) ->
                        Info = glisten:get_server_info(Listener_name, 5000),
                        Ip_address = to_mist_ip_address(erlang:element(3, Info)),
                        Scheme = case gleam@option:is_some(
                            erlang:element(7, Builder)
                        ) of
                            true ->
                                https;

                            false ->
                                http
                        end,
                        (erlang:element(4, Builder))(
                            erlang:element(2, Info),
                            Scheme,
                            Ip_address
                        ),
                        Server
                    end
                )
            end
        )
    ),
    _pipe@14 = gleam@otp@static_supervisor:add(
        _pipe@10,
        gleam@otp@supervision:supervisor(
            fun() ->
                _pipe@11 = gleam@otp@factory_supervisor:worker_child(
                    fun(Start) -> Start() end
                ),
                _pipe@12 = gleam@otp@factory_supervisor:named(
                    _pipe@11,
                    Factory_name
                ),
                _pipe@13 = gleam@otp@factory_supervisor:restart_strategy(
                    _pipe@12,
                    temporary
                ),
                gleam@otp@factory_supervisor:start(_pipe@13)
            end
        )
    ),
    gleam@otp@static_supervisor:start(_pipe@14).

-file("src/mist.gleam", 585).
?DOC(" Start the `mist` supervisor as a child of a supervision tree.\n").
-spec supervised(builder(mist@internal@http:connection(), response_data())) -> gleam@otp@supervision:child_specification(gleam@otp@static_supervisor:supervisor()).
supervised(Builder) ->
    gleam@otp@supervision:supervisor(fun() -> start(Builder) end).

-file("src/mist.gleam", 600).
-spec internal_to_public_ws_message(
    mist@internal@websocket:handler_message(MAX)
) -> {ok, websocket_message(MAX)} | {error, nil}.
internal_to_public_ws_message(Msg) ->
    case Msg of
        {internal, {data, {text_frame, Data}}} ->
            _pipe = Data,
            _pipe@1 = gleam@bit_array:to_string(_pipe),
            gleam@result:map(_pipe@1, fun(Field@0) -> {text, Field@0} end);

        {internal, {data, {binary_frame, Data@1}}} ->
            {ok, {binary, Data@1}};

        {user, Msg@1} ->
            {ok, {custom, Msg@1}};

        _ ->
            {error, nil}
    end.

-file("src/mist.gleam", 625).
?DOC(
    " Upgrade a request to handle websockets. If the request is\n"
    " malformed, or the websocket process fails to initialize, an empty\n"
    " 400 response will be sent to the client.\n"
    "\n"
    " The `on_init` method will be called when the actual WebSocket process\n"
    " is started, and the return value is the initial state and an optional\n"
    " selector for receiving user messages.\n"
    "\n"
    " The `on_close` method is called when the WebSocket process shuts down\n"
    " for any reason, valid or otherwise.\n"
).
-spec websocket(
    gleam@http@request:request(mist@internal@http:connection()),
    fun((MBD, websocket_message(MBE), mist@internal@websocket:websocket_connection()) -> next(MBD, MBE)),
    fun((mist@internal@websocket:websocket_connection()) -> {MBD,
        gleam@option:option(gleam@erlang@process:selector(MBE))}),
    fun((MBD) -> nil)
) -> gleam@http@response:response(response_data()).
websocket(Request, Handler, On_init, On_close) ->
    Handler@1 = fun(State, Message, Connection) -> _pipe = Message,
        _pipe@1 = internal_to_public_ws_message(_pipe),
        _pipe@2 = gleam@result:map(
            _pipe@1,
            fun(_capture) -> Handler(State, _capture, Connection) end
        ),
        _pipe@3 = gleam@result:unwrap(_pipe@2, continue(State)),
        convert_next(_pipe@3) end,
    Extensions = begin
        _pipe@4 = Request,
        _pipe@5 = gleam@http@request:get_header(
            _pipe@4,
            <<"sec-websocket-extensions"/utf8>>
        ),
        _pipe@6 = gleam@result:map(
            _pipe@5,
            fun(Header) -> gleam@string:split(Header, <<";"/utf8>>) end
        ),
        gleam@result:unwrap(_pipe@6, [])
    end,
    Socket = erlang:element(3, erlang:element(4, Request)),
    Transport = erlang:element(4, erlang:element(4, Request)),
    case mist@internal@http:upgrade(Socket, Transport, Extensions, Request) of
        {ok, _} ->
            Start = fun() ->
                mist@internal@websocket:initialize_connection(
                    On_init,
                    On_close,
                    Handler@1,
                    Socket,
                    Transport,
                    Extensions
                )
            end,
            Factory_supervisor = gleam@otp@factory_supervisor:get_by_name(
                erlang:element(5, erlang:element(4, Request))
            ),
            case gleam@otp@factory_supervisor:start_child(
                Factory_supervisor,
                Start
            ) of
                {ok, Started} ->
                    case glisten@transport:controlling_process(
                        Transport,
                        Socket,
                        erlang:element(3, Started)
                    ) of
                        {ok, _} -> nil;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"mist"/utf8>>,
                                        function => <<"websocket"/utf8>>,
                                        line => 664,
                                        value => _assert_fail,
                                        start => 20644,
                                        'end' => 20737,
                                        pattern_start => 20655,
                                        pattern_end => 20660})
                    end,
                    mist@internal@websocket:set_active(Transport, Socket),
                    _pipe@7 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@7, websocket);

                {error, Start_error} ->
                    Msg = case Start_error of
                        init_timeout ->
                            <<"init timed out"/utf8>>;

                        {init_failed, Reason} ->
                            <<"init failed: "/utf8, Reason/binary>>;

                        {init_exited, normal} ->
                            <<"init exited normally"/utf8>>;

                        {init_exited, killed} ->
                            <<"init killed"/utf8>>;

                        {init_exited, {abnormal, _}} ->
                            <<"init exited abnormally"/utf8>>
                    end,
                    logging:log(
                        error,
                        <<"Failed to start WebSocket process: "/utf8,
                            Msg/binary>>
                    ),
                    _pipe@8 = gleam@http@response:new(400),
                    gleam@http@response:set_body(
                        _pipe@8,
                        {bytes, gleam@bytes_tree:new()}
                    )
            end;

        {error, _} ->
            _pipe@9 = gleam@http@response:new(400),
            gleam@http@response:set_body(
                _pipe@9,
                {bytes, gleam@bytes_tree:new()}
            )
    end.

-file("src/mist.gleam", 698).
?DOC(" Sends a binary frame across the websocket.\n").
-spec send_binary_frame(
    mist@internal@websocket:websocket_connection(),
    bitstring()
) -> {ok, nil} | {error, glisten@socket:socket_reason()}.
send_binary_frame(Connection, Frame) ->
    Binary_frame = exception_ffi:rescue(
        fun() ->
            gramps@websocket:encode_binary_frame(
                Frame,
                erlang:element(4, Connection),
                none
            )
        end
    ),
    case Binary_frame of
        {ok, Binary_frame@1} ->
            glisten@transport:send(
                erlang:element(3, Connection),
                erlang:element(2, Connection),
                Binary_frame@1
            );

        {error, _} ->
            logging:log(
                error,
                <<"Cannot send messages from a different process than the WebSocket"/utf8>>
            ),
            erlang:error(#{gleam_error => panic,
                    message => <<"Exiting due to sending WebSocket message from non-owning process"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"mist"/utf8>>,
                    function => <<"send_binary_frame"/utf8>>,
                    line => 715})
    end.

-file("src/mist.gleam", 721).
?DOC(" Sends a text frame across the websocket.\n").
-spec send_text_frame(mist@internal@websocket:websocket_connection(), binary()) -> {ok,
        nil} |
    {error, glisten@socket:socket_reason()}.
send_text_frame(Connection, Frame) ->
    Text_frame = exception_ffi:rescue(
        fun() ->
            gramps@websocket:encode_text_frame(
                Frame,
                erlang:element(4, Connection),
                none
            )
        end
    ),
    case Text_frame of
        {ok, Text_frame@1} ->
            glisten@transport:send(
                erlang:element(3, Connection),
                erlang:element(2, Connection),
                Text_frame@1
            );

        {error, _} ->
            logging:log(
                error,
                <<"Cannot send messages from a different process than the WebSocket"/utf8>>
            ),
            erlang:error(#{gleam_error => panic,
                    message => <<"Exiting due to sending WebSocket message from non-owning process"/utf8>>,
                    file => <<?FILEPATH/utf8>>,
                    module => <<"mist"/utf8>>,
                    function => <<"send_text_frame"/utf8>>,
                    line => 738})
    end.

-file("src/mist.gleam", 764).
-spec event(gleam@string_tree:string_tree()) -> s_s_e_event().
event(Data) ->
    {s_s_e_event, none, none, none, Data}.

-file("src/mist.gleam", 769).
-spec event_id(s_s_e_event(), binary()) -> s_s_e_event().
event_id(Event, Id) ->
    {s_s_e_event,
        {some, Id},
        erlang:element(3, Event),
        erlang:element(4, Event),
        erlang:element(5, Event)}.

-file("src/mist.gleam", 774).
-spec event_name(s_s_e_event(), binary()) -> s_s_e_event().
event_name(Event, Name) ->
    {s_s_e_event,
        erlang:element(2, Event),
        {some, Name},
        erlang:element(4, Event),
        erlang:element(5, Event)}.

-file("src/mist.gleam", 779).
-spec event_retry(s_s_e_event(), integer()) -> s_s_e_event().
event_retry(Event, Retry) ->
    {s_s_e_event,
        erlang:element(2, Event),
        erlang:element(3, Event),
        {some, Retry},
        erlang:element(5, Event)}.

-file("src/mist.gleam", 792).
?DOC(
    " Sets up the connection for server-sent events. The initial response provided\n"
    " here will have its headers included in the SSE setup. The body is discarded.\n"
    " The `init` and `loop` parameters follow the same shape as the\n"
    " `gleam/otp/actor` module.\n"
    "\n"
    " NOTE:  There is no proper way within the spec for the server to \"close\" the\n"
    " SSE connection. There are ways around it.\n"
    "\n"
    " See:  `examples/eventz` for a sample usage.\n"
).
-spec server_sent_events(
    gleam@http@request:request(mist@internal@http:connection()),
    gleam@http@response:response(any()),
    fun((gleam@erlang@process:subject(MBS)) -> MBU),
    fun((MBU, MBS, s_s_e_connection()) -> gleam@otp@actor:next(MBU, MBS))
) -> gleam@http@response:response(response_data()).
server_sent_events(Req, Resp, Init, Loop) ->
    With_default_headers = begin
        _pipe = Resp,
        _pipe@1 = gleam@http@response:set_header(
            _pipe,
            <<"content-type"/utf8>>,
            <<"text/event-stream"/utf8>>
        ),
        _pipe@2 = gleam@http@response:set_header(
            _pipe@1,
            <<"cache-control"/utf8>>,
            <<"no-cache"/utf8>>
        ),
        gleam@http@response:set_header(
            _pipe@2,
            <<"connection"/utf8>>,
            <<"keep-alive"/utf8>>
        )
    end,
    case glisten@transport:send(
        erlang:element(4, erlang:element(4, Req)),
        erlang:element(3, erlang:element(4, Req)),
        mist@internal@encoder:response_builder(
            200,
            erlang:element(3, With_default_headers),
            <<"1.1"/utf8>>
        )
    ) of
        {ok, _} ->
            Start = fun() ->
                _pipe@8 = gleam@otp@actor:new_with_initialiser(
                    1000,
                    fun(Subj) -> _pipe@3 = Init(Subj),
                        _pipe@4 = gleam@otp@actor:initialised(_pipe@3),
                        _pipe@5 = gleam@otp@actor:returning(
                            _pipe@4,
                            erlang:self()
                        ),
                        _pipe@7 = gleam@otp@actor:selecting(
                            _pipe@5,
                            begin
                                _pipe@6 = gleam_erlang_ffi:new_selector(),
                                gleam@erlang@process:select(_pipe@6, Subj)
                            end
                        ),
                        {ok, _pipe@7} end
                ),
                _pipe@9 = gleam@otp@actor:on_message(
                    _pipe@8,
                    fun(State, Message) ->
                        Loop(
                            State,
                            Message,
                            {s_s_e_connection, erlang:element(4, Req)}
                        )
                    end
                ),
                _pipe@10 = gleam@otp@actor:start(_pipe@9),
                gleam@result:map(
                    _pipe@10,
                    fun(Started) ->
                        Pid = erlang:element(3, Started),
                        {started, Pid, Pid}
                    end
                )
            end,
            Factory_supervisor = gleam@otp@factory_supervisor:get_by_name(
                erlang:element(5, erlang:element(4, Req))
            ),
            case gleam@otp@factory_supervisor:start_child(
                Factory_supervisor,
                Start
            ) of
                {ok, Started@1} ->
                    case glisten@transport:controlling_process(
                        erlang:element(4, erlang:element(4, Req)),
                        erlang:element(3, erlang:element(4, Req)),
                        erlang:element(3, Started@1)
                    ) of
                        {ok, _} -> nil;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"mist"/utf8>>,
                                        function => <<"server_sent_events"/utf8>>,
                                        line => 832,
                                        value => _assert_fail,
                                        start => 26099,
                                        'end' => 26270,
                                        pattern_start => 26110,
                                        pattern_end => 26118})
                    end,
                    _pipe@11 = gleam@http@response:new(200),
                    gleam@http@response:set_body(_pipe@11, server_sent_events);

                {error, _} ->
                    logging:log(error, <<"Failed to start SSE process"/utf8>>),
                    _pipe@12 = gleam@http@response:new(400),
                    gleam@http@response:set_body(
                        _pipe@12,
                        {bytes, gleam@bytes_tree:new()}
                    )
            end;

        {error, _} ->
            _pipe@13 = gleam@http@response:new(400),
            gleam@http@response:set_body(
                _pipe@13,
                {bytes, gleam@bytes_tree:new()}
            )
    end.

-file("src/mist.gleam", 859).
-spec send_event(s_s_e_connection(), s_s_e_event()) -> {ok, nil} | {error, nil}.
send_event(Conn, Event) ->
    {s_s_e_connection, Conn@1} = Conn,
    Id@1 = begin
        _pipe = erlang:element(2, Event),
        _pipe@1 = gleam@option:map(
            _pipe,
            fun(Id) -> <<<<"id: "/utf8, Id/binary>>/binary, "\n"/utf8>> end
        ),
        gleam@option:unwrap(_pipe@1, <<""/utf8>>)
    end,
    Event_name = begin
        _pipe@2 = erlang:element(3, Event),
        _pipe@3 = gleam@option:map(
            _pipe@2,
            fun(Name) ->
                <<<<"event: "/utf8, Name/binary>>/binary, "\n"/utf8>>
            end
        ),
        gleam@option:unwrap(_pipe@3, <<""/utf8>>)
    end,
    Retry@1 = begin
        _pipe@4 = erlang:element(4, Event),
        _pipe@5 = gleam@option:map(
            _pipe@4,
            fun(Retry) ->
                <<<<"retry: "/utf8, (erlang:integer_to_binary(Retry))/binary>>/binary,
                    "\n"/utf8>>
            end
        ),
        gleam@option:unwrap(_pipe@5, <<""/utf8>>)
    end,
    Data = begin
        _pipe@6 = erlang:element(5, Event),
        _pipe@7 = gleam@string_tree:split(_pipe@6, <<"\n"/utf8>>),
        _pipe@8 = gleam@list:map(
            _pipe@7,
            fun(Row) -> gleam@string_tree:prepend(Row, <<"data: "/utf8>>) end
        ),
        gleam@string_tree:join(_pipe@8, <<"\n"/utf8>>)
    end,
    Message = begin
        _pipe@9 = Data,
        _pipe@10 = gleam@string_tree:prepend(_pipe@9, Event_name),
        _pipe@11 = gleam@string_tree:prepend(_pipe@10, Id@1),
        _pipe@12 = gleam@string_tree:prepend(_pipe@11, Retry@1),
        _pipe@13 = gleam@string_tree:append(_pipe@12, <<"\n\n"/utf8>>),
        gleam_stdlib:wrap_list(_pipe@13)
    end,
    _pipe@14 = glisten@transport:send(
        erlang:element(4, Conn@1),
        erlang:element(3, Conn@1),
        Message
    ),
    _pipe@15 = gleam@result:replace(_pipe@14, nil),
    gleam@result:replace_error(_pipe@15, nil).

-file("src/mist.gleam", 975).
-spec chunk_continue(MCK) -> chunk_next(MCK).
chunk_continue(State) ->
    {chunk_continue, State}.

-file("src/mist.gleam", 979).
-spec chunk_stop() -> chunk_next(any()).
chunk_stop() ->
    chunk_stop.

-file("src/mist.gleam", 983).
-spec chunk_stop_abnormal(binary()) -> chunk_next(any()).
chunk_stop_abnormal(Reason) ->
    {chunk_abort, Reason}.

-file("src/mist.gleam", 991).
-spec int_to_hex(integer()) -> binary().
int_to_hex(Int) ->
    erlang:integer_to_list(Int, 16).

-file("src/mist.gleam", 961).
-spec send_chunk(mist@internal@http:connection(), bitstring()) -> {ok, nil} |
    {error, nil}.
send_chunk(Connection, Data) ->
    Size = erlang:byte_size(Data),
    Encoded = begin
        _pipe = Size,
        _pipe@1 = int_to_hex(_pipe),
        _pipe@2 = gleam_stdlib:wrap_list(_pipe@1),
        _pipe@3 = gleam@bytes_tree:append_string(_pipe@2, <<"\r\n"/utf8>>),
        _pipe@4 = gleam@bytes_tree:append(_pipe@3, Data),
        gleam@bytes_tree:append_string(_pipe@4, <<"\r\n"/utf8>>)
    end,
    _pipe@5 = glisten@transport:send(
        erlang:element(4, Connection),
        erlang:element(3, Connection),
        Encoded
    ),
    gleam@result:replace_error(_pipe@5, nil).

-file("src/mist.gleam", 898).
-spec chunked(
    gleam@http@request:request(mist@internal@http:connection()),
    gleam@http@response:response(any()),
    fun((gleam@erlang@process:subject(MCD)) -> MCF),
    fun((MCF, MCD, mist@internal@http:connection()) -> chunk_next(MCF))
) -> gleam@http@response:response(response_data()).
chunked(Req, Response, Init, Loop) ->
    Start = fun() ->
        _pipe@5 = gleam@otp@actor:new_with_initialiser(
            1000,
            fun(Subj) -> _pipe = Init(Subj),
                _pipe@1 = gleam@otp@actor:initialised(_pipe),
                _pipe@2 = gleam@otp@actor:returning(_pipe@1, erlang:self()),
                _pipe@4 = gleam@otp@actor:selecting(
                    _pipe@2,
                    begin
                        _pipe@3 = gleam_erlang_ffi:new_selector(),
                        gleam@erlang@process:select(_pipe@3, Subj)
                    end
                ),
                {ok, _pipe@4} end
        ),
        _pipe@6 = gleam@otp@actor:on_message(
            _pipe@5,
            fun(State, Message) ->
                case Loop(State, Message, erlang:element(4, Req)) of
                    {chunk_continue, State@1} ->
                        gleam@otp@actor:continue(State@1);

                    chunk_stop ->
                        _ = case send_chunk(erlang:element(4, Req), <<>>) of
                            {ok, _} ->
                                nil;

                            {error, _} ->
                                logging:log(
                                    debug,
                                    <<"Failed to send final chunk"/utf8>>
                                )
                        end,
                        gleam@otp@actor:stop();

                    {chunk_abort, Reason} ->
                        gleam@otp@actor:stop_abnormal(Reason)
                end
            end
        ),
        _pipe@7 = gleam@otp@actor:start(_pipe@6),
        gleam@result:map(
            _pipe@7,
            fun(Started) ->
                {started,
                    erlang:element(3, Started),
                    erlang:element(3, Started)}
            end
        )
    end,
    Headers = [{<<"transfer-encoding"/utf8>>, <<"chunked"/utf8>>} |
        erlang:element(3, Response)],
    Initial_payload = mist@internal@encoder:response_builder(
        erlang:element(2, Response),
        Headers,
        mist@internal@http:version_to_string(http11)
    ),
    case glisten@transport:send(
        erlang:element(4, erlang:element(4, Req)),
        erlang:element(3, erlang:element(4, Req)),
        Initial_payload
    ) of
        {ok, _} -> nil;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"mist"/utf8>>,
                        function => <<"chunked"/utf8>>,
                        line => 939,
                        value => _assert_fail,
                        start => 29275,
                        'end' => 29369,
                        pattern_start => 29286,
                        pattern_end => 29294})
    end,
    Factory_supervisor = gleam@otp@factory_supervisor:get_by_name(
        erlang:element(5, erlang:element(4, Req))
    ),
    case gleam@otp@factory_supervisor:start_child(Factory_supervisor, Start) of
        {ok, Started@1} ->
            case glisten@transport:controlling_process(
                erlang:element(4, erlang:element(4, Req)),
                erlang:element(3, erlang:element(4, Req)),
                erlang:element(3, Started@1)
            ) of
                {ok, _} -> nil;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"mist"/utf8>>,
                                function => <<"chunked"/utf8>>,
                                line => 946,
                                value => _assert_fail@1,
                                start => 29525,
                                'end' => 29683,
                                pattern_start => 29536,
                                pattern_end => 29551})
            end,
            _pipe@8 = gleam@http@response:new(200),
            gleam@http@response:set_body(_pipe@8, chunked);

        {error, _} ->
            logging:log(
                error,
                <<"Failed to start chunked response process"/utf8>>
            ),
            _pipe@9 = gleam@http@response:new(400),
            gleam@http@response:set_body(
                _pipe@9,
                {bytes, gleam@bytes_tree:new()}
            )
    end.
