-module(glisten@socket).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/glisten/socket.gleam").
-export([reason_to_string/1]).
-export_type([socket_reason/0, listen_socket/0, socket/0]).

-type socket_reason() :: closed |
    timeout |
    badarg |
    terminated |
    eaddrinuse |
    eaddrnotavail |
    eafnosupport |
    ealready |
    econnaborted |
    econnrefused |
    econnreset |
    edestaddrreq |
    ehostdown |
    ehostunreach |
    einprogress |
    eisconn |
    emsgsize |
    enetdown |
    enetunreach |
    enopkg |
    enoprotoopt |
    enotconn |
    enotty |
    enotsock |
    eproto |
    eprotonosupport |
    eprototype |
    esocktnosupport |
    etimedout |
    ewouldblock |
    exbadport |
    exbadseq |
    eacces |
    eagain |
    ebadf |
    ebadmsg |
    ebusy |
    edeadlk |
    edeadlock |
    edquot |
    eexist |
    efault |
    efbig |
    eftype |
    eintr |
    einval |
    eio |
    eisdir |
    eloop |
    emfile |
    emlink |
    emultihop |
    enametoolong |
    enfile |
    enobufs |
    enodev |
    enolck |
    enolink |
    enoent |
    enomem |
    enospc |
    enosr |
    enostr |
    enosys |
    enotblk |
    enotdir |
    enotsup |
    enxio |
    eopnotsupp |
    eoverflow |
    eperm |
    epipe |
    erange |
    erofs |
    espipe |
    esrch |
    estale |
    etxtbsy |
    exdev.

-type listen_socket() :: any().

-type socket() :: any().

-file("src/glisten/socket.gleam", 87).
-spec reason_to_string(socket_reason()) -> binary().
reason_to_string(Reason) ->
    case Reason of
        closed ->
            <<"Closed"/utf8>>;

        timeout ->
            <<"Timeout"/utf8>>;

        badarg ->
            <<"Badarg"/utf8>>;

        terminated ->
            <<"Terminated"/utf8>>;

        eaddrinuse ->
            <<"Eaddrinuse"/utf8>>;

        eaddrnotavail ->
            <<"Eaddrnotavail"/utf8>>;

        eafnosupport ->
            <<"Eafnosupport"/utf8>>;

        ealready ->
            <<"Ealready"/utf8>>;

        econnaborted ->
            <<"Econnaborted"/utf8>>;

        econnrefused ->
            <<"Econnrefused"/utf8>>;

        econnreset ->
            <<"Econnreset"/utf8>>;

        edestaddrreq ->
            <<"Edestaddrreq"/utf8>>;

        ehostdown ->
            <<"Ehostdown"/utf8>>;

        ehostunreach ->
            <<"Ehostunreach"/utf8>>;

        einprogress ->
            <<"Einprogress"/utf8>>;

        eisconn ->
            <<"Eisconn"/utf8>>;

        emsgsize ->
            <<"Emsgsize"/utf8>>;

        enetdown ->
            <<"Enetdown"/utf8>>;

        enetunreach ->
            <<"Enetunreach"/utf8>>;

        enopkg ->
            <<"Enopkg"/utf8>>;

        enoprotoopt ->
            <<"Enoprotoopt"/utf8>>;

        enotconn ->
            <<"Enotconn"/utf8>>;

        enotty ->
            <<"Enotty"/utf8>>;

        enotsock ->
            <<"Enotsock"/utf8>>;

        eproto ->
            <<"Eproto"/utf8>>;

        eprotonosupport ->
            <<"Eprotonosupport"/utf8>>;

        eprototype ->
            <<"Eprototype"/utf8>>;

        esocktnosupport ->
            <<"Esocktnosupport"/utf8>>;

        etimedout ->
            <<"Etimedout"/utf8>>;

        ewouldblock ->
            <<"Ewouldblock"/utf8>>;

        exbadport ->
            <<"Exbadport"/utf8>>;

        exbadseq ->
            <<"Exbadseq"/utf8>>;

        eacces ->
            <<"Eacces"/utf8>>;

        eagain ->
            <<"Eagain"/utf8>>;

        ebadf ->
            <<"Ebadf"/utf8>>;

        ebadmsg ->
            <<"Ebadmsg"/utf8>>;

        ebusy ->
            <<"Ebusy"/utf8>>;

        edeadlk ->
            <<"Edeadlk"/utf8>>;

        edeadlock ->
            <<"Edeadlock"/utf8>>;

        edquot ->
            <<"Edquot"/utf8>>;

        eexist ->
            <<"Eexist"/utf8>>;

        efault ->
            <<"Efault"/utf8>>;

        efbig ->
            <<"Efbig"/utf8>>;

        eftype ->
            <<"Eftype"/utf8>>;

        eintr ->
            <<"Eintr"/utf8>>;

        einval ->
            <<"Einval"/utf8>>;

        eio ->
            <<"Eio"/utf8>>;

        eisdir ->
            <<"Eisdir"/utf8>>;

        eloop ->
            <<"Eloop"/utf8>>;

        emfile ->
            <<"Emfile"/utf8>>;

        emlink ->
            <<"Emlink"/utf8>>;

        emultihop ->
            <<"Emultihop"/utf8>>;

        enametoolong ->
            <<"Enametoolong"/utf8>>;

        enfile ->
            <<"Enfile"/utf8>>;

        enobufs ->
            <<"Enobufs"/utf8>>;

        enodev ->
            <<"Enodev"/utf8>>;

        enolck ->
            <<"Enolck"/utf8>>;

        enolink ->
            <<"Enolink"/utf8>>;

        enoent ->
            <<"Enoent"/utf8>>;

        enomem ->
            <<"Enomem"/utf8>>;

        enospc ->
            <<"Enospc"/utf8>>;

        enosr ->
            <<"Enosr"/utf8>>;

        enostr ->
            <<"Enostr"/utf8>>;

        enosys ->
            <<"Enosys"/utf8>>;

        enotblk ->
            <<"Enotblk"/utf8>>;

        enotdir ->
            <<"Enotdir"/utf8>>;

        enotsup ->
            <<"Enotsup"/utf8>>;

        enxio ->
            <<"Enxio"/utf8>>;

        eopnotsupp ->
            <<"Eopnotsupp"/utf8>>;

        eoverflow ->
            <<"Eoverflow"/utf8>>;

        eperm ->
            <<"Eperm"/utf8>>;

        epipe ->
            <<"Epipe"/utf8>>;

        erange ->
            <<"Erange"/utf8>>;

        erofs ->
            <<"Erofs"/utf8>>;

        espipe ->
            <<"Espipe"/utf8>>;

        esrch ->
            <<"Esrch"/utf8>>;

        estale ->
            <<"Estale"/utf8>>;

        etxtbsy ->
            <<"Etxtbsy"/utf8>>;

        exdev ->
            <<"Exdev"/utf8>>
    end.
