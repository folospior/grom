-module(kryptos@block).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/block.gleam").
-export([key_size/1, block_size/1, aes_128/1, aes_192/1, aes_256/1, ecb/1, cbc/2, ctr/2, encrypt/2, decrypt/2, cipher_name/1, cipher_key/1, cipher_iv/1, aes_key/1, is_ctr/1, wrap/2, unwrap/2]).
-export_type([block_cipher/0, cipher_context/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Block cipher implementations and modes of operation.\n"
    "\n"
    " AES block ciphers and modes of operation (ECB, CBC, CTR).\n"
    "\n"
    " **IMPORTANT SECURITY WARNING:**\n"
    " ECB, CBC, and CTR modes do NOT provide authentication. An attacker can modify\n"
    " ciphertext without detection. For most applications, you should use\n"
    " authenticated encryption modes like AES-GCM or ChaCha20-Poly1305\n"
    " from the `kryptos/aead` module instead.\n"
    "\n"
    " Use these modes only when:\n"
    " - Interoperating with legacy systems that require them\n"
    " - Implementing higher-level protocols that provide their own authentication\n"
    " - You fully understand the security implications\n"
    "\n"
    " ## Modes Overview\n"
    "\n"
    " - ECB (Electronic Codebook): Encrypts each block independently.\n"
    "   INSECURE for most uses - reveals patterns in data. Only use for\n"
    "   single-block encryption or specific legacy requirements.\n"
    " - CBC (Cipher Block Chaining): Each block XORed with previous ciphertext.\n"
    "   Requires random IV per encryption. Uses PKCS7 padding automatically.\n"
    " - CTR (Counter): Converts block cipher to stream cipher.\n"
    "   Nonce reuse is catastrophic - NEVER reuse a nonce with the same key.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " // CBC encryption with random IV\n"
    " let assert Ok(cipher) = block.aes_256(crypto.random_bytes(32))\n"
    " let assert Ok(ctx) = block.cbc(cipher, iv: crypto.random_bytes(16))\n"
    " let assert Ok(ciphertext) = block.encrypt(ctx, <<\"secret\":utf8>>)\n"
    " let assert Ok(decrypted) = block.decrypt(ctx, ciphertext)\n"
    " // decrypted == <<\"secret\":utf8>>\n"
    " ```\n"
).

-opaque block_cipher() :: {aes, integer(), bitstring()}.

-opaque cipher_context() :: {ecb, block_cipher()} |
    {cbc, block_cipher(), bitstring()} |
    {ctr, block_cipher(), bitstring()}.

-file("src/kryptos/block.gleam", 74).
?DOC(" Returns the key size in bits for a block cipher.\n").
-spec key_size(block_cipher()) -> integer().
key_size(Cipher) ->
    case Cipher of
        {aes, Key_size, _} ->
            Key_size
    end.

-file("src/kryptos/block.gleam", 81).
?DOC(" Returns the block size in bytes for a block cipher.\n").
-spec block_size(block_cipher()) -> integer().
block_size(Cipher) ->
    case Cipher of
        {aes, _, _} ->
            16
    end.

-file("src/kryptos/block.gleam", 90).
?DOC(
    " Creates a new AES-128 block cipher with the given key.\n"
    "\n"
    " The key must be exactly 16 bytes.\n"
).
-spec aes_128(bitstring()) -> {ok, block_cipher()} | {error, nil}.
aes_128(Key) ->
    case erlang:byte_size(Key) =:= 16 of
        true ->
            {ok, {aes, 128, Key}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 100).
?DOC(
    " Creates a new AES-192 block cipher with the given key.\n"
    "\n"
    " The key must be exactly 24 bytes.\n"
).
-spec aes_192(bitstring()) -> {ok, block_cipher()} | {error, nil}.
aes_192(Key) ->
    case erlang:byte_size(Key) =:= 24 of
        true ->
            {ok, {aes, 192, Key}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 110).
?DOC(
    " Creates a new AES-256 block cipher with the given key.\n"
    "\n"
    " The key must be exactly 32 bytes.\n"
).
-spec aes_256(bitstring()) -> {ok, block_cipher()} | {error, nil}.
aes_256(Key) ->
    case erlang:byte_size(Key) =:= 32 of
        true ->
            {ok, {aes, 256, Key}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 122).
?DOC(
    " Creates an ECB mode context for the given cipher.\n"
    "\n"
    " **SECURITY WARNING:** ECB mode is insecure for most use cases.\n"
    " Identical plaintext blocks produce identical ciphertext blocks,\n"
    " revealing patterns in the data.\n"
).
-spec ecb(block_cipher()) -> cipher_context().
ecb(Cipher) ->
    {ecb, Cipher}.

-file("src/kryptos/block.gleam", 129).
?DOC(
    " Creates a CBC mode context with the given cipher and IV.\n"
    "\n"
    " The IV must be exactly 16 bytes, random, and unique per encryption.\n"
).
-spec cbc(block_cipher(), bitstring()) -> {ok, cipher_context()} | {error, nil}.
cbc(Cipher, Iv) ->
    case erlang:byte_size(Iv) =:= 16 of
        true ->
            {ok, {cbc, Cipher, Iv}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 154).
?DOC(
    " Creates a CTR mode context with the given cipher and nonce.\n"
    "\n"
    " **SECURITY WARNING:** Nonce reuse is catastrophic in CTR mode.\n"
    " NEVER reuse a nonce with the same key.\n"
    "\n"
    " The nonce must be exactly 16 bytes.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " let assert Ok(cipher) = block.aes_256(crypto.random_bytes(32))\n"
    " let assert Ok(ctx) = block.ctr(cipher, nonce: crypto.random_bytes(16))\n"
    " let assert Ok(ciphertext) = block.encrypt(ctx, <<\"secret\":utf8>>)\n"
    " let assert Ok(plaintext) = block.decrypt(ctx, ciphertext)\n"
    " ```\n"
).
-spec ctr(block_cipher(), bitstring()) -> {ok, cipher_context()} | {error, nil}.
ctr(Cipher, Nonce) ->
    case erlang:byte_size(Nonce) =:= 16 of
        true ->
            {ok, {ctr, Cipher, Nonce}};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 177).
