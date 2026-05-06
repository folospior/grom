-module(kryptos@x509@certificate).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/x509/certificate.gleam").
-export([new/0, with_subject/2, with_validity/2, with_basic_constraints/3, with_key_usage/2, with_extended_key_usage/2, with_dns_name/2, with_email/2, with_ip/2, with_serial_number/2, with_subject_key_identifier/2, with_authority_key_identifier/2, generate_serial_number/0, to_der/1, version/1, serial_number/1, signature_algorithm/1, issuer/1, validity/1, subject/1, public_key/1, basic_constraints/1, key_usage/1, extended_key_usage/1, subject_alt_names/1, subject_key_identifier/1, authority_key_identifier/1, extensions/1, from_der/1, verify/2, verify_self_signed/1, to_pem/1, from_pem/1, self_signed_with_ecdsa/3, self_signed_with_rsa/3, self_signed_with_eddsa/2]).
-export_type([built/0, parsed/0, certificate_error/0, extensions_acc/0, subject_key_identifier_config/0, authority_key_identifier_config/0, certificate/1, builder/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " X.509 Certificate generation and parsing.\n"
    "\n"
    " Builder for creating self-signed X.509 certificates.\n"
    " CA-signing is not currently supported.\n"
    "\n"
    " ## Example\n"
    "\n"
    " ```gleam\n"
    " import gleam/option\n"
    " import gleam/time/duration\n"
    " import gleam/time/timestamp\n"
    " import kryptos/ec\n"
    " import kryptos/hash\n"
    " import kryptos/x509\n"
    " import kryptos/x509/certificate\n"
    "\n"
    " let #(private_key, _) = ec.generate_key_pair(ec.P256)\n"
    "\n"
    " let subject =\n"
    "   x509.name([\n"
    "     x509.cn(\"example.com\"),\n"
    "     x509.organization(\"Acme Inc\"),\n"
    "   ])\n"
    "\n"
    " let now = timestamp.system_time()\n"
    " // 86,400 seconds per day per CA/Browser Forum definition\n"
    " let one_year_later = timestamp.add(now, duration.seconds(86_400 * 365))\n"
    " let validity = x509.Validity(not_before: now, not_after: one_year_later)\n"
    "\n"
    " let assert Ok(builder) =\n"
    "   certificate.new()\n"
    "   |> certificate.with_subject(subject)\n"
    "   |> certificate.with_validity(validity)\n"
    "   |> certificate.with_basic_constraints(ca: False, path_len_constraint: option.None)\n"
    "   |> certificate.with_key_usage(x509.DigitalSignature)\n"
    "   |> certificate.with_extended_key_usage(x509.ServerAuth)\n"
    "   |> certificate.with_dns_name(\"example.com\")\n"
    "\n"
    " let assert Ok(cert) =\n"
    "   certificate.self_signed_with_ecdsa(builder, private_key, hash.Sha256)\n"
    " ```\n"
    "\n"
    " ## Parsing Certificates\n"
    "\n"
    " ```gleam\n"
    " import kryptos/x509/certificate\n"
    "\n"
    " let pem = \"-----BEGIN CERTIFICATE-----\n"
    " MIIBkTCB+wIJAK...\n"
    " -----END CERTIFICATE-----\"\n"
    "\n"
    " let assert Ok([cert]) = certificate.from_pem(pem)\n"
    "\n"
    " // Access certificate fields\n"
    " let subject = certificate.subject(cert)\n"
    " let validity = certificate.validity(cert)\n"
    " let public_key = certificate.public_key(cert)\n"
    "\n"
    " // Verify a self-signed certificate\n"
    " let assert Ok(Nil) = certificate.verify_self_signed(cert)\n"
    " ```\n"
).

-type built() :: any().

-type parsed() :: any().

-type certificate_error() :: parse_error |
    {unsupported_algorithm, kryptos@x509:oid()} |
    signature_verification_failed |
    {unrecognized_critical_extension, kryptos@x509:oid()}.

-type extensions_acc() :: {extensions_acc,
        gleam@option:option(kryptos@x509:basic_constraints()),
        list(kryptos@x509:key_usage()),
        list(kryptos@x509:extended_key_usage()),
        list(kryptos@x509:subject_alt_name()),
        gleam@option:option(bitstring()),
        gleam@option:option(kryptos@x509:authority_key_identifier()),
        list({kryptos@x509:oid(), boolean(), bitstring()}),
        gleam@set:set(list(integer()))}.

-type subject_key_identifier_config() :: ski_auto | {ski_explicit, bitstring()}.

-type authority_key_identifier_config() :: aki_auto |
    {aki_explicit, bitstring()} |
    aki_exclude.

-opaque certificate(HGD) :: {built_certificate, bitstring()} |
    {parsed_certificate,
        bitstring(),
        bitstring(),
        bitstring(),
        integer(),
        bitstring(),
        kryptos@x509:signature_algorithm(),
        kryptos@x509:name(),
        kryptos@x509:validity(),
        kryptos@x509:name(),
        kryptos@x509:public_key(),
        gleam@option:option(kryptos@x509:basic_constraints()),
        list(kryptos@x509:key_usage()),
        list(kryptos@x509:extended_key_usage()),
        list(kryptos@x509:subject_alt_name()),
        gleam@option:option(bitstring()),
        gleam@option:option(kryptos@x509:authority_key_identifier()),
        list({kryptos@x509:oid(), boolean(), bitstring()})} |
    {gleam_phantom, HGD}.

-opaque builder() :: {builder,
        kryptos@x509:name(),
        gleam@option:option(kryptos@x509:validity()),
        gleam@option:option({boolean(), gleam@option:option(integer())}),
        list(kryptos@x509:key_usage()),
        list(kryptos@x509:extended_key_usage()),
        list(kryptos@x509:subject_alt_name()),
        gleam@option:option(bitstring()),
        gleam@option:option(subject_key_identifier_config()),
        authority_key_identifier_config()}.

-file("src/kryptos/x509/certificate.gleam", 148).
-spec empty_extensions_acc() -> extensions_acc().
empty_extensions_acc() ->
    {extensions_acc, none, [], [], [], none, none, [], gleam@set:new()}.

-file("src/kryptos/x509/certificate.gleam", 236).
?DOC(
    " Creates a new certificate builder with default values.\n"
    "\n"
    " Use the `with_*` functions to configure the builder, then call\n"
    " a signing function to generate the certificate.\n"
).
-spec new() -> builder().
new() ->
    {builder,
        kryptos@x509:name([]),
        none,
        none,
        [],
        [],
        [],
        none,
        none,
        aki_auto}.

-file("src/kryptos/x509/certificate.gleam", 251).
?DOC(" Sets the distinguished name subject for the certificate.\n").
-spec with_subject(builder(), kryptos@x509:name()) -> builder().
with_subject(Builder, Subject) ->
    {builder,
        Subject,
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 256).
?DOC(" Sets the validity period for the certificate.\n").
-spec with_validity(builder(), kryptos@x509:validity()) -> builder().
with_validity(Builder, Validity) ->
    {builder,
        erlang:element(2, Builder),
        {some, Validity},
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 265).
?DOC(
    " Sets the Basic Constraints extension.\n"
    "\n"
    " This extension indicates whether the certificate is a CA certificate\n"
    " and optionally limits the path length of the certification chain.\n"
    " Per RFC 5280, path_len_constraint is only meaningful when ca is True.\n"
).
-spec with_basic_constraints(
    builder(),
    boolean(),
    gleam@option:option(integer())
) -> builder().
with_basic_constraints(Builder, Ca, Path_len_constraint) ->
    Effective_path_len = case Ca of
        true ->
            Path_len_constraint;

        false ->
            none
    end,
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        {some, {Ca, Effective_path_len}},
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 280).
?DOC(
    " Adds a Key Usage flag to the certificate.\n"
    "\n"
    " Multiple usages can be added by chaining calls.\n"
).
-spec with_key_usage(builder(), kryptos@x509:key_usage()) -> builder().
with_key_usage(Builder, Usage) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        [Usage | erlang:element(5, Builder)],
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 288).
?DOC(
    " Adds an Extended Key Usage purpose to the certificate.\n"
    "\n"
    " EKU narrows allowed purposes beyond Key Usage (e.g., ServerAuth,\n"
    " CodeSigning). Multiple usages can be added by chaining calls.\n"
).
-spec with_extended_key_usage(builder(), kryptos@x509:extended_key_usage()) -> builder().
with_extended_key_usage(Builder, Usage) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        [Usage | erlang:element(6, Builder)],
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 298).
?DOC(
    " Adds a DNS name to the Subject Alternative Names extension.\n"
    "\n"
    " The name must contain only ASCII characters.\n"
).
-spec with_dns_name(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_dns_name(Builder, Name) ->
    case kryptos@internal@utils:is_ascii(Name) of
        true ->
            _pipe = {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                [{dns_name, Name} | erlang:element(7, Builder)],
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder)},
            {ok, _pipe};

        false ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 313).
?DOC(
    " Adds an email address to the Subject Alternative Names extension.\n"
    "\n"
    " The email must contain only ASCII characters.\n"
).
-spec with_email(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_email(Builder, Email) ->
    case kryptos@internal@utils:is_ascii(Email) of
        true ->
            _pipe = {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                [{email, Email} | erlang:element(7, Builder)],
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder)},
            {ok, _pipe};

        false ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 328).
