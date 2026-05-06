-module(kryptos@x509@csr).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/x509/csr.gleam").
-export([new/0, with_subject/2, with_dns_name/2, with_email/2, with_ip/2, to_der/1, version/1, subject/1, public_key/1, signature_algorithm/1, subject_alt_names/1, extensions/1, attributes/1, from_der_unverified/1, from_der/1, sign_with_ecdsa/3, sign_with_rsa/3, sign_with_eddsa/2, to_pem/1, from_pem/1, from_pem_unverified/1]).
-export_type([built/0, parsed/0, csr/1, csr_error/0, builder/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " X.509 Certificate Signing Request (CSR) generation.\n"
    "\n"
    " Builder for creating PKCS#10 Certificate Signing Requests (CSRs).\n"
    " CSRs are used to request certificates from a Certificate Authority.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import gleam/result\n"
    " import kryptos/ec\n"
    " import kryptos/hash\n"
    " import kryptos/x509\n"
    " import kryptos/x509/csr\n"
    "\n"
    " let #(private_key, _) = ec.generate_key_pair(ec.P256)\n"
    "\n"
    " let subject = x509.name([\n"
    "   x509.cn(\"example.com\"),\n"
    "   x509.organization(\"Acme Inc\"),\n"
    "   x509.country(\"US\"),\n"
    " ])\n"
    "\n"
    " let assert Ok(builder) =\n"
    "   csr.new()\n"
    "   |> csr.with_subject(subject)\n"
    "   |> csr.with_dns_name(\"example.com\")\n"
    "   |> result.try(csr.with_dns_name(_, \"www.example.com\"))\n"
    "\n"
    " let assert Ok(my_csr) = csr.sign_with_ecdsa(builder, private_key, hash.Sha256)\n"
    "\n"
    " let pem = csr.to_pem(my_csr)\n"
    " ```\n"
).

-type built() :: any().

-type parsed() :: any().

-opaque csr(IXB) :: {built_csr, bitstring()} |
    {parsed_csr,
        bitstring(),
        integer(),
        kryptos@x509:name(),
        kryptos@x509:public_key(),
        kryptos@x509:signature_algorithm(),
        list(kryptos@x509:subject_alt_name()),
        list({kryptos@x509:oid(), boolean(), bitstring()}),
        list({kryptos@x509:oid(), bitstring()})} |
    {gleam_phantom, IXB}.

-type csr_error() :: invalid_pem |
    invalid_structure |
    {unsupported_signature_algorithm, kryptos@x509:oid()} |
    {unsupported_key_type, kryptos@x509:oid()} |
    signature_verification_failed |
    {unsupported_version, integer()}.

-opaque builder() :: {builder, kryptos@x509:name(), kryptos@x509:extensions()}.

-file("src/kryptos/x509/csr.gleam", 105).
?DOC(
    " Creates a new CSR builder with an empty subject and no extensions.\n"
    "\n"
    " Use the `with_*` functions to configure the builder, then call\n"
    " `sign_with_ecdsa` or `sign_with_rsa` to generate the signed CSR.\n"
).
-spec new() -> builder().
new() ->
    {builder, kryptos@x509:name([]), {extensions, []}}.

-file("src/kryptos/x509/csr.gleam", 113).
?DOC(" Sets the distinguished name subject for the CSR.\n").
-spec with_subject(builder(), kryptos@x509:name()) -> builder().
with_subject(Builder, Subject) ->
    {builder, Subject, erlang:element(3, Builder)}.

-file("src/kryptos/x509/csr.gleam", 122).
?DOC(
    " Adds a DNS name to the Subject Alternative Names extension.\n"
    "\n"
    " SANs allow a certificate to be valid for multiple hostnames. Modern\n"
    " browsers require the domain to appear in the SAN extension, not just\n"
    " the Common Name. The name must contain only ASCII characters.\n"
).
-spec with_dns_name(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_dns_name(Builder, Name) ->
    gleam@bool:guard(
        not kryptos@internal@utils:is_ascii(Name),
        {error, nil},
        fun() ->
            {extensions, Sans} = erlang:element(3, Builder),
            {ok,
                {builder,
                    erlang:element(2, Builder),
                    {extensions, [{dns_name, Name} | Sans]}}}
        end
    ).

-file("src/kryptos/x509/csr.gleam", 139).
?DOC(
    " Adds an email address to the Subject Alternative Names extension.\n"
    "\n"
    " Used for S/MIME certificates. The email must contain only ASCII characters.\n"
).
-spec with_email(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_email(Builder, Email) ->
    gleam@bool:guard(
        not kryptos@internal@utils:is_ascii(Email),
        {error, nil},
        fun() ->
            {extensions, Sans} = erlang:element(3, Builder),
            {ok,
                {builder,
                    erlang:element(2, Builder),
                    {extensions, [{email, Email} | Sans]}}}
        end
    ).

-file("src/kryptos/x509/csr.gleam", 153).
?DOC(
    " Adds an IP address to the Subject Alternative Names extension.\n"
    "\n"
    " Accepts IPv4 (e.g., \"192.168.1.1\") or IPv6 (e.g., \"2001:db8::1\") addresses.\n"
).
-spec with_ip(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_ip(Builder, Ip) ->
    gleam@result:'try'(
        kryptos@internal@utils:parse_ip(Ip),
        fun(Parsed) ->
            {extensions, Sans} = erlang:element(3, Builder),
            {ok,
                {builder,
                    erlang:element(2, Builder),
                    {extensions, [{ip_address, Parsed} | Sans]}}}
        end
    ).

-file("src/kryptos/x509/csr.gleam", 234).
?DOC(" Exports the CSR as DER-encoded bytes.\n").
-spec to_der(csr(any())) -> bitstring().
to_der(Csr) ->
    case Csr of
        {built_csr, Der} ->
            Der;

        {parsed_csr, Der@1, _, _, _, _, _, _, _} ->
            Der@1
    end.

-file("src/kryptos/x509/csr.gleam", 366).
?DOC(
    " Returns the version of a parsed CSR.\n"
    "\n"
    " PKCS#10 v1 CSRs always have version 0.\n"
).
-spec version(csr(parsed())) -> integer().
version(Csr) ->
    Version@1 = case Csr of
        {parsed_csr, _, Version, _, _, _, _, _, _} -> Version;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"version"/utf8>>,
                        line => 367,
                        value => _assert_fail,
                        start => 11643,
                        'end' => 11683,
                        pattern_start => 11654,
                        pattern_end => 11677})
    end,
    Version@1.

-file("src/kryptos/x509/csr.gleam", 372).
?DOC(" Returns the subject (distinguished name) of a parsed CSR.\n").
-spec subject(csr(parsed())) -> kryptos@x509:name().
subject(Csr) ->
    Subject@1 = case Csr of
        {parsed_csr, _, _, Subject, _, _, _, _, _} -> Subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"subject"/utf8>>,
                        line => 373,
                        value => _assert_fail,
                        start => 11809,
                        'end' => 11849,
                        pattern_start => 11820,
                        pattern_end => 11843})
    end,
    Subject@1.

