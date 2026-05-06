-module(kryptos@internal@subtle).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/subtle.gleam").
-export([constant_time_equal/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-file("src/kryptos/internal/subtle.gleam", 8).
?DOC(false).
-spec constant_time_equal(bitstring(), bitstring()) -> boolean().
constant_time_equal(A, B) ->
    kryptos_ffi:constant_time_equal(A, B).
