-module(kryptos@ecdh).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/ecdh.gleam").
-export([compute_shared_secret/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " Elliptic Curve Diffie-Hellman (ECDH) key agreement.\n"
    "\n"
    " ECDH allows two parties to establish a shared secret over an insecure\n"
    " channel using elliptic curve key pairs. The shared secret can then be\n"
    " used with a key derivation function (KDF) to derive symmetric keys.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import kryptos/ec\n"
    " import kryptos/ecdh\n"
    "\n"
    " // Alice generates a key pair\n"
    " let #(alice_private, alice_public) = ec.generate_key_pair(ec.P256)\n"
    "\n"
    " // Bob generates a key pair\n"
    " let #(bob_private, bob_public) = ec.generate_key_pair(ec.P256)\n"
    "\n"
    " // Both compute the same shared secret\n"
    " let assert Ok(alice_shared) = ecdh.compute_shared_secret(alice_private, bob_public)\n"
    " let assert Ok(bob_shared) = ecdh.compute_shared_secret(bob_private, alice_public)\n"
    " // alice_shared == bob_shared\n"
    " ```\n"
).

-file("src/kryptos/ecdh.gleam", 37).
?DOC(
    " Computes a shared secret using ECDH key agreement.\n"
    "\n"
    " Both parties compute the same shared secret by combining their private key\n"
    " with the other party's public key. The result is the x-coordinate of the\n"
    " resulting elliptic curve point, returned as raw bytes.\n"
    "\n"
    " The raw shared secret should be passed through a KDF (like HKDF) before\n"
    " use as a symmetric key. Both keys must use the same curve.\n"
).
-spec compute_shared_secret(kryptos@ec:private_key(), kryptos@ec:public_key()) -> {ok,
        bitstring()} |
    {error, nil}.
compute_shared_secret(Private_key, Peer_public_key) ->
    kryptos_ffi:ecdh_compute_shared_secret(Private_key, Peer_public_key).