?DOC(
    " Adds an IP address to the Subject Alternative Names extension.\n"
    "\n"
    " Accepts IPv4 (e.g., \"192.168.1.1\") or IPv6 (e.g., \"2001:db8::1\") addresses.\n"
).
-spec with_ip(builder(), binary()) -> {ok, builder()} | {error, nil}.
with_ip(Builder, Ip) ->
    _pipe = kryptos@internal@utils:parse_ip(Ip),
    gleam@result:map(
        _pipe,
        fun(Parsed) ->
            {builder,
                erlang:element(2, Builder),
                erlang:element(3, Builder),
                erlang:element(4, Builder),
                erlang:element(5, Builder),
                erlang:element(6, Builder),
                [{ip_address, Parsed} | erlang:element(7, Builder)],
                erlang:element(8, Builder),
                erlang:element(9, Builder),
                erlang:element(10, Builder)}
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 341).
?DOC(
    " Sets the serial number for the certificate.\n"
    "\n"
    " If not set, a random serial number will be generated during signing.\n"
).
-spec with_serial_number(builder(), bitstring()) -> builder().
with_serial_number(Builder, Serial) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        {some, Serial},
        erlang:element(9, Builder),
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 350).
?DOC(
    " Enables the Subject Key Identifier extension in the certificate.\n"
    "\n"
    " If not called, the SKI extension will not be included. Use `SkiAuto` to\n"
    " compute from the public key (SHA-1 hash per RFC 5280 method 1) or\n"
    " `SkiExplicit(bytes)` for a custom value.\n"
).
-spec with_subject_key_identifier(builder(), subject_key_identifier_config()) -> builder().
with_subject_key_identifier(Builder, Ski) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        {some, Ski},
        erlang:element(10, Builder)}.

-file("src/kryptos/x509/certificate.gleam", 362).
?DOC(
    " Configures the Authority Key Identifier extension for the certificate.\n"
    "\n"
    " By default, self-signed certificates include an AKI with keyIdentifier\n"
    " computed as the SHA-1 hash of the signing public key. Use `AkiExplicit`\n"
    " for a custom value or `AkiExclude` to omit the extension.\n"
).
-spec with_authority_key_identifier(
    builder(),
    authority_key_identifier_config()
) -> builder().
with_authority_key_identifier(Builder, Aki) ->
    {builder,
        erlang:element(2, Builder),
        erlang:element(3, Builder),
        erlang:element(4, Builder),
        erlang:element(5, Builder),
        erlang:element(6, Builder),
        erlang:element(7, Builder),
        erlang:element(8, Builder),
        erlang:element(9, Builder),
        Aki}.

-file("src/kryptos/x509/certificate.gleam", 370).
?DOC(" Generates a random 20-byte serial number with the high bit cleared per RFC 5280.\n").
-spec generate_serial_number() -> bitstring().
generate_serial_number() ->
    Bytes = kryptos_ffi:random_bytes(20),
    {First@1, Rest@1} = case Bytes of
        <<First:8, Rest/bitstring>> -> {First, Rest};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"generate_serial_number"/utf8>>,
                        line => 372,
                        value => _assert_fail,
                        start => 11779,
                        'end' => 11820,
                        pattern_start => 11790,
                        pattern_end => 11812})
    end,
    <<(erlang:'band'(First@1, 16#7f)):8, Rest@1/bitstring>>.

-file("src/kryptos/x509/certificate.gleam", 474).
?DOC(" Exports the certificate as DER-encoded bytes.\n").
-spec to_der(certificate(any())) -> bitstring().
to_der(Cert) ->
    case Cert of
        {built_certificate, Der} ->
            Der;

        {parsed_certificate,
            Der@1,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} ->
            Der@1
    end.

-file("src/kryptos/x509/certificate.gleam", 639).
?DOC(" Returns the version of a parsed certificate (0 = v1, 1 = v2, 2 = v3).\n").
-spec version(certificate(parsed())) -> integer().
version(Cert) ->
    Version@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            Version,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Version;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"version"/utf8>>,
                        line => 640,
                        value => _assert_fail,
                        start => 20268,
                        'end' => 20317,
                        pattern_start => 20279,
                        pattern_end => 20310})
    end,
    Version@1.

-file("src/kryptos/x509/certificate.gleam", 645).
?DOC(" Returns the serial number of a parsed certificate.\n").
-spec serial_number(certificate(parsed())) -> bitstring().
serial_number(Cert) ->
    Serial_number@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            Serial_number,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Serial_number;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"serial_number"/utf8>>,
                        line => 646,
                        value => _assert_fail,
                        start => 20450,
                        'end' => 20505,
                        pattern_start => 20461,
                        pattern_end => 20498})
    end,
    Serial_number@1.

-file("src/kryptos/x509/certificate.gleam", 651).
?DOC(" Returns the signature algorithm used to sign the certificate.\n").
-spec signature_algorithm(certificate(parsed())) -> kryptos@x509:signature_algorithm().
signature_algorithm(Cert) ->
    Signature_algorithm@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            Signature_algorithm,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Signature_algorithm;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"signature_algorithm"/utf8>>,
                        line => 652,
                        value => _assert_fail,
                        start => 20676,
                        'end' => 20737,
                        pattern_start => 20687,
                        pattern_end => 20730})
    end,
    Signature_algorithm@1.

-file("src/kryptos/x509/certificate.gleam", 659).
?DOC(
    " Returns the issuer distinguished name.\n"
    "\n"
    " For self-signed certificates, issuer equals subject.\n"
).
-spec issuer(certificate(parsed())) -> kryptos@x509:name().
issuer(Cert) ->
    Issuer@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            Issuer,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Issuer;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"issuer"/utf8>>,
                        line => 660,
                        value => _assert_fail,
                        start => 20925,
                        'end' => 20973,
                        pattern_start => 20936,
                        pattern_end => 20966})
    end,
    Issuer@1.

-file("src/kryptos/x509/certificate.gleam", 665).
?DOC(" Returns the validity period of the certificate.\n").
-spec validity(certificate(parsed())) -> kryptos@x509:validity().
validity(Cert) ->
    Validity@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Validity,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Validity;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"validity"/utf8>>,
                        line => 666,
                        value => _assert_fail,
                        start => 21102,
                        'end' => 21152,
                        pattern_start => 21113,
                        pattern_end => 21145})
    end,
    Validity@1.

-file("src/kryptos/x509/certificate.gleam", 671).
?DOC(" Returns the subject distinguished name.\n").
-spec subject(certificate(parsed())) -> kryptos@x509:name().
subject(Cert) ->
    Subject@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Subject,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Subject;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"subject"/utf8>>,
                        line => 672,
                        value => _assert_fail,
                        start => 21270,
                        'end' => 21319,
                        pattern_start => 21281,
                        pattern_end => 21312})
    end,
    Subject@1.

-file("src/kryptos/x509/certificate.gleam", 677).
?DOC(" Returns the public key embedded in the certificate.\n").
-spec public_key(certificate(parsed())) -> kryptos@x509:public_key().
public_key(Cert) ->
    Public_key@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Public_key,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> Public_key;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"public_key"/utf8>>,
                        line => 678,
                        value => _assert_fail,
                        start => 21456,
                        'end' => 21508,
                        pattern_start => 21467,
                        pattern_end => 21501})
    end,
    Public_key@1.

-file("src/kryptos/x509/certificate.gleam", 683).
?DOC(" Returns the Basic Constraints extension from a parsed certificate.\n").
-spec basic_constraints(certificate(parsed())) -> {ok,
        kryptos@x509:basic_constraints()} |
    {error, nil}.
basic_constraints(Cert) ->
    Basic_constraints@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Basic_constraints,
            _,
            _,
            _,
            _,
            _,
            _} -> Basic_constraints;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"basic_constraints"/utf8>>,
                        line => 686,
                        value => _assert_fail,
                        start => 21695,
                        'end' => 21754,
                        pattern_start => 21706,
                        pattern_end => 21747})
    end,
    gleam@option:to_result(Basic_constraints@1, nil).

-file("src/kryptos/x509/certificate.gleam", 691).
?DOC(" Returns the Key Usage flags from a parsed certificate.\n").
-spec key_usage(certificate(parsed())) -> list(kryptos@x509:key_usage()).
key_usage(Cert) ->
    Key_usage@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Key_usage,
            _,
            _,
            _,
            _,
            _} -> Key_usage;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"key_usage"/utf8>>,
                        line => 692,
                        value => _assert_fail,
                        start => 21931,
                        'end' => 21982,
                        pattern_start => 21942,
                        pattern_end => 21975})
    end,
    Key_usage@1.

-file("src/kryptos/x509/certificate.gleam", 697).
?DOC(" Returns the Extended Key Usage purposes from a parsed certificate.\n").
-spec extended_key_usage(certificate(parsed())) -> list(kryptos@x509:extended_key_usage()).
extended_key_usage(Cert) ->
    Extended_key_usage@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Extended_key_usage,
            _,
            _,
            _,
            _} -> Extended_key_usage;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"extended_key_usage"/utf8>>,
                        line => 700,
                        value => _assert_fail,
                        start => 22162,
                        'end' => 22222,
                        pattern_start => 22173,
                        pattern_end => 22215})
    end,
    Extended_key_usage@1.

-file("src/kryptos/x509/certificate.gleam", 705).
?DOC(" Returns the Subject Alternative Names (SANs) from a parsed certificate.\n").
-spec subject_alt_names(certificate(parsed())) -> list(kryptos@x509:subject_alt_name()).
subject_alt_names(Cert) ->
    Subject_alt_names@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Subject_alt_names,
            _,
            _,
            _} -> Subject_alt_names;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"subject_alt_names"/utf8>>,
                        line => 706,
                        value => _assert_fail,
                        start => 22408,
                        'end' => 22467,
                        pattern_start => 22419,
                        pattern_end => 22460})
    end,
    Subject_alt_names@1.

-file("src/kryptos/x509/certificate.gleam", 711).
?DOC(" Returns the Subject Key Identifier (SKI) from a parsed certificate.\n").
-spec subject_key_identifier(certificate(parsed())) -> {ok, bitstring()} |
    {error, nil}.
