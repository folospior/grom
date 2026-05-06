-module(glisten@socket@options).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/glisten/socket/options.gleam").
-export([to_erl_options/1, merge_type_list/2, merge_with_defaults/1]).
-export_type([socket_mode/0, active_state/0, interface/0, tls_certs/0, tcp_option/0, erlang_tcp_option/0, ip_address/0]).

-type socket_mode() :: binary.

-type active_state() :: once | passive | {count, integer()} | active.

-type interface() :: {address, ip_address()} | any | loopback.

-type tls_certs() :: {cert_key_files, binary(), binary()}.

-type tcp_option() :: {backlog, integer()} |
    {nodelay, boolean()} |
    {linger, {boolean(), integer()}} |
    {send_timeout, integer()} |
    {send_timeout_close, boolean()} |
    {reuseaddr, boolean()} |
    {active_mode, active_state()} |
    {mode, socket_mode()} |
    {cert_key_config, tls_certs()} |
    {alpn_preferred_protocols, list(binary())} |
    ipv6 |
    {buffer, integer()} |
    {ip, interface()}.

-type erlang_tcp_option() :: any().

-type ip_address() :: {ip_v4, integer(), integer(), integer(), integer()} |
    {ip_v6,
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer(),
        integer()}.

-file("src/glisten/socket/options.gleam", 56).
-spec to_erl_options(list(tcp_option())) -> list(erlang_tcp_option()).
to_erl_options(Options) ->
    glisten_ffi:to_erl_tcp_options(Options).

-file("src/glisten/socket/options.gleam", 69).
-spec merge_type_list(list(FGJ), list(FGJ)) -> list(FGJ).
merge_type_list(Original, Override) ->
    glisten_ffi:merge_type_list(Original, Override).

-file("src/glisten/socket/options.gleam", 71).
-spec merge_with_defaults(list(tcp_option())) -> list(tcp_option()).
merge_with_defaults(Options) ->
    glisten_ffi:merge_type_list(
        [{backlog, 1024},
            {nodelay, true},
            {send_timeout, 30000},
            {send_timeout_close, true},
            {reuseaddr, true},
            {mode, binary},
            {active_mode, passive}],
        Options
    ).
