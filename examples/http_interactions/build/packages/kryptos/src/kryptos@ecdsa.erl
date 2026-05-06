-module(kryptos@ecdsa).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/ecdsa.gleam").
-export([sign/3, verify/4, der_to_rs/2, sign_rs/3, rs_to_der/2, verify_rs/4]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Elliptic Curve Digital Signature Algorithm (ECDSA).\n"
    "\n"
    " ECDSA provides digital signatures using elliptic curve cryptography,\n"
    " offering strong security with smaller key sizes compared to RSA.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdsa\n"
    " import kryptos/hash\n"
    "\n"
    " let #(private_key, public_key) = ec.generate_key_pair(ec.P256)\n"
    " let message = <<\"hello world\":utf8>>\n"
    " let signature = ecdsa.sign(private_key, message, hash.Sha256)\n"
    " let valid = ecdsa.verify(public_key, message, signature, hash.Sha256)\n"
    " // valid == True\n"
    " ```\n"
).

-file("src/kryptos/ecdsa.gleam", 36).
?DOC(
    " Signs a message using ECDSA with the specified hash algorithm.\n"
    "\n"
    " The message is hashed internally before signing. Returns a DER-encoded\n"
    " signature. Signatures may be non-deterministic depending on platform\n"
    " (Erlang uses random nonces, some platforms may use deterministic\n"
    " RFC 6979 nonces).\n"
).
-spec sign(kryptos@ec:private_key(), bitstring(), kryptos@hash:hash_algorithm()) -> bitstring().
sign(Private_key, Message, Hash) ->
    kryptos_ffi:ecdsa_sign(Private_key, Message, Hash).

-file("src/kryptos/ecdsa.gleam", 48).
?DOC(
    " Verifies an ECDSA signature against a message.\n"
    "\n"
    " The message is hashed internally before verification. The same hash\n"
    " algorithm used during signing must be used for verification.\n"
).
-spec verify(
    kryptos@ec:public_key(),
    bitstring(),
    bitstring(),
    kryptos@hash:hash_algorithm()
) -> boolean().
verify(Public_key, Message, Signature, Hash) ->
    kryptos_ffi:ecdsa_verify(Public_key, Message, Signature, Hash).

-file("src/kryptos/ecdsa.gleam", 128).
?DOC(
    " Converts a DER-encoded ECDSA signature to R||S format.\n"
    "\n"
    " R||S format concatenates the r and s integer values, each padded\n"
    " to the curve's coordinate size with leading zeros.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdsa\n"
    " import kryptos/hash\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let der_sig = ecdsa.sign(private_key, <<\"hello\":utf8>>, hash.Sha256)\n"
    " let assert Ok(rs_sig) = ecdsa.der_to_rs(der_sig, ec.P256)\n"
    " ```\n"
).
-spec der_to_rs(bitstring(), kryptos@ec:curve()) -> {ok, bitstring()} |
    {error, nil}.
