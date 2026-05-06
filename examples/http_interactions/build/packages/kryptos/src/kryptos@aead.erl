-module(kryptos@aead).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/aead.gleam").
-export([gcm/1, gcm_with_nonce_size/2, ccm/1, ccm_with_sizes/3, chacha20_poly1305/1, xchacha20_poly1305/1, nonce_size/1, tag_size/1, seal_with_aad/4, seal/3, open_with_aad/5, open/4, cipher_name/1, cipher_key/1, is_ccm/1, is_gcm/1, is_chacha20_poly1305/1]).
-export_type([aead_context/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Authenticated Encryption with Associated Data (AEAD).\n"
    "\n"
    " AEAD provides both confidentiality and integrity for data, with optional\n"
    " authenticated additional data (AAD) that is integrity-protected but not\n"
    " encrypted.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/aead\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " let assert Ok(cipher) = block.aes_256(crypto.random_bytes(32))\n"
    " let ctx = aead.gcm(cipher)\n"
    " let nonce = crypto.random_bytes(aead.nonce_size(ctx))\n"
    " let assert Ok(#(ciphertext, tag)) = aead.seal(ctx, nonce:, plaintext: <<\"secret\":utf8>>)\n"
    " ```\n"
).

-opaque aead_context() :: {gcm, kryptos@block:block_cipher(), integer()} |
    {ccm, kryptos@block:block_cipher(), integer(), integer()} |
    {cha_cha20_poly1305, bitstring()} |
    {x_cha_cha20_poly1305, bitstring()}.

-file("src/kryptos/aead.gleam", 54).
?DOC(
    " Creates an AES-GCM context with the given block cipher.\n"
    "\n"
    " Uses standard parameters: 16-byte (128-bit) authentication tag and\n"
    " 12-byte (96-bit) nonce.\n"
    "\n"
    " **Note:** This library only supports the full 16-byte authentication tag.\n"
    " Truncated tags (as permitted by NIST SP 800-38D) are not supported due to\n"
    " their reduced security guarantees.\n"
).
-spec gcm(kryptos@block:block_cipher()) -> aead_context().
gcm(Cipher) ->
    {gcm, Cipher, 12}.

-file("src/kryptos/aead.gleam", 62).
?DOC(
    " Creates an AES-GCM context with a custom nonce size.\n"
    "\n"
    " GCM supports variable nonce sizes, though 12 bytes is strongly recommended.\n"
    " This function is primarily useful for compatibility testing with test vectors.\n"
).
-spec gcm_with_nonce_size(kryptos@block:block_cipher(), integer()) -> {ok,
        aead_context()} |
    {error, nil}.
gcm_with_nonce_size(Cipher, Nonce_size) ->
    case (Nonce_size >= 1) andalso (Nonce_size =< 64) of
        true ->
            {ok, {gcm, Cipher, Nonce_size}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 76).
?DOC(
    " Creates an AES-CCM context with the given block cipher.\n"
    "\n"
    " Uses standard parameters: 16-byte (128-bit) authentication tag and\n"
    " 13-byte (104-bit) nonce, which allows messages up to 64KB.\n"
).
-spec ccm(kryptos@block:block_cipher()) -> aead_context().
ccm(Cipher) ->
    {ccm, Cipher, 13, 16}.

-file("src/kryptos/aead.gleam", 87).
?DOC(
    " Creates an AES-CCM context with custom nonce and tag sizes.\n"
    "\n"
    " CCM allows flexible nonce and tag sizes per RFC 3610:\n"
    " - Nonce size affects maximum message length (larger nonce = smaller max message)\n"
    " - Tag size affects authentication strength (larger tag = stronger)\n"
    "\n"
    " Nonce must be 7-13 bytes. Tag must be 4, 6, 8, 10, 12, 14, or 16 bytes.\n"
).
-spec ccm_with_sizes(kryptos@block:block_cipher(), integer(), integer()) -> {ok,
        aead_context()} |
    {error, nil}.
ccm_with_sizes(Cipher, Nonce_size, Tag_size) ->
    Valid_nonce = (Nonce_size >= 7) andalso (Nonce_size =< 13),
    Valid_tag = gleam@list:contains([4, 6, 8, 10, 12, 14, 16], Tag_size),
    case Valid_nonce andalso Valid_tag of
        true ->
            {ok, {ccm, Cipher, Nonce_size, Tag_size}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 104).
?DOC(
    " Creates a ChaCha20-Poly1305 AEAD context with the given key.\n"
    "\n"
    " Uses standard parameters per RFC 8439: 12-byte (96-bit) nonce and\n"
    " 16-byte (128-bit) authentication tag. The key must be exactly 32 bytes.\n"
).
-spec chacha20_poly1305(bitstring()) -> {ok, aead_context()} | {error, nil}.
chacha20_poly1305(Key) ->
    case erlang:byte_size(Key) =:= 32 of
        true ->
            {ok, {cha_cha20_poly1305, Key}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 116).
?DOC(
    " Creates an XChaCha20-Poly1305 AEAD context with the given key.\n"
    "\n"
    " Uses extended parameters: 24-byte (192-bit) nonce and 16-byte (128-bit)\n"
    " authentication tag. The extended nonce provides better collision resistance\n"
    " when generating random nonces. The key must be exactly 32 bytes.\n"
).
-spec xchacha20_poly1305(bitstring()) -> {ok, aead_context()} | {error, nil}.
xchacha20_poly1305(Key) ->
    case erlang:byte_size(Key) =:= 32 of
        true ->
            {ok, {x_cha_cha20_poly1305, Key}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 124).
?DOC(" Returns the required nonce size in bytes for an AEAD context.\n").
-spec nonce_size(aead_context()) -> integer().
nonce_size(Ctx) ->
    case Ctx of
        {gcm, _, Nonce_size} ->
            Nonce_size;

        {ccm, _, Nonce_size@1, _} ->
            Nonce_size@1;

        {cha_cha20_poly1305, _} ->
            12;

        {x_cha_cha20_poly1305, _} ->
            24
    end.

-file("src/kryptos/aead.gleam", 134).
?DOC(" Returns the authentication tag size in bytes for an AEAD context.\n").
-spec tag_size(aead_context()) -> integer().
tag_size(Ctx) ->
    case Ctx of
        {gcm, _, _} ->
            16;

        {ccm, _, _, Tag_size} ->
            Tag_size;

        {cha_cha20_poly1305, _} ->
            16;

        {x_cha_cha20_poly1305, _} ->
            16
    end.

-file("src/kryptos/aead.gleam", 269).
?DOC(" Derives the subkey and ChaCha20 nonce for XChaCha20-Poly1305.\n").
-spec xchacha20_derive(bitstring(), bitstring()) -> {ok,
        {bitstring(), bitstring()}} |
    {error, nil}.
xchacha20_derive(Key, Nonce) ->
    case Nonce of
        <<Hchacha_input:16/binary, Nonce_suffix:8/binary>> ->
            Subkey = kryptos@internal@hchacha20:subkey(Key, Hchacha_input),
            Chacha_nonce = <<0:32, Nonce_suffix/bitstring>>,
            {ok, {Subkey, Chacha_nonce}};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 159).
