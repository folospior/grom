-module(kryptos@rsa).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/rsa.gleam").
-export([sign/4, verify/5, encrypt/3, decrypt/3, from_pem/2, from_der/2, to_pem/2, to_der/2, public_key_from_pem/2, public_key_from_der/2, public_key_to_pem/2, public_key_to_der/2, public_key_from_private_key/1, modulus_bits/1, public_key_modulus_bits/1, public_exponent/1, public_key_exponent/1, modulus/1, public_key_modulus/1, public_exponent_bytes/1, public_key_exponent_bytes/1, private_exponent_bytes/1, prime1/1, prime2/1, exponent1/1, exponent2/1, coefficient/1, public_key_from_components/2, from_full_components/8, from_components/3, generate_key_pair/1]).
-export_type([private_key/0, public_key/0, private_key_format/0, public_key_format/0, pss_salt_length/0, sign_padding/0, encrypt_padding/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " RSA (Rivest-Shamir-Adleman) cryptography.\n"
    "\n"
    " RSA key generation, signing, and encryption.\n"
    " RSA keys can be used for both digital signatures and encryption.\n"
    "\n"
    " ## Key Generation\n"
    "\n"
    " ```gleam\n"
    " import kryptos/rsa\n"
    "\n"
    " let assert Ok(#(private_key, public_key)) = rsa.generate_key_pair(2048)\n"
    " ```\n"
    "\n"
    " ## Signing (RSA-PSS)\n"
    "\n"
    " ```gleam\n"
    " import kryptos/rsa\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(#(private_key, public_key)) = rsa.generate_key_pair(2048)\n"
    " let message = <<\"hello world\":utf8>>\n"
    " let padding = rsa.Pss(rsa.SaltLengthHashLen)\n"
    " let signature = rsa.sign(private_key, message, hash.Sha256, padding)\n"
    " let valid = rsa.verify(public_key, message, signature, hash.Sha256, padding)\n"
    " ```\n"
    "\n"
    " ## Encryption (RSA-OAEP)\n"
    "\n"
    " ```gleam\n"
    " import kryptos/rsa\n"
    " import kryptos/hash\n"
    "\n"
    " let assert Ok(#(private_key, public_key)) = rsa.generate_key_pair(2048)\n"
    " let plaintext = <<\"secret\":utf8>>\n"
    " let padding = rsa.Oaep(hash: hash.Sha256, label: <<>>)\n"
    " let assert Ok(ciphertext) = rsa.encrypt(public_key, plaintext, padding)\n"
    " let assert Ok(decrypted) = rsa.decrypt(private_key, ciphertext, padding)\n"
    " ```\n"
).

-type private_key() :: any().

-type public_key() :: any().

-type private_key_format() :: pkcs8 | pkcs1.

-type public_key_format() :: spki | rsa_public_key.

-type pss_salt_length() :: salt_length_hash_len |
    salt_length_max |
    {salt_length_explicit, integer()}.

-type sign_padding() :: pkcs1v15 | {pss, pss_salt_length()}.

-type encrypt_padding() :: encrypt_pkcs1v15 |
    {oaep, kryptos@hash:hash_algorithm(), bitstring()}.

-file("src/kryptos/rsa.gleam", 130).
?DOC(
    " Signs a message using RSA with the specified hash algorithm and padding.\n"
    "\n"
    " The message is hashed internally using the provided algorithm before signing.\n"
).
-spec sign(
    private_key(),
    bitstring(),
    kryptos@hash:hash_algorithm(),
    sign_padding()
) -> bitstring().
sign(Private_key, Message, Hash, Padding) ->
    kryptos_ffi:rsa_sign(Private_key, Message, Hash, Padding).

-file("src/kryptos/rsa.gleam", 143).
?DOC(
    " Verifies an RSA signature against a message.\n"
    "\n"
    " The same hash algorithm and padding used during signing must be used\n"
    " for verification.\n"
).
-spec verify(
    public_key(),
    bitstring(),
    bitstring(),
    kryptos@hash:hash_algorithm(),
    sign_padding()
) -> boolean().
verify(Public_key, Message, Signature, Hash, Padding) ->
    kryptos_ffi:rsa_verify(Public_key, Message, Signature, Hash, Padding).

-file("src/kryptos/rsa.gleam", 158).
?DOC(
    " Encrypts data using RSA with the specified padding scheme.\n"
    "\n"
    " **Note**: RSA encryption should only be used for small amounts of data\n"
    " (typically symmetric keys). For bulk encryption, use a symmetric cipher\n"
    " with a randomly generated key, then encrypt that key with RSA.\n"
).
-spec encrypt(public_key(), bitstring(), encrypt_padding()) -> {ok, bitstring()} |
    {error, nil}.
encrypt(Public_key, Plaintext, Padding) ->
    kryptos_ffi:rsa_encrypt(Public_key, Plaintext, Padding).

-file("src/kryptos/rsa.gleam", 167).
?DOC(" Decrypts data using RSA with the specified padding scheme.\n").
-spec decrypt(private_key(), bitstring(), encrypt_padding()) -> {ok,
        bitstring()} |
    {error, nil}.
decrypt(Private_key, Ciphertext, Padding) ->
    kryptos_ffi:rsa_decrypt(Private_key, Ciphertext, Padding).

-file("src/kryptos/rsa.gleam", 176).
?DOC(" Imports an RSA private key from PEM-encoded data.\n").
-spec from_pem(binary(), private_key_format()) -> {ok,
        {private_key(), public_key()}} |
    {error, nil}.
from_pem(Pem, Format) ->
    kryptos_ffi:rsa_import_private_key_pem(Pem, Format).

-file("src/kryptos/rsa.gleam", 184).
?DOC(" Imports an RSA private key from DER-encoded data.\n").
-spec from_der(bitstring(), private_key_format()) -> {ok,
        {private_key(), public_key()}} |
    {error, nil}.
from_der(Der, Format) ->
    kryptos_ffi:rsa_import_private_key_der(Der, Format).

-file("src/kryptos/rsa.gleam", 190).
?DOC(" Exports an RSA private key to PEM format.\n").
-spec to_pem(private_key(), private_key_format()) -> {ok, binary()} |
    {error, nil}.
to_pem(Key, Format) ->
    _pipe = kryptos_ffi:rsa_export_private_key_pem(Key, Format),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/rsa.gleam", 201).
?DOC(" Exports an RSA private key to DER format.\n").
-spec to_der(private_key(), private_key_format()) -> {ok, bitstring()} |
    {error, nil}.
to_der(Key, Format) ->
    kryptos_ffi:rsa_export_private_key_der(Key, Format).

-file("src/kryptos/rsa.gleam", 209).
?DOC(" Imports an RSA public key from PEM-encoded data.\n").
-spec public_key_from_pem(binary(), public_key_format()) -> {ok, public_key()} |
    {error, nil}.
public_key_from_pem(Pem, Format) ->
    kryptos_ffi:rsa_import_public_key_pem(Pem, Format).

-file("src/kryptos/rsa.gleam", 217).
?DOC(" Imports an RSA public key from DER-encoded data.\n").
-spec public_key_from_der(bitstring(), public_key_format()) -> {ok,
        public_key()} |
    {error, nil}.
public_key_from_der(Der, Format) ->
    kryptos_ffi:rsa_import_public_key_der(Der, Format).

-file("src/kryptos/rsa.gleam", 223).
?DOC(" Exports an RSA public key to PEM format.\n").
-spec public_key_to_pem(public_key(), public_key_format()) -> {ok, binary()} |
    {error, nil}.
public_key_to_pem(Key, Format) ->
    _pipe = kryptos_ffi:rsa_export_public_key_pem(Key, Format),
    gleam@result:map(
        _pipe,
        fun(Pem) -> <<(gleam@string:trim_end(Pem))/binary, "\n"/utf8>> end
    ).

-file("src/kryptos/rsa.gleam", 241).
?DOC(" Exports an RSA public key to DER format.\n").
-spec public_key_to_der(public_key(), public_key_format()) -> {ok, bitstring()} |
    {error, nil}.
public_key_to_der(Key, Format) ->
    kryptos_ffi:rsa_export_public_key_der(Key, Format).

-file("src/kryptos/rsa.gleam", 249).
?DOC(" Derives the public key from an RSA private key.\n").
-spec public_key_from_private_key(private_key()) -> public_key().
public_key_from_private_key(Key) ->
    kryptos_ffi:rsa_public_key_from_private(Key).

-file("src/kryptos/rsa.gleam", 254).
?DOC(" Returns the modulus size in bits for an RSA private key.\n").
-spec modulus_bits(private_key()) -> integer().
modulus_bits(Key) ->
    kryptos_ffi:rsa_private_key_modulus_bits(Key).

-file("src/kryptos/rsa.gleam", 259).
?DOC(" Returns the modulus size in bits for an RSA public key.\n").
-spec public_key_modulus_bits(public_key()) -> integer().
public_key_modulus_bits(Key) ->
    kryptos_ffi:rsa_public_key_modulus_bits(Key).

-file("src/kryptos/rsa.gleam", 264).
?DOC(" Returns the public exponent for an RSA private key.\n").
-spec public_exponent(private_key()) -> integer().
public_exponent(Key) ->
    kryptos_ffi:rsa_private_key_public_exponent(Key).

-file("src/kryptos/rsa.gleam", 269).
?DOC(" Returns the public exponent for an RSA public key.\n").
-spec public_key_exponent(public_key()) -> integer().
public_key_exponent(Key) ->
    kryptos_ffi:rsa_public_key_public_exponent(Key).

-file("src/kryptos/rsa.gleam", 274).
?DOC(" Returns the modulus (n) as big-endian bytes for an RSA private key.\n").
-spec modulus(private_key()) -> bitstring().
modulus(Key) ->
    kryptos_ffi:rsa_private_key_modulus(Key).

-file("src/kryptos/rsa.gleam", 279).
?DOC(" Returns the modulus (n) as big-endian bytes for an RSA public key.\n").
-spec public_key_modulus(public_key()) -> bitstring().
public_key_modulus(Key) ->
    kryptos_ffi:rsa_public_key_modulus(Key).

-file("src/kryptos/rsa.gleam", 284).
?DOC(" Returns the public exponent (e) as big-endian bytes for an RSA private key.\n").
-spec public_exponent_bytes(private_key()) -> bitstring().
public_exponent_bytes(Key) ->
    kryptos_ffi:rsa_private_key_public_exponent_bytes(Key).

-file("src/kryptos/rsa.gleam", 289).
?DOC(" Returns the public exponent (e) as big-endian bytes for an RSA public key.\n").
-spec public_key_exponent_bytes(public_key()) -> bitstring().
public_key_exponent_bytes(Key) ->
    kryptos_ffi:rsa_public_key_exponent_bytes(Key).

-file("src/kryptos/rsa.gleam", 294).
?DOC(" Returns the private exponent (d) as big-endian bytes for an RSA private key.\n").
-spec private_exponent_bytes(private_key()) -> bitstring().
private_exponent_bytes(Key) ->
    kryptos_ffi:rsa_private_key_private_exponent_bytes(Key).

-file("src/kryptos/rsa.gleam", 302).
?DOC(
    " Returns the first prime factor (p) as big-endian bytes.\n"
    "\n"
    " The RSA modulus n = p * q. This is part of the CRT (Chinese Remainder\n"
    " Theorem) parameters used for efficient RSA operations.\n"
).
-spec prime1(private_key()) -> bitstring().
prime1(Key) ->
    kryptos_ffi:rsa_private_key_prime1(Key).

-file("src/kryptos/rsa.gleam", 310).
?DOC(
    " Returns the second prime factor (q) as big-endian bytes.\n"
    "\n"
    " The RSA modulus n = p * q. This is part of the CRT (Chinese Remainder\n"
    " Theorem) parameters used for efficient RSA operations.\n"
).
-spec prime2(private_key()) -> bitstring().
prime2(Key) ->
    kryptos_ffi:rsa_private_key_prime2(Key).

-file("src/kryptos/rsa.gleam", 318).
?DOC(
    " Returns the first CRT exponent (dp = d mod (p-1)) as big-endian bytes.\n"
    "\n"
    " This is part of the CRT (Chinese Remainder Theorem) parameters used\n"
    " for efficient RSA operations.\n"
).
-spec exponent1(private_key()) -> bitstring().
exponent1(Key) ->
    kryptos_ffi:rsa_private_key_exponent1(Key).

-file("src/kryptos/rsa.gleam", 326).
?DOC(
    " Returns the second CRT exponent (dq = d mod (q-1)) as big-endian bytes.\n"
    "\n"
    " This is part of the CRT (Chinese Remainder Theorem) parameters used\n"
    " for efficient RSA operations.\n"
).
-spec exponent2(private_key()) -> bitstring().
exponent2(Key) ->
    kryptos_ffi:rsa_private_key_exponent2(Key).

-file("src/kryptos/rsa.gleam", 334).
?DOC(
    " Returns the CRT coefficient (qi = q^-1 mod p) as big-endian bytes.\n"
    "\n"
    " This is part of the CRT (Chinese Remainder Theorem) parameters used\n"
    " for efficient RSA operations.\n"
).
-spec coefficient(private_key()) -> bitstring().
coefficient(Key) ->
    kryptos_ffi:rsa_private_key_coefficient(Key).

-file("src/kryptos/rsa.gleam", 339).
?DOC(" Constructs an RSA public key from its components.\n").
-spec public_key_from_components(bitstring(), bitstring()) -> {ok, public_key()} |
    {error, nil}.
public_key_from_components(N, E) ->
    kryptos_ffi:rsa_public_key_from_components(N, E).

-file("src/kryptos/rsa.gleam", 377).
?DOC(" Constructs an RSA private key from all components including CRT parameters.\n").
-spec from_full_components(
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring()
) -> {ok, {private_key(), public_key()}} | {error, nil}.
from_full_components(N, E, D, P, Q, Dp, Dq, Qi) ->
    kryptos_ffi:rsa_private_key_from_full_components(N, E, D, P, Q, Dp, Dq, Qi).

-file("src/kryptos/rsa.gleam", 365).
?DOC(
    " Constructs an RSA private key from its components.\n"
    "\n"
    " Creates a private key from the minimal set of components (n, e, d).\n"
    " CRT parameters are computed automatically using Miller's algorithm.\n"
    "\n"
    " Note: This function is not constant-time. The CRT parameter derivation\n"
    " involves operations that may leak timing information. This is acceptable\n"
    " for key import since the caller already possesses the secret material,\n"
    " but avoid calling this in timing-sensitive contexts.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/rsa\n"
    "\n"
    " let assert Ok(#(private_key, _public_key)) = rsa.generate_key_pair(2048)\n"
    " let n = rsa.modulus(private_key)\n"
    " let e = rsa.public_exponent_bytes(private_key)\n"
    " let d = rsa.private_exponent_bytes(private_key)\n"
    " let assert Ok(#(reconstructed, _pub)) = rsa.from_components(n, e, d)\n"
    " ```\n"
).
-spec from_components(bitstring(), bitstring(), bitstring()) -> {ok,
        {private_key(), public_key()}} |
    {error, nil}.
from_components(N, E, D) ->
    gleam@result:'try'(
        kryptos@internal@rsa_crt:compute_crt_params(N, E, D),
        fun(_use0) ->
            {P, Q, Dp, Dq, Qi} = _use0,
            kryptos_ffi:rsa_private_key_from_full_components(
                N,
                E,
                D,
                P,
                Q,
                Dp,
                Dq,
                Qi
            )
        end
    ).

-file("src/kryptos/rsa.gleam", 114).
?DOC(
    " Generates an RSA key pair with the specified key size.\n"
    "\n"
    " The key size must be >= 1024 bits.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " let assert Ok(#(private_key, public_key)) = rsa.generate_key_pair(2048)\n"
    " ```\n"
).
-spec generate_key_pair(integer()) -> {ok, {private_key(), public_key()}} |
    {error, nil}.
generate_key_pair(Bits) ->
    case Bits >= 1024 of
        true ->
            {ok, kryptos_ffi:rsa_generate_key_pair(Bits)};

        false ->
            {error, nil}
    end.
