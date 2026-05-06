-module(kryptos@internal@utils).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/utils.gleam").
-export([count_trailing_zeros/1, strip_leading_zeros/1, strip_trailing_zeros/1, pad_left/2, int_to_padded_string/2, is_ascii/1, chunk_string/2, parse_ip/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/utils.gleam", 27).
?DOC(false).
-spec trailing_zeros_in_byte(integer(), integer()) -> integer().
trailing_zeros_in_byte(Byte, Count) ->
    case erlang:'band'(Byte, 1) of
        0 ->
            trailing_zeros_in_byte(erlang:'bsr'(Byte, 1), Count + 1);

        _ ->
            Count
    end.

-file("src/kryptos/internal/utils.gleam", 14).
?DOC(false).
-spec do_count_trailing_zeros(bitstring(), integer(), integer()) -> integer().
do_count_trailing_zeros(Bits, Byte_pos, Count) ->
    case Byte_pos < 0 of
        true ->
            Count;

        false ->
            Byte@1 = case gleam_stdlib:bit_array_slice(Bits, Byte_pos, 1) of
                {ok, <<Byte>>} -> Byte;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/utils"/utf8>>,
                                function => <<"do_count_trailing_zeros"/utf8>>,
                                line => 18,
                                value => _assert_fail,
                                start => 468,
                                'end' => 528,
                                pattern_start => 479,
                                pattern_end => 491})
            end,
            case Byte@1 of
                0 ->
                    do_count_trailing_zeros(Bits, Byte_pos - 1, Count + 8);

                _ ->
                    Count + trailing_zeros_in_byte(Byte@1, 0)
            end
    end.

-file("src/kryptos/internal/utils.gleam", 9).
?DOC(false).
-spec count_trailing_zeros(bitstring()) -> integer().
count_trailing_zeros(Bits) ->
    Size = erlang:byte_size(Bits),
    do_count_trailing_zeros(Bits, Size - 1, 0).

-file("src/kryptos/internal/utils.gleam", 38).
?DOC(false).
-spec strip_leading_zeros(bitstring()) -> bitstring().
strip_leading_zeros(Bytes) ->
    case Bytes of
        <<16#00, Rest/bitstring>> ->
            case erlang:byte_size(Rest) > 0 of
                true ->
                    strip_leading_zeros(Rest);

                false ->
                    Bytes
            end;

        _ ->
            Bytes
    end.

-file("src/kryptos/internal/utils.gleam", 59).
?DOC(false).
-spec strip_trailing_zeros_loop(bitstring(), integer()) -> bitstring().
strip_trailing_zeros_loop(Data, Len) ->
    case Len of
        0 ->
            <<>>;

        _ ->
            Last_byte@1 = case gleam_stdlib:bit_array_slice(Data, Len - 1, 1) of
                {ok, <<Last_byte>>} -> Last_byte;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/utils"/utf8>>,
                                function => <<"strip_trailing_zeros_loop"/utf8>>,
                                line => 63,
                                value => _assert_fail,
                                start => 1719,
                                'end' => 1783,
                                pattern_start => 1730,
                                pattern_end => 1747})
            end,
            case Last_byte@1 of
                0 ->
                    strip_trailing_zeros_loop(Data, Len - 1);

                _ ->
                    Result@1 = case gleam_stdlib:bit_array_slice(Data, 0, Len) of
                        {ok, Result} -> Result;
                        _assert_fail@1 ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"kryptos/internal/utils"/utf8>>,
                                        function => <<"strip_trailing_zeros_loop"/utf8>>,
                                        line => 67,
                                        value => _assert_fail@1,
                                        start => 1886,
                                        'end' => 1939,
                                        pattern_start => 1897,
                                        pattern_end => 1907})
                    end,
                    Result@1
            end
    end.

-file("src/kryptos/internal/utils.gleam", 54).
?DOC(false).
-spec strip_trailing_zeros(bitstring()) -> bitstring().
strip_trailing_zeros(Data) ->
    Len = erlang:byte_size(Data),
    strip_trailing_zeros_loop(Data, Len).

-file("src/kryptos/internal/utils.gleam", 78).
?DOC(false).
-spec pad_left(bitstring(), integer()) -> bitstring().
pad_left(Value, Size) ->
    Current_size = erlang:byte_size(Value),
    case Current_size >= Size of
        true ->
            Value;

        false ->
            Padding_size = Size - Current_size,
            Padding = begin
                _pipe = gleam@list:repeat(<<0>>, Padding_size),
                gleam_stdlib:bit_array_concat(_pipe)
            end,
            gleam_stdlib:bit_array_concat([Padding, Value])
    end.

-file("src/kryptos/internal/utils.gleam", 93).
?DOC(false).
-spec int_to_padded_string(integer(), integer()) -> binary().
int_to_padded_string(N, Width) ->
    S = erlang:integer_to_binary(N),
    Padding = gleam@string:repeat(
        <<"0"/utf8>>,
        gleam@int:max(0, Width - string:length(S))
    ),
    <<Padding/binary, S/binary>>.

-file("src/kryptos/internal/utils.gleam", 100).
?DOC(false).
-spec is_ascii(binary()) -> boolean().
is_ascii(S) ->
    _pipe = S,
    _pipe@1 = gleam@string:to_utf_codepoints(_pipe),
    gleam@list:all(_pipe@1, fun(Cp) -> gleam_stdlib:identity(Cp) =< 127 end).