-spec validate_iv(cipher_context()) -> boolean().
validate_iv(Ctx) ->
    case Ctx of
        {ecb, _} ->
            true;

        {cbc, _, Iv} ->
            erlang:byte_size(Iv) =:= 16;

        {ctr, _, Nonce} ->
            erlang:byte_size(Nonce) =:= 16
    end.

-file("src/kryptos/block.gleam", 170).
?DOC(
    " Encrypts plaintext using the cipher mode.\n"
    "\n"
    " ## Notes\n"
    " - ECB: No IV required\n"
    " - CBC: Automatically applies PKCS7 padding; ciphertext may be larger than plaintext\n"
    " - CTR: No padding needed; ciphertext is same size as plaintext\n"
).
-spec encrypt(cipher_context(), bitstring()) -> {ok, bitstring()} | {error, nil}.
encrypt(Ctx, Plaintext) ->
    case validate_iv(Ctx) of
        true ->
            kryptos_ffi:block_cipher_encrypt(Ctx, Plaintext);

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 195).
?DOC(
    " Decrypts ciphertext using the cipher mode.\n"
    "\n"
    " ## Notes\n"
    " - ECB: No IV required\n"
    " - CBC: Automatically removes PKCS7 padding; returns error if padding is invalid\n"
    " - CTR: No padding; ciphertext size equals plaintext size\n"
).
-spec decrypt(cipher_context(), bitstring()) -> {ok, bitstring()} | {error, nil}.
decrypt(Ctx, Ciphertext) ->
    case validate_iv(Ctx) of
        true ->
            kryptos_ffi:block_cipher_decrypt(Ctx, Ciphertext);

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 210).
?DOC(false).
-spec cipher_name(cipher_context()) -> binary().
cipher_name(Ctx) ->
    case Ctx of
        {ecb, {aes, Key_size, _}} ->
            <<<<"aes-"/utf8, (erlang:integer_to_binary(Key_size))/binary>>/binary,
                "-ecb"/utf8>>;

        {cbc, {aes, Key_size@1, _}, _} ->
            <<<<"aes-"/utf8, (erlang:integer_to_binary(Key_size@1))/binary>>/binary,
                "-cbc"/utf8>>;

        {ctr, {aes, Key_size@2, _}, _} ->
            <<<<"aes-"/utf8, (erlang:integer_to_binary(Key_size@2))/binary>>/binary,
                "-ctr"/utf8>>
    end.

-file("src/kryptos/block.gleam", 222).
?DOC(false).
-spec cipher_key(cipher_context()) -> bitstring().
cipher_key(Ctx) ->
    case Ctx of
        {ecb, {aes, _, Key}} ->
            Key;

        {cbc, {aes, _, Key}, _} ->
            Key;

        {ctr, {aes, _, Key}, _} ->
            Key
    end.

