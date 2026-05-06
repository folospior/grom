-module(kryptos@internal@x509).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/internal/x509.gleam").
-export([verify_signature/4, parse_sequence_with_header/1, parse_signature_algorithm/1, parse_name/1, encode_name/1, parse_public_key/1, parse_general_name/2, parse_general_names/3, encode_general_name/1, parse_single_extension/1, parse_san_extension/2, encode_algorithm_identifier/1, extract_spki_public_key_bytes/1, decode_pem_all/3, decode_pem/3, encode_pem/3, encode_san_extension/2, rsa_sig_alg_info/1, ecdsa_sig_alg_info/1, eddsa_sig_alg_info/1]).
-export_type([pem_error/0, sig_alg_info/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(false).

-type pem_error() :: pem_not_found | pem_malformed.

-type sig_alg_info() :: {sig_alg_info, kryptos@x509:oid(), boolean()}.

-file("src/kryptos/internal/x509.gleam", 103).
?DOC(false).
-spec sig_alg_to_hash(kryptos@x509:signature_algorithm()) -> {ok,
        kryptos@hash:hash_algorithm()} |
    {error, nil}.
sig_alg_to_hash(Sig_alg) ->
    case Sig_alg of
        ecdsa_sha1 ->
            {ok, sha1};

        rsa_sha1 ->
            {ok, sha1};

        ecdsa_sha256 ->
            {ok, sha256};

        rsa_sha256 ->
            {ok, sha256};

        ecdsa_sha384 ->
            {ok, sha384};

        rsa_sha384 ->
            {ok, sha384};

        ecdsa_sha512 ->
            {ok, sha512};

        rsa_sha512 ->
            {ok, sha512};

        ed25519 ->
            {error, nil};

        ed448 ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 79).
?DOC(false).
-spec verify_signature(
    kryptos@x509:public_key(),
    bitstring(),
    bitstring(),
    kryptos@x509:signature_algorithm()
) -> boolean().
verify_signature(Public_key, Data, Signature, Signature_algorithm) ->
    case {Public_key, Signature_algorithm} of
        {{ec_public_key, Key}, Sig_alg} ->
            case sig_alg_to_hash(Sig_alg) of
                {ok, Hash_alg} ->
                    kryptos_ffi:ecdsa_verify(Key, Data, Signature, Hash_alg);

                {error, nil} ->
                    false
            end;

        {{rsa_public_key, Key@1}, Sig_alg@1} ->
            case sig_alg_to_hash(Sig_alg@1) of
                {ok, Hash_alg@1} ->
                    kryptos_ffi:rsa_verify(
                        Key@1,
                        Data,
                        Signature,
                        Hash_alg@1,
                        pkcs1v15
                    );

                {error, nil} ->
                    false
            end;

        {{ed_public_key, Key@2}, ed25519} ->
            kryptos_ffi:eddsa_verify(Key@2, Data, Signature);

        {{ed_public_key, Key@2}, ed448} ->
            kryptos_ffi:eddsa_verify(Key@2, Data, Signature);

        {{ed_public_key, _}, _} ->
            false;

        {{xdh_public_key, _}, _} ->
            false
    end.

-file("src/kryptos/internal/x509.gleam", 119).
?DOC(false).
-spec parse_sequence_with_header(bitstring()) -> {ok,
        {bitstring(), bitstring()}} |
    {error, nil}.
parse_sequence_with_header(Bytes) ->
    case Bytes of
        <<16#30, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Inner, Remaining} = _use0,
                    Inner_len = erlang:byte_size(Inner),
                    Header_len = (erlang:byte_size(Bytes) - erlang:byte_size(
                        Remaining
                    ))
                    - Inner_len,
                    Total_len = Header_len + Inner_len,
                    Full_seq@1 = case gleam_stdlib:bit_array_slice(
                        Bytes,
                        0,
                        Total_len
                    ) of
                        {ok, Full_seq} -> Full_seq;
                        _assert_fail ->
                            erlang:error(#{gleam_error => let_assert,
                                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                        file => <<?FILEPATH/utf8>>,
                                        module => <<"kryptos/internal/x509"/utf8>>,
                                        function => <<"parse_sequence_with_header"/utf8>>,
                                        line => 130,
                                        value => _assert_fail,
                                        start => 4174,
                                        'end' => 4236,
                                        pattern_start => 4185,
                                        pattern_end => 4197})
                    end,
                    {ok, {Full_seq@1, Remaining}}
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 141).
?DOC(false).
-spec parse_signature_algorithm(bitstring()) -> {ok,
        kryptos@x509:signature_algorithm()} |
    {error, kryptos@x509:oid()}.