?DOC(
    " Encrypts and authenticates plaintext with additional authenticated data.\n"
    "\n"
    " The AAD is authenticated but not encrypted. It can be used for headers,\n"
    " metadata, or context that should be tamper-proof but remain readable.\n"
).
-spec seal_with_aad(aead_context(), bitstring(), bitstring(), bitstring()) -> {ok,
        {bitstring(), bitstring()}} |
    {error, nil}.
seal_with_aad(Ctx, Nonce, Plaintext, Aad) ->
    Nonce_len = erlang:byte_size(Nonce),
    case (Nonce_len > 0) andalso (Nonce_len =:= nonce_size(Ctx)) of
        true ->
            case Ctx of
                {x_cha_cha20_poly1305, Key} ->
                    gleam@result:'try'(
                        xchacha20_derive(Key, Nonce),
                        fun(_use0) ->
                            {Subkey, Chacha_nonce} = _use0,
                            kryptos_ffi:aead_seal(
                                {cha_cha20_poly1305, Subkey},
                                Chacha_nonce,
                                Plaintext,
                                Aad
                            )
                        end
                    );

                {gcm, _, _} ->
                    kryptos_ffi:aead_seal(Ctx, Nonce, Plaintext, Aad);

                {ccm, _, _, _} ->
                    kryptos_ffi:aead_seal(Ctx, Nonce, Plaintext, Aad);

                {cha_cha20_poly1305, _} ->
                    kryptos_ffi:aead_seal(Ctx, Nonce, Plaintext, Aad)
            end;

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 147).
?DOC(
    " Encrypts and authenticates plaintext using AEAD.\n"
    "\n"
    " The nonce must be exactly `nonce_size` bytes. Never reuse a nonce with\n"
    " the same key.\n"
).
-spec seal(aead_context(), bitstring(), bitstring()) -> {ok,
        {bitstring(), bitstring()}} |
    {error, nil}.
seal(Ctx, Nonce, Plaintext) ->
    seal_with_aad(Ctx, Nonce, Plaintext, <<>>).

