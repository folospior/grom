-module(multipart_form@field).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_bit_array/3]).
-export_type([form_body/0]).

-type form_body() :: {string, binary()} |
    {string_with_type, binary(), binary()} |
    {file, binary(), binary(), bitstring()}.

-file("src/multipart_form/field.gleam", 9).
-spec to_bit_array(binary(), form_body(), binary()) -> bitstring().
to_bit_array(Field, Element, Boundary) ->
    Body = case Element of
        {file, Filename, Content_type, Content} ->
            <<"Content-Disposition: form-data; name=\""/utf8,
                Field/binary,
                "\"; filename=\""/utf8,
                Filename/binary,
                "\"\r\nContent-Type: "/utf8,
                Content_type/binary,
                "\r\n\r\n"/utf8,
                Content/bitstring>>;

        {string, Content@1} ->
            <<"Content-Disposition: form-data; name=\""/utf8,
                Field/binary,
                "\"\r\n\r\n"/utf8,
                Content@1/binary>>;

        {string_with_type, Content@2, Type_} ->
            <<"Content-Disposition: form-data; name=\""/utf8,
                Field/binary,
                "\"\r\nContent-Type: "/utf8,
                Type_/binary,
                "\r\n\r\n"/utf8,
                Content@2/binary>>
    end,
    gleam_stdlib:bit_array_concat(
        [<<"--"/utf8, Boundary/binary, "\r\n"/utf8>>, Body, <<"\r\n"/utf8>>]
    ).
