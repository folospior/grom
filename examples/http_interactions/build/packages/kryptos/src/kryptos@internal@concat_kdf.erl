-module(kryptos@internal@concat_kdf).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/concat_kdf.gleam").
-export([derive_loop/6]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/concat_kdf.gleam", 13).
?DOC(false).
-spec derive_loop(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    integer(),
    integer(),
    gleam@bytes_tree:bytes_tree()
) -> {ok, bitstring()} | {error, nil}.
derive_loop(Algorithm, Secret, Info, Remaining, Counter, Acc) ->
    gleam@bool:guard(
        Remaining =< 0,
        {ok, erlang:list_to_bitstring(Acc)},
        fun() ->
            Input = gleam_stdlib:bit_array_concat(
                [<<Counter:32/big>>, Secret, Info]
            ),
            gleam@result:'try'(
                kryptos@hash:new(Algorithm),
                fun(Hasher) ->
                    Block = begin
                        _pipe = Hasher,
                        _pipe@1 = kryptos_ffi:hash_update(_pipe, Input),
                        kryptos_ffi:hash_final(_pipe@1)
                    end,
                    Length = erlang:byte_size(Block),
                    case Remaining =< Length of
                        true ->
                            Final_block@1 = case gleam_stdlib:bit_array_slice(
                                Block,
                                0,
                                Remaining
                            ) of
                                {ok, Final_block} -> Final_block;
                                _assert_fail ->
                                    erlang:error(#{gleam_error => let_assert,
                                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                file => <<?FILEPATH/utf8>>,
                                                module => <<"kryptos/internal/concat_kdf"/utf8>>,
                                                function => <<"derive_loop"/utf8>>,
                                                line => 37,
                                                value => _assert_fail,
                                                start => 1013,
                                                'end' => 1078,
                                                pattern_start => 1024,
                                                pattern_end => 1039})
                            end,
                            _pipe@2 = gleam@bytes_tree:append(
                                Acc,
                                Final_block@1
                            ),
                            _pipe@3 = erlang:list_to_bitstring(_pipe@2),
                            {ok, _pipe@3};

                        false ->
                            derive_loop(
                                Algorithm,
                                Secret,
                                Info,
                                Remaining - Length,
                                Counter + 1,
                                gleam@bytes_tree:append(Acc, Block)
                            )
                    end
                end
            )
        end
    ).
