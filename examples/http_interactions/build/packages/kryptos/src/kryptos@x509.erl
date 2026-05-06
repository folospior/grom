-module(kryptos@x509).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/kryptos/x509.gleam").
-export([name/1, encode_attribute_value/1, utf8_string/1, printable_string/1, ia5_string/1, attribute_value_to_string/1, name_to_string/1, cn/1, organization/1, organizational_unit/1, country/1, state/1, locality/1, email_address/1]).
-export_type([oid/0, name/0, rdn/0, attribute_value/0, subject_alt_name/0, extensions/0, public_key/0, signature_algorithm/0, basic_constraints/0, key_usage/0, extended_key_usage/0, validity/0, authority_key_identifier/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

?MODULEDOC(
    " X.509 certificate and CSR types and utilities.\n"
    "\n"
    " Types and helpers for X.509 public key infrastructure:\n"
    "\n"
    " - Distinguished Names: Type-safe construction of subject/issuer names\n"
    " - Extensions: Subject Alternative Names, Basic Constraints, Key Usage, etc.\n"
    " - Public Keys: Unified representation for RSA, ECDSA, EdDSA, and XDH keys\n"
    " - Signature Algorithms: Common signing algorithms for certificates and CSRs\n"
    " - Certificate Fields: Validity periods, authority key identifiers\n"
    "\n"
    " See also:\n"
    " - `x509/csr` for creating and parsing Certificate Signing Requests\n"
    " - `x509/certificate` for parsing and working with X.509 certificates\n"
    "\n"
    " ## Distinguished Names\n"
    "\n"
    " Distinguished names (DNs) identify subjects and issuers in X.509 structures.\n"
    " They consist of attribute-value pairs like Common Name (CN), Organization (O),\n"
    " and Country (C). Helper functions provide type-safe construction with correct\n"
    " ASN.1 string encodings:\n"
    "\n"
    " ```gleam\n"
    " import kryptos/x509\n"
    "\n"
    " let subject = x509.name([\n"
    "   x509.cn(\"example.com\"),\n"
    "   x509.organization(\"Acme Inc\"),\n"
    "   x509.organizational_unit(\"Engineering\"),\n"
    "   x509.locality(\"San Francisco\"),\n"
    "   x509.state(\"California\"),\n"
    "   x509.country(\"US\"),\n"
    " ])\n"
    " ```\n"
    "\n"
    " ## Extensions\n"
    "\n"
    " Subject Alternative Names (SANs) specify additional identities:\n"
    "\n"
    " ```gleam\n"
    " import kryptos/x509.{DnsName, Email, IpAddress, Uri}\n"
    "\n"
    " let extensions = x509.Extensions([\n"
    "   DnsName(\"www.example.com\"),\n"
    "   DnsName(\"api.example.com\"),\n"
    "   Email(\"admin@example.com\"),\n"
    "   Uri(\"https://example.com/cps\"),\n"
    " ])\n"
    " ```\n"
).

-type oid() :: {oid, list(integer())}.

-type name() :: {name, list(rdn())}.

-type rdn() :: {rdn, list({oid(), attribute_value()})}.

-opaque attribute_value() :: {utf8_string, binary()} |
    {printable_string, binary()} |
    {ia5_string, binary()}.

-type subject_alt_name() :: {dns_name, binary()} |
    {ip_address, bitstring()} |
    {email, binary()} |
    {uri, binary()} |
    {directory_name, name()} |
    {registered_id, oid()} |
    {other_name, oid(), bitstring()} |
    {unknown, integer(), bitstring()}.

-type extensions() :: {extensions, list(subject_alt_name())}.

-type public_key() :: {ec_public_key, kryptos@ec:public_key()} |
    {rsa_public_key, kryptos@rsa:public_key()} |
    {ed_public_key, kryptos@eddsa:public_key()} |
    {xdh_public_key, kryptos@xdh:public_key()}.

-type signature_algorithm() :: rsa_sha1 |
    rsa_sha256 |
    rsa_sha384 |
    rsa_sha512 |
    ecdsa_sha1 |
    ecdsa_sha256 |
    ecdsa_sha384 |
    ecdsa_sha512 |
    ed25519 |
    ed448.

-type basic_constraints() :: {basic_constraints,
        boolean(),
        gleam@option:option(integer())}.

-type key_usage() :: digital_signature |
    non_repudiation |
    key_encipherment |
    data_encipherment |
    key_agreement |
    key_cert_sign |
    crl_sign |
    encipher_only |
    decipher_only.

-type extended_key_usage() :: server_auth |
    client_auth |
    code_signing |
    email_protection |
    ocsp_signing.

-type validity() :: {validity,
        gleam@time@timestamp:timestamp(),
        gleam@time@timestamp:timestamp()}.

-type authority_key_identifier() :: {authority_key_identifier,
        gleam@option:option(bitstring()),
        gleam@option:option(list(subject_alt_name())),
        gleam@option:option(bitstring())}.

-file("src/kryptos/x509.gleam", 224).
?DOC(
    " Builds a distinguished name from a list of attribute-value pairs.\n"
    "\n"
    " Creates a Name with each attribute in its own Relative Distinguished Name\n"
    " (RDN). Use helper functions like `cn`, `organization`, `country`, etc.\n"
    " to construct the attribute list.\n"
).
-spec name(list({oid(), attribute_value()})) -> name().
name(Attributes) ->
    {name, gleam@list:map(Attributes, fun(Attr) -> {rdn, [Attr]} end)}.

-file("src/kryptos/x509.gleam", 281).
?DOC(false).
-spec encode_attribute_value(attribute_value()) -> {ok, bitstring()} |
    {error, nil}.
encode_attribute_value(Value) ->
    case Value of
        {utf8_string, S} ->
            kryptos@internal@der:encode_utf8_string(S);

        {printable_string, S@1} ->
            kryptos@internal@der:encode_printable_string(S@1);

        {ia5_string, S@2} ->
            kryptos@internal@der:encode_ia5_string(S@2)
    end.

-file("src/kryptos/x509.gleam", 290).
?DOC(false).
-spec utf8_string(binary()) -> attribute_value().
utf8_string(Value) ->
    {utf8_string, Value}.

-file("src/kryptos/x509.gleam", 295).
?DOC(false).
-spec printable_string(binary()) -> attribute_value().
printable_string(Value) ->
    {printable_string, Value}.

-file("src/kryptos/x509.gleam", 300).
?DOC(false).
-spec ia5_string(binary()) -> attribute_value().
ia5_string(Value) ->
    {ia5_string, Value}.

-file("src/kryptos/x509.gleam", 308).
?DOC(
    " Extracts the string value from an AttributeValue.\n"
    "\n"
    " Returns the underlying string regardless of encoding type\n"
    " (UTF8String, PrintableString, or IA5String).\n"
).
-spec attribute_value_to_string(attribute_value()) -> binary().
attribute_value_to_string(Value) ->
    case Value of
        {utf8_string, S} ->
            S;

        {printable_string, S@1} ->
            S@1;

        {ia5_string, S@2} ->
            S@2
    end.

-file("src/kryptos/x509.gleam", 335).
-spec oid_to_abbrev(oid()) -> binary().
oid_to_abbrev(Oid) ->
    case Oid of
        {oid, [2, 5, 4, 3]} ->
            <<"CN"/utf8>>;

        {oid, [2, 5, 4, 6]} ->
            <<"C"/utf8>>;

        {oid, [2, 5, 4, 7]} ->
            <<"L"/utf8>>;

        {oid, [2, 5, 4, 8]} ->
            <<"ST"/utf8>>;

        {oid, [2, 5, 4, 10]} ->
            <<"O"/utf8>>;

        {oid, [2, 5, 4, 11]} ->
            <<"OU"/utf8>>;

        {oid, [1, 2, 840, 113549, 1, 9, 1]} ->
            <<"emailAddress"/utf8>>;

        {oid, Components} ->
            gleam@string:join(
                gleam@list:map(Components, fun erlang:integer_to_binary/1),
                <<"."/utf8>>
            )
    end.

-file("src/kryptos/x509.gleam", 322).
?DOC(
    " Converts a distinguished name to a human-readable string.\n"
    "\n"
    " Formats the name in OpenSSL style: \"CN=example.com, O=Acme Inc, C=US\"\n"
    "\n"
    " Known OIDs are displayed with their standard abbreviations (CN, O, OU, C, ST, L).\n"
    " Unknown OIDs are displayed in dotted-decimal notation (e.g., \"1.2.3.4=value\").\n"
).
-spec name_to_string(name()) -> binary().
name_to_string(Name) ->
    {name, Rdns} = Name,
    _pipe = Rdns,
    _pipe@1 = gleam@list:flat_map(
        _pipe,
        fun(Rdn) ->
            {rdn, Attributes} = Rdn,
            gleam@list:map(
                Attributes,
                fun(Attr) ->
                    {Oid, Value} = Attr,
                    <<<<(oid_to_abbrev(Oid))/binary, "="/utf8>>/binary,
                        (attribute_value_to_string(Value))/binary>>
                end
            )
        end
    ),
    gleam@string:join(_pipe@1, <<", "/utf8>>).

-file("src/kryptos/x509.gleam", 233).
?DOC(
    " Creates a Common Name (CN) attribute.\n"
    "\n"
    " The Common Name typically contains the primary identifier for the subject,\n"
    " such as a domain name for server certificates or a person's name for\n"
    " client certificates.\n"
).
-spec cn(binary()) -> {oid(), attribute_value()}.
cn(Value) ->
    {{oid, [2, 5, 4, 3]}, {utf8_string, Value}}.

-file("src/kryptos/x509.gleam", 238).
?DOC(" Creates an Organization (O) attribute.\n").
-spec organization(binary()) -> {oid(), attribute_value()}.
organization(Value) ->
    {{oid, [2, 5, 4, 10]}, {utf8_string, Value}}.

-file("src/kryptos/x509.gleam", 243).
?DOC(" Creates an Organizational Unit (OU) attribute.\n").
-spec organizational_unit(binary()) -> {oid(), attribute_value()}.
organizational_unit(Value) ->
    {{oid, [2, 5, 4, 11]}, {utf8_string, Value}}.

-file("src/kryptos/x509.gleam", 254).
?DOC(
    " Creates a Country (C) attribute.\n"
    "\n"
    " Uses PrintableString encoding as required by X.520.\n"
    "\n"
    " **Important:** The value must be a two-letter uppercase ISO 3166-1 alpha-2\n"
    " country code (e.g., \"US\", \"GB\", \"DE\"). Non-ASCII or incorrectly formatted\n"
    " values will produce non-compliant DER that may be rejected by CAs and clients.\n"
).
-spec country(binary()) -> {oid(), attribute_value()}.
country(Value) ->
    {{oid, [2, 5, 4, 6]}, {printable_string, Value}}.

-file("src/kryptos/x509.gleam", 259).
?DOC(" Creates a State or Province (ST) attribute.\n").
-spec state(binary()) -> {oid(), attribute_value()}.
state(Value) ->
    {{oid, [2, 5, 4, 8]}, {utf8_string, Value}}.

-file("src/kryptos/x509.gleam", 264).
?DOC(" Creates a Locality (L) attribute.\n").
-spec locality(binary()) -> {oid(), attribute_value()}.
locality(Value) ->
    {{oid, [2, 5, 4, 7]}, {utf8_string, Value}}.

-file("src/kryptos/x509.gleam", 276).
?DOC(
    " Creates an Email Address attribute.\n"
    "\n"
    " Note: emailAddress in the DN is deprecated; prefer using\n"
    " Subject Alternative Names via `csr.with_email` instead.\n"
    "\n"
    " **Important:** The value must contain only ASCII characters.\n"
    " Non-ASCII values will produce non-compliant DER that may be rejected\n"
    " by CAs and clients.\n"
).
-spec email_address(binary()) -> {oid(), attribute_value()}.
email_address(Value) ->
    {{oid, [1, 2, 840, 113549, 1, 9, 1]}, {ia5_string, Value}}.
