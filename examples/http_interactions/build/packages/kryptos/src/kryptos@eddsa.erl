-module(kryptos@eddsa).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/eddsa.gleam").
-export([key_size/1, generate_key_pair/1, sign/2, verify/3, from_bytes/2, to_bytes/1, public_key_from_bytes/2, public_key_to_bytes/1, from_pem/1, from_der/1, to_pem/1, to_der/1, public_key_from_pem/1, public_key_from_der/1, public_key_to_pem/1, public_key_to_der/1, public_key_from_private_key/1, curve/1, public_key_curve/1]).
-export_type([private_key/0, public_key/0, curve/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Edwards-curve Digital Signature Algorithm (EdDSA).\n"
    "\n"
    " EdDSA provides digital signatures using Edwards curves Ed25519 and Ed448.\n"
    " Unlike ECDSA, EdDSA has built-in hashing (SHA-512 for Ed25519, SHAKE256\n"
    " for Ed448) and produces deterministic signatures.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/eddsa\n"
    "\n"
    " let #(private_key, public_key) = eddsa.generate_key_pair(eddsa.Ed25519)\n"
    " let message = <<\"hello world\":utf8>>\n"
    " let signature = eddsa.sign(private_key, message)\n"
    " let valid = eddsa.verify(public_key, message, signature)\n"
    " // valid == True\n"
    " ```\n"
).

-type private_key() :: any().

-type public_key() :: any().

-type curve() :: ed25519 | ed448.

-file("src/kryptos/eddsa.gleam", 37).
?DOC(" Returns the key size in bytes for the given curve.\n").
-spec key_size(curve()) -> integer().
key_size(Curve) ->
    case Curve of
        ed25519 ->
            32;

        ed448 ->
            57
    end.

-file("src/kryptos/eddsa.gleam", 47).
?DOC(" Generates a new EdDSA key pair.\n").
-spec generate_key_pair(curve()) -> {private_key(), public_key()}.
generate_key_pair(Curve) ->
    kryptos_ffi:eddsa_generate_key_pair(Curve).

-file("src/kryptos/eddsa.gleam", 56).
?DOC(
    " Signs a message using EdDSA.\n"
    "\n"
    " The message is hashed internally using the curve's built-in hash function\n"
    " (SHA-512 for Ed25519, SHAKE256 for Ed448). Signatures are deterministic:\n"
    " signing the same message with the same key always produces the same signature.\n"
).
-spec sign(private_key(), bitstring()) -> bitstring().
sign(Private_key, Message) ->
    kryptos_ffi:eddsa_sign(Private_key, Message).

-file("src/kryptos/eddsa.gleam", 61).
?DOC(" Verifies an EdDSA signature against a message.\n").
-spec verify(public_key(), bitstring(), bitstring()) -> boolean().
verify(Public_key, Message, Signature) ->
    kryptos_ffi:eddsa_verify(Public_key, Message, Signature).

-file("src/kryptos/eddsa.gleam", 77).
?DOC(
    " Imports a private key from raw bytes.\n"
    "\n"
    " The bytes should be the raw private key seed:\n"
    " - Ed25519: 32 bytes\n"
    " - Ed448: 57 bytes\n"
    "\n"
    " Returns the private key and its corresponding public key, or `Error(Nil)`\n"
    " if the bytes are invalid.\n"
).
-spec from_bytes(curve(), bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_bytes(Curve, Private_bytes) ->
    kryptos_ffi:eddsa_private_key_from_bytes(Curve, Private_bytes).

-file("src/kryptos/eddsa.gleam", 89).
?DOC(
    " Exports a private key to raw bytes.\n"
    "\n"
    " Returns the raw private key seed:\n"
    " - Ed25519: 32 bytes\n"
    " - Ed448: 57 bytes\n"
).
-spec to_bytes(private_key()) -> bitstring().
to_bytes(Key) ->
    kryptos_ffi:eddsa_private_key_to_bytes(Key).

-file("src/kryptos/eddsa.gleam", 106).
?DOC(
    " Imports a public key from raw bytes.\n"
    "\n"
    " The bytes should be the raw public key point:\n"
    " - Ed25519: 32 bytes\n"
    " - Ed448: 57 bytes\n"
    "\n"
    " Returns the public key or `Error(Nil)` if the bytes have an invalid length.\n"
    "\n"
    " **Security note:** This function only validates the byte length, not that the\n"
    " bytes encode a valid curve point or that the key is in the prime-order\n"
    " subgroup. Callers that accept public keys from untrusted sources should\n"
    " perform their own validation to reject small-order or invalid points, as\n"
    " such keys can allow trivial signature forgery.\n"
).
-spec public_key_from_bytes(curve(), bitstring()) -> {ok, public_key()} |
    {error, nil}.
public_key_from_bytes(Curve, Public_bytes) ->
    kryptos_ffi:eddsa_public_key_from_bytes(Curve, Public_bytes).

-file("src/kryptos/eddsa.gleam", 118).
?DOC(
    " Exports a public key to raw bytes.\n"
    "\n"
    " Returns the raw public key point:\n"
    " - Ed25519: 32 bytes\n"
    " - Ed448: 57 bytes\n"
).
-spec public_key_to_bytes(public_key()) -> bitstring().
public_key_to_bytes(Key) ->
    kryptos_ffi:eddsa_public_key_to_bytes(Key).

-file("src/kryptos/eddsa.gleam", 125).
?DOC(
    " Imports an EdDSA private key from PEM-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_pem(binary()) -> {ok, {private_key(), public_key()}} | {error, nil}.
from_pem(Pem) ->
    kryptos_ffi:eddsa_import_private_key_pem(Pem).

-file("src/kryptos/eddsa.gleam", 132).
?DOC(
    " Imports an EdDSA private key from DER-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_der(bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_der(Der) ->
    kryptos_ffi:eddsa_import_private_key_der(Der).

-file("src/kryptos/eddsa.gleam", 137).
?DOC(
    " Exports an EdDSA private key to PEM format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_pem(private_key()) -> {ok, binary()} | {error, nil}.
to_pem(Key) ->
    _pipe = kryptos_ffi:eddsa_export_private_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/eddsa.gleam", 150).
?DOC(
    " Exports an EdDSA private key to DER format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_der(private_key()) -> {ok, bitstring()} | {error, nil}.
to_der(Key) ->
    kryptos_ffi:eddsa_export_private_key_der(Key).

-file("src/kryptos/eddsa.gleam", 157).
?DOC(
    " Imports an EdDSA public key from PEM-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_pem(binary()) -> {ok, public_key()} | {error, nil}.
public_key_from_pem(Pem) ->
    kryptos_ffi:eddsa_import_public_key_pem(Pem).

-file("src/kryptos/eddsa.gleam", 164).
?DOC(
    " Imports an EdDSA public key from DER-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_der(bitstring()) -> {ok, public_key()} | {error, nil}.
public_key_from_der(Der) ->
    kryptos_ffi:eddsa_import_public_key_der(Der).

-file("src/kryptos/eddsa.gleam", 169).
?DOC(
    " Exports an EdDSA public key to PEM format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_pem(public_key()) -> {ok, binary()} | {error, nil}.
public_key_to_pem(Key) ->
    _pipe = kryptos_ffi:eddsa_export_public_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/eddsa.gleam", 183).
?DOC(
    " Exports an EdDSA public key to DER format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_der(public_key()) -> {ok, bitstring()} | {error, nil}.
public_key_to_der(Key) ->
    kryptos_ffi:eddsa_export_public_key_der(Key).

-file("src/kryptos/eddsa.gleam", 188).
?DOC(" Derives the public key from an EdDSA private key.\n").
-spec public_key_from_private_key(private_key()) -> public_key().
public_key_from_private_key(Key) ->
    kryptos_ffi:eddsa_public_key_from_private(Key).

-file("src/kryptos/eddsa.gleam", 193).
?DOC(" Returns the curve for an EdDSA private key.\n").
-spec curve(private_key()) -> curve().
curve(Key) ->
    kryptos_ffi:eddsa_private_key_curve(Key).

-file("src/kryptos/eddsa.gleam", 198).
?DOC(" Returns the curve for an EdDSA public key.\n").
-spec public_key_curve(public_key()) -> curve().
public_key_curve(Key) ->
    kryptos_ffi:eddsa_public_key_curve(Key).
