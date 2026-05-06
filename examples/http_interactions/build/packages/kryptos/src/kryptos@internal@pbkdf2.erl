-module(kryptos@internal@pbkdf2).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/pbkdf2.gleam").
-export([do_derive/5]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/pbkdf2.gleam", 10).
?DOC(false).
-spec do_derive(
    kryptos@hash:hash_algorithm(),
    bitstring(),
    bitstring(),
    integer(),
    integer()
) -> {ok, bitstring()} | {error, nil}.
do_derive(Algorithm, Password, Salt, Iterations, Length) ->
    kryptos_ffi:pbkdf2_derive(Algorithm, Password, Salt, Iterations, Length).