-file("src/kryptos/internal/utils.gleam", 108).
?DOC(false).
-spec chunk_string(binary(), integer()) -> list(binary()).
chunk_string(S, Size) ->
    case Size > 0 of
        false ->
            [];

        true ->
            case string:length(S) =< Size of
                true ->
                    [S];

                false ->
                    Chunk = gleam@string:slice(S, 0, Size),
                    Rest = gleam@string:slice(S, Size, string:length(S) - Size),
                    [Chunk | chunk_string(Rest, Size)]
            end
    end.

-file("src/kryptos/internal/utils.gleam", 138).
?DOC(false).
-spec parse_ipv4_octet(binary()) -> {ok, integer()} | {error, nil}.
parse_ipv4_octet(S) ->
    gleam@result:'try'(
        gleam_stdlib:parse_int(S),
        fun(N) ->
            gleam@bool:guard(
                (N < 0) orelse (N > 255),
                {error, nil},
                fun() -> {ok, N} end
            )
        end
    ).

-file("src/kryptos/internal/utils.gleam", 131).
?DOC(false).
-spec parse_ipv4(binary()) -> {ok, bitstring()} | {error, nil}.
parse_ipv4(Ip) ->
    Parts = gleam@string:split(Ip, <<"."/utf8>>),
    gleam@bool:guard(
        erlang:length(Parts) /= 4,
        {error, nil},
        fun() ->
            gleam@result:'try'(
                gleam@list:try_map(Parts, fun parse_ipv4_octet/1),
                fun(Bytes) ->
                    {ok,
                        gleam_stdlib:bit_array_concat(
                            gleam@list:map(Bytes, fun(B) -> <<B:8>> end)
                        )}
                end
            )
        end
    ).

-file("src/kryptos/internal/utils.gleam", 192).
?DOC(false).
-spec parse_ipv6_word(binary()) -> {ok, integer()} | {error, nil}.
parse_ipv6_word(S) ->
    gleam@result:'try'(
        gleam@int:base_parse(S, 16),
        fun(N) ->
            gleam@bool:guard(
                (N < 0) orelse (N > 16#ffff),
                {error, nil},
                fun() -> {ok, N} end
            )
        end
    ).

-file("src/kryptos/internal/utils.gleam", 160).
?DOC(false).
-spec parse_ipv6_full(binary()) -> {ok, bitstring()} | {error, nil}.
parse_ipv6_full(Ip) ->
    Parts = gleam@string:split(Ip, <<":"/utf8>>),
    gleam@bool:guard(
        erlang:length(Parts) /= 8,
        {error, nil},
        fun() ->
            gleam@result:'try'(
                gleam@list:try_map(Parts, fun parse_ipv6_word/1),
                fun(Words) ->
                    {ok,
                        gleam_stdlib:bit_array_concat(
                            gleam@list:map(Words, fun(W) -> <<W:16>> end)
                        )}
                end
            )
        end
    ).

-file("src/kryptos/internal/utils.gleam", 167).
?DOC(false).
-spec parse_ipv6_compressed(binary()) -> {ok, bitstring()} | {error, nil}.
parse_ipv6_compressed(Ip) ->
    gleam@result:'try'(case gleam@string:split(Ip, <<"::"/utf8>>) of
            [L, R] ->
                {ok, {L, R}};

            _ ->
                {error, nil}
        end, fun(_use0) ->
            {Left, Right} = _use0,
            Left_parts = case Left of
                <<""/utf8>> ->
                    [];

                _ ->
                    gleam@string:split(Left, <<":"/utf8>>)
            end,
            Right_parts = case Right of
                <<""/utf8>> ->
                    [];

                _ ->
                    gleam@string:split(Right, <<":"/utf8>>)
            end,
            Total = erlang:length(Left_parts) + erlang:length(Right_parts),
            gleam@bool:guard(
                Total > 7,
                {error, nil},
                fun() ->
                    Zeros = gleam@list:repeat(0, 8 - Total),
                    gleam@result:'try'(
                        gleam@list:try_map(Left_parts, fun parse_ipv6_word/1),
                        fun(Left_words) ->
                            gleam@result:'try'(
                                gleam@list:try_map(
                                    Right_parts,
                                    fun parse_ipv6_word/1
                                ),
                                fun(Right_words) ->
                                    All_words = lists:append(
                                        [Left_words, Zeros, Right_words]
                                    ),
                                    {ok,
                                        gleam_stdlib:bit_array_concat(
                                            gleam@list:map(
                                                All_words,
                                                fun(W) -> <<W:16>> end
                                            )
                                        )}
                                end
                            )
                        end
                    )
                end
            )
        end).

-file("src/kryptos/internal/utils.gleam", 144).
?DOC(false).
-spec parse_ipv6(binary()) -> {ok, bitstring()} | {error, nil}.
parse_ipv6(Ip) ->
    Ip@1 = case gleam_stdlib:string_starts_with(Ip, <<"::"/utf8>>) of
        true ->
            <<"0"/utf8, Ip/binary>>;

        false ->
            Ip
    end,
    Ip@2 = case gleam_stdlib:string_ends_with(Ip@1, <<"::"/utf8>>) of
        true ->
            <<Ip@1/binary, "0"/utf8>>;

        false ->
            Ip@1
    end,
    case gleam_stdlib:contains_string(Ip@2, <<"::"/utf8>>) of
        true ->
            parse_ipv6_compressed(Ip@2);

        false ->
            parse_ipv6_full(Ip@2)
    end.

-file("src/kryptos/internal/utils.gleam", 124).
?DOC(false).
-spec parse_ip(binary()) -> {ok, bitstring()} | {error, nil}.
parse_ip(Ip) ->
    case gleam_stdlib:contains_string(Ip, <<":"/utf8>>) of
        true ->
            parse_ipv6(Ip);

        false ->
            parse_ipv4(Ip)
    end.
