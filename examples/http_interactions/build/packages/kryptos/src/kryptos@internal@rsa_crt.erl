-module(kryptos@internal@rsa_crt).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/rsa_crt.gleam").
-export([compute_crt_params/3]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/rsa_crt.gleam", 42).
?DOC(false).
-spec validate_components(
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int(),
    fun(() -> {ok, GBE} | {error, nil})
) -> {ok, GBE} | {error, nil}.
validate_components(N, E, D, Next) ->
    Zero = bigi_ffi:from(0),
    One = bigi_ffi:from(1),
    case ((bigi_ffi:compare(N, One) =:= gt) andalso (bigi_ffi:compare(E, One)
    =:= gt))
    andalso (bigi_ffi:compare(D, Zero) =:= gt) of
        true ->
            Next();

        false ->
            {error, nil}
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 89).
?DOC(false).
-spec to_bytes_trimmed(bigi:big_int(), integer()) -> {ok, bitstring()} |
    {error, nil}.
to_bytes_trimmed(Value, Max_byte_len) ->
    gleam@result:'try'(
        bigi_ffi:to_bytes(Value, big_endian, unsigned, Max_byte_len),
        fun(Bytes) ->
            {ok, kryptos@internal@utils:strip_leading_zeros(Bytes)}
        end
    ).

-file("src/kryptos/internal/rsa_crt.gleam", 116).
?DOC(false).
-spec compute_byte_length(bigi:big_int(), integer()) -> integer().
compute_byte_length(Value, Len) ->
    Bound@1 = case bigi_ffi:power(bigi_ffi:from(256), bigi_ffi:from(Len)) of
        {ok, Bound} -> Bound;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/internal/rsa_crt"/utf8>>,
                        function => <<"compute_byte_length"/utf8>>,
                        line => 117,
                        value => _assert_fail,
                        start => 3224,
                        'end' => 3297,
                        pattern_start => 3235,
                        pattern_end => 3244})
    end,
    case bigi_ffi:compare(Value, Bound@1) =:= lt of
        true ->
            Len;

        false ->
            compute_byte_length(Value, Len + 1)
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 99).
?DOC(false).
-spec to_bytes_minimal(bigi:big_int()) -> {ok, bitstring()} | {error, nil}.
to_bytes_minimal(Value) ->
    Zero = bigi_ffi:from(0),
    case Value =:= Zero of
        true ->
            {ok, <<0>>};

        false ->
            Byte_len = compute_byte_length(Value, 1),
            gleam@result:'try'(
                bigi_ffi:to_bytes(Value, big_endian, unsigned, Byte_len),
                fun(Bytes) ->
                    {ok, kryptos@internal@utils:strip_leading_zeros(Bytes)}
                end
            )
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 65).
?DOC(false).
-spec mod_pow(bigi:big_int(), bigi:big_int(), bigi:big_int(), integer()) -> {ok,
        bigi:big_int()} |
    {error, nil}.
