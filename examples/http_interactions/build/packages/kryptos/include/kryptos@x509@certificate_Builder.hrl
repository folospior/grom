-record(builder, {
    subject :: kryptos@x509:name(),
    validity :: gleam@option:option(kryptos@x509:validity()),
    basic_constraints :: gleam@option:option({boolean(),
        gleam@option:option(integer())}),
    key_usage :: list(kryptos@x509:key_usage()),
    extended_key_usage :: list(kryptos@x509:extended_key_usage()),
    subject_alt_names :: list(kryptos@x509:subject_alt_name()),
    serial_number :: gleam@option:option(bitstring()),
    subject_key_identifier :: gleam@option:option(kryptos@x509@certificate:subject_key_identifier_config()),
    authority_key_identifier :: kryptos@x509@certificate:authority_key_identifier_config()
}).
