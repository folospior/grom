-record(parsed_certificate, {
    der :: bitstring(),
    tbs_bytes :: bitstring(),
    signature :: bitstring(),
    version :: integer(),
    serial_number :: bitstring(),
    signature_algorithm :: kryptos@x509:signature_algorithm(),
    issuer :: kryptos@x509:name(),
    validity :: kryptos@x509:validity(),
    subject :: kryptos@x509:name(),
    public_key :: kryptos@x509:public_key(),
    basic_constraints :: gleam@option:option(kryptos@x509:basic_constraints()),
    key_usage :: list(kryptos@x509:key_usage()),
    extended_key_usage :: list(kryptos@x509:extended_key_usage()),
    subject_alt_names :: list(kryptos@x509:subject_alt_name()),
    subject_key_identifier :: gleam@option:option(bitstring()),
    authority_key_identifier :: gleam@option:option(kryptos@x509:authority_key_identifier()),
    extensions :: list({kryptos@x509:oid(), boolean(), bitstring()})
}).