parse_signature_algorithm(Bytes) ->
    case kryptos@internal@der:parse_oid(Bytes) of
        {ok, {Oid_components, _}} ->
            case Oid_components of
                [1, 2, 840, 113549, 1, 1, 5] ->
                    {ok, rsa_sha1};

                [1, 2, 840, 113549, 1, 1, 11] ->
                    {ok, rsa_sha256};

                [1, 2, 840, 113549, 1, 1, 12] ->
                    {ok, rsa_sha384};

                [1, 2, 840, 113549, 1, 1, 13] ->
                    {ok, rsa_sha512};

                [1, 2, 840, 10045, 4, 1] ->
                    {ok, ecdsa_sha1};

                [1, 2, 840, 10045, 4, 3, 2] ->
                    {ok, ecdsa_sha256};

                [1, 2, 840, 10045, 4, 3, 3] ->
                    {ok, ecdsa_sha384};

                [1, 2, 840, 10045, 4, 3, 4] ->
                    {ok, ecdsa_sha512};

                [1, 3, 101, 112] ->
                    {ok, ed25519};

                [1, 3, 101, 113] ->
                    {ok, ed448};

                _ ->
                    {error, {oid, Oid_components}}
            end;

        {error, _} ->
            {error, {oid, []}}
    end.

-file("src/kryptos/internal/x509.gleam", 206).
?DOC(false).
-spec parse_attribute_value(bitstring()) -> {ok,
        {kryptos@x509:attribute_value(), bitstring()}} |
    {error, nil}.
parse_attribute_value(Bytes) ->
    case Bytes of
        <<16#0c, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_utf8_string(Bytes),
                fun(_use0) ->
                    {S, Rest} = _use0,
                    {ok, {kryptos@x509:utf8_string(S), Rest}}
                end
            );

        <<16#13, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_printable_string(Bytes),
                fun(_use0@1) ->
                    {S@1, Rest@1} = _use0@1,
                    {ok, {kryptos@x509:printable_string(S@1), Rest@1}}
                end
            );

        <<16#14, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_teletex_string(Bytes),
                fun(_use0@2) ->
                    {S@2, Rest@2} = _use0@2,
                    {ok, {kryptos@x509:utf8_string(S@2), Rest@2}}
                end
            );

        <<16#16, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_ia5_string(Bytes),
                fun(_use0@3) ->
                    {S@3, Rest@3} = _use0@3,
                    {ok, {kryptos@x509:ia5_string(S@3), Rest@3}}
                end
            );

        <<16#1c, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_universal_string(Bytes),
                fun(_use0@4) ->
                    {S@4, Rest@4} = _use0@4,
                    {ok, {kryptos@x509:utf8_string(S@4), Rest@4}}
                end
            );

        <<16#1e, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_bmp_string(Bytes),
                fun(_use0@5) ->
                    {S@5, Rest@5} = _use0@5,
                    {ok, {kryptos@x509:utf8_string(S@5), Rest@5}}
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 189).
?DOC(false).
-spec parse_rdn_attributes(
    bitstring(),
    list({kryptos@x509:oid(), kryptos@x509:attribute_value()})
) -> {ok, list({kryptos@x509:oid(), kryptos@x509:attribute_value()})} |
    {error, nil}.
