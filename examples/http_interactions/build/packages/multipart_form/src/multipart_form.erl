-module(multipart_form).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_request/2, from_request/1]).

-file("src/multipart_form.gleam", 6).
-spec to_request(
    gleam@http@request:request(any()),
    list({binary(), multipart_form@field:form_body()})
) -> gleam@http@request:request(bitstring()).
to_request(Req, Form) ->
    Boundary = <<"gleam_multipart_form"/utf8>>,
    _pipe = Req,
    _pipe@1 = gleam@http@request:set_header(
        _pipe,
        <<"Content-Type"/utf8>>,
        <<"multipart/form-data; boundary="/utf8, Boundary/binary>>
    ),
    gleam@http@request:set_body(
        _pipe@1,
        multipart_form@form:to_bit_array(Form, Boundary)
    ).

-file("src/multipart_form.gleam", 21).
-spec from_request(gleam@http@request:request(bitstring())) -> {ok,
        list({binary(), multipart_form@field:form_body()})} |
    {error, binary()}.
from_request(Req) ->
    gleam@result:'try'(
        begin
            _pipe = gleam@http@request:get_header(Req, <<"content-type"/utf8>>),
            gleam@result:replace_error(
                _pipe,
                <<"Request does not hace content-type"/utf8>>
            )
        end,
        fun(Content_type) -> case Content_type of
                <<"multipart/form-data; boundary="/utf8, Boundary/binary>> ->
                    multipart_form@form:from_bit_array(
                        erlang:element(4, Req),
                        Boundary
                    );

                _ ->
                    {error, <<"Request is not a multipart form"/utf8>>}
            end end
    ).