-file("src/kryptos/block.gleam", 231).
?DOC(false).
-spec cipher_iv(cipher_context()) -> bitstring().
cipher_iv(Ctx) ->
    case Ctx of
        {ecb, _} ->
            <<>>;

        {cbc, _, Iv} ->
            Iv;

        {ctr, _, Nonce} ->
            Nonce
    end.

-file("src/kryptos/block.gleam", 400).
-spec split_into_blocks(bitstring(), list(bitstring())) -> list(bitstring()).
split_into_blocks(Data, Acc) ->
    case Data of
        <<Block:8/binary, Rest/binary>> ->
            split_into_blocks(Rest, [Block | Acc]);

        _ ->
            lists:reverse(Acc)
    end.

-file("src/kryptos/block.gleam", 417).
-spec xor_with_counter(bitstring(), integer()) -> bitstring().
xor_with_counter(A, T) ->
    A_int@1 = case A of
        <<A_int:64/unsigned>> -> A_int;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/block"/utf8>>,
                        function => <<"xor_with_counter"/utf8>>,
                        line => 418,
                        value => _assert_fail,
                        start => 11957,
                        'end' => 11999,
                        pattern_start => 11968,
                        pattern_end => 11995})
    end,
    Result = erlang:'bxor'(A_int@1, T),
    <<Result:64>>.

-file("src/kryptos/block.gleam", 298).
-spec wrap_inner(
    block_cipher(),
    bitstring(),
    list(bitstring()),
    integer(),
    integer(),
    integer(),
    list(bitstring())
) -> {bitstring(), list(bitstring())}.
wrap_inner(Cipher, A, R, N, J, I, Acc) ->
    case R of
        [] ->
            {A, lists:reverse(Acc)};

        [Ri | Rest] ->
            B = kryptos_ffi:aes_encrypt_block(
                Cipher,
                <<A/bitstring, Ri/bitstring>>
            ),
            {A_new@1, Ri_new@1} = case B of
                <<A_new:8/binary, Ri_new:8/binary>> -> {A_new, Ri_new};
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/block"/utf8>>,
                                function => <<"wrap_inner"/utf8>>,
                                line => 311,
                                value => _assert_fail,
                                start => 9124,
                                'end' => 9184,
                                pattern_start => 9135,
                                pattern_end => 9180})
            end,
            T = (N * J) + I,
            A_xored = xor_with_counter(A_new@1, T),
            wrap_inner(Cipher, A_xored, Rest, N, J, I + 1, [Ri_new@1 | Acc])
    end.

-file("src/kryptos/block.gleam", 281).
-spec wrap_rounds(
    block_cipher(),
    bitstring(),
    list(bitstring()),
    integer(),
    integer()
) -> {bitstring(), list(bitstring())}.
wrap_rounds(Cipher, A, R, N, J) ->
    case J < 6 of
        false ->
            {A, R};

        true ->
            {A_new, R_new} = wrap_inner(Cipher, A, R, N, J, 1, []),
            wrap_rounds(Cipher, A_new, R_new, N, J + 1)
    end.

-file("src/kryptos/block.gleam", 378).
-spec unwrap_inner(
    block_cipher(),
    bitstring(),
    list(bitstring()),
    integer(),
    integer(),
    integer(),
    list(bitstring())
) -> {bitstring(), list(bitstring())}.
unwrap_inner(Cipher, A, R, N, J, I, Acc) ->
    case R of
        [] ->
            {A, Acc};

        [Ri | Rest] ->
            T = (N * J) + I,
            A_xored = xor_with_counter(A, T),
            B = kryptos_ffi:aes_decrypt_block(
                Cipher,
                <<A_xored/bitstring, Ri/bitstring>>
            ),
            {A_new@1, Ri_new@1} = case B of
                <<A_new:8/binary, Ri_new:8/binary>> -> {A_new, Ri_new};
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"kryptos/block"/utf8>>,
                                function => <<"unwrap_inner"/utf8>>,
                                line => 393,
                                value => _assert_fail,
                                start => 11225,
                                'end' => 11285,
                                pattern_start => 11236,
                                pattern_end => 11281})
            end,
            unwrap_inner(Cipher, A_new@1, Rest, N, J, I - 1, [Ri_new@1 | Acc])
    end.