parse_rdn_attributes(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, lists:reverse(Acc)};

        _ ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Attr_bytes, Rest} = _use0,
                    gleam@result:'try'(
                        kryptos@internal@der:parse_oid(Attr_bytes),
                        fun(_use0@1) ->
                            {Oid_components, After_oid} = _use0@1,
                            gleam@result:'try'(
                                parse_attribute_value(After_oid),
                                fun(_use0@2) ->
                                    {Value, Remaining} = _use0@2,
                                    gleam@bool:guard(
                                        Remaining /= <<>>,
                                        {error, nil},
                                        fun() ->
                                            parse_rdn_attributes(
                                                Rest,
                                                [{{oid, Oid_components}, Value} |
                                                    Acc]
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
    end.

-file("src/kryptos/internal/x509.gleam", 172).
?DOC(false).
-spec parse_rdns(bitstring(), list(kryptos@x509:rdn())) -> {ok,
        list(kryptos@x509:rdn())} |
    {error, nil}.
parse_rdns(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, lists:reverse(Acc)};

        _ ->
            gleam@result:'try'(
                kryptos@internal@der:parse_set(Bytes),
                fun(_use0) ->
                    {Rdn_bytes, Rest} = _use0,
                    _pipe = parse_rdn_attributes(Rdn_bytes, []),
                    gleam@result:'try'(
                        _pipe,
                        fun(Attributes) ->
                            parse_rdns(Rest, [{rdn, Attributes} | Acc])
                        end
                    )
                end
            )
    end.

-file("src/kryptos/internal/x509.gleam", 167).
?DOC(false).
-spec parse_name(bitstring()) -> {ok, kryptos@x509:name()} | {error, nil}.
parse_name(Bytes) ->
    _pipe = parse_rdns(Bytes, []),
    gleam@result:map(_pipe, fun(Field@0) -> {name, Field@0} end).

-file("src/kryptos/internal/x509.gleam", 264).
?DOC(false).
-spec encode_attribute_type_and_value(
    {kryptos@x509:oid(), kryptos@x509:attribute_value()}
) -> {ok, bitstring()} | {error, nil}.
encode_attribute_type_and_value(Attr) ->
    {{oid, Oid_components}, Value} = Attr,
    gleam@result:'try'(
        kryptos@x509:encode_attribute_value(Value),
        fun(Encoded_value) ->
            gleam@result:'try'(
                kryptos@internal@der:encode_oid(Oid_components),
                fun(Oid_encoded) ->
                    kryptos@internal@der:encode_sequence(
                        gleam_stdlib:bit_array_concat(
                            [Oid_encoded, Encoded_value]
                        )
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 254).
?DOC(false).
-spec encode_rdn(kryptos@x509:rdn()) -> {ok, bitstring()} | {error, nil}.
encode_rdn(Rdn) ->
    {rdn, Attributes} = Rdn,
    gleam@result:'try'(
        gleam@list:try_map(Attributes, fun encode_attribute_type_and_value/1),
        fun(Encoded_attrs) ->
            Sorted_attrs = gleam@list:sort(
                Encoded_attrs,
                fun gleam@bit_array:compare/2
            ),
            kryptos@internal@der:encode_set(
                gleam_stdlib:bit_array_concat(Sorted_attrs)
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 245).
?DOC(false).
-spec encode_name(kryptos@x509:name()) -> {ok, bitstring()} | {error, nil}.
encode_name(Name) ->
    {name, Rdns} = Name,
    _pipe = gleam@list:try_map(Rdns, fun encode_rdn/1),
    gleam@result:'try'(
        _pipe,
        fun(Encoded_rdns) ->
            kryptos@internal@der:encode_sequence(
                gleam_stdlib:bit_array_concat(Encoded_rdns)
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 297).
?DOC(false).
-spec dispatch_public_key_parse(list(integer()), bitstring()) -> {ok,
        kryptos@x509:public_key()} |
    {error, kryptos@x509:oid()}.
dispatch_public_key_parse(Alg_oid, Spki_bytes) ->
    case Alg_oid of
        [1, 2, 840, 10045, 2, 1] ->
            _pipe = kryptos_ffi:ec_import_public_key_der(Spki_bytes),
            _pipe@1 = gleam@result:map(
                _pipe,
                fun(Field@0) -> {ec_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@1, {oid, Alg_oid});

        [1, 2, 840, 113549, 1, 1, 1] ->
            _pipe@2 = kryptos_ffi:rsa_import_public_key_der(Spki_bytes, spki),
            _pipe@3 = gleam@result:map(
                _pipe@2,
                fun(Field@0) -> {rsa_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@3, {oid, Alg_oid});

        [1, 3, 101, 110] ->
            _pipe@4 = kryptos_ffi:xdh_import_public_key_der(Spki_bytes),
            _pipe@5 = gleam@result:map(
                _pipe@4,
                fun(Field@0) -> {xdh_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@5, {oid, Alg_oid});

        [1, 3, 101, 111] ->
            _pipe@4 = kryptos_ffi:xdh_import_public_key_der(Spki_bytes),
            _pipe@5 = gleam@result:map(
                _pipe@4,
                fun(Field@0) -> {xdh_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@5, {oid, Alg_oid});

        [1, 3, 101, 112] ->
            _pipe@6 = kryptos_ffi:eddsa_import_public_key_der(Spki_bytes),
            _pipe@7 = gleam@result:map(
                _pipe@6,
                fun(Field@0) -> {ed_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@7, {oid, Alg_oid});

        [1, 3, 101, 113] ->
            _pipe@6 = kryptos_ffi:eddsa_import_public_key_der(Spki_bytes),
            _pipe@7 = gleam@result:map(
                _pipe@6,
                fun(Field@0) -> {ed_public_key, Field@0} end
            ),
            gleam@result:replace_error(_pipe@7, {oid, Alg_oid});

        _ ->
            {error, {oid, Alg_oid}}
    end.

-file("src/kryptos/internal/x509.gleam", 277).
?DOC(false).
-spec parse_public_key(bitstring()) -> {ok, kryptos@x509:public_key()} |
    {error, kryptos@x509:oid()}.
parse_public_key(Spki_bytes) ->
    Result = begin
        _pipe = begin
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Spki_bytes),
                fun(_use0) ->
                    {Spki_content, _} = _use0,
                    gleam@result:'try'(
                        kryptos@internal@der:parse_sequence(Spki_content),
                        fun(_use0@1) ->
                            {Alg_id_bytes, After_alg} = _use0@1,
                            gleam@result:'try'(
                                kryptos@internal@der:parse_oid(Alg_id_bytes),
                                fun(_use0@2) ->
                                    {Alg_oid, _} = _use0@2,
                                    gleam@result:'try'(
                                        kryptos@internal@der:parse_bit_string(
                                            After_alg
                                        ),
                                        fun(_) -> {ok, Alg_oid} end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end,
        gleam@result:replace_error(_pipe, {oid, []})
    end,
    _pipe@1 = Result,
    gleam@result:'try'(
        _pipe@1,
        fun(_capture) -> dispatch_public_key_parse(_capture, Spki_bytes) end
    ).

-file("src/kryptos/internal/x509.gleam", 350).
?DOC(false).
-spec parse_general_name(bitstring(), boolean()) -> {ok,
        {kryptos@x509:subject_alt_name(), bitstring()}} |
    {error, nil}.
parse_general_name(Bytes, Is_critical) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_tlv(Bytes),
        fun(_use0) ->
            {Tag, Value, Rest} = _use0,
            case Tag of
                16#a0 ->
                    gleam@result:'try'(
                        kryptos@internal@der:parse_oid(Value),
                        fun(_use0@1) ->
                            {Oid_components, After_oid} = _use0@1,
                            gleam@result:'try'(
                                kryptos@internal@der:parse_context_tag(
                                    After_oid,
                                    0
                                ),
                                fun(_use0@2) ->
                                    {Other_value, _} = _use0@2,
                                    {ok,
                                        {{other_name,
                                                {oid, Oid_components},
                                                Other_value},
                                            Rest}}
                                end
                            )
                        end
                    );

                16#81 ->
                    _pipe = gleam@bit_array:to_string(Value),
                    gleam@result:map(_pipe, fun(S) -> {{email, S}, Rest} end);

                16#82 ->
                    _pipe@1 = gleam@bit_array:to_string(Value),
                    gleam@result:map(
                        _pipe@1,
                        fun(S@1) -> {{dns_name, S@1}, Rest} end
                    );

                16#a4 ->
                    gleam@result:'try'(
                        kryptos@internal@der:parse_sequence(Value),
                        fun(_use0@3) ->
                            {Name_content, Remaining} = _use0@3,
                            gleam@bool:guard(
                                Remaining /= <<>>,
                                {error, nil},
                                fun() ->
                                    gleam@result:'try'(
                                        parse_name(Name_content),
                                        fun(Name) ->
                                            {ok, {{directory_name, Name}, Rest}}
                                        end
                                    )
                                end
                            )
                        end
                    );

                16#86 ->
                    _pipe@2 = gleam@bit_array:to_string(Value),
                    gleam@result:map(
                        _pipe@2,
                        fun(S@2) -> {{uri, S@2}, Rest} end
                    );

                16#87 ->
                    {ok, {{ip_address, Value}, Rest}};

                16#88 ->
                    gleam@result:'try'(
                        kryptos@internal@der:decode_oid_components(Value),
                        fun(Oid_components@1) ->
                            {ok,
                                {{registered_id, {oid, Oid_components@1}}, Rest}}
                        end
                    );

                _ ->
                    case Is_critical of
                        true ->
                            {error, nil};

                        false ->
                            {ok, {{unknown, Tag, Value}, Rest}}
                    end
            end
        end
    ).

-file("src/kryptos/internal/x509.gleam", 331).
?DOC(false).
-spec parse_general_names(
    bitstring(),
    list(kryptos@x509:subject_alt_name()),
    boolean()
) -> {ok, list(kryptos@x509:subject_alt_name())} | {error, nil}.
parse_general_names(Bytes, Acc, Is_critical) ->
    case Bytes of
        <<>> ->
            {ok, lists:reverse(Acc)};

        _ ->
            gleam@result:'try'(
                parse_general_name(Bytes, Is_critical),
                fun(_use0) ->
                    {San, Rest} = _use0,
                    parse_general_names(Rest, [San | Acc], Is_critical)
                end
            )
    end.

-file("src/kryptos/internal/x509.gleam", 407).
?DOC(false).
-spec encode_general_name(kryptos@x509:subject_alt_name()) -> {ok, bitstring()} |
    {error, nil}.
encode_general_name(San) ->
    case San of
        {dns_name, Name} ->
            kryptos@internal@der:encode_context_primitive_tag(
                2,
                gleam_stdlib:identity(Name)
            );

        {email, Email} ->
            kryptos@internal@der:encode_context_primitive_tag(
                1,
                gleam_stdlib:identity(Email)
            );

        {ip_address, Ip} ->
            kryptos@internal@der:encode_context_primitive_tag(7, Ip);

        {uri, Uri} ->
            kryptos@internal@der:encode_context_primitive_tag(
                6,
                gleam_stdlib:identity(Uri)
            );

        {directory_name, Name@1} ->
            gleam@result:'try'(
                encode_name(Name@1),
                fun(Encoded_name) ->
                    kryptos@internal@der:encode_context_tag(4, Encoded_name)
                end
            );

        {registered_id, {oid, Components}} ->
            gleam@result:'try'(
                kryptos@internal@der:encode_oid(Components),
                fun(Oid_encoded) ->
                    gleam@result:'try'(
                        kryptos@internal@der:parse_tlv(Oid_encoded),
                        fun(_use0) ->
                            {_, Oid_content, _} = _use0,
                            kryptos@internal@der:encode_context_primitive_tag(
                                8,
                                Oid_content
                            )
                        end
                    )
                end
            );

        {other_name, {oid, Oid_components}, Value} ->
            gleam@result:'try'(
                kryptos@internal@der:encode_oid(Oid_components),
                fun(Oid_encoded@1) ->
                    gleam@result:'try'(
                        kryptos@internal@der:encode_context_tag(0, Value),
                        fun(Value_tagged) ->
                            Content = gleam_stdlib:bit_array_concat(
                                [Oid_encoded@1, Value_tagged]
                            ),
                            kryptos@internal@der:encode_context_tag(0, Content)
                        end
                    )
                end
            );

        {unknown, _, _} ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 440).
?DOC(false).
-spec parse_single_extension(bitstring()) -> {ok,
        {kryptos@x509:oid(), boolean(), bitstring()}} |
    {error, nil}.
parse_single_extension(Bytes) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_oid(Bytes),
        fun(_use0) ->
            {Oid_components, After_oid} = _use0,
            {Is_critical, After_critical} = case After_oid of
                <<16#01, 16#01, Critical_byte, Rest/bitstring>> ->
                    {Critical_byte /= 0, Rest};

                Other ->
                    {false, Other}
            end,
            gleam@result:'try'(
                kryptos@internal@der:parse_octet_string(After_critical),
                fun(_use0@1) ->
                    {Value, Remaining} = _use0@1,
                    gleam@bool:guard(
                        Remaining /= <<>>,
                        {error, nil},
                        fun() ->
                            {ok, {{oid, Oid_components}, Is_critical, Value}}
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 458).
?DOC(false).
-spec parse_san_extension(bitstring(), boolean()) -> {ok,
        list(kryptos@x509:subject_alt_name())} |
    {error, nil}.
parse_san_extension(Bytes, Is_critical) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_sequence(Bytes),
        fun(_use0) ->
            {San_content, _} = _use0,
            parse_general_names(San_content, [], Is_critical)
        end
    ).

-file("src/kryptos/internal/x509.gleam", 470).
?DOC(false).
-spec encode_algorithm_identifier(sig_alg_info()) -> {ok, bitstring()} |
    {error, nil}.
encode_algorithm_identifier(Sig_alg) ->
    {sig_alg_info, Oid, Include_null_params} = Sig_alg,
    {oid, Components} = Oid,
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Components),
        fun(Oid_encoded) -> case Include_null_params of
                true ->
                    kryptos@internal@der:encode_sequence(
                        gleam_stdlib:bit_array_concat(
                            [Oid_encoded, <<16#05, 16#00>>]
                        )
                    );

                false ->
                    kryptos@internal@der:encode_sequence(Oid_encoded)
            end end
    ).

-file("src/kryptos/internal/x509.gleam", 484).
?DOC(false).
-spec extract_spki_public_key_bytes(bitstring()) -> {ok, bitstring()} |
    {error, nil}.
extract_spki_public_key_bytes(Spki) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_sequence(Spki),
        fun(_use0) ->
            {Spki_content, _} = _use0,
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Spki_content),
                fun(_use0@1) ->
                    {_, After_alg} = _use0@1,
                    gleam@result:'try'(
                        kryptos@internal@der:parse_bit_string(After_alg),
                        fun(_use0@2) ->
                            {Pub_key_bytes, _} = _use0@2,
                            {ok, Pub_key_bytes}
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 538).
?DOC(false).
-spec extract_pem_body(
    list(binary()),
    boolean(),
    list(binary()),
    binary(),
    binary()
) -> {ok, {list(binary()), list(binary())}} | {error, pem_error()}.
extract_pem_body(Lines, In_body, Acc, Begin_marker, End_marker) ->
    case {Lines, In_body} of
        {[], false} ->
            {error, pem_not_found};

        {[], true} ->
            {error, pem_malformed};

        {[Line | Rest], false} ->
            case gleam_stdlib:string_starts_with(Line, Begin_marker) of
                true ->
                    extract_pem_body(Rest, true, Acc, Begin_marker, End_marker);

                false ->
                    extract_pem_body(Rest, false, Acc, Begin_marker, End_marker)
            end;

        {[Line@1 | Rest@1], true} ->
            case gleam_stdlib:string_starts_with(Line@1, End_marker) of
                true ->
                    {ok, {lists:reverse(Acc), Rest@1}};

                false ->
                    extract_pem_body(
                        Rest@1,
                        true,
                        [Line@1 | Acc],
                        Begin_marker,
                        End_marker
                    )
            end
    end.

-file("src/kryptos/internal/x509.gleam", 524).
?DOC(false).
-spec extract_all_pem_bodies(
    list(binary()),
    binary(),
    binary(),
    list(list(binary()))
) -> {ok, list(list(binary()))} | {error, nil}.
extract_all_pem_bodies(Lines, Begin_marker, End_marker, Acc) ->
    case extract_pem_body(Lines, false, [], Begin_marker, End_marker) of
        {error, pem_not_found} ->
            {ok, lists:reverse(Acc)};

        {error, pem_malformed} ->
            {error, nil};

        {ok, {Body, Remaining}} ->
            extract_all_pem_bodies(
                Remaining,
                Begin_marker,
                End_marker,
                [Body | Acc]
            )
    end.

-file("src/kryptos/internal/x509.gleam", 508).
?DOC(false).
-spec decode_pem_all(binary(), binary(), binary()) -> {ok, list(bitstring())} |
    {error, nil}.
decode_pem_all(Pem, Begin_marker, End_marker) ->
    Lines = gleam@string:split(Pem, <<"\n"/utf8>>),
    Lines@1 = gleam@list:map(Lines, fun gleam@string:trim/1),
    gleam@result:'try'(
        extract_all_pem_bodies(Lines@1, Begin_marker, End_marker, []),
        fun(Blocks) ->
            gleam@list:try_map(
                Blocks,
                fun(Body_lines) ->
                    Body = gleam@string:join(Body_lines, <<""/utf8>>),
                    gleam@bit_array:base64_decode(Body)
                end
            )
        end
    ).

-file("src/kryptos/internal/x509.gleam", 495).
?DOC(false).
-spec decode_pem(binary(), binary(), binary()) -> {ok, bitstring()} |
    {error, nil}.
decode_pem(Pem, Begin_marker, End_marker) ->
    _pipe = decode_pem_all(Pem, Begin_marker, End_marker),
    gleam@result:'try'(_pipe, fun gleam@list:first/1).

-file("src/kryptos/internal/x509.gleam", 568).
?DOC(false).
-spec encode_pem(bitstring(), binary(), binary()) -> binary().
encode_pem(Der, Begin_marker, End_marker) ->
    Encoded = gleam_stdlib:base64_encode(Der, true),
    Lines = begin
        _pipe = kryptos@internal@utils:chunk_string(Encoded, 64),
        gleam@list:map(_pipe, fun(Line) -> <<Line/binary, "\n"/utf8>> end)
    end,
    _pipe@1 = gleam@string_tree:new(),
    _pipe@2 = gleam@string_tree:append(
        _pipe@1,
        <<Begin_marker/binary, "\n"/utf8>>
    ),
    _pipe@3 = gleam_stdlib:iodata_append(_pipe@2, gleam_stdlib:identity(Lines)),
    _pipe@4 = gleam@string_tree:append(
        _pipe@3,
        <<End_marker/binary, "\n\n"/utf8>>
    ),
    unicode:characters_to_binary(_pipe@4).

-file("src/kryptos/internal/x509.gleam", 590).
?DOC(false).
-spec encode_san_extension(list(kryptos@x509:subject_alt_name()), boolean()) -> {ok,
        bitstring()} |
    {error, nil}.
encode_san_extension(Sans, Critical) ->
    Oid_components = [2, 5, 29, 17],
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) -> _pipe = Sans,
            _pipe@1 = lists:reverse(_pipe),
            _pipe@2 = gleam@list:try_map(_pipe@1, fun encode_general_name/1),
            _pipe@3 = gleam@result:map(
                _pipe@2,
                fun gleam_stdlib:bit_array_concat/1
            ),
            _pipe@4 = gleam@result:'try'(
                _pipe@3,
                fun kryptos@internal@der:encode_sequence/1
            ),
            _pipe@5 = gleam@result:'try'(
                _pipe@4,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@6 = gleam@result:map(
                _pipe@5,
                fun(Value_octet) -> case Critical of
                        true ->
                            gleam_stdlib:bit_array_concat(
                                [Oid_encoded,
                                    kryptos@internal@der:encode_bool(true),
                                    Value_octet]
                            );

                        false ->
                            gleam_stdlib:bit_array_concat(
                                [Oid_encoded, Value_octet]
                            )
                    end end
            ),
            gleam@result:'try'(
                _pipe@6,
                fun kryptos@internal@der:encode_sequence/1
            ) end
    ).

-file("src/kryptos/internal/x509.gleam", 60).
?DOC(false).
-spec rsa_sig_alg_info(kryptos@hash:hash_algorithm()) -> {ok, sig_alg_info()} |
    {error, nil}.
rsa_sig_alg_info(Hash) ->
    case Hash of
        sha1 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 113549, 1, 1, 5]}, true}};

        sha256 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 113549, 1, 1, 11]}, true}};

        sha384 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 113549, 1, 1, 12]}, true}};

        sha512 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 113549, 1, 1, 13]}, true}};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 49).
?DOC(false).
-spec ecdsa_sig_alg_info(kryptos@hash:hash_algorithm()) -> {ok, sig_alg_info()} |
    {error, nil}.
ecdsa_sig_alg_info(Hash) ->
    case Hash of
        sha1 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 10045, 4, 1]}, false}};

        sha256 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 10045, 4, 3, 2]}, false}};

        sha384 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 10045, 4, 3, 3]}, false}};

        sha512 ->
            {ok, {sig_alg_info, {oid, [1, 2, 840, 10045, 4, 3, 4]}, false}};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/internal/x509.gleam", 71).
?DOC(false).
-spec eddsa_sig_alg_info(kryptos@eddsa:curve()) -> sig_alg_info().
eddsa_sig_alg_info(Curve) ->
    case Curve of
        ed25519 ->
            {sig_alg_info, {oid, [1, 3, 101, 112]}, false};

        ed448 ->
            {sig_alg_info, {oid, [1, 3, 101, 113]}, false}
    end.
