-record(parsed_csr, {
    der :: bitstring(),
    version :: integer(),
    subject :: kryptos@x509:name(),
    public_key :: kryptos@x509:public_key(),
    signature_algorithm :: kryptos@x509:signature_algorithm(),
    subject_alt_names :: list(kryptos@x509:subject_alt_name()),
    extensions :: list({kryptos@x509:oid(), boolean(), bitstring()}),
    attributes :: list({kryptos@x509:oid(), bitstring()})
}).