subject_key_identifier(Cert) ->
    Subject_key_identifier@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Subject_key_identifier,
            _,
            _} -> Subject_key_identifier;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"subject_key_identifier"/utf8>>,
                        line => 714,
                        value => _assert_fail,
                        start => 22654,
                        'end' => 22718,
                        pattern_start => 22665,
                        pattern_end => 22711})
    end,
    gleam@option:to_result(Subject_key_identifier@1, nil).

-file("src/kryptos/x509/certificate.gleam", 719).
?DOC(" Returns the Authority Key Identifier (AKI) from a parsed certificate.\n").
-spec authority_key_identifier(certificate(parsed())) -> {ok,
        kryptos@x509:authority_key_identifier()} |
    {error, nil}.
authority_key_identifier(Cert) ->
    Authority_key_identifier@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Authority_key_identifier,
            _} -> Authority_key_identifier;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"authority_key_identifier"/utf8>>,
                        line => 722,
                        value => _assert_fail,
                        start => 22956,
                        'end' => 23022,
                        pattern_start => 22967,
                        pattern_end => 23015})
    end,
    gleam@option:to_result(Authority_key_identifier@1, nil).

-file("src/kryptos/x509/certificate.gleam", 730).
?DOC(
    " Returns all extensions as raw (OID, critical, value) tuples.\n"
    "\n"
    " Includes all extensions, even those with typed representations.\n"
    " The Bool indicates whether the extension was marked as critical per RFC 5280.\n"
).
-spec extensions(certificate(parsed())) -> list({kryptos@x509:oid(),
    boolean(),
    bitstring()}).
extensions(Cert) ->
    Extensions@1 = case Cert of
        {parsed_certificate,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            Extensions} -> Extensions;
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"extensions"/utf8>>,
                        line => 733,
                        value => _assert_fail,
                        start => 23386,
                        'end' => 23438,
                        pattern_start => 23397,
                        pattern_end => 23431})
    end,
    Extensions@1.

-file("src/kryptos/x509/certificate.gleam", 776).
-spec parse_certificate_version(bitstring()) -> {ok, {integer(), bitstring()}} |
    {error, certificate_error()}.
parse_certificate_version(Bytes) ->
    case kryptos@internal@der:parse_context_tag(Bytes, 0) of
        {ok, {Version_content, Rest}} ->
            gleam@result:'try'(
                begin
                    _pipe = kryptos@internal@der:parse_integer(Version_content),
                    gleam@result:replace_error(_pipe, parse_error)
                end,
                fun(_use0) ->
                    {Version_bytes, _} = _use0,
                    case Version_bytes of
                        <<0>> ->
                            {ok, {0, Rest}};

                        <<1>> ->
                            {ok, {1, Rest}};

                        <<2>> ->
                            {ok, {2, Rest}};

                        <<_:8>> ->
                            {error, parse_error};

                        _ ->
                            {error, parse_error}
                    end
                end
            );

        {error, _} ->
            {ok, {0, Bytes}}
    end.

-file("src/kryptos/x509/certificate.gleam", 808).
-spec parse_time(bitstring()) -> {ok,
        {gleam@time@timestamp:timestamp(), bitstring()}} |
    {error, nil}.
parse_time(Bytes) ->
    case Bytes of
        <<16#17, _/bitstring>> ->
            kryptos@internal@der:parse_utc_time(Bytes);

        <<16#18, _/bitstring>> ->
            kryptos@internal@der:parse_generalized_time(Bytes);

        _ ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 798).
-spec parse_validity(bitstring()) -> {ok, kryptos@x509:validity()} |
    {error, certificate_error()}.
parse_validity(Bytes) ->
    gleam@result:'try'(
        begin
            _pipe = parse_time(Bytes),
            gleam@result:replace_error(_pipe, parse_error)
        end,
        fun(_use0) ->
            {Not_before, After_not_before} = _use0,
            gleam@result:'try'(
                begin
                    _pipe@1 = parse_time(After_not_before),
                    gleam@result:replace_error(_pipe@1, parse_error)
                end,
                fun(_use0@1) ->
                    {Not_after, _} = _use0@1,
                    {ok, {validity, Not_before, Not_after}}
                end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 817).
?DOC(" Parse optional unique IDs with RFC 5280 version validation.\n").
-spec parse_optional_unique_ids(bitstring(), integer()) -> {ok, bitstring()} |
    {error, certificate_error()}.
parse_optional_unique_ids(Bytes, Version) ->
    case Bytes of
        <<16#81, _/bitstring>> ->
            gleam@bool:guard(
                Version < 1,
                {error, parse_error},
                fun() -> case kryptos@internal@der:parse_tlv(Bytes) of
                        {ok, {_, _, Remaining}} ->
                            parse_optional_unique_ids(Remaining, Version);

                        {error, _} ->
                            {error, parse_error}
                    end end
            );

        <<16#82, _/bitstring>> ->
            gleam@bool:guard(
                Version < 1,
                {error, parse_error},
                fun() -> case kryptos@internal@der:parse_tlv(Bytes) of
                        {ok, {_, _, Remaining}} ->
                            parse_optional_unique_ids(Remaining, Version);

                        {error, _} ->
                            {error, parse_error}
                    end end
            );

        _ ->
            {ok, Bytes}
    end.

-file("src/kryptos/x509/certificate.gleam", 852).
-spec parse_raw_extensions(
    bitstring(),
    list({kryptos@x509:oid(), boolean(), bitstring()})
) -> {ok, list({kryptos@x509:oid(), boolean(), bitstring()})} | {error, nil}.
parse_raw_extensions(Bytes, Acc) ->
    case Bytes of
        <<>> ->
            {ok, lists:reverse(Acc)};

        _ ->
            gleam@result:'try'(
                kryptos@internal@der:parse_sequence(Bytes),
                fun(_use0) ->
                    {Ext_bytes, Rest} = _use0,
                    _pipe = kryptos@internal@x509:parse_single_extension(
                        Ext_bytes
                    ),
                    gleam@result:'try'(
                        _pipe,
                        fun(Ext) -> parse_raw_extensions(Rest, [Ext | Acc]) end
                    )
                end
            )
    end.

-file("src/kryptos/x509/certificate.gleam", 941).
-spec parse_subject_key_identifier_ext(bitstring()) -> {ok, bitstring()} |
    {error, nil}.
parse_subject_key_identifier_ext(Bytes) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_octet_string(Bytes),
        fun(_use0) ->
            {Value, Remaining} = _use0,
            gleam@bool:guard(
                Remaining /= <<>>,
                {error, nil},
                fun() -> {ok, Value} end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 960).
-spec parse_aki_fields(
    bitstring(),
    gleam@option:option(bitstring()),
    gleam@option:option(list(kryptos@x509:subject_alt_name())),
    gleam@option:option(bitstring())
) -> {ok, kryptos@x509:authority_key_identifier()} | {error, nil}.
parse_aki_fields(Bytes, Key_id, Issuer, Serial) ->
    case Bytes of
        <<>> ->
            {ok, {authority_key_identifier, Key_id, Issuer, Serial}};

        <<16#80, Len:8, Rest/bitstring>> ->
            gleam@bool:guard(
                erlang:byte_size(Rest) < Len,
                {error, nil},
                fun() ->
                    gleam@result:'try'(
                        gleam_stdlib:bit_array_slice(Rest, 0, Len),
                        fun(Key_bytes) ->
                            gleam@result:'try'(
                                gleam_stdlib:bit_array_slice(
                                    Rest,
                                    Len,
                                    erlang:byte_size(Rest) - Len
                                ),
                                fun(Remaining) ->
                                    parse_aki_fields(
                                        Remaining,
                                        {some, Key_bytes},
                                        Issuer,
                                        Serial
                                    )
                                end
                            )
                        end
                    )
                end
            );

        <<16#a1, _/bitstring>> ->
            gleam@result:'try'(
                kryptos@internal@der:parse_context_tag(Bytes, 1),
                fun(_use0) ->
                    {Issuer_content, Remaining@1} = _use0,
                    gleam@result:'try'(
                        kryptos@internal@x509:parse_general_names(
                            Issuer_content,
                            [],
                            false
                        ),
                        fun(Parsed_issuers) ->
                            parse_aki_fields(
                                Remaining@1,
                                Key_id,
                                {some, Parsed_issuers},
                                Serial
                            )
                        end
                    )
                end
            );

        <<16#82, Len@1:8, Rest@1/bitstring>> ->
            gleam@bool:guard(
                erlang:byte_size(Rest@1) < Len@1,
                {error, nil},
                fun() ->
                    gleam@result:'try'(
                        gleam_stdlib:bit_array_slice(Rest@1, 0, Len@1),
                        fun(Serial_bytes) ->
                            gleam@result:'try'(
                                gleam_stdlib:bit_array_slice(
                                    Rest@1,
                                    Len@1,
                                    erlang:byte_size(Rest@1) - Len@1
                                ),
                                fun(Remaining@2) ->
                                    parse_aki_fields(
                                        Remaining@2,
                                        Key_id,
                                        Issuer,
                                        {some, Serial_bytes}
                                    )
                                end
                            )
                        end
                    )
                end
            );

        _ ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 947).
-spec parse_authority_key_identifier_ext(bitstring()) -> {ok,
        kryptos@x509:authority_key_identifier()} |
    {error, nil}.
parse_authority_key_identifier_ext(Bytes) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_sequence(Bytes),
        fun(_use0) ->
            {Inner, Remaining} = _use0,
            gleam@bool:guard(
                Remaining /= <<>>,
                {error, nil},
                fun() -> parse_aki_fields(Inner, none, none, none) end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1068).
-spec bytes_to_int(bitstring()) -> {ok, integer()} | {error, nil}.
bytes_to_int(Bytes) ->
    case Bytes of
        <<N:8>> ->
            {ok, N};

        <<N@1:16>> ->
            {ok, N@1};

        <<N@2:24>> ->
            {ok, N@2};

        <<N@3:32>> ->
            {ok, N@3};

        _ ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 1035).