mod_pow(Base, Exp, Mod, Byte_len) ->
    gleam@result:'try'(
        bigi_ffi:to_bytes(Base, big_endian, unsigned, Byte_len),
        fun(Base_bytes) ->
            gleam@result:'try'(
                to_bytes_minimal(Exp),
                fun(Exp_bytes) ->
                    gleam@result:'try'(
                        bigi_ffi:to_bytes(Mod, big_endian, unsigned, Byte_len),
                        fun(Mod_bytes) ->
                            Result_bytes = kryptos_ffi:mod_pow(
                                Base_bytes,
                                Exp_bytes,
                                Mod_bytes
                            ),
                            bigi_ffi:from_bytes(
                                Result_bytes,
                                big_endian,
                                unsigned
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/rsa_crt.gleam", 158).
?DOC(false).
-spec factor_out_twos(bigi:big_int(), bigi:big_int(), integer()) -> {integer(),
    bigi:big_int()}.
factor_out_twos(K, Two, Count) ->
    case bigi_ffi:modulo(K, Two) =:= bigi_ffi:from(0) of
        true ->
            Next@1 = case bigi:floor_divide(K, Two) of
                {ok, Next} -> Next;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/rsa_crt"/utf8>>,
                                function => <<"factor_out_twos"/utf8>>,
                                line => 161,
                                value => _assert_fail,
                                start => 4442,
                                'end' => 4508,
                                pattern_start => 4453,
                                pattern_end => 4461})
            end,
            factor_out_twos(Next@1, Two, Count + 1);

        false ->
            {Count, K}
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 225).
?DOC(false).
-spec gcd(bigi:big_int(), bigi:big_int()) -> bigi:big_int().
gcd(A, B) ->
    Zero = bigi_ffi:from(0),
    case B =:= Zero of
        true ->
            erlang:abs(A);

        false ->
            gcd(B, bigi_ffi:modulo(A, B))
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 183).
?DOC(false).
-spec try_factor_loop(
    bigi:big_int(),
    integer(),
    bigi:big_int(),
    integer(),
    integer()
) -> {ok, {bigi:big_int(), bigi:big_int()}} | {error, nil}.
try_factor_loop(N, T, X, I, Byte_len) ->
    case I > T of
        true ->
            {error, nil};

        false ->
            One = bigi_ffi:from(1),
            Two = bigi_ffi:from(2),
            N_minus_1 = bigi_ffi:subtract(N, One),
            gleam@result:'try'(
                mod_pow(X, Two, N, Byte_len),
                fun(Y) -> case Y =:= One of
                        true ->
                            P = gcd(bigi_ffi:subtract(X, One), N),
                            case (bigi_ffi:compare(P, One) =:= gt) andalso (bigi_ffi:compare(
                                P,
                                N
                            )
                            =:= lt) of
                                true ->
                                    Q@1 = case bigi:floor_divide(N, P) of
                                        {ok, Q} -> Q;
                                        _assert_fail ->
                                            erlang:error(
                                                    #{gleam_error => let_assert,
                                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                        file => <<?FILEPATH/utf8>>,
                                                        module => <<"kryptos/internal/rsa_crt"/utf8>>,
                                                        function => <<"try_factor_loop"/utf8>>,
                                                        line => 206,
                                                        value => _assert_fail,
                                                        start => 5456,
                                                        'end' => 5517,
                                                        pattern_start => 5467,
                                                        pattern_end => 5472}
                                                )
                                    end,
                                    case bigi_ffi:compare(P, Q@1) =:= lt of
                                        true ->
                                            {ok, {P, Q@1}};

                                        false ->
                                            {ok, {Q@1, P}}
                                    end;

                                false ->
                                    {error, nil}
                            end;

                        false ->
                            case Y =:= N_minus_1 of
                                true ->
                                    {error, nil};

                                false ->
                                    try_factor_loop(N, T, Y, I + 1, Byte_len)
                            end
                    end end
            )
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 168).
?DOC(false).
-spec try_factor(bigi:big_int(), integer(), bigi:big_int(), integer()) -> {ok,
        {bigi:big_int(), bigi:big_int()}} |
    {error, nil}.
try_factor(N, T, X, Byte_len) ->
    One = bigi_ffi:from(1),
    N_minus_1 = bigi_ffi:subtract(N, One),
    case (X =:= One) orelse (X =:= N_minus_1) of
        true ->
            {error, nil};

        false ->
            try_factor_loop(N, T, X, 1, Byte_len)
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 124).
?DOC(false).
-spec factor_rsa_modulus(
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int(),
    integer(),
    integer()
) -> {ok, {bigi:big_int(), bigi:big_int()}} | {error, nil}.
factor_rsa_modulus(N, E, D, Byte_len, Attempts_left) ->
    case Attempts_left of
        0 ->
            {error, nil};

        _ ->
            One = bigi_ffi:from(1),
            Two = bigi_ffi:from(2),
            Three = bigi_ffi:from(3),
            K = bigi_ffi:subtract(bigi_ffi:multiply(E, D), One),
            {T, R} = factor_out_twos(K, Two, 0),
            G_bytes = kryptos_ffi:random_bytes(Byte_len),
            G_raw@1 = case bigi_ffi:from_bytes(G_bytes, big_endian, unsigned) of
                {ok, G_raw} -> G_raw;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/rsa_crt"/utf8>>,
                                function => <<"factor_rsa_modulus"/utf8>>,
                                line => 142,
                                value => _assert_fail,
                                start => 3871,
                                'end' => 3957,
                                pattern_start => 3882,
                                pattern_end => 3891})
            end,
            N_minus_3 = bigi_ffi:subtract(N, Three),
            G = bigi_ffi:add(bigi_ffi:modulo(G_raw@1, N_minus_3), Two),
            gleam@result:'try'(
                mod_pow(G, R, N, Byte_len),
                fun(X) -> case try_factor(N, T, X, Byte_len) of
                        {ok, {P, Q}} ->
                            {ok, {P, Q}};

                        {error, nil} ->
                            factor_rsa_modulus(
                                N,
                                E,
                                D,
                                Byte_len,
                                Attempts_left - 1
                            )
                    end end
            )
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 251).
?DOC(false).
-spec extended_gcd_loop(
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int(),
    bigi:big_int()
) -> {bigi:big_int(), bigi:big_int(), bigi:big_int()}.
extended_gcd_loop(Old_r, R, Old_s, S, Old_t, T) ->
    Zero = bigi_ffi:from(0),
    case R =:= Zero of
        true ->
            {Old_r, Old_s, Old_t};

        false ->
            Q@1 = case bigi:floor_divide(Old_r, R) of
                {ok, Q} -> Q;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/internal/rsa_crt"/utf8>>,
                                function => <<"extended_gcd_loop"/utf8>>,
                                line => 263,
                                value => _assert_fail,
                                start => 6764,
                                'end' => 6829,
                                pattern_start => 6775,
                                pattern_end => 6780})
            end,
            New_r = bigi_ffi:subtract(Old_r, bigi_ffi:multiply(Q@1, R)),
            New_s = bigi_ffi:subtract(Old_s, bigi_ffi:multiply(Q@1, S)),
            New_t = bigi_ffi:subtract(Old_t, bigi_ffi:multiply(Q@1, T)),
            extended_gcd_loop(R, New_r, S, New_s, T, New_t)
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 233).
?DOC(false).
-spec mod_inverse(bigi:big_int(), bigi:big_int()) -> {ok, bigi:big_int()} |
    {error, nil}.