-file("src/kryptos/block.gleam", 360).
-spec unwrap_rounds(
    block_cipher(),
    bitstring(),
    list(bitstring()),
    integer(),
    integer()
) -> {bitstring(), list(bitstring())}.
unwrap_rounds(Cipher, A, R, N, J) ->
    case J >= 0 of
        false ->
            {A, R};

        true ->
            {A_new, R_new} = unwrap_inner(
                Cipher,
                A,
                lists:reverse(R),
                N,
                J,
                N,
                []
            ),
            unwrap_rounds(Cipher, A_new, R_new, N, J - 1)
    end.

-file("src/kryptos/block.gleam", 424).
?DOC(false).
-spec aes_key(block_cipher()) -> bitstring().
aes_key(Cipher) ->
    case Cipher of
        {aes, _, Key} ->
            Key
    end.

-file("src/kryptos/block.gleam", 431).
?DOC(false).
-spec is_ctr(cipher_context()) -> boolean().
is_ctr(Ctx) ->
    case Ctx of
        {ctr, _, _} ->
            true;

        _ ->
            false
    end.

-file("src/kryptos/block.gleam", 272).
-spec do_wrap(block_cipher(), bitstring()) -> {ok, bitstring()} | {error, nil}.
do_wrap(Cipher, Plaintext) ->
    N = erlang:byte_size(Plaintext) div 8,
    R = split_into_blocks(Plaintext, []),
    {A, R_final} = wrap_rounds(
        Cipher,
        <<16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6>>,
        R,
        N,
        0
    ),
    {ok, gleam_stdlib:bit_array_concat([A | R_final])}.

-file("src/kryptos/block.gleam", 259).
?DOC(
    " Wraps key material using AES Key Wrap (RFC 3394).\n"
    "\n"
    " Key wrapping is used to protect cryptographic keys when they need to be\n"
    " transported or stored. Unlike general encryption, key wrapping:\n"
    " - Does not require an IV (uses a default IV internally)\n"
    " - Provides integrity protection\n"
    " - Output is always 8 bytes larger than input\n"
    "\n"
    " The plaintext must be a multiple of 8 bytes, minimum 16 bytes.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/block\n"
    " import kryptos/crypto\n"
    "\n"
    " let assert Ok(kek) = block.aes_256(crypto.random_bytes(32))\n"
    " let key_to_wrap = crypto.random_bytes(32)\n"
    " let assert Ok(wrapped) = block.wrap(kek, key_to_wrap)\n"
    " ```\n"
).
-spec wrap(block_cipher(), bitstring()) -> {ok, bitstring()} | {error, nil}.
wrap(Cipher, Plaintext) ->
    Size = erlang:byte_size(Plaintext),
    case (Size >= 16) andalso ((Size rem 8) =:= 0) of
        true ->
            do_wrap(Cipher, Plaintext);

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 347).
-spec do_unwrap(block_cipher(), bitstring()) -> {ok, bitstring()} | {error, nil}.
do_unwrap(Cipher, Ciphertext) ->
    {A@1, Rest@1} = case Ciphertext of
        <<A:8/binary, Rest/binary>> -> {A, Rest};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/block"/utf8>>,
                        function => <<"do_unwrap"/utf8>>,
                        line => 348,
                        value => _assert_fail,
                        start => 10166,
                        'end' => 10221,
                        pattern_start => 10177,
                        pattern_end => 10208})
    end,
    N = erlang:byte_size(Rest@1) div 8,
    R = split_into_blocks(Rest@1, []),
    {A_final, R_final} = unwrap_rounds(Cipher, A@1, R, N, 5),
    case fun kryptos_ffi:constant_time_equal/2(
        A_final,
        <<16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6, 16#a6>>
    ) of
        true ->
            {ok, gleam_stdlib:bit_array_concat(R_final)};

        false ->
            {error, nil}
    end.

-file("src/kryptos/block.gleam", 331).
?DOC(
    " Unwraps key material using AES Key Wrap (RFC 3394).\n"
    "\n"
    " The ciphertext must be a multiple of 8 bytes, minimum 24 bytes.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/block\n"
    "\n"
    " let assert Ok(kek) = block.aes_256(kek_bytes)\n"
    " let assert Ok(unwrapped) = block.unwrap(kek, wrapped_key)\n"
    " ```\n"
).
-spec unwrap(block_cipher(), bitstring()) -> {ok, bitstring()} | {error, nil}.
unwrap(Cipher, Ciphertext) ->
    Size = erlang:byte_size(Ciphertext),
    case (Size >= 24) andalso ((Size rem 8) =:= 0) of
        true ->
            do_unwrap(Cipher, Ciphertext);

        false ->
            {error, nil}
    end.
