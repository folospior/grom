-record(authority_key_identifier, {
    key_identifier :: gleam@option:option(bitstring()),
    authority_cert_issuer :: gleam@option:option(list(kryptos@x509:subject_alt_name())),
    authority_cert_serial_number :: gleam@option:option(bitstring())
}).