-file("src/kryptos/x509/csr.gleam", 378).
?DOC(" Returns the public key embedded in a parsed CSR.\n").
-spec public_key(csr(parsed())) -> kryptos@x509:public_key().
public_key(Csr) ->
    Public_key@1 = case Csr of
        {parsed_csr, _, _, _, Public_key, _, _, _, _} -> Public_key;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"public_key"/utf8>>,
                        line => 379,
                        value => _assert_fail,
                        start => 11974,
                        'end' => 12017,
                        pattern_start => 11985,
                        pattern_end => 12011})
    end,
    Public_key@1.

-file("src/kryptos/x509/csr.gleam", 384).
?DOC(" Returns the signature algorithm used to sign the CSR.\n").
-spec signature_algorithm(csr(parsed())) -> kryptos@x509:signature_algorithm().
signature_algorithm(Csr) ->
    Signature_algorithm@1 = case Csr of
        {parsed_csr, _, _, _, _, Signature_algorithm, _, _, _} -> Signature_algorithm;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"signature_algorithm"/utf8>>,
                        line => 385,
                        value => _assert_fail,
                        start => 12168,
                        'end' => 12220,
                        pattern_start => 12179,
                        pattern_end => 12214})
    end,
    Signature_algorithm@1.

-file("src/kryptos/x509/csr.gleam", 390).
?DOC(" Returns the Subject Alternative Names from the CSR.\n").
-spec subject_alt_names(csr(parsed())) -> list(kryptos@x509:subject_alt_name()).
subject_alt_names(Csr) ->
    Subject_alt_names@1 = case Csr of
        {parsed_csr, _, _, _, _, _, Subject_alt_names, _, _} -> Subject_alt_names;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"subject_alt_names"/utf8>>,
                        line => 391,
                        value => _assert_fail,
                        start => 12378,
                        'end' => 12428,
                        pattern_start => 12389,
                        pattern_end => 12422})
    end,
    Subject_alt_names@1.

