-module(kryptos@xdh).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/xdh.gleam").
-export([key_size/1, generate_key_pair/1, compute_shared_secret/2, from_bytes/2, to_bytes/1, public_key_from_bytes/2, public_key_to_bytes/1, from_pem/1, from_der/1, to_pem/1, to_der/1, public_key_from_pem/1, public_key_from_der/1, public_key_to_pem/1, public_key_to_der/1, public_key_from_private_key/1, curve/1, public_key_curve/1]).
-export_type([private_key/0, public_key/0, curve/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " X25519 and X448 (XDH) key agreement.\n"
    "\n"
    " XDH provides Diffie-Hellman key agreement using Montgomery curves X25519\n"
    " and X448. These curves are designed specifically for key agreement and\n"
    " offer excellent performance with strong security properties.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/xdh\n"
    "\n"
    " // Alice generates a key pair\n"
    " let #(alice_private, alice_public) = xdh.generate_key_pair(xdh.X25519)\n"
    "\n"
    " // Bob generates a key pair\n"
    " let #(bob_private, bob_public) = xdh.generate_key_pair(xdh.X25519)\n"
    "\n"
    " // Both compute the same shared secret\n"
    " let assert Ok(alice_shared) = xdh.compute_shared_secret(alice_private, bob_public)\n"
    " let assert Ok(bob_shared) = xdh.compute_shared_secret(bob_private, alice_public)\n"
    " // alice_shared == bob_shared\n"
    " ```\n"
).

-type private_key() :: any().

-type public_key() :: any().

-type curve() :: x25519 | x448.

-file("src/kryptos/xdh.gleam", 42).
?DOC(" Returns the key size in bytes for the given curve.\n").
-spec key_size(curve()) -> integer().
key_size(Curve) ->
    case Curve of
        x25519 ->
            32;

        x448 ->
            56
    end.

-file("src/kryptos/xdh.gleam", 52).
?DOC(" Generates a new XDH key pair.\n").
-spec generate_key_pair(curve()) -> {private_key(), public_key()}.
generate_key_pair(Curve) ->
    kryptos_ffi:xdh_generate_key_pair(Curve).

-file("src/kryptos/xdh.gleam", 78).
-spec is_all_zeros(bitstring()) -> boolean().
is_all_zeros(Bytes) ->
    case Bytes of
        <<>> ->
            true;

        <<0, Rest/binary>> ->
            is_all_zeros(Rest);

        _ ->
            false
    end.

-file("src/kryptos/xdh.gleam", 64).
?DOC(
    " Computes a shared secret using XDH key agreement.\n"
    "\n"
    " Both parties compute the same shared secret by combining their private key\n"
    " with the other party's public key.\n"
    "\n"
    " Returns `Error(Nil)` if the keys use different curves, the result is an\n"
    " all-zero shared secret (low-order point attack), or another error occurs.\n"
    "\n"
    " The raw shared secret should be passed through a KDF (like HKDF) before\n"
    " use as a symmetric key.\n"
).
-spec compute_shared_secret(private_key(), public_key()) -> {ok, bitstring()} |
    {error, nil}.
compute_shared_secret(Private_key, Peer_public_key) ->
    gleam@result:'try'(
        kryptos_ffi:xdh_compute_shared_secret(Private_key, Peer_public_key),
        fun(Shared) -> case is_all_zeros(Shared) of
                true ->
                    {error, nil};

                false ->
                    {ok, Shared}
            end end
    ).

-file("src/kryptos/xdh.gleam", 103).
?DOC(
    " Imports a private key from raw bytes.\n"
    "\n"
    " The bytes should be the raw private key scalar:\n"
    " - X25519: 32 bytes\n"
    " - X448: 56 bytes\n"
    "\n"
    " Returns the private key and its corresponding public key, or `Error(Nil)`\n"
    " if the bytes are invalid.\n"
).
-spec from_bytes(curve(), bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_bytes(Curve, Private_bytes) ->
    kryptos_ffi:xdh_private_key_from_bytes(Curve, Private_bytes).

-file("src/kryptos/xdh.gleam", 115).
?DOC(
    " Exports a private key to raw bytes.\n"
    "\n"
    " Returns the raw private key scalar:\n"
    " - X25519: 32 bytes\n"
    " - X448: 56 bytes\n"
).
-spec to_bytes(private_key()) -> bitstring().
to_bytes(Key) ->
    kryptos_ffi:xdh_private_key_to_bytes(Key).

-file("src/kryptos/xdh.gleam", 126).
?DOC(
    " Imports a public key from raw bytes.\n"
    "\n"
    " The bytes should be the raw public key point:\n"
    " - X25519: 32 bytes\n"
    " - X448: 56 bytes\n"
    "\n"
    " Returns the public key or `Error(Nil)` if the bytes are invalid.\n"
).
-spec public_key_from_bytes(curve(), bitstring()) -> {ok, public_key()} |
    {error, nil}.
public_key_from_bytes(Curve, Public_bytes) ->
    kryptos_ffi:xdh_public_key_from_bytes(Curve, Public_bytes).

-file("src/kryptos/xdh.gleam", 138).
?DOC(
    " Exports a public key to raw bytes.\n"
    "\n"
    " Returns the raw public key point:\n"
    " - X25519: 32 bytes\n"
    " - X448: 56 bytes\n"
).
-spec public_key_to_bytes(public_key()) -> bitstring().
public_key_to_bytes(Key) ->
    kryptos_ffi:xdh_public_key_to_bytes(Key).

-file("src/kryptos/xdh.gleam", 145).
?DOC(
    " Imports an XDH private key from PEM-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_pem(binary()) -> {ok, {private_key(), public_key()}} | {error, nil}.
from_pem(Pem) ->
    kryptos_ffi:xdh_import_private_key_pem(Pem).

-file("src/kryptos/xdh.gleam", 152).
?DOC(
    " Imports an XDH private key from DER-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_der(bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_der(Der) ->
    kryptos_ffi:xdh_import_private_key_der(Der).

-file("src/kryptos/xdh.gleam", 157).
?DOC(
    " Exports an XDH private key to PEM format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_pem(private_key()) -> {ok, binary()} | {error, nil}.
to_pem(Key) ->
    _pipe = kryptos_ffi:xdh_export_private_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/xdh.gleam", 170).
?DOC(
    " Exports an XDH private key to DER format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_der(private_key()) -> {ok, bitstring()} | {error, nil}.
to_der(Key) ->
    kryptos_ffi:xdh_export_private_key_der(Key).

-file("src/kryptos/xdh.gleam", 177).
?DOC(
    " Imports an XDH public key from PEM-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_pem(binary()) -> {ok, public_key()} | {error, nil}.
public_key_from_pem(Pem) ->
    kryptos_ffi:xdh_import_public_key_pem(Pem).

-file("src/kryptos/xdh.gleam", 184).
?DOC(
    " Imports an XDH public key from DER-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_der(bitstring()) -> {ok, public_key()} | {error, nil}.
public_key_from_der(Der) ->
    kryptos_ffi:xdh_import_public_key_der(Der).

-file("src/kryptos/xdh.gleam", 189).
?DOC(
    " Exports an XDH public key to PEM format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_pem(public_key()) -> {ok, binary()} | {error, nil}.
public_key_to_pem(Key) ->
    _pipe = kryptos_ffi:xdh_export_public_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/xdh.gleam", 203).
?DOC(
    " Exports an XDH public key to DER format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_der(public_key()) -> {ok, bitstring()} | {error, nil}.
public_key_to_der(Key) ->
    kryptos_ffi:xdh_export_public_key_der(Key).

-file("src/kryptos/xdh.gleam", 208).
?DOC(" Derives the public key from an XDH private key.\n").
-spec public_key_from_private_key(private_key()) -> public_key().
public_key_from_private_key(Key) ->
    kryptos_ffi:xdh_public_key_from_private(Key).

-file("src/kryptos/xdh.gleam", 213).
?DOC(" Returns the curve for an XDH private key.\n").
-spec curve(private_key()) -> curve().
curve(Key) ->
    kryptos_ffi:xdh_private_key_curve(Key).

-file("src/kryptos/xdh.gleam", 218).
?DOC(" Returns the curve for an XDH public key.\n").
-spec public_key_curve(public_key()) -> curve().
public_key_curve(Key) ->
    kryptos_ffi:xdh_public_key_curve(Key).