mod_inverse(A, Mod) ->
    Zero = bigi_ffi:from(0),
    One = bigi_ffi:from(1),
    {Old_r, Old_s, _} = extended_gcd_loop(A, Mod, One, Zero, Zero, One),
    case Old_r =:= One of
        true ->
            Result = bigi_ffi:modulo(Old_s, Mod),
            case bigi_ffi:compare(Result, Zero) =:= lt of
                true ->
                    {ok, bigi_ffi:add(Result, Mod)};

                false ->
                    {ok, Result}
            end;

        false ->
            {error, nil}
    end.

-file("src/kryptos/internal/rsa_crt.gleam", 12).
?DOC(false).
-spec compute_crt_params(bitstring(), bitstring(), bitstring()) -> {ok,
        {bitstring(), bitstring(), bitstring(), bitstring(), bitstring()}} |
    {error, nil}.
compute_crt_params(N_bytes, E_bytes, D_bytes) ->
    gleam@result:'try'(
        bigi_ffi:from_bytes(N_bytes, big_endian, unsigned),
        fun(N) ->
            gleam@result:'try'(
                bigi_ffi:from_bytes(E_bytes, big_endian, unsigned),
                fun(E) ->
                    gleam@result:'try'(
                        bigi_ffi:from_bytes(D_bytes, big_endian, unsigned),
                        fun(D) ->
                            validate_components(
                                N,
                                E,
                                D,
                                fun() ->
                                    Byte_len = erlang:byte_size(N_bytes),
                                    gleam@result:'try'(
                                        factor_rsa_modulus(
                                            N,
                                            E,
                                            D,
                                            Byte_len,
                                            500
                                        ),
                                        fun(_use0) ->
                                            {P, Q} = _use0,
                                            One = bigi_ffi:from(1),
                                            Dp = bigi_ffi:modulo(
                                                D,
                                                bigi_ffi:subtract(P, One)
                                            ),
                                            Dq = bigi_ffi:modulo(
                                                D,
                                                bigi_ffi:subtract(Q, One)
                                            ),
                                            gleam@result:'try'(
                                                mod_inverse(Q, P),
                                                fun(Qi) ->
                                                    gleam@result:'try'(
                                                        to_bytes_trimmed(
                                                            P,
                                                            Byte_len
                                                        ),
                                                        fun(P_bytes) ->
                                                            gleam@result:'try'(
                                                                to_bytes_trimmed(
                                                                    Q,
                                                                    Byte_len
                                                                ),
                                                                fun(Q_bytes) ->
                                                                    gleam@result:'try'(
                                                                        to_bytes_trimmed(
                                                                            Dp,
                                                                            Byte_len
                                                                        ),
                                                                        fun(
                                                                            Dp_bytes
                                                                        ) ->
                                                                            gleam@result:'try'(
                                                                                to_bytes_trimmed(
                                                                                    Dq,
                                                                                    Byte_len
                                                                                ),
                                                                                fun(
                                                                                    Dq_bytes
                                                                                ) ->
                                                                                    gleam@result:'try'(
                                                                                        to_bytes_trimmed(
                                                                                            Qi,
                                                                                            Byte_len
                                                                                        ),
                                                                                        fun(
                                                                                            Qi_bytes
                                                                                        ) ->
                                                                                            {ok,
                                                                                                {P_bytes,
                                                                                                    Q_bytes,
                                                                                                    Dp_bytes,
                                                                                                    Dq_bytes,
                                                                                                    Qi_bytes}}
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
