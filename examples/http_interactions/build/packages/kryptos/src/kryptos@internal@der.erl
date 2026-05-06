-module(kryptos@internal@der).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/der.gleam").
-export([encode_length/1, parse_length/1, encode_context_tag/2, encode_context_primitive_tag/2, parse_content/2, parse_tlv/1, parse_context_tag/2, decode_oid_components/1, encode_bool/1, parse_bool/1, encode_integer/1, encode_small_int/1, parse_integer/1, encode_bit_string/1, parse_bit_string/1, encode_octet_string/1, parse_octet_string/1, encode_oid/1, parse_oid/1, encode_utf8_string/1, parse_utf8_string/1, encode_printable_string/1, parse_printable_string/1, parse_teletex_string/1, encode_ia5_string/1, parse_ia5_string/1, parse_utc_time/1, encode_generalized_time/1, encode_timestamp/1, parse_generalized_time/1, parse_universal_string/1, parse_bmp_string/1, encode_sequence/1, parse_sequence/1, encode_set/1, parse_set/1]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/der.gleam", 46).
?DOC(false).
-spec encode_length(integer()) -> {ok, bitstring()} | {error, nil}.
encode_length(Len) ->
    case Len of
        L when L < 0 ->
            {error, nil};

        L@1 when L@1 < 128 ->
            {ok, <<L@1:8>>};

        L@2 when L@2 < 256 ->
            {ok, <<16#81, L@2:8>>};

        L@3 when L@3 =< 65535 ->
            {ok, <<16#82, L@3:16>>};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 60).
?DOC(false).
-spec parse_length(bitstring()) -> {ok, {integer(), bitstring()}} | {error, nil}.
parse_length(Bytes) ->
    case Bytes of
        <<Len:8, Rest/bitstring>> when Len < 128 ->
            {ok, {Len, Rest}};

        <<16#81, Len@1:8, Rest@1/bitstring>> when Len@1 >= 128 ->
            {ok, {Len@1, Rest@1}};

        <<16#82, Len@2:16, Rest@2/bitstring>> when Len@2 >= 256 ->
            {ok, {Len@2, Rest@2}};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 243).
?DOC(false).
-spec is_printable_char(integer()) -> boolean().
is_printable_char(Codepoint) ->
    case Codepoint of
        C when (C >= 65) andalso (C =< 90) ->
            true;

        C@1 when (C@1 >= 97) andalso (C@1 =< 122) ->
            true;

        C@2 when (C@2 >= 48) andalso (C@2 =< 57) ->
            true;

        32 ->
            true;

        39 ->
            true;

        40 ->
            true;

        41 ->
            true;

        43 ->
            true;

        44 ->
            true;

        45 ->
            true;

        46 ->
            true;

        47 ->
            true;

        58 ->
            true;

        61 ->
            true;

        63 ->
            true;

        _ ->
            false
    end.

-file("src/kryptos/internal/der.gleam", 277).
?DOC(false).
-spec is_valid_printable_string(bitstring()) -> boolean().
is_valid_printable_string(Value) ->
    case Value of
        <<>> ->
            true;

        <<Byte:8, Rest/bitstring>> ->
            is_printable_char(Byte) andalso is_valid_printable_string(Rest);

        _ ->
            false
    end.

-file("src/kryptos/internal/der.gleam", 537).
?DOC(false).
-spec encode_context_tag(integer(), bitstring()) -> {ok, bitstring()} |
    {error, nil}.
encode_context_tag(Tag, Content) ->
    Tag_byte = erlang:'bor'(16#a0, Tag),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok,
                gleam_stdlib:bit_array_concat(
                    [<<Tag_byte:8>>, Len_bytes, Content]
                )}
        end
    ).

-file("src/kryptos/internal/der.gleam", 559).
?DOC(false).
-spec encode_context_primitive_tag(integer(), bitstring()) -> {ok, bitstring()} |
    {error, nil}.
encode_context_primitive_tag(Tag, Content) ->
    Tag_byte = erlang:'bor'(16#80, Tag),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok,
                gleam_stdlib:bit_array_concat(
                    [<<Tag_byte:8>>, Len_bytes, Content]
                )}
        end
    ).

-file("src/kryptos/internal/der.gleam", 569).
?DOC(false).
-spec parse_content(bitstring(), integer()) -> {ok, {bitstring(), bitstring()}} |
    {error, nil}.
parse_content(Content, Len) ->
    Content_size = erlang:byte_size(Content),
    gleam@bool:guard(
        Content_size < Len,
        {error, nil},
        fun() ->
            Inner@1 = case gleam_stdlib:bit_array_slice(Content, 0, Len) of
                {ok, Inner} -> Inner;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/der"/utf8>>,
                                function => <<"parse_content"/utf8>>,
                                line => 576,
                                value => _assert_fail,
                                start => 20465,
                                'end' => 20520,
                                pattern_start => 20476,
                                pattern_end => 20485})
            end,
            Remaining@1 = case gleam_stdlib:bit_array_slice(
                Content,
                Len,
                Content_size - Len
            ) of
                {ok, Remaining} -> Remaining;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/der"/utf8>>,
                                function => <<"parse_content"/utf8>>,
                                line => 577,
                                value => _assert_fail@1,
                                start => 20523,
                                'end' => 20599,
                                pattern_start => 20534,
                                pattern_end => 20547})
            end,
            {ok, {Inner@1, Remaining@1}}
        end
    ).

