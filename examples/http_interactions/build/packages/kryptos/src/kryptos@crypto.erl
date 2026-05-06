-module(kryptos@crypto).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/crypto.gleam").
-export([hash/2, hmac/3, hkdf/5, concat_kdf/4, pbkdf2/5, random_bytes/1, random_uuid/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Convenience wrappers for hashing, key derivation, random bytes, and constant-time comparison.\n"
    "\n"
    " - One-shot hashing via `hash()` and HMAC via `hmac()`\n"
    " - Key derivation: HKDF (RFC 5869), PBKDF2 (RFC 8018), Concat KDF (NIST SP 800-56A)\n"
    " - Random bytes via `random_bytes()` and UUID v4 via `random_uuid()`\n"
    " - Constant-time comparison via `constant_time_equal()`\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/crypto\n"
    "\n"
    " // Generate 32 random bytes (suitable for a 256-bit key)\n"
    " let key = crypto.random_bytes(32)\n"
    " ```\n"
).

-file("src/kryptos/crypto.gleam", 41).
?DOC(
    " Computes the hash digest of input data in one call.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/crypto\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(digest) = crypto.hash(hash.Sha256, <<\"hello\":utf8>>)\n"
    " ```\n"
).
-spec hash(kryptos@hash:hash_algorithm(), bitstring()) -> {ok, bitstring()} |
    {error, nil}.
hash(Algorithm, Data) ->
    gleam@result:'try'(
        kryptos@hash:new(Algorithm),
        fun(Hasher) -> _pipe = Hasher,
            _pipe@1 = kryptos_ffi:hash_update(_pipe, Data),
            _pipe@2 = kryptos_ffi:hash_final(_pipe@1),
            {ok, _pipe@2} end
    ).

-file("src/kryptos/crypto.gleam", 59).
?DOC(
    " Computes the HMAC of input data in one call.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/crypto\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(mac) = crypto.hmac(hash.Sha256, key: <<\"secret\":utf8>>, data: <<\"hello\":utf8>>)\n"
    " ```\n"
).
-spec hmac(kryptos@hash:hash_algorithm(), bitstring(), bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
hmac(Algorithm, Key, Data) ->
    gleam@result:'try'(
        kryptos@hmac:new(Algorithm, Key),
        fun(Hmac) -> _pipe = Hmac,
            _pipe@1 = crypto:mac_update(_pipe, Data),
            _pipe@2 = crypto:mac_final(_pipe@1),
            {ok, _pipe@2} end
    ).

-file("src/kryptos/crypto.gleam", 91).
?DOC(
    " Derives key material using HKDF (RFC 5869).\n"
    "\n"
    " HKDF combines an extract-then-expand approach to derive cryptographically\n"
    " strong key material from input key material. The algorithm must be\n"
    " HMAC-compatible. Maximum output length is 255 * hash_length bytes.\n"
    " A `None` salt uses hash-length zeros per RFC 5869.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import gleam/option\n"
    " import kryptos/crypto\n"
    " import kryptos/hash\n"
    "\n"
    " let ikm = crypto.random_bytes(32)\n"
    " let salt = option.Some(crypto.random_bytes(16))\n"
    " let assert Ok(derived) =\n"
    "   crypto.hkdf(hash.Sha256, input: ikm, salt:, info: <<\"app\":utf8>>, length: 32)\n"
    " ```\n"
).
-spec hkdf(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    gleam@option:option(bitstring()),
    bitstring(),
    integer()
) -> {ok, bitstring()} | {error, nil}.
hkdf(Algorithm, Ikm, Salt, Info, Length) ->
    Hash_len = kryptos@hash:byte_size(Algorithm),
    Max_length = 255 * Hash_len,
    Salt_bytes = gleam@option:lazy_unwrap(
        Salt,
        fun() -> _pipe = gleam@list:repeat(<<0>>, Hash_len),
            gleam_stdlib:bit_array_concat(_pipe) end
    ),
    case {kryptos@hmac:supported_hash(Algorithm),
        Length > 0,
        Length =< Max_length} of
        {true, true, true} ->
            kryptos@internal@hkdf:do_derive(
                Algorithm,
                Ikm,
                Salt_bytes,
                Info,
                Length
            );

        {_, _, _} ->
            {error, nil}
    end.

-file("src/kryptos/crypto.gleam", 150).
-spec concat_kdf_supported_hash(kryptos@hash:hash_algorithm()) -> boolean().
concat_kdf_supported_hash(Algorithm) ->
    case Algorithm of
        sha1 ->
            true;

        sha256 ->
            true;

        sha384 ->
            true;

        sha512 ->
            true;

        sha512x224 ->
            true;

        sha512x256 ->
            true;

        sha3x224 ->
            true;

        sha3x256 ->
            true;

        sha3x384 ->
            true;

        sha3x512 ->
            true;

        blake2b ->
            false;

        blake2s ->
            false;

        md5 ->
            false;

        {shake128, _} ->
            false;

        {shake256, _} ->
            false
    end.

-file("src/kryptos/crypto.gleam", 128).
?DOC(
    " Derives key material using Concat KDF (NIST SP 800-56A). Also called the\n"
    " single-step or one-step key derivation function.\n"
    "\n"
    " Concat KDF uses a hash function to derive key material from a shared secret\n"
    " and context-specific information. Supports SHA-1, SHA-2, and SHA-3 family\n"
    " algorithms. Maximum output length is 255 * hash_length bytes.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/crypto\n"
    " import kryptos/hash\n"
    "\n"
    " let secret = crypto.random_bytes(32)\n"
    " let assert Ok(derived) =\n"
    "   crypto.concat_kdf(hash.Sha256, secret:, info: <<\"context\":utf8>>, length: 32)\n"
    " ```\n"
).
-spec concat_kdf(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    integer()
) -> {ok, bitstring()} | {error, nil}.
concat_kdf(Algorithm, Secret, Info, Length) ->
    Max_length = 255 * kryptos@hash:byte_size(Algorithm),
    case {concat_kdf_supported_hash(Algorithm),
        Length > 0,
        Length =< Max_length} of
        {true, true, true} ->
            kryptos@internal@concat_kdf:derive_loop(
                Algorithm,
                Secret,
                Info,
                Length,
                1,
                gleam@bytes_tree:new()
            );

        {_, _, _} ->
            {error, nil}
    end.

-file("src/kryptos/crypto.gleam", 199).
?DOC(
    " Derives key material from a password using PBKDF2 (RFC 8018).\n"
    "\n"
    " PBKDF2 applies a pseudorandom function (HMAC) to derive keys from passwords.\n"
    " It is designed to be computationally expensive to resist brute-force attacks.\n"
    "\n"
    " **Note:** For password hashing in production applications, consider using\n"
    " [Argus](https://github.com/Pevensie/argus) which provides Argon2 an\n"
    " algorithm specifically designed for password storage. PBKDF2 is primarily\n"
    " useful for interoperability with systems that require it.\n"
    "\n"
    " The algorithm must be HMAC-compatible. SHA-256 or stronger is recommended;\n"
    " MD5 and SHA-1 are weak for password hashing.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/crypto\n"
    " import kryptos/hash\n"
    "\n"
    " let salt = crypto.random_bytes(16)\n"
    " let assert Ok(derived) =\n"
    "   crypto.pbkdf2(\n"
    "     hash.Sha256,\n"
    "     password: <<\"hunter2\":utf8>>,\n"
    "     salt:,\n"
    "     iterations: 100_000,\n"
    "     length: 32,\n"
    "   )\n"
    " ```\n"
).
-spec pbkdf2(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    integer(),
    integer()
) -> {ok, bitstring()} | {error, nil}.
pbkdf2(Algorithm, Password, Salt, Iterations, Length) ->
    case {kryptos@hmac:supported_hash(Algorithm), Iterations > 0, Length > 0} of
        {true, true, true} ->
            kryptos_ffi:pbkdf2_derive(
                Algorithm,
                Password,
                Salt,
                Iterations,
                Length
            );

        {_, _, _} ->
            {error, nil}
    end.

-file("src/kryptos/crypto.gleam", 219).
?DOC(
    " Generates cryptographically secure random bytes using the platform's\n"
    " cryptographically secure random number generator.\n"
    "\n"
    " A negative length returns an empty `BitArray`.\n"
).
-spec random_bytes(integer()) -> bitstring().
random_bytes(Length) ->
    kryptos_ffi:random_bytes(Length).

-file("src/kryptos/crypto.gleam", 223).
?DOC(" Generates a cryptographically secure random UUID v4.\n").
-spec random_uuid() -> binary().
random_uuid() ->
    {A@1, B@1, C_raw@1, D_raw@1, E@1} = case kryptos_ffi:random_bytes(16) of
        <<A:32, B:16, C_raw:16, D_raw:16, E:48>> -> {A, B, C_raw, D_raw, E};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/crypto"/utf8>>,
                        function => <<"random_uuid"/utf8>>,
                        line => 224,
                        value => _assert_fail,
                        start => 6402,
                        'end' => 6472,
                        pattern_start => 6413,
                        pattern_end => 6453})
    end,
    C = erlang:'bor'(erlang:'band'(C_raw@1, 16#0FFF), 16#4000),
    D = erlang:'bor'(erlang:'band'(D_raw@1, 16#3FFF), 16#8000),
    Uuid = <<<<<<<<<<<<<<<<(gleam@string:pad_start(
                                        gleam@int:to_base16(A@1),
                                        8,
                                        <<"0"/utf8>>
                                    ))/binary,
                                    "-"/utf8>>/binary,
                                (gleam@string:pad_start(
                                    gleam@int:to_base16(B@1),
                                    4,
                                    <<"0"/utf8>>
                                ))/binary>>/binary,
                            "-"/utf8>>/binary,
                        (gleam@string:pad_start(
                            gleam@int:to_base16(C),
                            4,
                            <<"0"/utf8>>
                        ))/binary>>/binary,
                    "-"/utf8>>/binary,
                (gleam@string:pad_start(gleam@int:to_base16(D), 4, <<"0"/utf8>>))/binary>>/binary,
            "-"/utf8>>/binary,
        (gleam@string:pad_start(gleam@int:to_base16(E@1), 12, <<"0"/utf8>>))/binary>>,
    string:lowercase(Uuid).
