-module(status_code).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\status_code.gleam").
-export([is_informational/1, is_successful/1, is_redirection/1, is_client_error/1, is_server_error/1]).

-file("src\\status_code.gleam", 129).
-spec is_informational(integer()) -> boolean().
is_informational(Status) ->
    (Status >= 100) andalso (Status =< 199).

-file("src\\status_code.gleam", 133).
-spec is_successful(integer()) -> boolean().
is_successful(Status) ->
    (Status >= 200) andalso (Status =< 299).

-file("src\\status_code.gleam", 137).
-spec is_redirection(integer()) -> boolean().
is_redirection(Status) ->
    (Status >= 300) andalso (Status =< 399).

-file("src\\status_code.gleam", 141).
-spec is_client_error(integer()) -> boolean().
is_client_error(Status) ->
    (Status >= 400) andalso (Status =< 499).

-file("src\\status_code.gleam", 145).
-spec is_server_error(integer()) -> boolean().
is_server_error(Status) ->
    (Status >= 500) andalso (Status =< 599).