-file("src/kryptos/internal/der.gleam", 582).
?DOC(false).
-spec parse_tlv(bitstring()) -> {ok, {integer(), bitstring(), bitstring()}} |
    {error, nil}.
parse_tlv(Bytes) ->
    case Bytes of
        <<Tag:8, Rest/bitstring>> ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@result:'try'(
                        parse_content(Content, Len),
                        fun(_use0@1) ->
                            {Value, Remaining} = _use0@1,
                            {ok, {Tag, Value, Remaining}}
                        end
                    )
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 593).
?DOC(false).
-spec require_tag(
    bitstring(),
    integer(),
    fun((bitstring()) -> {ok, FAC} | {error, nil})
) -> {ok, FAC} | {error, nil}.
require_tag(Bytes, Tag, Next) ->
    case Bytes of
        <<T:8, Rest/bitstring>> when T =:= Tag ->
            Next(Rest);

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 546).
?DOC(false).
-spec parse_context_tag(bitstring(), integer()) -> {ok,
        {bitstring(), bitstring()}} |
    {error, nil}.
parse_context_tag(Bytes, Tag) ->
    Tag_byte = erlang:'bor'(16#a0, Tag),
    require_tag(
        Bytes,
        Tag_byte,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    parse_content(Content, Len)
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 604).
?DOC(false).
-spec reject_non_minimal_zeros(bitstring(), fun(() -> {ok, FAH} | {error, nil})) -> {ok,
        FAH} |
    {error, nil}.
reject_non_minimal_zeros(Value, Next) ->
    case Value of
        <<16#00, Second:8, _/bitstring>> when Second < 128 ->
            {error, nil};

        _ ->
            Next()
    end.

-file("src/kryptos/internal/der.gleam", 614).
?DOC(false).
-spec bytes_from_list(list(integer())) -> bitstring().
bytes_from_list(Bytes) ->
    _pipe = Bytes,
    _pipe@1 = gleam@list:fold(
        _pipe,
        gleam@bytes_tree:new(),
        fun(Tree, Byte) -> gleam@bytes_tree:append(Tree, <<Byte:8>>) end
    ),
    erlang:list_to_bitstring(_pipe@1).

-file("src/kryptos/internal/der.gleam", 629).
?DOC(false).
-spec encode_oid_component_base128(integer(), list(integer())) -> list(integer()).
encode_oid_component_base128(Value, Acc) ->
    case Value of
        0 ->
            Acc;

        _ ->
            Byte = erlang:'band'(Value, 16#7f),
            Next_value = erlang:'bsr'(Value, 7),
            New_byte = case Acc of
                [] ->
                    Byte;

                _ ->
                    erlang:'bor'(Byte, 16#80)
            end,
            encode_oid_component_base128(Next_value, [New_byte | Acc])
    end.

-file("src/kryptos/internal/der.gleam", 622).
?DOC(false).
-spec encode_oid_component(integer()) -> list(integer()).
encode_oid_component(Value) ->
    case Value < 128 of
        true ->
            [Value];

        false ->
            encode_oid_component_base128(Value, [])
    end.

-file("src/kryptos/internal/der.gleam", 661).
?DOC(false).
-spec decode_first_oid_component(bitstring(), integer()) -> {ok,
        {integer(), bitstring()}} |
    {error, nil}.
decode_first_oid_component(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {error, nil};

        <<Byte:8, Rest/bitstring>> ->
            Value = erlang:'bor'(
                erlang:'bsl'(Acc, 7),
                erlang:'band'(Byte, 16#7f)
            ),
            Is_continuation = erlang:'band'(Byte, 16#80) /= 0,
            case Is_continuation of
                true ->
                    decode_first_oid_component(Rest, Value);

                false ->
                    {ok, {Value, Rest}}
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 683).
?DOC(false).
-spec decode_oid_rest(bitstring(), integer(), list(integer())) -> {ok,
        list(integer())} |
    {error, nil}.
decode_oid_rest(Bytes, Acc, Components) ->
    case Bytes of
        <<>> when Acc =:= 0 ->
            {ok, lists:reverse(Components)};

        <<>> ->
            {error, nil};

        <<Byte:8, Rest/bitstring>> ->
            Value = erlang:'bor'(
                erlang:'bsl'(Acc, 7),
                erlang:'band'(Byte, 16#7f)
            ),
            Is_continuation = erlang:'band'(Byte, 16#80) /= 0,
            case Is_continuation of
                true ->
                    decode_oid_rest(Rest, Value, Components);

                false ->
                    decode_oid_rest(Rest, 0, [Value | Components])
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 647).
?DOC(false).
-spec decode_oid_components(bitstring()) -> {ok, list(integer())} | {error, nil}.
decode_oid_components(Bytes) ->
    gleam@result:'try'(
        decode_first_oid_component(Bytes, 0),
        fun(_use0) ->
            {First_value, Rest} = _use0,
            First = case First_value of
                V when V < 40 ->
                    0;

                V@1 when V@1 < 80 ->
                    1;

                _ ->
                    2
            end,
            Second = First_value - (First * 40),
            gleam@result:'try'(
                decode_oid_rest(Rest, 0, []),
                fun(Rest_components) ->
                    {ok, [First, Second | Rest_components]}
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 718).
?DOC(false).
-spec latin1_to_utf8_loop(bitstring(), list(integer())) -> {ok, list(integer())} |
    {error, nil}.
latin1_to_utf8_loop(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, Acc};

        <<Byte:8, Rest/bitstring>> ->
            case gleam@string:utf_codepoint(Byte) of
                {ok, Cp} ->
                    latin1_to_utf8_loop(Rest, [Cp | Acc]);

                {error, _} ->
                    {error, nil}
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 711).
?DOC(false).
-spec latin1_to_utf8(bitstring()) -> {ok, binary()} | {error, nil}.
latin1_to_utf8(Bytes) ->
    _pipe = latin1_to_utf8_loop(Bytes, []),
    gleam@result:map(_pipe, fun(Codepoints) -> _pipe@1 = Codepoints,
            _pipe@2 = lists:reverse(_pipe@1),
            gleam_stdlib:utf_codepoint_list_to_string(_pipe@2) end).

-file("src/kryptos/internal/der.gleam", 744).
?DOC(false).
-spec ucs2_to_utf8_loop(bitstring(), list(integer())) -> {ok, list(integer())} |
    {error, nil}.
ucs2_to_utf8_loop(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, Acc};

        <<Codepoint:16/big, Rest/bitstring>> ->
            case gleam@string:utf_codepoint(Codepoint) of
                {ok, Cp} ->
                    ucs2_to_utf8_loop(Rest, [Cp | Acc]);

                {error, _} ->
                    {error, nil}
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 737).
?DOC(false).
-spec ucs2_to_utf8(bitstring()) -> {ok, binary()} | {error, nil}.
ucs2_to_utf8(Bytes) ->
    _pipe = ucs2_to_utf8_loop(Bytes, []),
    gleam@result:map(_pipe, fun(Codepoints) -> _pipe@1 = Codepoints,
            _pipe@2 = lists:reverse(_pipe@1),
            gleam_stdlib:utf_codepoint_list_to_string(_pipe@2) end).

-file("src/kryptos/internal/der.gleam", 770).
?DOC(false).
-spec ucs4_to_utf8_loop(bitstring(), list(integer())) -> {ok, list(integer())} |
    {error, nil}.
ucs4_to_utf8_loop(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, Acc};

        <<Codepoint:32/big, Rest/bitstring>> ->
            case gleam@string:utf_codepoint(Codepoint) of
                {ok, Cp} ->
                    ucs4_to_utf8_loop(Rest, [Cp | Acc]);

                {error, _} ->
                    {error, nil}
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 763).
?DOC(false).
-spec ucs4_to_utf8(bitstring()) -> {ok, binary()} | {error, nil}.
ucs4_to_utf8(Bytes) ->
    _pipe = ucs4_to_utf8_loop(Bytes, []),
    gleam@result:map(_pipe, fun(Codepoints) -> _pipe@1 = Codepoints,
            _pipe@2 = lists:reverse(_pipe@1),
            gleam_stdlib:utf_codepoint_list_to_string(_pipe@2) end).

-file("src/kryptos/internal/der.gleam", 70).
?DOC(false).
-spec encode_bool(boolean()) -> bitstring().
encode_bool(Value) ->
    case Value of
        true ->
            <<16#01, 16#01, 16#ff>>;

        false ->
            <<16#01, 16#01, 16#00>>
    end.

-file("src/kryptos/internal/der.gleam", 81).
?DOC(false).
-spec parse_bool(bitstring()) -> {ok, {boolean(), bitstring()}} | {error, nil}.
parse_bool(Bytes) ->
    require_tag(
        Bytes,
        16#01,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len /= 1,
                        {error, nil},
                        fun() -> case Content of
                                <<16#00, Remaining/bitstring>> ->
                                    {ok, {false, Remaining}};

                                <<_:8, Remaining@1/bitstring>> ->
                                    {ok, {true, Remaining@1}};

                                _ ->
                                    {error, nil}
                            end end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 96).
?DOC(false).
-spec encode_integer(bitstring()) -> {ok, bitstring()} | {error, nil}.
encode_integer(Value) ->
    Stripped = kryptos@internal@utils:strip_leading_zeros(Value),
    Int_bytes = case Stripped of
        <<High:8, _/bitstring>> when High >= 128 ->
            gleam_stdlib:bit_array_concat([<<16#00>>, Stripped]);

        <<>> ->
            <<16#00>>;

        _ ->
            Stripped
    end,
    gleam@result:'try'(
        encode_length(erlang:byte_size(Int_bytes)),
        fun(Len_bytes) ->
            {ok,
                gleam_stdlib:bit_array_concat([<<16#02>>, Len_bytes, Int_bytes])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 113).
?DOC(false).
-spec encode_small_int(integer()) -> {ok, bitstring()} | {error, nil}.
encode_small_int(N) ->
    case N of
        _ when N < 0 ->
            {error, nil};

        _ when N < 16#100 ->
            encode_integer(<<N:8>>);

        _ when N < 16#10000 ->
            encode_integer(<<N:16>>);

        _ when N < 16#1000000 ->
            encode_integer(<<N:24>>);

        _ when N < 16#100000000 ->
            encode_integer(<<N:32>>);

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 128).
?DOC(false).
-spec parse_integer(bitstring()) -> {ok, {bitstring(), bitstring()}} |
    {error, nil}.
parse_integer(Bytes) ->
    require_tag(
        Bytes,
        16#02,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len =< 0,
                        {error, nil},
                        fun() ->
                            Content_size = erlang:byte_size(Content),
                            gleam@bool:guard(
                                Content_size < Len,
                                {error, nil},
                                fun() ->
                                    Value@1 = case gleam_stdlib:bit_array_slice(
                                        Content,
                                        0,
                                        Len
                                    ) of
                                        {ok, Value} -> Value;
                                        _assert_fail ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"kryptos/internal/der"/utf8>>,
                                                        function => <<"parse_integer"/utf8>>,
                                                        line => 137,
                                                        value => _assert_fail,
                                                        start => 4080,
                                                        'end' => 4135,
                                                        pattern_start => 4091,
                                                        pattern_end => 4100}
                                                )
                                    end,
                                    reject_non_minimal_zeros(
                                        Value@1,
                                        fun() ->
                                            Remaining@1 = case gleam_stdlib:bit_array_slice(
                                                Content,
                                                Len,
                                                Content_size - Len
                                            ) of
                                                {ok, Remaining} -> Remaining;
                                                _assert_fail@1 ->
                                                    erlang:error(
                                                            #{gleam_error => let_assert,
                                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                                file => <<?FILEPATH/utf8>>,
                                                                module => <<"kryptos/internal/der"/utf8>>,
                                                                function => <<"parse_integer"/utf8>>,
                                                                line => 141,
                                                                value => _assert_fail@1,
                                                                start => 4252,
                                                                'end' => 4328,
                                                                pattern_start => 4263,
                                                                pattern_end => 4276}
                                                        )
                                            end,
                                            {ok, {Value@1, Remaining@1}}
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 182).
?DOC(false).
-spec encode_bit_string(bitstring()) -> {ok, bitstring()} | {error, nil}.
encode_bit_string(Value) ->
    Bit_size = erlang:bit_size(Value),
    Unused_bits = case Bit_size rem 8 of
        0 ->
            0;

        Remainder ->
            8 - Remainder
    end,
    Padded = gleam_stdlib:bit_array_pad_to_bytes(Value),
    Content = <<Unused_bits:8, Padded/bitstring>>,
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#03>>, Len_bytes, Content])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 198).
?DOC(false).
-spec parse_bit_string(bitstring()) -> {ok, {bitstring(), bitstring()}} |
    {error, nil}.
parse_bit_string(Bytes) ->
    require_tag(
        Bytes,
        16#03,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len < 1,
                        {error, nil},
                        fun() ->
                            Content_size = erlang:byte_size(Content),
                            gleam@bool:guard(
                                Content_size < Len,
                                {error, nil},
                                fun() -> case Content of
                                        <<16#00,
                                            Value:(Len - 1)/binary,
                                            Remaining/bitstring>> ->
                                            {ok, {Value, Remaining}};

                                        _ ->
                                            {error, nil}
                                    end end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 214).
?DOC(false).
-spec encode_octet_string(bitstring()) -> {ok, bitstring()} | {error, nil}.
encode_octet_string(Value) ->
    gleam@result:'try'(
        encode_length(erlang:byte_size(Value)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#04>>, Len_bytes, Value])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 220).
?DOC(false).
-spec parse_octet_string(bitstring()) -> {ok, {bitstring(), bitstring()}} |
    {error, nil}.
parse_octet_string(Bytes) ->
    require_tag(
        Bytes,
        16#04,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    parse_content(Content, Len)
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 494).
?DOC(false).
-spec encode_oid(list(integer())) -> {ok, bitstring()} | {error, nil}.
encode_oid(Components) ->
    case Components of
        [First, Second | Rest] when (((First >= 0) andalso (First =< 2)) andalso (Second >= 0)) andalso ((First =:= 2) orelse (Second =< 39)) ->
            First_value = (First * 40) + Second,
            First_bytes = encode_oid_component(First_value),
            Rest_bytes = gleam@list:flat_map(Rest, fun encode_oid_component/1),
            Content = gleam_stdlib:bit_array_concat(
                [bytes_from_list(First_bytes), bytes_from_list(Rest_bytes)]
            ),
            gleam@result:'try'(
                encode_length(erlang:byte_size(Content)),
                fun(Len_bytes) ->
                    {ok,
                        gleam_stdlib:bit_array_concat(
                            [<<16#06>>, Len_bytes, Content]
                        )}
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/der.gleam", 518).
?DOC(false).
-spec parse_oid(bitstring()) -> {ok, {list(integer()), bitstring()}} |
    {error, nil}.
parse_oid(Bytes) ->
    require_tag(
        Bytes,
        16#06,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len < 1,
                        {error, nil},
                        fun() ->
                            Content_size = erlang:byte_size(Content),
                            gleam@bool:guard(
                                Content_size < Len,
                                {error, nil},
                                fun() ->
                                    Oid_bytes@1 = case gleam_stdlib:bit_array_slice(
                                        Content,
                                        0,
                                        Len
                                    ) of
                                        {ok, Oid_bytes} -> Oid_bytes;
                                        _assert_fail ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"kryptos/internal/der"/utf8>>,
                                                        function => <<"parse_oid"/utf8>>,
                                                        line => 527,
                                                        value => _assert_fail,
                                                        start => 18708,
                                                        'end' => 18767,
                                                        pattern_start => 18719,
                                                        pattern_end => 18732}
                                                )
                                    end,
                                    Remaining@1 = case gleam_stdlib:bit_array_slice(
                                        Content,
                                        Len,
                                        Content_size - Len
                                    ) of
                                        {ok, Remaining} -> Remaining;
                                        _assert_fail@1 ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"kryptos/internal/der"/utf8>>,
                                                        function => <<"parse_oid"/utf8>>,
                                                        line => 528,
                                                        value => _assert_fail@1,
                                                        start => 18770,
                                                        'end' => 18846,
                                                        pattern_start => 18781,
                                                        pattern_end => 18794}
                                                )
                                    end,
                                    gleam@result:'try'(
                                        decode_oid_components(Oid_bytes@1),
                                        fun(Components) ->
                                            {ok, {Components, Remaining@1}}
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 227).
?DOC(false).
-spec encode_utf8_string(binary()) -> {ok, bitstring()} | {error, nil}.
encode_utf8_string(Value) ->
    Content = gleam_stdlib:identity(Value),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#0c>>, Len_bytes, Content])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 234).
?DOC(false).
-spec parse_utf8_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_utf8_string(Bytes) ->
    require_tag(
        Bytes,
        16#0c,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@result:'try'(
                        parse_content(Content, Len),
                        fun(_use0@1) ->
                            {Value_bytes, Remaining} = _use0@1,
                            gleam@result:'try'(
                                gleam@bit_array:to_string(Value_bytes),
                                fun(Value) -> {ok, {Value, Remaining}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 289).
?DOC(false).
-spec encode_printable_string(binary()) -> {ok, bitstring()} | {error, nil}.
encode_printable_string(Value) ->
    Content = gleam_stdlib:identity(Value),
    gleam@bool:guard(
        not is_valid_printable_string(Content),
        {error, nil},
        fun() ->
            gleam@result:'try'(
                encode_length(erlang:byte_size(Content)),
                fun(Len_bytes) ->
                    {ok,
                        gleam_stdlib:bit_array_concat(
                            [<<16#13>>, Len_bytes, Content]
                        )}
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 302).
?DOC(false).
-spec parse_printable_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_printable_string(Bytes) ->
    require_tag(
        Bytes,
        16#13,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@result:'try'(
                        parse_content(Content, Len),
                        fun(_use0@1) ->
                            {Value_bytes, Remaining} = _use0@1,
                            gleam@result:'try'(
                                gleam@bit_array:to_string(Value_bytes),
                                fun(Value) -> {ok, {Value, Remaining}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 334).
?DOC(false).
-spec parse_teletex_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_teletex_string(Bytes) ->
    require_tag(
        Bytes,
        16#14,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@result:'try'(
                        parse_content(Content, Len),
                        fun(_use0@1) ->
                            {Value_bytes, Remaining} = _use0@1,
                            gleam@result:'try'(
                                latin1_to_utf8(Value_bytes),
                                fun(Value) -> {ok, {Value, Remaining}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 313).
?DOC(false).
-spec encode_ia5_string(binary()) -> {ok, bitstring()} | {error, nil}.
encode_ia5_string(Value) ->
    Content = gleam_stdlib:identity(Value),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#16>>, Len_bytes, Content])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 322).
?DOC(false).
-spec parse_ia5_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_ia5_string(Bytes) ->
    require_tag(
        Bytes,
        16#16,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@result:'try'(
                        parse_content(Content, Len),
                        fun(_use0@1) ->
                            {Value_bytes, Remaining} = _use0@1,
                            gleam@result:'try'(
                                gleam@bit_array:to_string(Value_bytes),
                                fun(Value) -> {ok, {Value, Remaining}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 380).
?DOC(false).
-spec encode_utc_time(gleam@time@timestamp:timestamp()) -> {ok, bitstring()} |
    {error, nil}.
encode_utc_time(Timestamp) ->
    {Date, Time} = gleam@time@timestamp:to_calendar(Timestamp, {duration, 0, 0}),
    Yy = erlang:element(2, Date) rem 100,
    Pad2 = fun(_capture) ->
        kryptos@internal@utils:int_to_padded_string(_capture, 2)
    end,
    Content = <<<<<<<<<<<<(Pad2(Yy))/binary,
                            (Pad2(
                                gleam@time@calendar:month_to_int(
                                    erlang:element(3, Date)
                                )
                            ))/binary>>/binary,
                        (Pad2(erlang:element(4, Date)))/binary>>/binary,
                    (Pad2(erlang:element(2, Time)))/binary>>/binary,
                (Pad2(erlang:element(3, Time)))/binary>>/binary,
            (Pad2(erlang:element(4, Time)))/binary>>/binary,
        "Z"/utf8>>,
    Bytes = gleam_stdlib:identity(Content),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Bytes)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#17>>, Len_bytes, Bytes])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 399).
?DOC(false).
-spec parse_utc_time(bitstring()) -> {ok,
        {gleam@time@timestamp:timestamp(), bitstring()}} |
    {error, nil}.
parse_utc_time(Bytes) ->
    require_tag(
        Bytes,
        16#17,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len /= 13,
                        {error, nil},
                        fun() ->
                            gleam@result:'try'(
                                parse_content(Content, Len),
                                fun(_use0@1) ->
                                    {Time_bytes, Remaining} = _use0@1,
                                    gleam@result:'try'(
                                        gleam@bit_array:to_string(Time_bytes),
                                        fun(Time_str) ->
                                            gleam@bool:guard(
                                                not gleam_stdlib:string_ends_with(
                                                    Time_str,
                                                    <<"Z"/utf8>>
                                                ),
                                                {error, nil},
                                                fun() ->
                                                    gleam@result:'try'(
                                                        gleam_stdlib:parse_int(
                                                            gleam@string:slice(
                                                                Time_str,
                                                                0,
                                                                2
                                                            )
                                                        ),
                                                        fun(Yy) ->
                                                            gleam@result:'try'(
                                                                gleam_stdlib:parse_int(
                                                                    gleam@string:slice(
                                                                        Time_str,
                                                                        2,
                                                                        2
                                                                    )
                                                                ),
                                                                fun(Month_int) ->
                                                                    gleam@result:'try'(
                                                                        gleam@time@calendar:month_from_int(
                                                                            Month_int
                                                                        ),
                                                                        fun(
                                                                            Month
                                                                        ) ->
                                                                            gleam@result:'try'(
                                                                                gleam_stdlib:parse_int(
                                                                                    gleam@string:slice(
                                                                                        Time_str,
                                                                                        4,
                                                                                        2
                                                                                    )
                                                                                ),
                                                                                fun(
                                                                                    Day
                                                                                ) ->
                                                                                    gleam@result:'try'(
                                                                                        gleam_stdlib:parse_int(
                                                                                            gleam@string:slice(
                                                                                                Time_str,
                                                                                                6,
                                                                                                2
                                                                                            )
                                                                                        ),
                                                                                        fun(
                                                                                            Hour
                                                                                        ) ->
                                                                                            gleam@result:'try'(
                                                                                                gleam_stdlib:parse_int(
                                                                                                    gleam@string:slice(
                                                                                                        Time_str,
                                                                                                        8,
                                                                                                        2
                                                                                                    )
                                                                                                ),
                                                                                                fun(
                                                                                                    Minute
                                                                                                ) ->
                                                                                                    gleam@result:'try'(
                                                                                                        gleam_stdlib:parse_int(
                                                                                                            gleam@string:slice(
                                                                                                                Time_str,
                                                                                                                10,
                                                                                                                2
                                                                                                            )
                                                                                                        ),
                                                                                                        fun(
                                                                                                            Second
                                                                                                        ) ->
                                                                                                            Year = case Yy
                                                                                                            >= 50 of
                                                                                                                true ->
                                                                                                                    1900
                                                                                                                    + Yy;

                                                                                                                false ->
                                                                                                                    2000
                                                                                                                    + Yy
                                                                                                            end,
                                                                                                            Ts = gleam@time@timestamp:from_calendar(
                                                                                                                {date,
                                                                                                                    Year,
                                                                                                                    Month,
                                                                                                                    Day},
                                                                                                                {time_of_day,
                                                                                                                    Hour,
                                                                                                                    Minute,
                                                                                                                    Second,
                                                                                                                    0},
                                                                                                                {duration,
                                                                                                                    0,
                                                                                                                    0}
                                                                                                            ),
                                                                                                            {ok,
                                                                                                                {Ts,
                                                                                                                    Remaining}}
                                                                                                        end
                                                                                                    )
                                                                                                end
                                                                                            )
                                                                                        end
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 436).
?DOC(false).
-spec encode_generalized_time(gleam@time@timestamp:timestamp()) -> {ok,
        bitstring()} |
    {error, nil}.
encode_generalized_time(Timestamp) ->
    {Date, Time} = gleam@time@timestamp:to_calendar(Timestamp, {duration, 0, 0}),
    Pad2 = fun(_capture) ->
        kryptos@internal@utils:int_to_padded_string(_capture, 2)
    end,
    Pad4 = fun(_capture@1) ->
        kryptos@internal@utils:int_to_padded_string(_capture@1, 4)
    end,
    Content = <<<<<<<<<<<<(Pad4(erlang:element(2, Date)))/binary,
                            (Pad2(
                                gleam@time@calendar:month_to_int(
                                    erlang:element(3, Date)
                                )
                            ))/binary>>/binary,
                        (Pad2(erlang:element(4, Date)))/binary>>/binary,
                    (Pad2(erlang:element(2, Time)))/binary>>/binary,
                (Pad2(erlang:element(3, Time)))/binary>>/binary,
            (Pad2(erlang:element(4, Time)))/binary>>/binary,
        "Z"/utf8>>,
    Bytes = gleam_stdlib:identity(Content),
    gleam@result:'try'(
        encode_length(erlang:byte_size(Bytes)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#18>>, Len_bytes, Bytes])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 371).
?DOC(false).
-spec encode_timestamp(gleam@time@timestamp:timestamp()) -> {ok, bitstring()} |
    {error, nil}.
encode_timestamp(Timestamp) ->
    {Date, _} = gleam@time@timestamp:to_calendar(Timestamp, {duration, 0, 0}),
    case (erlang:element(2, Date) >= 1950) andalso (erlang:element(2, Date) < 2050) of
        true ->
            encode_utc_time(Timestamp);

        false ->
            encode_generalized_time(Timestamp)
    end.

-file("src/kryptos/internal/der.gleam", 454).
?DOC(false).
-spec parse_generalized_time(bitstring()) -> {ok,
        {gleam@time@timestamp:timestamp(), bitstring()}} |
    {error, nil}.
parse_generalized_time(Bytes) ->
    require_tag(
        Bytes,
        16#18,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        Len /= 15,
                        {error, nil},
                        fun() ->
                            gleam@result:'try'(
                                parse_content(Content, Len),
                                fun(_use0@1) ->
                                    {Time_bytes, Remaining} = _use0@1,
                                    gleam@result:'try'(
                                        gleam@bit_array:to_string(Time_bytes),
                                        fun(Time_str) ->
                                            gleam@bool:guard(
                                                not gleam_stdlib:string_ends_with(
                                                    Time_str,
                                                    <<"Z"/utf8>>
                                                ),
                                                {error, nil},
                                                fun() ->
                                                    gleam@result:'try'(
                                                        gleam_stdlib:parse_int(
                                                            gleam@string:slice(
                                                                Time_str,
                                                                0,
                                                                4
                                                            )
                                                        ),
                                                        fun(Year) ->
                                                            gleam@result:'try'(
                                                                gleam_stdlib:parse_int(
                                                                    gleam@string:slice(
                                                                        Time_str,
                                                                        4,
                                                                        2
                                                                    )
                                                                ),
                                                                fun(Month_int) ->
                                                                    gleam@result:'try'(
                                                                        gleam@time@calendar:month_from_int(
                                                                            Month_int
                                                                        ),
                                                                        fun(
                                                                            Month
                                                                        ) ->
                                                                            gleam@result:'try'(
                                                                                gleam_stdlib:parse_int(
                                                                                    gleam@string:slice(
                                                                                        Time_str,
                                                                                        6,
                                                                                        2
                                                                                    )
                                                                                ),
                                                                                fun(
                                                                                    Day
                                                                                ) ->
                                                                                    gleam@result:'try'(
                                                                                        gleam_stdlib:parse_int(
                                                                                            gleam@string:slice(
                                                                                                Time_str,
                                                                                                8,
                                                                                                2
                                                                                            )
                                                                                        ),
                                                                                        fun(
                                                                                            Hour
                                                                                        ) ->
                                                                                            gleam@result:'try'(
                                                                                                gleam_stdlib:parse_int(
                                                                                                    gleam@string:slice(
                                                                                                        Time_str,
                                                                                                        10,
                                                                                                        2
                                                                                                    )
                                                                                                ),
                                                                                                fun(
                                                                                                    Minute
                                                                                                ) ->
                                                                                                    gleam@result:'try'(
                                                                                                        gleam_stdlib:parse_int(
                                                                                                            gleam@string:slice(
                                                                                                                Time_str,
                                                                                                                12,
                                                                                                                2
                                                                                                            )
                                                                                                        ),
                                                                                                        fun(
                                                                                                            Second
                                                                                                        ) ->
                                                                                                            Timestamp = gleam@time@timestamp:from_calendar(
                                                                                                                {date,
                                                                                                                    Year,
                                                                                                                    Month,
                                                                                                                    Day},
                                                                                                                {time_of_day,
                                                                                                                    Hour,
                                                                                                                    Minute,
                                                                                                                    Second,
                                                                                                                    0},
                                                                                                                {duration,
                                                                                                                    0,
                                                                                                                    0}
                                                                                                            ),
                                                                                                            {ok,
                                                                                                                {Timestamp,
                                                                                                                    Remaining}}
                                                                                                        end
                                                                                                    )
                                                                                                end
                                                                                            )
                                                                                        end
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 359).
?DOC(false).
-spec parse_universal_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_universal_string(Bytes) ->
    require_tag(
        Bytes,
        16#1c,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        (Len rem 4) /= 0,
                        {error, nil},
                        fun() ->
                            gleam@result:'try'(
                                parse_content(Content, Len),
                                fun(_use0@1) ->
                                    {Value_bytes, Remaining} = _use0@1,
                                    gleam@result:'try'(
                                        ucs4_to_utf8(Value_bytes),
                                        fun(Value) ->
                                            {ok, {Value, Remaining}}
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 346).
?DOC(false).
-spec parse_bmp_string(bitstring()) -> {ok, {binary(), bitstring()}} |
    {error, nil}.
parse_bmp_string(Bytes) ->
    require_tag(
        Bytes,
        16#1e,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    gleam@bool:guard(
                        (Len rem 2) /= 0,
                        {error, nil},
                        fun() ->
                            gleam@result:'try'(
                                parse_content(Content, Len),
                                fun(_use0@1) ->
                                    {Value_bytes, Remaining} = _use0@1,
                                    gleam@result:'try'(
                                        ucs2_to_utf8(Value_bytes),
                                        fun(Value) ->
                                            {ok, {Value, Remaining}}
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 146).
?DOC(false).
-spec encode_sequence(bitstring()) -> {ok, bitstring()} | {error, nil}.
encode_sequence(Content) ->
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#30>>, Len_bytes, Content])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 152).
?DOC(false).
-spec parse_sequence(bitstring()) -> {ok, {bitstring(), bitstring()}} |
    {error, nil}.
parse_sequence(Bytes) ->
    require_tag(
        Bytes,
        16#30,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    Content_size = erlang:byte_size(Content),
                    gleam@bool:guard(
                        Content_size < Len,
                        {error, nil},
                        fun() ->
                            Inner@1 = case gleam_stdlib:bit_array_slice(
                                Content,
                                0,
                                Len
                            ) of
                                {ok, Inner} -> Inner;
                                _assert_fail ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"kryptos/internal/der"/utf8>>,
                                                function => <<"parse_sequence"/utf8>>,
                                                line => 160,
                                                value => _assert_fail,
                                                start => 5061,
                                                'end' => 5116,
                                                pattern_start => 5072,
                                                pattern_end => 5081})
                            end,
                            Remaining@1 = case gleam_stdlib:bit_array_slice(
                                Content,
                                Len,
                                Content_size - Len
                            ) of
                                {ok, Remaining} -> Remaining;
                                _assert_fail@1 ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"kryptos/internal/der"/utf8>>,
                                                function => <<"parse_sequence"/utf8>>,
                                                line => 161,
                                                value => _assert_fail@1,
                                                start => 5119,
                                                'end' => 5195,
                                                pattern_start => 5130,
                                                pattern_end => 5143})
                            end,
                            {ok, {Inner@1, Remaining@1}}
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/der.gleam", 166).
?DOC(false).
-spec encode_set(bitstring()) -> {ok, bitstring()} | {error, nil}.
encode_set(Content) ->
    gleam@result:'try'(
        encode_length(erlang:byte_size(Content)),
        fun(Len_bytes) ->
            {ok, gleam_stdlib:bit_array_concat([<<16#31>>, Len_bytes, Content])}
        end
    ).

-file("src/kryptos/internal/der.gleam", 172).
?DOC(false).
-spec parse_set(bitstring()) -> {ok, {bitstring(), bitstring()}} | {error, nil}.
parse_set(Bytes) ->
    require_tag(
        Bytes,
        16#31,
        fun(Rest) ->
            gleam@result:'try'(
                parse_length(Rest),
                fun(_use0) ->
                    {Len, Content} = _use0,
                    parse_content(Content, Len)
                end
            )
        end
    ).
