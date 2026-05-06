-module(operating_system_ffi).
-export([name/0]).

-spec name() -> bitstring().
name() ->
    case element(2, os:type()) of
        nt -> <<"windows_nt">>;
        Name -> atom_to_binary(Name)
    end.