der_to_rs(Der_sig, Curve) ->
    Coord_size = kryptos@ec:coordinate_size(Curve),
    gleam@result:'try'(
        kryptos@internal@der:parse_sequence(Der_sig),
        fun(_use0) ->
            {Content, Remaining} = _use0,
            gleam@bool:guard(
                erlang:byte_size(Remaining) /= 0,
                {error, nil},
                fun() ->
                    gleam@result:'try'(
                        kryptos@internal@der:parse_integer(Content),
                        fun(_use0@1) ->
                            {R_bytes, Remaining@1} = _use0@1,
                            gleam@result:'try'(
                                kryptos@internal@der:parse_integer(Remaining@1),
                                fun(_use0@2) ->
                                    {S_bytes, Remaining@2} = _use0@2,
                                    gleam@bool:guard(
                                        erlang:byte_size(Remaining@2) /= 0,
                                        {error, nil},
                                        fun() ->
                                            R = kryptos@internal@utils:strip_leading_zeros(
                                                R_bytes
                                            ),
                                            S = kryptos@internal@utils:strip_leading_zeros(
                                                S_bytes
                                            ),
                                            R_ok = erlang:byte_size(R) =< Coord_size,
                                            S_ok = erlang:byte_size(S) =< Coord_size,
                                            gleam@bool:guard(
                                                not R_ok orelse not S_ok,
                                                {error, nil},
                                                fun() ->
                                                    {ok,
                                                        gleam_stdlib:bit_array_concat(
                                                            [kryptos@internal@utils:pad_left(
                                                                    R,
                                                                    Coord_size
                                                                ),
                                                                kryptos@internal@utils:pad_left(
                                                                    S,
                                                                    Coord_size
                                                                )]
                                                        )}
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

-file("src/kryptos/ecdsa.gleam", 70).
?DOC(
    " Signs a message and returns the signature in R||S format (IEEE P1363).\n"
    "\n"
    " In R||S format, the signature is the concatenation of r and s values,\n"
    " each padded to the curve's coordinate size.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdsa\n"
    " import kryptos/hash\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let signature = ecdsa.sign_rs(private_key, <<\"hello\":utf8>>, hash.Sha256)\n"
    " ```\n"
).
-spec sign_rs(
    kryptos@ec:private_key(),
    bitstring(),
    kryptos@hash:hash_algorithm()
) -> bitstring().
sign_rs(Private_key, Message, Hash) ->
    Der_sig = kryptos_ffi:ecdsa_sign(Private_key, Message, Hash),
    Curve = kryptos_ffi:ec_private_key_curve(Private_key),
    Rs_sig@1 = case der_to_rs(Der_sig, Curve) of
        {ok, Rs_sig} -> Rs_sig;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/ecdsa"/utf8>>,
                        function => <<"sign_rs"/utf8>>,
                        line => 77,
                        value => _assert_fail,
                        start => 2399,
                        'end' => 2448,
                        pattern_start => 2410,
                        pattern_end => 2420})
    end,
    Rs_sig@1.

-file("src/kryptos/ecdsa.gleam", 173).
?DOC(
    " Converts an R||S format signature to DER encoding.\n"
    "\n"
    " The R||S input must be exactly 2 * coordinate_size bytes.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdsa\n"
    " import kryptos/hash\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let rs_sig = ecdsa.sign_rs(private_key, <<\"hello\":utf8>>, hash.Sha256)\n"
    " let assert Ok(der_sig) = ecdsa.rs_to_der(rs_sig, ec.P256)\n"
    " ```\n"
).
-spec rs_to_der(bitstring(), kryptos@ec:curve()) -> {ok, bitstring()} |
    {error, nil}.
rs_to_der(Rs, Curve) ->
    Coord_size = kryptos@ec:coordinate_size(Curve),
    case Rs of
        <<R:Coord_size/binary, S:Coord_size/binary>> ->
            gleam@result:'try'(
                kryptos@internal@der:encode_integer(R),
                fun(R_encoded) ->
                    gleam@result:'try'(
                        kryptos@internal@der:encode_integer(S),
                        fun(S_encoded) ->
                            kryptos@internal@der:encode_sequence(
                                gleam_stdlib:bit_array_concat(
                                    [R_encoded, S_encoded]
                                )
                            )
                        end
                    )
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/ecdsa.gleam", 99).
?DOC(
    " Verifies an R||S format signature against a message.\n"
    "\n"
    " The R||S format is the concatenation of r and s values, each padded\n"
    " to the curve's coordinate size.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdsa\n"
    " import kryptos/hash\n"
    "\n"
    " let #(private_key, public_key) = ec.generate_key_pair(ec.P256)\n"
    " let message = <<\"hello\":utf8>>\n"
    " let signature = ecdsa.sign_rs(private_key, message, hash.Sha256)\n"
    " let valid = ecdsa.verify_rs(public_key, message, signature, hash.Sha256)\n"
    " // valid == True\n"
    " ```\n"
).
-spec verify_rs(
    kryptos@ec:public_key(),
    bitstring(),
    bitstring(),
    kryptos@hash:hash_algorithm()
) -> boolean().
verify_rs(Public_key, Message, Signature, Hash) ->
    Curve = kryptos_ffi:ec_public_key_curve(Public_key),
    case rs_to_der(Signature, Curve) of
        {ok, Der_sig} ->
            kryptos_ffi:ecdsa_verify(Public_key, Message, Der_sig, Hash);

        {error, nil} ->
            false
    end.