-spec parse_basic_constraints_ext(bitstring()) -> {ok,
        kryptos@x509:basic_constraints()} |
    {error, nil}.
parse_basic_constraints_ext(Bytes) ->
    gleam@result:'try'(
        kryptos@internal@der:parse_sequence(Bytes),
        fun(_use0) ->
            {Seq_content, Remaining} = _use0,
            gleam@bool:guard(
                Remaining /= <<>>,
                {error, nil},
                fun() ->
                    gleam@bool:guard(
                        erlang:byte_size(Seq_content) =:= 0,
                        {ok, {basic_constraints, false, none}},
                        fun() ->
                            gleam@result:'try'(
                                kryptos@internal@der:parse_bool(Seq_content),
                                fun(_use0@1) ->
                                    {Ca, After_ca} = _use0@1,
                                    gleam@bool:guard(
                                        erlang:byte_size(After_ca) =:= 0,
                                        {ok, {basic_constraints, Ca, none}},
                                        fun() ->
                                            gleam@bool:guard(
                                                not Ca,
                                                {ok,
                                                    {basic_constraints,
                                                        false,
                                                        none}},
                                                fun() ->
                                                    gleam@result:'try'(
                                                        kryptos@internal@der:parse_integer(
                                                            After_ca
                                                        ),
                                                        fun(_use0@2) ->
                                                            {Path_len_bytes,
                                                                Remaining@1} = _use0@2,
                                                            gleam@bool:guard(
                                                                Remaining@1 /= <<>>,
                                                                {error, nil},
                                                                fun() ->
                                                                    gleam@result:'try'(
                                                                        bytes_to_int(
                                                                            Path_len_bytes
                                                                        ),
                                                                        fun(
                                                                            Path_len
                                                                        ) ->
                                                                            {ok,
                                                                                {basic_constraints,
                                                                                    Ca,
                                                                                    {some,
                                                                                        Path_len}}}
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

-file("src/kryptos/x509/certificate.gleam", 1088).
-spec decode_key_usage_bits(bitstring()) -> list(kryptos@x509:key_usage()).
decode_key_usage_bits(Bytes) ->
    case Bytes of
        <<Digital_signature:1,
            Non_repudiation:1,
            Key_encipherment:1,
            Data_encipherment:1,
            Key_agreement:1,
            Key_cert_sign:1,
            Crl_sign:1,
            Encipher_only:1,
            Rest/bitstring>> ->
            Usages = begin
                _pipe = [{Digital_signature, digital_signature},
                    {Non_repudiation, non_repudiation},
                    {Key_encipherment, key_encipherment},
                    {Data_encipherment, data_encipherment},
                    {Key_agreement, key_agreement},
                    {Key_cert_sign, key_cert_sign},
                    {Crl_sign, crl_sign},
                    {Encipher_only, encipher_only}],
                gleam@list:filter_map(
                    _pipe,
                    fun(Pair) ->
                        {Bit, Usage} = Pair,
                        case Bit =:= 1 of
                            true ->
                                {ok, Usage};

                            false ->
                                {error, nil}
                        end
                    end
                )
            end,
            case Rest of
                <<1:1, _/bitstring>> ->
                    [decipher_only | Usages];

                _ ->
                    Usages
            end;

        _ ->
            []
    end.

-file("src/kryptos/x509/certificate.gleam", 1078).
-spec parse_key_usage_ext(bitstring()) -> {ok, list(kryptos@x509:key_usage())} |
    {error, nil}.
parse_key_usage_ext(Bytes) ->
    case Bytes of
        <<16#03, Len:8, Unused_bits:8, Rest/bitstring>> when (Unused_bits =< 7) andalso (Len >= 2) ->
            _pipe = gleam_stdlib:bit_array_slice(Rest, 0, Len - 1),
            gleam@result:map(_pipe, fun decode_key_usage_bits/1);

        _ ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 1139).
-spec parse_eku_oids(
    bitstring(),
    list(kryptos@x509:extended_key_usage()),
    boolean()
) -> {ok, list(kryptos@x509:extended_key_usage())} |
    {error, certificate_error()}.
parse_eku_oids(Bytes, Acc, Is_critical) ->
    case Bytes of
        <<>> ->
            {ok, lists:reverse(Acc)};

        _ ->
            gleam@result:'try'(
                begin
                    _pipe = kryptos@internal@der:parse_oid(Bytes),
                    gleam@result:replace_error(_pipe, parse_error)
                end,
                fun(_use0) ->
                    {Oid_components, Rest} = _use0,
                    Eku = case Oid_components of
                        [1, 3, 6, 1, 5, 5, 7, 3, 1] ->
                            {some, server_auth};

                        [1, 3, 6, 1, 5, 5, 7, 3, 2] ->
                            {some, client_auth};

                        [1, 3, 6, 1, 5, 5, 7, 3, 3] ->
                            {some, code_signing};

                        [1, 3, 6, 1, 5, 5, 7, 3, 4] ->
                            {some, email_protection};

                        [1, 3, 6, 1, 5, 5, 7, 3, 9] ->
                            {some, ocsp_signing};

                        _ ->
                            none
                    end,
                    case {Eku, Is_critical} of
                        {{some, E}, _} ->
                            parse_eku_oids(Rest, [E | Acc], Is_critical);

                        {none, false} ->
                            parse_eku_oids(Rest, Acc, Is_critical);

                        {none, true} ->
                            {error,
                                {unrecognized_critical_extension,
                                    {oid, Oid_components}}}
                    end
                end
            )
    end.

-file("src/kryptos/x509/certificate.gleam", 1129).
-spec parse_extended_key_usage_ext(bitstring(), boolean()) -> {ok,
        list(kryptos@x509:extended_key_usage())} |
    {error, certificate_error()}.
parse_extended_key_usage_ext(Bytes, Is_critical) ->
    gleam@result:'try'(
        begin
            _pipe = kryptos@internal@der:parse_sequence(Bytes),
            gleam@result:replace_error(_pipe, parse_error)
        end,
        fun(_use0) ->
            {Seq_content, _} = _use0,
            parse_eku_oids(Seq_content, [], Is_critical)
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 866).
-spec process_extension(
    extensions_acc(),
    {kryptos@x509:oid(), boolean(), bitstring()}
) -> {ok, extensions_acc()} | {error, certificate_error()}.
process_extension(Acc, Ext) ->
    {Oid, Is_critical, Value} = Ext,
    case Oid of
        {oid, [2, 5, 29, 19]} ->
            _pipe = parse_basic_constraints_ext(Value),
            _pipe@1 = gleam@result:replace_error(_pipe, parse_error),
            gleam@result:map(
                _pipe@1,
                fun(Bc) ->
                    {extensions_acc,
                        {some, Bc},
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        erlang:element(5, Acc),
                        erlang:element(6, Acc),
                        erlang:element(7, Acc),
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        {oid, [2, 5, 29, 15]} ->
            _pipe@2 = parse_key_usage_ext(Value),
            _pipe@3 = gleam@result:replace_error(_pipe@2, parse_error),
            gleam@result:map(
                _pipe@3,
                fun(Key_usage) ->
                    {extensions_acc,
                        erlang:element(2, Acc),
                        Key_usage,
                        erlang:element(4, Acc),
                        erlang:element(5, Acc),
                        erlang:element(6, Acc),
                        erlang:element(7, Acc),
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        {oid, [2, 5, 29, 37]} ->
            _pipe@4 = parse_extended_key_usage_ext(Value, Is_critical),
            gleam@result:map(
                _pipe@4,
                fun(Extended_key_usage) ->
                    {extensions_acc,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        Extended_key_usage,
                        erlang:element(5, Acc),
                        erlang:element(6, Acc),
                        erlang:element(7, Acc),
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        {oid, [2, 5, 29, 17]} ->
            _pipe@5 = kryptos@internal@x509:parse_san_extension(
                Value,
                Is_critical
            ),
            _pipe@6 = gleam@result:replace_error(_pipe@5, parse_error),
            gleam@result:map(
                _pipe@6,
                fun(Subject_alt_names) ->
                    {extensions_acc,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        Subject_alt_names,
                        erlang:element(6, Acc),
                        erlang:element(7, Acc),
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        {oid, [2, 5, 29, 14]} ->
            _pipe@7 = parse_subject_key_identifier_ext(Value),
            _pipe@8 = gleam@result:replace_error(_pipe@7, parse_error),
            gleam@result:map(
                _pipe@8,
                fun(Ski) ->
                    {extensions_acc,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        erlang:element(5, Acc),
                        {some, Ski},
                        erlang:element(7, Acc),
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        {oid, [2, 5, 29, 35]} ->
            _pipe@9 = parse_authority_key_identifier_ext(Value),
            _pipe@10 = gleam@result:replace_error(_pipe@9, parse_error),
            gleam@result:map(
                _pipe@10,
                fun(Aki) ->
                    {extensions_acc,
                        erlang:element(2, Acc),
                        erlang:element(3, Acc),
                        erlang:element(4, Acc),
                        erlang:element(5, Acc),
                        erlang:element(6, Acc),
                        {some, Aki},
                        erlang:element(8, Acc),
                        erlang:element(9, Acc)}
                end
            );

        _ ->
            case Is_critical of
                true ->
                    {error, {unrecognized_critical_extension, Oid}};

                false ->
                    {ok, Acc}
            end
    end.

-file("src/kryptos/x509/certificate.gleam", 920).
-spec parse_extensions_content(bitstring()) -> {ok, extensions_acc()} |
    {error, certificate_error()}.
parse_extensions_content(Bytes) ->
    gleam@result:'try'(
        begin
            _pipe = parse_raw_extensions(Bytes, []),
            gleam@result:replace_error(_pipe, parse_error)
        end,
        fun(Raw) ->
            _pipe@2 = gleam@list:try_fold(
                Raw,
                empty_extensions_acc(),
                fun(Acc, Ext) ->
                    {{oid, Components}, _, _} = Ext,
                    case gleam@set:contains(erlang:element(9, Acc), Components) of
                        true ->
                            {error, parse_error};

                        false ->
                            _pipe@1 = {extensions_acc,
                                erlang:element(2, Acc),
                                erlang:element(3, Acc),
                                erlang:element(4, Acc),
                                erlang:element(5, Acc),
                                erlang:element(6, Acc),
                                erlang:element(7, Acc),
                                erlang:element(8, Acc),
                                gleam@set:insert(
                                    erlang:element(9, Acc),
                                    Components
                                )},
                            process_extension(_pipe@1, Ext)
                    end
                end
            ),
            gleam@result:map(
                _pipe@2,
                fun(Acc@1) ->
                    {extensions_acc,
                        erlang:element(2, Acc@1),
                        erlang:element(3, Acc@1),
                        erlang:element(4, Acc@1),
                        erlang:element(5, Acc@1),
                        erlang:element(6, Acc@1),
                        erlang:element(7, Acc@1),
                        Raw,
                        erlang:element(9, Acc@1)}
                end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 834).
?DOC(" Parse extensions with RFC 5280 version validation.\n").
-spec parse_certificate_extensions(bitstring(), integer()) -> {ok,
        extensions_acc()} |
    {error, certificate_error()}.
parse_certificate_extensions(Bytes, Version) ->
    gleam@result:'try'(
        parse_optional_unique_ids(Bytes, Version),
        fun(Bytes@1) ->
            case kryptos@internal@der:parse_context_tag(Bytes@1, 3) of
                {ok, {Exts_content, _}} ->
                    gleam@bool:guard(
                        Version < 2,
                        {error, parse_error},
                        fun() ->
                            gleam@result:'try'(
                                begin
                                    _pipe = kryptos@internal@der:parse_sequence(
                                        Exts_content
                                    ),
                                    gleam@result:replace_error(
                                        _pipe,
                                        parse_error
                                    )
                                end,
                                fun(_use0) ->
                                    {Exts_seq, _} = _use0,
                                    parse_extensions_content(Exts_seq)
                                end
                            )
                        end
                    );

                {error, _} ->
                    {ok, empty_extensions_acc()}
            end
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 510).
?DOC(
    " Parse a DER-encoded X.509 certificate.\n"
    "\n"
    " Validates the ASN.1 structure and extracts all standard fields and\n"
    " extensions. Unknown non-critical extensions are preserved but not parsed.\n"
    "\n"
    " **Note:** This function does NOT verify the certificate's cryptographic\n"
    " signature. To verify a certificate was signed by an issuer, use `verify()`.\n"
    " For self-signed certificates, use `verify_self_signed()`.\n"
).
-spec from_der(bitstring()) -> {ok, certificate(parsed())} |
    {error, certificate_error()}.
from_der(Der) ->
    gleam@result:'try'(
        begin
            _pipe = kryptos@internal@der:parse_sequence(Der),
            gleam@result:replace_error(_pipe, parse_error)
        end,
        fun(_use0) ->
            {Cert_content, Remaining} = _use0,
            gleam@bool:guard(
                erlang:byte_size(Remaining) /= 0,
                {error, parse_error},
                fun() ->
                    gleam@result:'try'(
                        begin
                            _pipe@1 = kryptos@internal@x509:parse_sequence_with_header(
                                Cert_content
                            ),
                            gleam@result:replace_error(_pipe@1, parse_error)
                        end,
                        fun(_use0@1) ->
                            {Tbs_bytes, After_tbs} = _use0@1,
                            gleam@result:'try'(
                                begin
                                    _pipe@2 = kryptos@internal@der:parse_sequence(
                                        Tbs_bytes
                                    ),
                                    gleam@result:replace_error(
                                        _pipe@2,
                                        parse_error
                                    )
                                end,
                                fun(_use0@2) ->
                                    {Tbs_content, _} = _use0@2,
                                    gleam@result:'try'(
                                        parse_certificate_version(Tbs_content),
                                        fun(_use0@3) ->
                                            {Version, After_version} = _use0@3,
                                            gleam@result:'try'(
                                                begin
                                                    _pipe@3 = kryptos@internal@der:parse_integer(
                                                        After_version
                                                    ),
                                                    gleam@result:replace_error(
                                                        _pipe@3,
                                                        parse_error
                                                    )
                                                end,
                                                fun(_use0@4) ->
                                                    {Serial_number,
                                                        After_serial} = _use0@4,
                                                    gleam@result:'try'(
                                                        begin
                                                            _pipe@4 = kryptos@internal@der:parse_sequence(
                                                                After_serial
                                                            ),
                                                            gleam@result:replace_error(
                                                                _pipe@4,
                                                                parse_error
                                                            )
                                                        end,
                                                        fun(_use0@5) ->
                                                            {Sig_alg_bytes,
                                                                After_sig_alg} = _use0@5,
                                                            gleam@result:'try'(
                                                                begin
                                                                    _pipe@5 = kryptos@internal@x509:parse_signature_algorithm(
                                                                        Sig_alg_bytes
                                                                    ),
                                                                    gleam@result:map_error(
                                                                        _pipe@5,
                                                                        fun(Field@0) -> {unsupported_algorithm, Field@0} end
                                                                    )
                                                                end,
                                                                fun(
                                                                    Signature_algorithm
                                                                ) ->
                                                                    gleam@result:'try'(
                                                                        begin
                                                                            _pipe@6 = kryptos@internal@der:parse_sequence(
                                                                                After_sig_alg
                                                                            ),
                                                                            gleam@result:replace_error(
                                                                                _pipe@6,
                                                                                parse_error
                                                                            )
                                                                        end,
                                                                        fun(
                                                                            _use0@6
                                                                        ) ->
                                                                            {Issuer_bytes,
                                                                                After_issuer} = _use0@6,
                                                                            gleam@result:'try'(
                                                                                begin
                                                                                    _pipe@7 = kryptos@internal@x509:parse_name(
                                                                                        Issuer_bytes
                                                                                    ),
                                                                                    gleam@result:replace_error(
                                                                                        _pipe@7,
                                                                                        parse_error
                                                                                    )
                                                                                end,
                                                                                fun(
                                                                                    Issuer
                                                                                ) ->
                                                                                    gleam@result:'try'(
                                                                                        begin
                                                                                            _pipe@8 = kryptos@internal@der:parse_sequence(
                                                                                                After_issuer
                                                                                            ),
                                                                                            gleam@result:replace_error(
                                                                                                _pipe@8,
                                                                                                parse_error
                                                                                            )
                                                                                        end,
                                                                                        fun(
                                                                                            _use0@7
                                                                                        ) ->
                                                                                            {Validity_bytes,
                                                                                                After_validity} = _use0@7,
                                                                                            gleam@result:'try'(
                                                                                                parse_validity(
                                                                                                    Validity_bytes
                                                                                                ),
                                                                                                fun(
                                                                                                    Validity
                                                                                                ) ->
                                                                                                    gleam@result:'try'(
                                                                                                        begin
                                                                                                            _pipe@9 = kryptos@internal@der:parse_sequence(
                                                                                                                After_validity
                                                                                                            ),
                                                                                                            gleam@result:replace_error(
                                                                                                                _pipe@9,
                                                                                                                parse_error
                                                                                                            )
                                                                                                        end,
                                                                                                        fun(
                                                                                                            _use0@8
                                                                                                        ) ->
                                                                                                            {Subject_bytes,
                                                                                                                After_subject} = _use0@8,
                                                                                                            gleam@result:'try'(
                                                                                                                begin
                                                                                                                    _pipe@10 = kryptos@internal@x509:parse_name(
                                                                                                                        Subject_bytes
                                                                                                                    ),
                                                                                                                    gleam@result:replace_error(
                                                                                                                        _pipe@10,
                                                                                                                        parse_error
                                                                                                                    )
                                                                                                                end,
                                                                                                                fun(
                                                                                                                    Subject
                                                                                                                ) ->
                                                                                                                    gleam@result:'try'(
                                                                                                                        begin
                                                                                                                            _pipe@11 = kryptos@internal@x509:parse_sequence_with_header(
                                                                                                                                After_subject
                                                                                                                            ),
                                                                                                                            gleam@result:replace_error(
                                                                                                                                _pipe@11,
                                                                                                                                parse_error
                                                                                                                            )
                                                                                                                        end,
                                                                                                                        fun(
                                                                                                                            _use0@9
                                                                                                                        ) ->
                                                                                                                            {Spki_bytes,
                                                                                                                                After_spki} = _use0@9,
                                                                                                                            gleam@result:'try'(
                                                                                                                                begin
                                                                                                                                    _pipe@12 = kryptos@internal@x509:parse_public_key(
                                                                                                                                        Spki_bytes
                                                                                                                                    ),
                                                                                                                                    gleam@result:map_error(
                                                                                                                                        _pipe@12,
                                                                                                                                        fun(
                                                                                                                                            Oid
                                                                                                                                        ) ->
                                                                                                                                            case Oid of
                                                                                                                                                {oid,
                                                                                                                                                    []} ->
                                                                                                                                                    parse_error;

                                                                                                                                                _ ->
                                                                                                                                                    {unsupported_algorithm,
                                                                                                                                                        Oid}
                                                                                                                                            end
                                                                                                                                        end
                                                                                                                                    )
                                                                                                                                end,
                                                                                                                                fun(
                                                                                                                                    Public_key
                                                                                                                                ) ->
                                                                                                                                    gleam@result:'try'(
                                                                                                                                        parse_certificate_extensions(
                                                                                                                                            After_spki,
                                                                                                                                            Version
                                                                                                                                        ),
                                                                                                                                        fun(
                                                                                                                                            Exts
                                                                                                                                        ) ->
                                                                                                                                            gleam@result:'try'(
                                                                                                                                                begin
                                                                                                                                                    _pipe@13 = kryptos@internal@der:parse_sequence(
                                                                                                                                                        After_tbs
                                                                                                                                                    ),
                                                                                                                                                    gleam@result:replace_error(
                                                                                                                                                        _pipe@13,
                                                                                                                                                        parse_error
                                                                                                                                                    )
                                                                                                                                                end,
                                                                                                                                                fun(
                                                                                                                                                    _use0@10
                                                                                                                                                ) ->
                                                                                                                                                    {Outer_sig_alg_bytes,
                                                                                                                                                        After_outer_sig_alg} = _use0@10,
                                                                                                                                                    gleam@result:'try'(
                                                                                                                                                        begin
                                                                                                                                                            _pipe@14 = kryptos@internal@x509:parse_signature_algorithm(
                                                                                                                                                                Outer_sig_alg_bytes
                                                                                                                                                            ),
                                                                                                                                                            gleam@result:replace_error(
                                                                                                                                                                _pipe@14,
                                                                                                                                                                parse_error
                                                                                                                                                            )
                                                                                                                                                        end,
                                                                                                                                                        fun(
                                                                                                                                                            Outer_signature_algorithm
                                                                                                                                                        ) ->
                                                                                                                                                            gleam@bool:guard(
                                                                                                                                                                Signature_algorithm
                                                                                                                                                                /= Outer_signature_algorithm,
                                                                                                                                                                {error,
                                                                                                                                                                    parse_error},
                                                                                                                                                                fun(
                                                                                                                                                                    
                                                                                                                                                                ) ->
                                                                                                                                                                    gleam@result:'try'(
                                                                                                                                                                        begin
                                                                                                                                                                            _pipe@15 = kryptos@internal@der:parse_bit_string(
                                                                                                                                                                                After_outer_sig_alg
                                                                                                                                                                            ),
                                                                                                                                                                            gleam@result:replace_error(
                                                                                                                                                                                _pipe@15,
                                                                                                                                                                                parse_error
                                                                                                                                                                            )
                                                                                                                                                                        end,
                                                                                                                                                                        fun(
                                                                                                                                                                            _use0@11
                                                                                                                                                                        ) ->
                                                                                                                                                                            {Signature,
                                                                                                                                                                                _} = _use0@11,
                                                                                                                                                                            {ok,
                                                                                                                                                                                {parsed_certificate,
                                                                                                                                                                                    Der,
                                                                                                                                                                                    Tbs_bytes,
                                                                                                                                                                                    Signature,
                                                                                                                                                                                    Version,
                                                                                                                                                                                    Serial_number,
                                                                                                                                                                                    Signature_algorithm,
                                                                                                                                                                                    Issuer,
                                                                                                                                                                                    Validity,
                                                                                                                                                                                    Subject,
                                                                                                                                                                                    Public_key,
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        2,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        3,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        4,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        5,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        6,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        7,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    ),
                                                                                                                                                                                    erlang:element(
                                                                                                                                                                                        8,
                                                                                                                                                                                        Exts
                                                                                                                                                                                    )}}
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

-file("src/kryptos/x509/certificate.gleam", 1199).
-spec encode_version() -> {ok, bitstring()} | {error, nil}.
encode_version() ->
    _pipe = kryptos@internal@der:encode_integer(<<2>>),
    gleam@result:'try'(
        _pipe,
        fun(_capture) ->
            kryptos@internal@der:encode_context_tag(0, _capture)
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1204).
-spec encode_validity(kryptos@x509:validity()) -> {ok, bitstring()} |
    {error, nil}.
encode_validity(Validity) ->
    {validity, Not_before, Not_after} = Validity,
    gleam@result:'try'(
        kryptos@internal@der:encode_timestamp(Not_before),
        fun(Not_before_der) ->
            gleam@result:'try'(
                kryptos@internal@der:encode_timestamp(Not_after),
                fun(Not_after_der) ->
                    kryptos@internal@der:encode_sequence(
                        gleam_stdlib:bit_array_concat(
                            [Not_before_der, Not_after_der]
                        )
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1264).
-spec encode_san_opt(list(kryptos@x509:subject_alt_name()), boolean()) -> {ok,
        {ok, bitstring()} | {error, nil}} |
    {error, nil}.
encode_san_opt(Sans, Critical) ->
    gleam@bool:guard(
        gleam@list:is_empty(Sans),
        {ok, {error, nil}},
        fun() ->
            gleam@result:map(
                kryptos@internal@x509:encode_san_extension(Sans, Critical),
                fun(Field@0) -> {ok, Field@0} end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1399).
-spec compute_ski(bitstring()) -> {ok, bitstring()} | {error, nil}.
compute_ski(Spki) ->
    _pipe = Spki,
    _pipe@1 = kryptos@internal@x509:extract_spki_public_key_bytes(_pipe),
    gleam@result:'try'(
        _pipe@1,
        fun(_capture) -> kryptos@crypto:hash(sha1, _capture) end
    ).

-file("src/kryptos/x509/certificate.gleam", 1432).
-spec encode_certificate(
    bitstring(),
    kryptos@internal@x509:sig_alg_info(),
    bitstring()
) -> {ok, bitstring()} | {error, nil}.
encode_certificate(Tbs, Sig_alg, Signature) ->
    gleam@result:'try'(
        kryptos@internal@x509:encode_algorithm_identifier(Sig_alg),
        fun(Sig_alg_der) ->
            gleam@result:'try'(
                kryptos@internal@der:encode_bit_string(Signature),
                fun(Sig_bits) ->
                    kryptos@internal@der:encode_sequence(
                        gleam_stdlib:bit_array_concat(
                            [Tbs, Sig_alg_der, Sig_bits]
                        )
                    )
                end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1444).
-spec is_xdh_key(kryptos@x509:public_key()) -> boolean().
is_xdh_key(Key) ->
    case Key of
        {xdh_public_key, _} ->
            true;

        _ ->
            false
    end.

-file("src/kryptos/x509/certificate.gleam", 1451).
-spec xdh_key_oid(kryptos@x509:public_key()) -> {ok, kryptos@x509:oid()} |
    {error, nil}.
xdh_key_oid(Key) ->
    case Key of
        {xdh_public_key, Xdh_key} ->
            case kryptos_ffi:xdh_public_key_curve(Xdh_key) of
                x25519 ->
                    {ok, {oid, [1, 3, 101, 110]}};

                x448 ->
                    {ok, {oid, [1, 3, 101, 111]}}
            end;

        _ ->
            {error, nil}
    end.

-file("src/kryptos/x509/certificate.gleam", 740).
?DOC(
    " Verify a certificate's signature against an issuer's public key.\n"
    "\n"
    " The public key must be RSA, ECDSA, or EdDSA (XDH keys cannot sign).\n"
).
-spec verify(certificate(parsed()), kryptos@x509:public_key()) -> {ok, nil} |
    {error, certificate_error()}.
verify(Cert, Issuer_public_key) ->
    {Tbs_bytes@1, Signature@1, Signature_algorithm@1} = case Cert of
        {parsed_certificate,
            _,
            Tbs_bytes,
            Signature,
            _,
            _,
            Signature_algorithm,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _,
            _} -> {Tbs_bytes, Signature, Signature_algorithm};
        _assert_fail ->
            erlang:error(#{gleam_error => let_assert,
                        message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                        file => <<?FILEPATH/utf8>>,
                        module => <<"kryptos/x509/certificate"/utf8>>,
                        function => <<"verify"/utf8>>,
                        line => 744,
                        value => _assert_fail,
                        start => 23720,
                        'end' => 23809,
                        pattern_start => 23731,
                        pattern_end => 23798})
    end,
    gleam@bool:lazy_guard(
        is_xdh_key(Issuer_public_key),
        fun() ->
            Oid = begin
                _pipe = xdh_key_oid(Issuer_public_key),
                gleam@result:unwrap(_pipe, {oid, []})
            end,
            {error, {unsupported_algorithm, Oid}}
        end,
        fun() ->
            Verified = kryptos@internal@x509:verify_signature(
                Issuer_public_key,
                Tbs_bytes@1,
                Signature@1,
                Signature_algorithm@1
            ),
            case Verified of
                true ->
                    {ok, nil};

                false ->
                    {error, signature_verification_failed}
            end
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 769).
?DOC(" Verify a self-signed certificate against its own public key.\n").
-spec verify_self_signed(certificate(parsed())) -> {ok, nil} |
    {error, certificate_error()}.
verify_self_signed(Cert) ->
    _pipe = public_key(Cert),
    verify(Cert, _pipe).

-file("src/kryptos/x509/certificate.gleam", 1418).
-spec encode_authority_key_identifier_extension(bitstring()) -> {ok,
        bitstring()} |
    {error, nil}.
encode_authority_key_identifier_extension(Key_identifier) ->
    {oid, Oid_components} = {oid, [2, 5, 29, 35]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) -> _pipe = Key_identifier,
            _pipe@1 = kryptos@internal@der:encode_context_primitive_tag(
                0,
                _pipe
            ),
            _pipe@2 = gleam@result:'try'(
                _pipe@1,
                fun kryptos@internal@der:encode_sequence/1
            ),
            _pipe@3 = gleam@result:'try'(
                _pipe@2,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@4 = gleam@result:map(
                _pipe@3,
                fun(Value_octet) ->
                    gleam_stdlib:bit_array_concat([Oid_encoded, Value_octet])
                end
            ),
            gleam@result:'try'(
                _pipe@4,
                fun kryptos@internal@der:encode_sequence/1
            ) end
    ).

-file("src/kryptos/x509/certificate.gleam", 1288).
-spec encode_aki_opt(authority_key_identifier_config(), bitstring()) -> {ok,
        {ok, bitstring()} | {error, nil}} |
    {error, nil}.
encode_aki_opt(Config, Spki) ->
    case Config of
        aki_exclude ->
            {ok, {error, nil}};

        aki_auto ->
            _pipe = compute_ski(Spki),
            _pipe@1 = gleam@result:'try'(
                _pipe,
                fun encode_authority_key_identifier_extension/1
            ),
            gleam@result:map(_pipe@1, fun(Field@0) -> {ok, Field@0} end);

        {aki_explicit, Key_id} ->
            _pipe@2 = encode_authority_key_identifier_extension(Key_id),
            gleam@result:map(_pipe@2, fun(Field@0) -> {ok, Field@0} end)
    end.

-file("src/kryptos/x509/certificate.gleam", 1304).
-spec encode_basic_constraints_extension(
    boolean(),
    gleam@option:option(integer())
) -> {ok, bitstring()} | {error, nil}.
encode_basic_constraints_extension(Ca, Path_len) ->
    {oid, Oid_components} = {oid, [2, 5, 29, 19]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) ->
            Ca_bool = case Ca of
                true ->
                    kryptos@internal@der:encode_bool(true);

                false ->
                    <<>>
            end,
            _pipe = case Path_len of
                {some, N} ->
                    kryptos@internal@der:encode_small_int(N);

                none ->
                    {ok, <<>>}
            end,
            _pipe@1 = gleam@result:map(
                _pipe,
                fun(Path_len_int) ->
                    gleam_stdlib:bit_array_concat([Ca_bool, Path_len_int])
                end
            ),
            _pipe@2 = gleam@result:'try'(
                _pipe@1,
                fun kryptos@internal@der:encode_sequence/1
            ),
            _pipe@3 = gleam@result:'try'(
                _pipe@2,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@4 = gleam@result:map(
                _pipe@3,
                fun(Value_octet) ->
                    gleam_stdlib:bit_array_concat(
                        [Oid_encoded,
                            kryptos@internal@der:encode_bool(true),
                            Value_octet]
                    )
                end
            ),
            gleam@result:'try'(
                _pipe@4,
                fun kryptos@internal@der:encode_sequence/1
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1240).
-spec encode_basic_constraints_opt(
    gleam@option:option({boolean(), gleam@option:option(integer())})
) -> {ok, {ok, bitstring()} | {error, nil}} | {error, nil}.
encode_basic_constraints_opt(Config) ->
    case Config of
        none ->
            {ok, {error, nil}};

        {some, {Ca, Path_len}} ->
            gleam@result:map(
                encode_basic_constraints_extension(Ca, Path_len),
                fun(Field@0) -> {ok, Field@0} end
            )
    end.

-file("src/kryptos/x509/certificate.gleam", 1375).
-spec encode_extended_key_usage_extension(
    list(kryptos@x509:extended_key_usage())
) -> {ok, bitstring()} | {error, nil}.
encode_extended_key_usage_extension(Usages) ->
    {oid, Oid_components} = {oid, [2, 5, 29, 37]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) -> _pipe = Usages,
            _pipe@1 = gleam@list:try_map(
                _pipe,
                fun(Usage) ->
                    {oid, Components} = case Usage of
                        server_auth ->
                            {oid, [1, 3, 6, 1, 5, 5, 7, 3, 1]};

                        client_auth ->
                            {oid, [1, 3, 6, 1, 5, 5, 7, 3, 2]};

                        code_signing ->
                            {oid, [1, 3, 6, 1, 5, 5, 7, 3, 3]};

                        email_protection ->
                            {oid, [1, 3, 6, 1, 5, 5, 7, 3, 4]};

                        ocsp_signing ->
                            {oid, [1, 3, 6, 1, 5, 5, 7, 3, 9]}
                    end,
                    kryptos@internal@der:encode_oid(Components)
                end
            ),
            _pipe@2 = gleam@result:map(
                _pipe@1,
                fun gleam_stdlib:bit_array_concat/1
            ),
            _pipe@3 = gleam@result:'try'(
                _pipe@2,
                fun kryptos@internal@der:encode_sequence/1
            ),
            _pipe@4 = gleam@result:'try'(
                _pipe@3,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@5 = gleam@result:map(
                _pipe@4,
                fun(Value_octet) ->
                    gleam_stdlib:bit_array_concat([Oid_encoded, Value_octet])
                end
            ),
            gleam@result:'try'(
                _pipe@5,
                fun kryptos@internal@der:encode_sequence/1
            ) end
    ).

-file("src/kryptos/x509/certificate.gleam", 1257).
-spec encode_extended_key_usage_opt(list(kryptos@x509:extended_key_usage())) -> {ok,
        {ok, bitstring()} | {error, nil}} |
    {error, nil}.
encode_extended_key_usage_opt(Usages) ->
    gleam@bool:guard(
        gleam@list:is_empty(Usages),
        {ok, {error, nil}},
        fun() ->
            gleam@result:map(
                encode_extended_key_usage_extension(Usages),
                fun(Field@0) -> {ok, Field@0} end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1405).
-spec encode_subject_key_identifier_extension(bitstring()) -> {ok, bitstring()} |
    {error, nil}.
encode_subject_key_identifier_extension(Ski) ->
    {oid, Oid_components} = {oid, [2, 5, 29, 14]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) -> _pipe = Ski,
            _pipe@1 = kryptos@internal@der:encode_octet_string(_pipe),
            _pipe@2 = gleam@result:'try'(
                _pipe@1,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@3 = gleam@result:map(
                _pipe@2,
                fun(Value_octet) ->
                    gleam_stdlib:bit_array_concat([Oid_encoded, Value_octet])
                end
            ),
            gleam@result:'try'(
                _pipe@3,
                fun kryptos@internal@der:encode_sequence/1
            ) end
    ).

-file("src/kryptos/x509/certificate.gleam", 1272).
-spec encode_ski_opt(
    gleam@option:option(subject_key_identifier_config()),
    bitstring()
) -> {ok, {ok, bitstring()} | {error, nil}} | {error, nil}.
encode_ski_opt(Config, Spki) ->
    case Config of
        none ->
            {ok, {error, nil}};

        {some, ski_auto} ->
            _pipe = compute_ski(Spki),
            _pipe@1 = gleam@result:'try'(
                _pipe,
                fun encode_subject_key_identifier_extension/1
            ),
            gleam@result:map(_pipe@1, fun(Field@0) -> {ok, Field@0} end);

        {some, {ski_explicit, Ski}} ->
            _pipe@2 = encode_subject_key_identifier_extension(Ski),
            gleam@result:map(_pipe@2, fun(Field@0) -> {ok, Field@0} end)
    end.

-file("src/kryptos/x509/certificate.gleam", 482).
?DOC(" Exports the certificate as a PEM-encoded string.\n").
-spec to_pem(certificate(any())) -> binary().
to_pem(Cert) ->
    kryptos@internal@x509:encode_pem(
        to_der(Cert),
        <<"-----BEGIN CERTIFICATE-----"/utf8>>,
        <<"-----END CERTIFICATE-----"/utf8>>
    ).

-file("src/kryptos/x509/certificate.gleam", 494).
?DOC(
    " Parse all PEM-encoded certificates from a string.\n"
    "\n"
    " Extracts and parses all `-----BEGIN CERTIFICATE-----` blocks from the input.\n"
    " Certificates are returned in the order they appear.\n"
    "\n"
    " **Note:** This function does NOT verify the certificates' cryptographic\n"
    " signatures. To verify a certificate was signed by an issuer, use `verify()`.\n"
    " For self-signed certificates, use `verify_self_signed()`.\n"
).
-spec from_pem(binary()) -> {ok, list(certificate(parsed()))} |
    {error, certificate_error()}.
from_pem(Pem) ->
    _pipe = kryptos@internal@x509:decode_pem_all(
        Pem,
        <<"-----BEGIN CERTIFICATE-----"/utf8>>,
        <<"-----END CERTIFICATE-----"/utf8>>
    ),
    _pipe@1 = gleam@result:replace_error(_pipe, parse_error),
    gleam@result:'try'(
        _pipe@1,
        fun(_capture) -> gleam@list:try_map(_capture, fun from_der/1) end
    ).

-file("src/kryptos/x509/certificate.gleam", 1341).
-spec encode_key_usage_extension(list(kryptos@x509:key_usage())) -> {ok,
        bitstring()} |
    {error, nil}.
encode_key_usage_extension(Usages) ->
    {oid, Oid_components} = {oid, [2, 5, 29, 15]},
    gleam@result:'try'(
        kryptos@internal@der:encode_oid(Oid_components),
        fun(Oid_encoded) ->
            Last_set_index = gleam@list:index_fold(
                [digital_signature,
                    non_repudiation,
                    key_encipherment,
                    data_encipherment,
                    key_agreement,
                    key_cert_sign,
                    crl_sign,
                    encipher_only,
                    decipher_only],
                0,
                fun(Last_index, Usage, Index) ->
                    case gleam@list:contains(Usages, Usage) of
                        true ->
                            Index + 1;

                        false ->
                            Last_index
                    end
                end
            ),
            Key_usage_bits = begin
                _pipe = [digital_signature,
                    non_repudiation,
                    key_encipherment,
                    data_encipherment,
                    key_agreement,
                    key_cert_sign,
                    crl_sign,
                    encipher_only,
                    decipher_only],
                _pipe@1 = gleam@list:take(_pipe, Last_set_index),
                gleam@list:fold(
                    _pipe@1,
                    <<>>,
                    fun(Acc, Usage@1) ->
                        Bit = case gleam@list:contains(Usages, Usage@1) of
                            true ->
                                1;

                            false ->
                                0
                        end,
                        <<Acc/bitstring, Bit:1>>
                    end
                )
            end,
            _pipe@2 = Key_usage_bits,
            _pipe@3 = kryptos@internal@der:encode_bit_string(_pipe@2),
            _pipe@4 = gleam@result:'try'(
                _pipe@3,
                fun kryptos@internal@der:encode_octet_string/1
            ),
            _pipe@5 = gleam@result:map(
                _pipe@4,
                fun(Value_octet) ->
                    gleam_stdlib:bit_array_concat(
                        [Oid_encoded,
                            kryptos@internal@der:encode_bool(true),
                            Value_octet]
                    )
                end
            ),
            gleam@result:'try'(
                _pipe@5,
                fun kryptos@internal@der:encode_sequence/1
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1250).
-spec encode_key_usage_opt(list(kryptos@x509:key_usage())) -> {ok,
        {ok, bitstring()} | {error, nil}} |
    {error, nil}.
encode_key_usage_opt(Usages) ->
    gleam@bool:guard(
        gleam@list:is_empty(Usages),
        {ok, {error, nil}},
        fun() ->
            gleam@result:map(
                encode_key_usage_extension(Usages),
                fun(Field@0) -> {ok, Field@0} end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1211).
-spec encode_extensions(builder(), bitstring()) -> {ok, bitstring()} |
    {error, nil}.
encode_extensions(Builder, Spki) ->
    {name, Rdns} = erlang:element(2, Builder),
    Subject_is_empty = gleam@list:is_empty(Rdns),
    Sans_is_empty = gleam@list:is_empty(erlang:element(7, Builder)),
    gleam@bool:guard(
        Subject_is_empty andalso Sans_is_empty,
        {error, nil},
        fun() ->
            Extension_results = [encode_basic_constraints_opt(
                    erlang:element(4, Builder)
                ),
                encode_key_usage_opt(erlang:element(5, Builder)),
                encode_extended_key_usage_opt(erlang:element(6, Builder)),
                encode_san_opt(erlang:element(7, Builder), Subject_is_empty),
                encode_ski_opt(erlang:element(9, Builder), Spki),
                encode_aki_opt(erlang:element(10, Builder), Spki)],
            gleam@result:'try'(
                gleam@result:all(Extension_results),
                fun(Results) ->
                    Encoded = gleam@result:values(Results),
                    case Encoded of
                        [] ->
                            {ok, <<>>};

                        _ ->
                            _pipe = Encoded,
                            _pipe@1 = gleam_stdlib:bit_array_concat(_pipe),
                            _pipe@2 = kryptos@internal@der:encode_sequence(
                                _pipe@1
                            ),
                            gleam@result:'try'(
                                _pipe@2,
                                fun(_capture) ->
                                    kryptos@internal@der:encode_context_tag(
                                        3,
                                        _capture
                                    )
                                end
                            )
                    end
                end
            )
        end
    ).

-file("src/kryptos/x509/certificate.gleam", 1168).
-spec encode_tbs_certificate(
    builder(),
    bitstring(),
    kryptos@internal@x509:sig_alg_info(),
    bitstring(),
    kryptos@x509:validity()
) -> {ok, bitstring()} | {error, nil}.
encode_tbs_certificate(Builder, Serial, Sig_alg, Spki, Validity) ->
    gleam@result:'try'(
        encode_version(),
        fun(Version) ->
            gleam@result:'try'(
                kryptos@internal@der:encode_integer(Serial),
                fun(Serial_int) ->
                    gleam@result:'try'(
                        kryptos@internal@x509:encode_algorithm_identifier(
                            Sig_alg
                        ),
                        fun(Sig_alg_der) ->
                            gleam@result:'try'(
                                kryptos@internal@x509:encode_name(
                                    erlang:element(2, Builder)
                                ),
                                fun(Issuer) ->
                                    gleam@result:'try'(
                                        encode_validity(Validity),
                                        fun(Validity_der) ->
                                            gleam@result:'try'(
                                                kryptos@internal@x509:encode_name(
                                                    erlang:element(2, Builder)
                                                ),
                                                fun(Subject) ->
                                                    gleam@result:'try'(
                                                        encode_extensions(
                                                            Builder,
                                                            Spki
                                                        ),
                                                        fun(Extensions) ->
                                                            kryptos@internal@der:encode_sequence(
                                                                gleam_stdlib:bit_array_concat(
                                                                    [Version,
                                                                        Serial_int,
                                                                        Sig_alg_der,
                                                                        Issuer,
                                                                        Validity_der,
                                                                        Subject,
                                                                        Spki,
                                                                        Extensions]
                                                                )
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

-file("src/kryptos/x509/certificate.gleam", 380).
?DOC(
    " Signs a self-signed certificate with an ECDSA private key.\n"
    "\n"
    " The public key is derived from the private key and used as both\n"
    " the issuer and subject public key.\n"
).
-spec self_signed_with_ecdsa(
    builder(),
    kryptos@ec:private_key(),
    kryptos@hash:hash_algorithm()
) -> {ok, certificate(built())} | {error, nil}.
self_signed_with_ecdsa(Builder, Key, Hash) ->
    gleam@result:'try'(
        gleam@option:to_result(erlang:element(3, Builder), nil),
        fun(Validity) ->
            gleam@result:'try'(
                kryptos@internal@x509:ecdsa_sig_alg_info(Hash),
                fun(Sig_alg) ->
                    Public_key = kryptos_ffi:ec_public_key_from_private(Key),
                    gleam@result:'try'(
                        kryptos_ffi:ec_export_public_key_der(Public_key),
                        fun(Spki) ->
                            Serial = case erlang:element(8, Builder) of
                                {some, S} ->
                                    S;

                                none ->
                                    generate_serial_number()
                            end,
                            gleam@result:'try'(
                                encode_tbs_certificate(
                                    Builder,
                                    Serial,
                                    Sig_alg,
                                    Spki,
                                    Validity
                                ),
                                fun(Tbs) ->
                                    Signature = kryptos_ffi:ecdsa_sign(
                                        Key,
                                        Tbs,
                                        Hash
                                    ),
                                    gleam@result:'try'(
                                        encode_certificate(
                                            Tbs,
                                            Sig_alg,
                                            Signature
                                        ),
                                        fun(Cert_der) ->
                                            {ok, {built_certificate, Cert_der}}
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

-file("src/kryptos/x509/certificate.gleam", 412).
?DOC(
    " Signs a self-signed certificate with an RSA private key using PKCS#1 v1.5 padding.\n"
    "\n"
    " The public key is derived from the private key and used as both\n"
    " the issuer and subject public key.\n"
).
-spec self_signed_with_rsa(
    builder(),
    kryptos@rsa:private_key(),
    kryptos@hash:hash_algorithm()
) -> {ok, certificate(built())} | {error, nil}.
self_signed_with_rsa(Builder, Key, Hash) ->
    gleam@result:'try'(
        gleam@option:to_result(erlang:element(3, Builder), nil),
        fun(Validity) ->
            gleam@result:'try'(
                kryptos@internal@x509:rsa_sig_alg_info(Hash),
                fun(Sig_alg) ->
                    Public_key = kryptos_ffi:rsa_public_key_from_private(Key),
                    gleam@result:'try'(
                        kryptos_ffi:rsa_export_public_key_der(Public_key, spki),
                        fun(Spki) ->
                            Serial = case erlang:element(8, Builder) of
                                {some, S} ->
                                    S;

                                none ->
                                    generate_serial_number()
                            end,
                            gleam@result:'try'(
                                encode_tbs_certificate(
                                    Builder,
                                    Serial,
                                    Sig_alg,
                                    Spki,
                                    Validity
                                ),
                                fun(Tbs) ->
                                    Signature = kryptos_ffi:rsa_sign(
                                        Key,
                                        Tbs,
                                        Hash,
                                        pkcs1v15
                                    ),
                                    gleam@result:'try'(
                                        encode_certificate(
                                            Tbs,
                                            Sig_alg,
                                            Signature
                                        ),
                                        fun(Cert_der) ->
                                            {ok, {built_certificate, Cert_der}}
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

-file("src/kryptos/x509/certificate.gleam", 444).
?DOC(
    " Signs a self-signed certificate with an EdDSA private key.\n"
    "\n"
    " The public key is derived from the private key and used as both\n"
    " the issuer and subject public key. EdDSA has built-in hashing, so no\n"
    " hash algorithm parameter is needed.\n"
).
-spec self_signed_with_eddsa(builder(), kryptos@eddsa:private_key()) -> {ok,
        certificate(built())} |
    {error, nil}.
self_signed_with_eddsa(Builder, Key) ->
    gleam@result:'try'(
        gleam@option:to_result(erlang:element(3, Builder), nil),
        fun(Validity) ->
            Sig_alg = case kryptos_ffi:eddsa_private_key_curve(Key) of
                ed25519 ->
                    {sig_alg_info, {oid, [1, 3, 101, 112]}, false};

                ed448 ->
                    {sig_alg_info, {oid, [1, 3, 101, 113]}, false}
            end,
            Public_key = kryptos_ffi:eddsa_public_key_from_private(Key),
            gleam@result:'try'(
                kryptos_ffi:eddsa_export_public_key_der(Public_key),
                fun(Spki) ->
                    Serial = case erlang:element(8, Builder) of
                        {some, S} ->
                            S;

                        none ->
                            generate_serial_number()
                    end,
                    gleam@result:'try'(
                        encode_tbs_certificate(
                            Builder,
                            Serial,
                            Sig_alg,
                            Spki,
                            Validity
                        ),
                        fun(Tbs) ->
                            Signature = kryptos_ffi:eddsa_sign(Key, Tbs),
                            gleam@result:'try'(
                                encode_certificate(Tbs, Sig_alg, Signature),
                                fun(Cert_der) ->
                                    {ok, {built_certificate, Cert_der}}
                                end
                            )
                        end
                    )
                end
            )
        end
    ).