-file("src/kryptos/x509/csr.gleam", 400).
?DOC(
    " Returns any extensions beyond SANs as raw (OID, critical, value) tuples.\n"
    "\n"
    " This allows access to extensions that kryptos doesn't have typed\n"
    " representations for. The Bool indicates whether the extension was\n"
    " marked as critical per RFC 5280.\n"
).
-spec extensions(csr(parsed())) -> list({kryptos@x509:oid(),
    boolean(),
    bitstring()}).
extensions(Csr) ->
    Extensions@1 = case Csr of
        {parsed_csr, _, _, _, _, _, _, Extensions, _} -> Extensions;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"extensions"/utf8>>,
                        line => 401,
                        value => _assert_fail,
                        start => 12786,
                        'end' => 12829,
                        pattern_start => 12797,
                        pattern_end => 12823})
    end,
    Extensions@1.

-file("src/kryptos/x509/csr.gleam", 409).
?DOC(
    " Returns any non-extension attributes as raw (OID, value) pairs.\n"
    "\n"
    " Most CSRs only have the extensionRequest attribute, so this is\n"
    " typically empty.\n"
).
-spec attributes(csr(parsed())) -> list({kryptos@x509:oid(), bitstring()}).
attributes(Csr) ->
    Attributes@1 = case Csr of
        {parsed_csr, _, _, _, _, _, _, _, Attributes} -> Attributes;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"attributes"/utf8>>,
                        line => 410,
                        value => _assert_fail,
                        start => 13077,
                        'end' => 13120,
                        pattern_start => 13088,
                        pattern_end => 13114})
    end,
    Attributes@1.

-file("src/kryptos/x509/csr.gleam", 421).
-spec parse_version(bitstring()) -> {ok, integer()} | {error, csr_error()}.
parse_version(Bytes) ->
    case Bytes of
        <<0>> ->
            {ok, 0};

        <<V>> ->
            {error, {unsupported_version, V}};

        _ ->
            {error, invalid_structure}
    end.

-file("src/kryptos/x509/csr.gleam", 485).
-spec parse_single_attribute(bitstring()) -> {ok,
        {kryptos@x509:oid(), bitstring()}} |
    {error, nil}.
parse_single_attribute(Bytes) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_oid(Bytes),
        fun(_use0) ->
            {Oid_components, After_oid} = _use0,
            gleam@result:'try'(
                kryptos@internal@der:parse_set(After_oid),
                fun(_use0@1) ->
                    {Value, Remaining} = _use0@1,
                    gleam@bool:guard(
                        Remaining /= <<>>,
                        {error, nil},
                        fun() -> {ok, {{oid, Oid_components}, Value}} end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 506).
-spec parse_extensions(
    bitstring(),
    list(kryptos@x509:subject_alt_name()),
    list({kryptos@x509:oid(), boolean(), bitstring()})
) -> {ok,
        {list(kryptos@x509:subject_alt_name()),
            list({kryptos@x509:oid(), boolean(), bitstring()})}} |
    {error, nil}.
parse_extensions(Bytes, Sans, Exts) ->
    case Bytes of
        <<>> ->
            {ok, {Sans, lists:reverse(Exts)}};

        _ ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Ext_bytes, Rest} = _use0,
                    gleam@result:'try'(
                        kryptos@internal@x509:parse_single_extension(Ext_bytes),
                        fun(_use0@1) ->
                            {Oid, Is_critical, Value} = _use0@1,
                            case Oid of
                                {oid, [2, 5, 29, 17]} ->
                                    gleam@result:'try'(
                                        kryptos@internal@x509:parse_san_extension(
                                            Value,
                                            false
                                        ),
                                        fun(New_sans) ->
                                            parse_extensions(
                                                Rest,
                                                lists:append(Sans, New_sans),
                                                Exts
                                            )
                                        end
                                    );

                                _ ->
                                    parse_extensions(
                                        Rest,
                                        Sans,
                                        [{Oid, Is_critical, Value} | Exts]
                                    )
                            end
                        end
                    )
                end
            )
    end.

-file("src/kryptos/x509/csr.gleam", 492).
-spec parse_extension_request(bitstring()) -> {ok,
        {list(kryptos@x509:subject_alt_name()),
            list({kryptos@x509:oid(), boolean(), bitstring()})}} |
    {error, nil}.