-file("src/kryptos/aead.gleam", 233).
?DOC(
    " Decrypts and verifies AEAD-encrypted data with additional authenticated data.\n"
    "\n"
    " The AAD must match exactly what was provided during encryption.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/aead\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " let assert Ok(cipher) = block.aes_256(crypto.random_bytes(32))\n"
    " let ctx = aead.gcm(cipher)\n"
    " let nonce = crypto.random_bytes(aead.nonce_size(ctx))\n"
    " let aad = <<\"header\":utf8>>\n"
    " let assert Ok(#(ciphertext, tag)) =\n"
    "   aead.seal_with_aad(ctx, nonce:, plaintext: <<\"secret\":utf8>>, additional_data: aad)\n"
    " let assert Ok(plaintext) =\n"
    "   aead.open_with_aad(ctx, nonce:, tag:, ciphertext:, additional_data: aad)\n"
    " ```\n"
).
-spec open_with_aad(
    aead_context(),
    bitstring(),
    bitstring(),
    bitstring(),
    bitstring()
) -> {ok, bitstring()} | {error, nil}.
open_with_aad(Ctx, Nonce, Tag, Ciphertext, Aad) ->
    Nonce_len = erlang:byte_size(Nonce),
    Tag_len = erlang:byte_size(Tag),
    case ((Nonce_len > 0) andalso (Nonce_len =:= nonce_size(Ctx))) andalso (Tag_len
    =:= tag_size(Ctx)) of
        true ->
            case Ctx of
                {x_cha_cha20_poly1305, Key} ->
                    gleam@result:'try'(
                        xchacha20_derive(Key, Nonce),
                        fun(_use0) ->
                            {Subkey, Chacha_nonce} = _use0,
                            kryptos_ffi:aead_open(
                                {cha_cha20_poly1305, Subkey},
                                Chacha_nonce,
                                Tag,
                                Ciphertext,
                                Aad
                            )
                        end
                    );

                {gcm, _, _} ->
                    kryptos_ffi:aead_open(Ctx, Nonce, Tag, Ciphertext, Aad);

                {ccm, _, _, _} ->
                    kryptos_ffi:aead_open(Ctx, Nonce, Tag, Ciphertext, Aad);

                {cha_cha20_poly1305, _} ->
                    kryptos_ffi:aead_open(Ctx, Nonce, Tag, Ciphertext, Aad)
            end;

        false ->
            {error, nil}
    end.

-file("src/kryptos/aead.gleam", 204).
?DOC(
    " Decrypts and verifies AEAD-encrypted data.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/aead\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " let assert Ok(cipher) = block.aes_256(crypto.random_bytes(32))\n"
    " let ctx = aead.gcm(cipher)\n"
    " let nonce = crypto.random_bytes(aead.nonce_size(ctx))\n"
    " let assert Ok(#(ciphertext, tag)) = aead.seal(ctx, nonce:, plaintext: <<\"secret\":utf8>>)\n"
    " let assert Ok(plaintext) = aead.open(ctx, nonce:, tag:, ciphertext:)\n"
    " ```\n"
).
-spec open(aead_context(), bitstring(), bitstring(), bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
open(Ctx, Nonce, Tag, Ciphertext) ->
    open_with_aad(Ctx, Nonce, Tag, Ciphertext, <<>>).

-file("src/kryptos/aead.gleam", 287).
?DOC(false).
-spec cipher_name(aead_context()) -> binary().
cipher_name(Ctx) ->
    case Ctx of
        {gcm, Cipher, _} ->
            <<<<"aes-"/utf8,
                    (erlang:integer_to_binary(kryptos@block:key_size(Cipher)))/binary>>/binary,
                "-gcm"/utf8>>;

        {ccm, Cipher@1, _, _} ->
            <<<<"aes-"/utf8,
                    (erlang:integer_to_binary(kryptos@block:key_size(Cipher@1)))/binary>>/binary,
                "-ccm"/utf8>>;

        {cha_cha20_poly1305, _} ->
            <<"chacha20-poly1305"/utf8>>;

        {x_cha_cha20_poly1305, _} ->
            <<"chacha20-poly1305"/utf8>>
    end.

-file("src/kryptos/aead.gleam", 299).
?DOC(false).
-spec cipher_key(aead_context()) -> bitstring().
cipher_key(Ctx) ->
    case Ctx of
        {gcm, Cipher, _} ->
            kryptos@block:aes_key(Cipher);

        {ccm, Cipher, _, _} ->
            kryptos@block:aes_key(Cipher);

        {cha_cha20_poly1305, Key} ->
            Key;

        {x_cha_cha20_poly1305, Key} ->
            Key
    end.

-file("src/kryptos/aead.gleam", 307).
?DOC(false).
-spec is_ccm(aead_context()) -> boolean().
is_ccm(Ctx) ->
    case Ctx of
        {ccm, _, _, _} ->
            true;

        _ ->
            false
    end.

-file("src/kryptos/aead.gleam", 315).
?DOC(false).
-spec is_gcm(aead_context()) -> boolean().
is_gcm(Ctx) ->
    case Ctx of
        {gcm, _, _} ->
            true;

        _ ->
            false
    end.

-file("src/kryptos/aead.gleam", 323).
?DOC(false).
-spec is_chacha20_poly1305(aead_context()) -> boolean().
is_chacha20_poly1305(Ctx) ->
    case Ctx of
        {cha_cha20_poly1305, _} ->
            true;

        _ ->
            false
    end.
