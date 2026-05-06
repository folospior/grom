-module(kryptos@hash).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/hash.gleam").
-export([shake_128/1, shake_256/1, algorithm_name/1, byte_size/1, new/1, update/2, final/1, is_supported/1]).
-export_type([hash_algorithm/0, hasher/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Cryptographic hash functions.\n"
    "\n"
    " Hash functions take arbitrary input data and produce a fixed-size digest.\n"
    " Use these for data integrity verification, fingerprinting, and as building\n"
    " blocks for other cryptographic constructs like HMAC.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(h) = hash.new(hash.Sha256)\n"
    " let digest = h |> hash.update(<<\"hello\":utf8>>) |> hash.final()\n"
    " ```\n"
).

-type hash_algorithm() :: blake2b |
    blake2s |
    md5 |
    sha1 |
    sha256 |
    sha384 |
    sha512 |
    sha512x224 |
    sha512x256 |
    sha3x224 |
    sha3x256 |
    sha3x384 |
    sha3x512 |
    {shake128, integer()} |
    {shake256, integer()}.

-type hasher() :: any().

-file("src/kryptos/hash.gleam", 57).
?DOC(
    " Creates a SHAKE128 hash algorithm with the given output length in bytes.\n"
    "\n"
    " The output length must be greater than zero.\n"
).
-spec shake_128(integer()) -> {ok, hash_algorithm()} | {error, nil}.
shake_128(Length) ->
    case Length > 0 of
        true ->
            {ok, {shake128, Length}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/hash.gleam", 67).
?DOC(
    " Creates a SHAKE256 hash algorithm with the given output length in bytes.\n"
    "\n"
    " The output length must be greater than zero.\n"
).
-spec shake_256(integer()) -> {ok, hash_algorithm()} | {error, nil}.
shake_256(Length) ->
    case Length > 0 of
        true ->
            {ok, {shake256, Length}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/hash.gleam", 75).
?DOC(false).
-spec algorithm_name(hash_algorithm()) -> binary().
algorithm_name(Algorithm) ->
    case Algorithm of
        blake2b ->
            <<"blake2b512"/utf8>>;

        blake2s ->
            <<"blake2s256"/utf8>>;

        md5 ->
            <<"md5"/utf8>>;

        sha1 ->
            <<"sha1"/utf8>>;

        sha256 ->
            <<"sha256"/utf8>>;

        sha384 ->
            <<"sha384"/utf8>>;

        sha512 ->
            <<"sha512"/utf8>>;

        sha512x224 ->
            <<"sha512-224"/utf8>>;

        sha512x256 ->
            <<"sha512-256"/utf8>>;

        sha3x224 ->
            <<"sha3-224"/utf8>>;

        sha3x256 ->
            <<"sha3-256"/utf8>>;

        sha3x384 ->
            <<"sha3-384"/utf8>>;

        sha3x512 ->
            <<"sha3-512"/utf8>>;

        {shake128, _} ->
            <<"shake128"/utf8>>;

        {shake256, _} ->
            <<"shake256"/utf8>>
    end.

-file("src/kryptos/hash.gleam", 96).
?DOC(" Returns the output size in bytes for a hash algorithm.\n").
-spec byte_size(hash_algorithm()) -> integer().
byte_size(Algorithm) ->
    case Algorithm of
        blake2b ->
            64;

        blake2s ->
            32;

        md5 ->
            16;

        sha1 ->
            20;

        sha256 ->
            32;

        sha384 ->
            48;

        sha512 ->
            64;

        sha512x224 ->
            28;

        sha512x256 ->
            32;

        sha3x224 ->
            28;

        sha3x256 ->
            32;

        sha3x384 ->
            48;

        sha3x512 ->
            64;

        {shake128, Output_length} ->
            Output_length;

        {shake256, Output_length@1} ->
            Output_length@1
    end.

-file("src/kryptos/hash.gleam", 125).
?DOC(
    " Creates a new hasher for incremental hashing.\n"
    "\n"
    " Use this when you need to hash data in chunks, such as when streaming\n"
    " or when the full input isn't available at once.\n"
).
-spec new(hash_algorithm()) -> {ok, hasher()} | {error, nil}.
new(Algorithm) ->
    case Algorithm of
        {shake128, Output_length} when Output_length =< 0 ->
            {error, nil};

        {shake256, Output_length} when Output_length =< 0 ->
            {error, nil};

        _ ->
            kryptos_ffi:hash_new(Algorithm)
    end.

-file("src/kryptos/hash.gleam", 142).
?DOC(
    " Adds data to an in-progress hash computation.\n"
    "\n"
    " Can be called multiple times to incrementally hash data.\n"
).
-spec update(hasher(), bitstring()) -> hasher().
update(Hasher, Data) ->
    kryptos_ffi:hash_update(Hasher, Data).

-file("src/kryptos/hash.gleam", 149).
?DOC(
    " Finalizes the hash computation and returns the digest.\n"
    "\n"
    " After calling this function, the hasher should not be reused.\n"
).
-spec final(hasher()) -> bitstring().
final(Hasher) ->
    kryptos_ffi:hash_final(Hasher).

-file("src/kryptos/hash.gleam", 155).
?DOC(
    " Checks if a hash algorithm is supported by the current runtime.\n"
    "\n"
    " Some algorithms may not be available depending on the platform or\n"
    " OpenSSL/crypto library version.\n"
).
-spec is_supported(hash_algorithm()) -> boolean().
is_supported(Algorithm) ->
    case new(Algorithm) of
        {ok, _} ->
            true;

        {error, _} ->
            false
    end.
