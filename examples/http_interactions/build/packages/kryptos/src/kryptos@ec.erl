-module(kryptos@ec).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/ec.gleam").
-export([coordinate_size/1, generate_key_pair/1, from_pem/1, from_der/1, to_pem/1, to_der/1, public_key_from_pem/1, public_key_from_der/1, public_key_from_raw_point/2, public_key_to_raw_point/1, public_key_to_pem/1, public_key_to_der/1, public_key_from_private_key/1, curve/1, public_key_curve/1, to_bytes/1, from_bytes/2]).
-export_type([private_key/0, public_key/0, curve/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Elliptic Curve Cryptography key generation and management.\n"
    "\n"
    " Key pair generation and management for elliptic curve cryptography,\n"
    " supporting standard NIST curves and secp256k1. EC keys can be used for\n"
    " both ECDSA signatures and ECDH key agreement.\n"
    "\n"
    " ## Key Generation\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    "\n"
    " let #(private_key, public_key) = ec.generate_key_pair(ec.P256)\n"
    " ```\n"
    "\n"
    " ## Import/Export\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let assert Ok(pem) = ec.to_pem(private_key)\n"
    " let assert Ok(#(imported_private, _)) = ec.from_pem(pem)\n"
    " ```\n"
).

-type private_key() :: any().

-type public_key() :: any().

-type curve() :: p256 | p384 | p521 | secp256k1.

-file("src/kryptos/ec.gleam", 49).
?DOC(
    " Returns the coordinate size in bytes for the given curve.\n"
    "\n"
    " This is the size of each coordinate (x or y) in an EC point.\n"
).
-spec coordinate_size(curve()) -> integer().
coordinate_size(Curve) ->
    case Curve of
        p256 ->
            32;

        secp256k1 ->
            32;

        p384 ->
            48;

        p521 ->
            66
    end.

-file("src/kryptos/ec.gleam", 60).
?DOC(" Generates a new elliptic curve key pair.\n").
-spec generate_key_pair(curve()) -> {private_key(), public_key()}.
generate_key_pair(Curve) ->
    kryptos_ffi:ec_generate_key_pair(Curve).

-file("src/kryptos/ec.gleam", 67).
?DOC(
    " Imports an EC private key from PEM-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_pem(binary()) -> {ok, {private_key(), public_key()}} | {error, nil}.
from_pem(Pem) ->
    kryptos_ffi:ec_import_private_key_pem(Pem).

-file("src/kryptos/ec.gleam", 74).
?DOC(
    " Imports an EC private key from DER-encoded data.\n"
    "\n"
    " The key must be in PKCS#8 format.\n"
).
-spec from_der(bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_der(Der) ->
    kryptos_ffi:ec_import_private_key_der(Der).

-file("src/kryptos/ec.gleam", 79).
?DOC(
    " Exports an EC private key to PEM format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_pem(private_key()) -> {ok, binary()} | {error, nil}.
to_pem(Key) ->
    _pipe = kryptos_ffi:ec_export_private_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/ec.gleam", 92).
?DOC(
    " Exports an EC private key to DER format.\n"
    "\n"
    " The key is exported in PKCS#8 format.\n"
).
-spec to_der(private_key()) -> {ok, bitstring()} | {error, nil}.
to_der(Key) ->
    kryptos_ffi:ec_export_private_key_der(Key).

-file("src/kryptos/ec.gleam", 99).
?DOC(
    " Imports an EC public key from PEM-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_pem(binary()) -> {ok, public_key()} | {error, nil}.
public_key_from_pem(Pem) ->
    kryptos_ffi:ec_import_public_key_pem(Pem).

-file("src/kryptos/ec.gleam", 106).
?DOC(
    " Imports an EC public key from DER-encoded data.\n"
    "\n"
    " The key must be in SPKI format.\n"
).
-spec public_key_from_der(bitstring()) -> {ok, public_key()} | {error, nil}.
public_key_from_der(Der) ->
    kryptos_ffi:ec_import_public_key_der(Der).

-file("src/kryptos/ec.gleam", 124).
?DOC(
    " Imports an EC public key from an uncompressed SEC1 point.\n"
    "\n"
    " The point must be in uncompressed format: `0x04 || x || y`\n"
    " where x and y are the coordinates padded to the curve's coordinate size.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    "\n"
    " let #(_private_key, public_key) = ec.generate_key_pair(ec.P256)\n"
    " let point = ec.public_key_to_raw_point(public_key)\n"
    " let assert Ok(imported) = ec.public_key_from_raw_point(ec.P256, point)\n"
    " ```\n"
).
-spec public_key_from_raw_point(curve(), bitstring()) -> {ok, public_key()} |
    {error, nil}.
public_key_from_raw_point(Curve, Point) ->
    kryptos_ffi:ec_public_key_from_raw_point(Curve, Point).

-file("src/kryptos/ec.gleam", 141).
?DOC(
    " Exports a public key to uncompressed SEC1 point format.\n"
    "\n"
    " Returns a BitArray in the format: `0x04 || X || Y` where X and Y are\n"
    " the coordinates of the public key point, each padded to the curve's\n"
    " coordinate size.\n"
    "\n"
    " If the key was imported with a compressed point format, it will be\n"
    " automatically decompressed.\n"
    "\n"
    " This is the inverse of `public_key_from_raw_point`.\n"
).
-spec public_key_to_raw_point(public_key()) -> bitstring().
public_key_to_raw_point(Key) ->
    kryptos_ffi:ec_public_key_to_raw_point(Key).

-file("src/kryptos/ec.gleam", 146).
?DOC(
    " Exports an EC public key to PEM format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_pem(public_key()) -> {ok, binary()} | {error, nil}.
public_key_to_pem(Key) ->
    _pipe = kryptos_ffi:ec_export_public_key_pem(Key),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/ec.gleam", 160).
?DOC(
    " Exports an EC public key to DER format.\n"
    "\n"
    " The key is exported in SPKI format.\n"
).
-spec public_key_to_der(public_key()) -> {ok, bitstring()} | {error, nil}.
public_key_to_der(Key) ->
    kryptos_ffi:ec_export_public_key_der(Key).

-file("src/kryptos/ec.gleam", 165).
?DOC(" Derives the public key from an EC private key.\n").
-spec public_key_from_private_key(private_key()) -> public_key().
public_key_from_private_key(Key) ->
    kryptos_ffi:ec_public_key_from_private(Key).

-file("src/kryptos/ec.gleam", 170).
?DOC(" Returns the curve for an EC private key.\n").
-spec curve(private_key()) -> curve().
curve(Key) ->
    kryptos_ffi:ec_private_key_curve(Key).

-file("src/kryptos/ec.gleam", 175).
?DOC(" Returns the curve for an EC public key.\n").
-spec public_key_curve(public_key()) -> curve().
public_key_curve(Key) ->
    kryptos_ffi:ec_public_key_curve(Key).

-file("src/kryptos/ec.gleam", 192).
?DOC(
    " Exports an EC private key to raw scalar bytes.\n"
    "\n"
    " Returns the private scalar (the \"d\" value in JWK terminology) as\n"
    " big-endian bytes. The size matches the curve's coordinate size.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let scalar = ec.to_bytes(private_key)\n"
    " ```\n"
).
-spec to_bytes(private_key()) -> bitstring().
to_bytes(Key) ->
    kryptos_ffi:ec_private_key_to_bytes(Key).

-file("src/kryptos/ec.gleam", 211).
?DOC(
    " Imports an EC private key from raw scalar bytes.\n"
    "\n"
    " The scalar should be in big-endian format with size matching the\n"
    " curve's coordinate size (32 bytes for P256/Secp256k1, 48 for P384,\n"
    " 66 for P521).\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    "\n"
    " let #(private_key, _public_key) = ec.generate_key_pair(ec.P256)\n"
    " let scalar = ec.to_bytes(private_key)\n"
    " let assert Ok(#(imported, _pub)) = ec.from_bytes(ec.P256, scalar)\n"
    " ```\n"
).
-spec from_bytes(curve(), bitstring()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
from_bytes(Curve, Private_bytes) ->
    kryptos_ffi:ec_private_key_from_bytes(Curve, Private_bytes).