parse_extension_request(Bytes) ->
    gleam@bool:guard(
        erlang:byte_size(Bytes) =:= 0,
        {ok, {[], []}},
        fun() ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Exts_content, _} = _use0,
                    parse_extensions(Exts_content, [], [])
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 450).
-spec parse_attributes_content(
    bitstring(),
    list(kryptos@x509:subject_alt_name()),
    list({kryptos@x509:oid(), boolean(), bitstring()}),
    list({kryptos@x509:oid(), bitstring()})
) -> {ok,
        {list(kryptos@x509:subject_alt_name()),
            list({kryptos@x509:oid(), boolean(), bitstring()}),
            list({kryptos@x509:oid(), bitstring()})}} |
    {error, nil}.
parse_attributes_content(Bytes, Sans, Exts, Attrs) ->
    case Bytes of
        <<>> ->
            {ok, {Sans, lists:reverse(Exts), lists:reverse(Attrs)}};

        _ ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Attr_bytes, Rest} = _use0,
                    gleam@result:'try'(
                        parse_single_attribute(Attr_bytes),
                        fun(_use0@1) ->
                            {Oid, Value} = _use0@1,
                            case Oid of
                                {oid, [1, 2, 840, 113549, 1, 9, 14]} ->
                                    gleam@result:'try'(
                                        parse_extension_request(Value),
                                        fun(_use0@2) ->
                                            {New_sans, New_exts} = _use0@2,
                                            parse_attributes_content(
                                                Rest,
                                                lists:append(Sans, New_sans),
                                                lists:append(Exts, New_exts),
                                                Attrs
                                            )
                                        end
                                    );

                                _ ->
                                    parse_attributes_content(
                                        Rest,
                                        Sans,
                                        Exts,
                                        [{Oid, Value} | Attrs]
                                    )
                            end
                        end
                    )
                end
            )
    end.

-file("src/kryptos/x509/csr.gleam", 429).
-spec parse_attributes(bitstring()) -> {ok,
        {list(kryptos@x509:subject_alt_name()),
            list({kryptos@x509:oid(), boolean(), bitstring()}),
            list({kryptos@x509:oid(), bitstring()})}} |
    {error, nil}.
parse_attributes(Bytes) ->
    case Bytes of
        <<16#a0, _/bitstring>> ->
            case kryptos@internal@der:parse_context_tag(Bytes, 0) of
                {ok, {Attrs_content, _}} ->
                    parse_attributes_content(Attrs_content, [], [], []);

                {error, _} ->
                    {error, nil}
            end;

        _ ->
            {ok, {[], [], []}}
    end.

-file("src/kryptos/x509/csr.gleam", 279).
?DOC(
    " Parse a DER-encoded CSR without verifying the signature.\n"
    "\n"
    " Useful for debugging malformed or partially valid CSRs.\n"
    " The parsed fields may not be trustworthy since the signature\n"
    " was not verified.\n"
).
-spec from_der_unverified(bitstring()) -> {ok, csr(parsed())} |
    {error, csr_error()}.
