-module(kryptos@internal@hchacha20).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/hchacha20.gleam").
-export([subkey/2]).
-export_type([state/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type state() :: {state,
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer()}.

-file("src/kryptos/internal/hchacha20.gleam", 157).
?DOC(false).
-spec add_modulo_32(integer(), integer()) -> integer().
add_modulo_32(A, B) ->
    erlang:'band'(A + B, 16#FFFFFFFF).

-file("src/kryptos/internal/hchacha20.gleam", 161).
?DOC(false).
-spec rotate_left_32(integer(), integer()) -> integer().
rotate_left_32(X, N) ->
    Shifted_left = erlang:'bsl'(X, N),
    Shifted_right = erlang:'bsr'(X, 32 - N),
    erlang:'band'(erlang:'bor'(Shifted_left, Shifted_right), 16#FFFFFFFF).

-file("src/kryptos/internal/hchacha20.gleam", 137).
?DOC(false).
-spec quarter_round(integer(), integer(), integer(), integer()) -> {integer(),
    integer(),
    integer(),
    integer()}.
quarter_round(A, B, C, D) ->
    A@1 = add_modulo_32(A, B),
    D@1 = rotate_left_32(erlang:'bxor'(D, A@1), 16),
    C@1 = add_modulo_32(C, D@1),
    B@1 = rotate_left_32(erlang:'bxor'(B, C@1), 12),
    A@2 = add_modulo_32(A@1, B@1),
    D@2 = rotate_left_32(erlang:'bxor'(D@1, A@2), 8),
    C@2 = add_modulo_32(C@1, D@2),
    B@2 = rotate_left_32(erlang:'bxor'(B@1, C@2), 7),
    {A@2, B@2, C@2, D@2}.

-file("src/kryptos/internal/hchacha20.gleam", 91).
?DOC(false).
-spec perform_rounds(state(), integer()) -> state().
perform_rounds(State, Remaining) ->
    case Remaining =< 0 of
        true ->
            State;

        false ->
            {S0, S4, S8, S12} = quarter_round(
                erlang:element(2, State),
                erlang:element(6, State),
                erlang:element(10, State),
                erlang:element(14, State)
            ),
            {S1, S5, S9, S13} = quarter_round(
                erlang:element(3, State),
                erlang:element(7, State),
                erlang:element(11, State),
                erlang:element(15, State)
            ),
            {S2, S6, S10, S14} = quarter_round(
                erlang:element(4, State),
                erlang:element(8, State),
                erlang:element(12, State),
                erlang:element(16, State)
            ),
            {S3, S7, S11, S15} = quarter_round(
                erlang:element(5, State),
                erlang:element(9, State),
                erlang:element(13, State),
                erlang:element(17, State)
            ),
            {S0@1, S5@1, S10@1, S15@1} = quarter_round(S0, S5, S10, S15),
            {S1@1, S6@1, S11@1, S12@1} = quarter_round(S1, S6, S11, S12),
            {S2@1, S7@1, S8@1, S13@1} = quarter_round(S2, S7, S8, S13),
            {S3@1, S4@1, S9@1, S14@1} = quarter_round(S3, S4, S9, S14),
            State@1 = {state,
                S0@1,
                S1@1,
                S2@1,
                S3@1,
                S4@1,
                S5@1,
                S6@1,
                S7@1,
                S8@1,
                S9@1,
                S10@1,
                S11@1,
                S12@1,
                S13@1,
                S14@1,
                S15@1},
            perform_rounds(State@1, Remaining - 1)
    end.

-file("src/kryptos/internal/hchacha20.gleam", 11).
?DOC(false).
-spec subkey(bitstring(), bitstring()) -> bitstring().
subkey(Key, Input) ->
    {K0@1, K1@1, K2@1, K3@1, K4@1, K5@1, K6@1, K7@1} = case Key of
        <<K0:32/little-unsigned,
            K1:32/little-unsigned,
            K2:32/little-unsigned,
            K3:32/little-unsigned,
            K4:32/little-unsigned,
            K5:32/little-unsigned,
            K6:32/little-unsigned,
            K7:32/little-unsigned>> -> {K0, K1, K2, K3, K4, K5, K6, K7};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/internal/hchacha20"/utf8>>,
                        function => <<"subkey"/utf8>>,
                        line => 13,
                        value => _assert_fail,
                        start => 513,
                        'end' => 753,
                        pattern_start => 524,
                        pattern_end => 747})
    end,
    {N0@1, N1@1, N2@1, N3@1} = case Input of
        <<N0:32/little-unsigned,
            N1:32/little-unsigned,
            N2:32/little-unsigned,
            N3:32/little-unsigned>> -> {N0, N1, N2, N3};
        _assert_fail@1 ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/internal/hchacha20"/utf8>>,
                        function => <<"subkey"/utf8>>,
                        line => 25,
                        value => _assert_fail@1,
                        start => 806,
                        'end' => 940,
                        pattern_start => 817,
                        pattern_end => 932})
    end,
    State = {state,
        16#61707865,
        16#3320646E,
        16#79622D32,
        16#6B206574,
        K0@1,
        K1@1,
        K2@1,
        K3@1,
        K4@1,
        K5@1,
        K6@1,
        K7@1,
        N0@1,
        N1@1,
        N2@1,
        N3@1},
    State@1 = perform_rounds(State, 10),
    <<(erlang:element(2, State@1)):32/little,
        (erlang:element(3, State@1)):32/little,
        (erlang:element(4, State@1)):32/little,
        (erlang:element(5, State@1)):32/little,
        (erlang:element(14, State@1)):32/little,
        (erlang:element(15, State@1)):32/little,
        (erlang:element(16, State@1)):32/little,
        (erlang:element(17, State@1)):32/little>>.
