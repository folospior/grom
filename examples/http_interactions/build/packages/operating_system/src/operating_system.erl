-module(operating_system).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).
-define(FILEPATH, "src/operating_system.gleam").
-export([name/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " This package exposes a function - `name`, which returns the name of the\n"
    " current operating system, as reported by `uname`.\n"
).

-file("src/operating_system.gleam", 7).
?DOC(" Returns the operating system name, as returned by `uname -s`, in lowercase.\n").
-spec name() -> binary().
name() ->
    operating_system_ffi:name().
