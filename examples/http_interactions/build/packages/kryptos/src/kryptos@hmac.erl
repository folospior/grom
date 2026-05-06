-module(kryptos@hmac).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/hmac.gleam").
-export([supported_hash/1, new/2, update/2, final/1, verify/4]).
-export_type([hmac/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Hash-based Message Authentication Code (HMAC).\n"
    "\n"
    " HMAC provides message authentication using a cryptographic hash function\n"
    " combined with a secret key. Use it to verify both data integrity and\n"
    " authenticity.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/hmac\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(h) = hmac.new(hash.Sha256, <<\"secret key\":utf8>>)\n"
    " let mac = h |> hmac.update(<<\"hello\":utf8>>) |> hmac.final()\n"
    " ```\n"
).

-type hmac() :: any().

-file("src/kryptos/hmac.gleam", 22).
?DOC(" Checks if a hash algorithm is supported for HMAC operations.\n").
-spec supported_hash(kryptos@hash:hash_algorithm()) -> boolean().
supported_hash(Algorithm) ->
    case Algorithm of
        md5 ->
            true;

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

        blake2b ->
            false;

        blake2s ->
            false;

        sha3x224 ->
            false;

        sha3x256 ->
            false;

        sha3x384 ->
            false;

        sha3x512 ->
            false;

        {shake128, _} ->
            false;

        {shake256, _} ->
            false
    end.

-file("src/kryptos/hmac.gleam", 51).
?DOC(
    " Creates a new HMAC for incremental authentication.\n"
    "\n"
    " Use this when you need to authenticate data in chunks, such as when streaming\n"
    " or when the full input isn't available at once.\n"
).
-spec new(kryptos@hash:hash_algorithm(), bitstring()) -> {ok, hmac()} |
    {error, nil}.
new(Algorithm, Key) ->
    case supported_hash(Algorithm) of
        true ->
            kryptos_ffi:hmac_new(Algorithm, Key);

        false ->
            {error, nil}
    end.

-file("src/kryptos/hmac.gleam", 67).
?DOC(
    " Adds data to an in-progress HMAC computation.\n"
    "\n"
    " Can be called multiple times to incrementally authenticate data.\n"
).
-spec update(hmac(), bitstring()) -> hmac().
update(Hmac, Data) ->
    crypto:mac_update(Hmac, Data).

-file("src/kryptos/hmac.gleam", 74).
?DOC(
    " Finalizes the HMAC computation and returns the authentication code.\n"
    "\n"
    " After calling this function, the HMAC should not be reused.\n"
).
-spec final(hmac()) -> bitstring().
final(Hmac) ->
    crypto:mac_final(Hmac).

-file("src/kryptos/hmac.gleam", 80).
?DOC(
    " Verifies that a MAC matches the expected value using constant-time comparison.\n"
    "\n"
    " Computes the HMAC and compares it to the expected value in constant time\n"
    " to prevent timing attacks.\n"
).
-spec verify(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    bitstring()
) -> {ok, boolean()} | {error, nil}.
verify(Algorithm, Key, Data, Expected) ->
    gleam@result:'try'(
        new(Algorithm, Key),
        fun(Hmac_state) ->
            Actual = begin
                _pipe = Hmac_state,
                _pipe@1 = crypto:mac_update(_pipe, Data),
                crypto:mac_final(_pipe@1)
            end,
            {ok, kryptos_ffi:constant_time_equal(Actual, Expected)}
        end
    ).
