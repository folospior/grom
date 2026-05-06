-module(kryptos@internal@hkdf).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/hkdf.gleam").
-export([do_derive/5]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/hkdf.gleam", 45).
?DOC(false).
-spec expand_loop(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    integer(),
    bitstring(),
    integer(),
    gleam@bytes_tree:bytes_tree()
) -> {ok, bitstring()} | {error, nil}.
expand_loop(Algorithm, Prk, Info, Remaining, Prev, Counter, Acc) ->
    case Remaining =< 0 of
        true ->
            {ok, erlang:list_to_bitstring(Acc)};

        false ->
            Input = gleam_stdlib:bit_array_concat([Prev, Info, <<Counter>>]),
            gleam@result:'try'(
                kryptos@hmac:new(Algorithm, Prk),
                fun(Hmac_state) ->
                    T = begin
                        _pipe = Hmac_state,
                        _pipe@1 = crypto:mac_update(_pipe, Input),
                        crypto:mac_final(_pipe@1)
                    end,
                    T_len = erlang:byte_size(T),
                    case Remaining =< T_len of
                        true ->
                            Final_block@1 = case gleam_stdlib:bit_array_slice(
                                T,
                                0,
                                Remaining
                            ) of
                                {ok, Final_block} -> Final_block;
                                _assert_fail ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"kryptos/internal/hkdf"/utf8>>,
                                                function => <<"expand_loop"/utf8>>,
                                                line => 69,
                                                value => _assert_fail,
                                                start => 1843,
                                                'end' => 1904,
                                                pattern_start => 1854,
                                                pattern_end => 1869})
                            end,
                            _pipe@2 = gleam@bytes_tree:append(
                                Acc,
                                Final_block@1
                            ),
                            _pipe@3 = erlang:list_to_bitstring(_pipe@2),
                            {ok, _pipe@3};

                        false ->
                            expand_loop(
                                Algorithm,
                                Prk,
                                Info,
                                Remaining - T_len,
                                T,
                                Counter + 1,
                                gleam@bytes_tree:append(Acc, T)
                            )
                    end
                end
            )
    end.

-file("src/kryptos/internal/hkdf.gleam", 36).
?DOC(false).
-spec expand(kryptos@hash:hash_algorithm(), bitstring(), bitstring(), integer()) -> {ok,
        bitstring()} |
    {error, nil}.
expand(Algorithm, Prk, Info, Length) ->
    expand_loop(Algorithm, Prk, Info, Length, <<>>, 1, gleam@bytes_tree:new()).

-file("src/kryptos/internal/hkdf.gleam", 13).
?DOC(false).
-spec do_derive(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    bitstring(),
    integer()
) -> {ok, bitstring()} | {error, nil}.
do_derive(Algorithm, Ikm, Salt, Info, Length) ->
    gleam@result:'try'(
        kryptos@hmac:new(Algorithm, Salt),
        fun(Hmac_state) ->
            Prk = begin
                _pipe = Hmac_state,
                _pipe@1 = crypto:mac_update(_pipe, Ikm),
                crypto:mac_final(_pipe@1)
            end,
            expand(Algorithm, Prk, Info, Length)
        end
    ).