from_der_unverified(Der) ->
    gleam@result:'try'(
        begin
            _pipe = kryptos@internal@der:parse_sequence(Der),
            gleam@result:replace_error(_pipe, invalid_structure)
        end,
        fun(_use0) ->
            {Csr_content, Remaining} = _use0,
            gleam@bool:guard(
                erlang:byte_size(Remaining) /= 0,
                {error, invalid_structure},
                fun() ->
                    gleam@result:'try'(
                        begin
                            _pipe@1 = kryptos@internal@x509:parse_sequence_with_header(
                                Csr_content
                            ),
                            gleam@result:replace_error(
                                _pipe@1,
                                invalid_structure
                            )
                        end,
                        fun(_use0@1) ->
                            {Cert_req_info_bytes, After_info} = _use0@1,
                            gleam@result:'try'(
                                begin
                                    _pipe@2 = kryptos@internal@der:parse_sequence(
                                        Cert_req_info_bytes
                                    ),
                                    gleam@result:replace_error(
                                        _pipe@2,
                                        invalid_structure
                                    )
                                end,
                                fun(_use0@2) ->
                                    {Cert_req_info_content, _} = _use0@2,
                                    gleam@result:'try'(
                                        begin
                                            _pipe@3 = kryptos@internal@der:parse_integer(
                                                Cert_req_info_content
                                            ),
                                            gleam@result:replace_error(
                                                _pipe@3,
                                                invalid_structure
                                            )
                                        end,
                                        fun(_use0@3) ->
                                            {Version_bytes, After_version} = _use0@3,
                                            gleam@result:'try'(
                                                parse_version(Version_bytes),
                                                fun(Version) ->
                                                    gleam@result:'try'(
                                                        begin
                                                            _pipe@4 = kryptos@internal@der:parse_sequence(
                                                                After_version
                                                            ),
                                                            gleam@result:replace_error(
                                                                _pipe@4,
                                                                invalid_structure
                                                            )
                                                        end,
                                                        fun(_use0@4) ->
                                                            {Subject_bytes,
                                                                After_subject} = _use0@4,
                                                            gleam@result:'try'(
                                                                begin
                                                                    _pipe@5 = kryptos@internal@x509:parse_name(
                                                                        Subject_bytes
                                                                    ),
                                                                    gleam@result:replace_error(
                                                                        _pipe@5,
                                                                        invalid_structure
                                                                    )
                                                                end,
                                                                fun(Subject) ->
                                                                    gleam@result:'try'(
                                                                        begin
                                                                            _pipe@6 = kryptos@internal@x509:parse_sequence_with_header(
                                                                                After_subject
                                                                            ),
                                                                            gleam@result:replace_error(
                                                                                _pipe@6,
                                                                                invalid_structure
                                                                            )
                                                                        end,
                                                                        fun(
                                                                            _use0@5
                                                                        ) ->
                                                                            {Spki_bytes,
                                                                                After_spki} = _use0@5,
                                                                            gleam@result:'try'(
                                                                                begin
                                                                                    _pipe@7 = kryptos@internal@x509:parse_public_key(
                                                                                        Spki_bytes
                                                                                    ),
                                                                                    gleam@result:map_error(
                                                                                        _pipe@7,
                                                                                        fun(
                                                                                            Oid
                                                                                        ) ->
                                                                                            case Oid of
                                                                                                {oid,
                                                                                                    []} ->
                                                                                                    invalid_structure;

                                                                                                _ ->
                                                                                                    {unsupported_key_type,
                                                                                                        Oid}
                                                                                            end
                                                                                        end
                                                                                    )
                                                                                end,
                                                                                fun(
                                                                                    Public_key
                                                                                ) ->
                                                                                    gleam@result:'try'(
                                                                                        begin
                                                                                            _pipe@8 = parse_attributes(
                                                                                                After_spki
                                                                                            ),
                                                                                            gleam@result:replace_error(
                                                                                                _pipe@8,
                                                                                                invalid_structure
                                                                                            )
                                                                                        end,
                                                                                        fun(
                                                                                            _use0@6
                                                                                        ) ->
                                                                                            {Subject_alt_names,
                                                                                                Extensions,
                                                                                                Attributes} = _use0@6,
                                                                                            gleam@result:'try'(
                                                                                                begin
                                                                                                    _pipe@9 = kryptos@internal@der:parse_sequence(
                                                                                                        After_info
                                                                                                    ),
                                                                                                    gleam@result:replace_error(
                                                                                                        _pipe@9,
                                                                                                        invalid_structure
                                                                                                    )
                                                                                                end,
                                                                                                fun(
                                                                                                    _use0@7
                                                                                                ) ->
                                                                                                    {Sig_alg_bytes,
                                                                                                        After_sig_alg} = _use0@7,
                                                                                                    gleam@result:'try'(
                                                                                                        begin
                                                                                                            _pipe@10 = kryptos@internal@x509:parse_signature_algorithm(
                                                                                                                Sig_alg_bytes
                                                                                                            ),
                                                                                                            gleam@result:map_error(
                                                                                                                _pipe@10,
                                                                                                                fun(Field@0) -> {unsupported_signature_algorithm, Field@0} end
                                                                                                            )
                                                                                                        end,
                                                                                                        fun(
                                                                                                            Signature_algorithm
                                                                                                        ) ->
                                                                                                            gleam@result:'try'(
                                                                                                                begin
                                                                                                                    _pipe@11 = kryptos@internal@der:parse_bit_string(
                                                                                                                        After_sig_alg
                                                                                                                    ),
                                                                                                                    gleam@result:replace_error(
                                                                                                                        _pipe@11,
                                                                                                                        invalid_structure
                                                                                                                    )
                                                                                                                end,
                                                                                                                fun(
                                                                                                                    _use0@8
                                                                                                                ) ->
                                                                                                                    {_,
                                                                                                                        _} = _use0@8,
                                                                                                                    {ok,
                                                                                                                        {parsed_csr,
                                                                                                                            Der,
                                                                                                                            Version,
                                                                                                                            Subject,
                                                                                                                            Public_key,
                                                                                                                            Signature_algorithm,
                                                                                                                            Subject_alt_names,
                                                                                                                            Extensions,
                                                                                                                            Attributes}}
                                                                                                                end
                                                                                                            )
                                                                                                        end
                                                                                                    )
                                                                                                end
                                                                                            )
                                                                                        end
                                                                                    )
                                                                                end
                                                                            )
                                                                        end
                                                                    )
                                                                end
                                                            )
                                                        end
                                                    )
                                                end
                                            )
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 535).
-spec verify_signature(csr(parsed())) -> {ok, nil} | {error, csr_error()}.
verify_signature(Csr) ->
    {Der@1, Public_key@1, Signature_algorithm@1} = case Csr of
        {parsed_csr, Der, _, _, Public_key, Signature_algorithm, _, _, _} -> {
        Der,
            Public_key,
            Signature_algorithm};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/csr"/utf8>>,
                        function => <<"verify_signature"/utf8>>,
                        line => 536,
                        value => _assert_fail,
                        start => 16508,
                        'end' => 16579,
                        pattern_start => 16519,
                        pattern_end => 16573})
    end,
    gleam@result:'try'(
        begin
            _pipe = kryptos@internal@der:parse_sequence(Der@1),
            gleam@result:replace_error(_pipe, invalid_structure)
        end,
        fun(_use0) ->
            {Csr_content, _} = _use0,
            gleam@result:'try'(
                begin
                    _pipe@1 = kryptos@internal@x509:parse_sequence_with_header(
                        Csr_content
                    ),
                    gleam@result:replace_error(_pipe@1, invalid_structure)
                end,
                fun(_use0@1) ->
                    {Cert_req_info_bytes, After_info} = _use0@1,
                    gleam@result:'try'(
                        begin
                            _pipe@2 = kryptos@internal@der:parse_sequence(
                                After_info
                            ),
                            gleam@result:replace_error(
                                _pipe@2,
                                invalid_structure
                            )
                        end,
                        fun(_use0@2) ->
                            {_, After_sig_alg} = _use0@2,
                            gleam@result:'try'(
                                begin
                                    _pipe@3 = kryptos@internal@der:parse_bit_string(
                                        After_sig_alg
                                    ),
                                    gleam@result:replace_error(
                                        _pipe@3,
                                        invalid_structure
                                    )
                                end,
                                fun(_use0@3) ->
                                    {Signature, _} = _use0@3,
                                    Verified = kryptos@internal@x509:verify_signature(
                                        Public_key@1,
                                        Cert_req_info_bytes,
                                        Signature,
                                        Signature_algorithm@1
                                    ),
                                    case Verified of
                                        true ->
                                            {ok, nil};

                                        false ->
                                            {error,
                                                signature_verification_failed}
                                    end
                                end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 259).
?DOC(" Parse a DER-encoded CSR and verify its signature.\n").
-spec from_der(bitstring()) -> {ok, csr(parsed())} | {error, csr_error()}.
from_der(Der) ->
    gleam@result:'try'(
        from_der_unverified(Der),
        fun(Parsed) ->
            gleam@result:'try'(
                verify_signature(Parsed),
                fun(_) -> {ok, Parsed} end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 574).
-spec encode_csr(bitstring(), kryptos@internal@x509:sig_alg_info(), bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
encode_csr(Cert_request_info, Sig_alg, Signature) ->
    gleam@result:'try'(
        kryptos@internal@x509:encode_algorithm_identifier(Sig_alg),
        fun(Sig_alg_der) ->
            gleam@result:'try'(
                kryptos@internal@der:encode_bit_string(Signature),
                fun(Sig_bits) ->
                    kryptos@internal@der:encode_sequence(
                        gleam_stdlib:bit_array_concat(
                            [Cert_request_info, Sig_alg_der, Sig_bits]
                        )
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 621).
-spec encode_extensions(kryptos@x509:extensions()) -> {ok, bitstring()} |
    {error, nil}.
encode_extensions(Extensions) ->
    {extensions, Sans} = Extensions,
    _pipe = kryptos@internal@x509:encode_san_extension(Sans, false),
    gleam@result:'try'(_pipe, fun kryptos@internal@der:encode_sequence/1).

-file("src/kryptos/x509/csr.gleam", 608).
-spec encode_extension_request(kryptos@x509:extensions()) -> {ok, bitstring()} |
    {error, nil}.
encode_extension_request(Extensions) ->
    {oid, Ext_req_components} = {oid, [1, 2, 840, 113549, 1, 9, 14]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Ext_req_components),
        fun(Oid_encoded) -> _pipe = Extensions,
            _pipe@1 = encode_extensions(_pipe),
            _pipe@2 = gleam@result:'try'(
                _pipe@1,
                fun kryptos@internal@der:encode_set/1
            ),
            _pipe@3 = gleam@result:map(
                _pipe@2,
                fun(Set_encoded) ->
                    gleam_stdlib:bit_array_concat([Oid_encoded, Set_encoded])
                end
            ),
            gleam@result:'try'(
                _pipe@3,
                fun kryptos@internal@der:encode_sequence/1
            ) end
    ).

-file("src/kryptos/x509/csr.gleam", 598).
-spec encode_attributes(kryptos@x509:extensions()) -> {ok, bitstring()} |
    {error, nil}.
encode_attributes(Extensions) ->
    case gleam@list:is_empty(erlang:element(2, Extensions)) of
        true ->
            kryptos@internal@der:encode_context_tag(0, <<>>);

        false ->
            _pipe = Extensions,
            _pipe@1 = encode_extension_request(_pipe),
            gleam@result:'try'(
                _pipe@1,
                fun(_capture) ->
                    kryptos@internal@der:encode_context_tag(0, _capture)
                end
            )
    end.

-file("src/kryptos/x509/csr.gleam", 588).
-spec encode_certification_request_info(builder(), bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
encode_certification_request_info(Builder, Spki) ->
    gleam@result:'try'(
        kryptos@internal@der:encode_integer(<<0>>),
        fun(Version) ->
            gleam@result:'try'(
                kryptos@internal@x509:encode_name(erlang:element(2, Builder)),
                fun(Subject) ->
                    gleam@result:'try'(
                        encode_attributes(erlang:element(3, Builder)),
                        fun(Attributes) ->
                            kryptos@internal@der:encode_sequence(
                                gleam_stdlib:bit_array_concat(
                                    [Version, Subject, Spki, Attributes]
                                )
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 173).
?DOC(
    " Signs the CSR with an ECDSA private key.\n"
    "\n"
    " The public key is derived from the private key and included in the CSR.\n"
    " Recommended hash: `Sha256` for P-256, `Sha384` for P-384, `Sha512` for\n"
    " P-521. `Sha1` is supported for legacy compatibility but is\n"
    " cryptographically weak.\n"
).
-spec sign_with_ecdsa(
    builder(),
    kryptos@ec:private_key(),
    kryptos@hash:hash_algorithm()
) -> {ok, csr(built())} | {error, nil}.
sign_with_ecdsa(Builder, Key, Hash) ->
    gleam@result:'try'(
        kryptos@internal@x509:ecdsa_sig_alg_info(Hash),
        fun(Sig_alg) ->
            Public_key = kryptos_ffi:ec_public_key_from_private(Key),
            gleam@result:'try'(
                kryptos_ffi:ec_export_public_key_der(Public_key),
                fun(Spki) ->
                    gleam@result:'try'(
                        encode_certification_request_info(Builder, Spki),
                        fun(Cert_request_info) ->
                            Signature = kryptos_ffi:ecdsa_sign(
                                Key,
                                Cert_request_info,
                                Hash
                            ),
                            gleam@result:'try'(
                                encode_csr(
                                    Cert_request_info,
                                    Sig_alg,
                                    Signature
                                ),
                                fun(Csr_der) -> {ok, {built_csr, Csr_der}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 196).
?DOC(
    " Signs the CSR with an RSA private key using PKCS#1 v1.5 padding.\n"
    "\n"
    " The public key is derived from the private key and included in the CSR.\n"
    " Recommended hash: `Sha256` for 2048-bit keys, `Sha384` or `Sha512` for\n"
    " 3072-bit or larger keys. `Sha1` is supported for legacy compatibility\n"
    " but is cryptographically weak.\n"
).
-spec sign_with_rsa(
    builder(),
    kryptos@rsa:private_key(),
    kryptos@hash:hash_algorithm()
) -> {ok, csr(built())} | {error, nil}.
sign_with_rsa(Builder, Key, Hash) ->
    gleam@result:'try'(
        kryptos@internal@x509:rsa_sig_alg_info(Hash),
        fun(Sig_alg) ->
            Public_key = kryptos_ffi:rsa_public_key_from_private(Key),
            gleam@result:'try'(
                kryptos_ffi:rsa_export_public_key_der(Public_key, spki),
                fun(Spki) ->
                    gleam@result:'try'(
                        encode_certification_request_info(Builder, Spki),
                        fun(Cert_request_info) ->
                            Signature = kryptos_ffi:rsa_sign(
                                Key,
                                Cert_request_info,
                                Hash,
                                pkcs1v15
                            ),
                            gleam@result:'try'(
                                encode_csr(
                                    Cert_request_info,
                                    Sig_alg,
                                    Signature
                                ),
                                fun(Csr_der) -> {ok, {built_csr, Csr_der}} end
                            )
                        end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 217).
?DOC(
    " Signs the CSR with an EdDSA private key (Ed25519 or Ed448).\n"
    "\n"
    " **Note**: Support for EdDSA is limited with browsers and certificate\n"
    " authorities.\n"
).
-spec sign_with_eddsa(builder(), kryptos@eddsa:private_key()) -> {ok,
        csr(built())} |
    {error, nil}.
sign_with_eddsa(Builder, Key) ->
    Sig_alg = kryptos@internal@x509:eddsa_sig_alg_info(
        kryptos_ffi:eddsa_private_key_curve(Key)
    ),
    Public_key = kryptos_ffi:eddsa_public_key_from_private(Key),
    gleam@result:'try'(
        kryptos_ffi:eddsa_export_public_key_der(Public_key),
        fun(Spki) ->
            gleam@result:'try'(
                encode_certification_request_info(Builder, Spki),
                fun(Cert_request_info) ->
                    Signature = kryptos_ffi:eddsa_sign(Key, Cert_request_info),
                    gleam@result:'try'(
                        encode_csr(Cert_request_info, Sig_alg, Signature),
                        fun(Csr_der) -> {ok, {built_csr, Csr_der}} end
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/csr.gleam", 245).
?DOC(
    " Exports the CSR as a PEM-encoded string.\n"
    "\n"
    " This is the format typically required when submitting a CSR to a\n"
    " Certificate Authority.\n"
).
-spec to_pem(csr(any())) -> binary().
to_pem(Csr) ->
    kryptos@internal@x509:encode_pem(
        to_der(Csr),
        <<"-----BEGIN CERTIFICATE REQUEST-----"/utf8>>,
        <<"-----END CERTIFICATE REQUEST-----"/utf8>>
    ).

-file("src/kryptos/x509/csr.gleam", 414).
-spec decode_csr_pem(binary()) -> {ok, bitstring()} | {error, nil}.
decode_csr_pem(Pem) ->
    case kryptos@internal@x509:decode_pem(
        Pem,
        <<"-----BEGIN CERTIFICATE REQUEST-----"/utf8>>,
        <<"-----END CERTIFICATE REQUEST-----"/utf8>>
    ) of
        {ok, Der} ->
            {ok, Der};

        {error, _} ->
            kryptos@internal@x509:decode_pem(
                Pem,
                <<"-----BEGIN NEW CERTIFICATE REQUEST-----"/utf8>>,
                <<"-----END NEW CERTIFICATE REQUEST-----"/utf8>>
            )
    end.

-file("src/kryptos/x509/csr.gleam", 253).
?DOC(
    " Parse a PEM-encoded CSR and verify its signature.\n"
    "\n"
    " Returns an error if the PEM is invalid, the structure is malformed,\n"
    " or the signature doesn't verify against the embedded public key.\n"
).
-spec from_pem(binary()) -> {ok, csr(parsed())} | {error, csr_error()}.
from_pem(Pem) ->
    gleam@result:'try'(
        begin
            _pipe = decode_csr_pem(Pem),
            gleam@result:replace_error(_pipe, invalid_pem)
        end,
        fun(Der) -> from_der(Der) end
    ).

-file("src/kryptos/x509/csr.gleam", 269).
?DOC(
    " Parse a PEM-encoded CSR without verifying the signature.\n"
    "\n"
    " Useful for debugging malformed or partially valid CSRs.\n"
    " The parsed fields may not be trustworthy.\n"
).
-spec from_pem_unverified(binary()) -> {ok, csr(parsed())} |
    {error, csr_error()}.
from_pem_unverified(Pem) ->
    gleam@result:'try'(
        begin
            _pipe = decode_csr_pem(Pem),
            gleam@result:replace_error(_pipe, invalid_pem)
        end,
        fun(Der) -> from_der_unverified(Der) end
    ).
