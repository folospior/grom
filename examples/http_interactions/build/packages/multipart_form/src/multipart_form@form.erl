-module(multipart_form@form).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch]).

-export([to_bit_array/2, from_bit_array/2]).

-file("src/multipart_form/form.gleam", 13).
-spec to_bit_array(list({binary(), multipart_form@field:form_body()}), binary()) -> bitstring().
to_bit_array(Fields, Boundary) ->
    _pipe = gleam@list:map(
        Fields,
        fun(Field) ->
            {Name, Body} = Field,
            multipart_form@field:to_bit_array(Name, Body, Boundary)
        end
    ),
    _pipe@1 = lists:append(_pipe, [<<"--"/utf8, Boundary/binary, "--"/utf8>>]),
    gleam_stdlib:bit_array_concat(_pipe@1).

-file("src/multipart_form/form.gleam", 30).
-spec parse_field(
    bitstring(),
    binary(),
    list({binary(), multipart_form@field:form_body()})
) -> {ok, list({binary(), multipart_form@field:form_body()})} |
    {error, binary()}.
parse_field(Body, Boundary, Fields) ->
    gleam@result:'try'(
        begin
            _pipe = gleam@http:parse_multipart_headers(Body, Boundary),
            gleam@result:replace_error(
                _pipe,
                <<"Failed to parse Field headers"/utf8>>
            )
        end,
        fun(Headers) -> gleam@result:'try'(case Headers of
                    {more_required_for_headers, _} ->
                        {error, <<"Must provide a full body"/utf8>>};

                    {multipart_headers, Headers@1, Rest} ->
                        {ok, {Headers@1, Rest}}
                end, fun(_use0) ->
                    {Headers@2, Rest@1} = _use0,
                    gleam@result:'try'(
                        begin
                            _pipe@1 = gleam@list:key_find(
                                Headers@2,
                                <<"content-disposition"/utf8>>
                            ),
                            gleam@result:replace_error(
                                _pipe@1,
                                <<"Invalid form field, does not contain Content-Disposition"/utf8>>
                            )
                        end,
                        fun(Header) ->
                            gleam@result:'try'(
                                begin
                                    _pipe@2 = gleam@http:parse_content_disposition(
                                        Header
                                    ),
                                    gleam@result:replace_error(
                                        _pipe@2,
                                        <<"Invalid form field, contains an invalid Content-Disposition header"/utf8>>
                                    )
                                end,
                                fun(Header@1) ->
                                    gleam@result:'try'(
                                        begin
                                            _pipe@3 = gleam@list:key_find(
                                                erlang:element(3, Header@1),
                                                <<"name"/utf8>>
                                            ),
                                            gleam@result:replace_error(
                                                _pipe@3,
                                                <<"Invalid form field, does not contain field name"/utf8>>
                                            )
                                        end,
                                        fun(Field) ->
                                            Filename = gleam@option:from_result(
                                                gleam@list:key_find(
                                                    erlang:element(3, Header@1),
                                                    <<"filename"/utf8>>
                                                )
                                            ),
                                            gleam@result:'try'(
                                                begin
                                                    _pipe@4 = gleam@http:parse_multipart_body(
                                                        Rest@1,
                                                        Boundary
                                                    ),
                                                    gleam@result:replace_error(
                                                        _pipe@4,
                                                        <<"Failed to parse field body"/utf8>>
                                                    )
                                                end,
                                                fun(Body@1) ->
                                                    gleam@result:'try'(
                                                        case Body@1 of
                                                            {more_required_for_body,
                                                                _,
                                                                _} ->
                                                                {error,
                                                                    <<"Must provide a full body"/utf8>>};

                                                            {multipart_body,
                                                                Body@2,
                                                                Done,
                                                                Rest@2} ->
                                                                {ok,
                                                                    {Body@2,
                                                                        Done,
                                                                        Rest@2}}
                                                        end,
                                                        fun(_use0@1) ->
                                                            {Body@3,
                                                                Done@1,
                                                                Rest@3} = _use0@1,
                                                            gleam@result:'try'(
                                                                case Filename of
                                                                    none ->
                                                                        gleam@result:map(
                                                                            begin
                                                                                _pipe@5 = gleam@bit_array:to_string(
                                                                                    Body@3
                                                                                ),
                                                                                gleam@result:replace_error(
                                                                                    _pipe@5,
                                                                                    <<"Invalid utf-8 string in string field"/utf8>>
                                                                                )
                                                                            end,
                                                                            fun(
                                                                                Content
                                                                            ) ->
                                                                                case gleam@list:key_find(
                                                                                    Headers@2,
                                                                                    <<"content-type"/utf8>>
                                                                                ) of
                                                                                    {ok,
                                                                                        Content_type} ->
                                                                                        {Field,
                                                                                            {string_with_type,
                                                                                                Content,
                                                                                                Content_type}};

                                                                                    {error,
                                                                                        _} ->
                                                                                        {Field,
                                                                                            {string,
                                                                                                Content}}
                                                                                end
                                                                            end
                                                                        );

                                                                    {some,
                                                                        Filename@1} ->
                                                                        gleam@result:map(
                                                                            begin
                                                                                _pipe@6 = gleam@list:key_find(
                                                                                    Headers@2,
                                                                                    <<"content-type"/utf8>>
                                                                                ),
                                                                                gleam@result:replace_error(
                                                                                    _pipe@6,
                                                                                    <<"Invalid form file field, does not contain Content-Type header"/utf8>>
                                                                                )
                                                                            end,
                                                                            fun(
                                                                                Header@2
                                                                            ) ->
                                                                                {Field,
                                                                                    {file,
                                                                                        Filename@1,
                                                                                        Header@2,
                                                                                        Body@3}}
                                                                            end
                                                                        )
                                                                end,
                                                                fun(Field@1) ->
                                                                    Fields@1 = [Field@1 |
                                                                        Fields],
                                                                    case Done@1 of
                                                                        false ->
                                                                            parse_field(
                                                                                Rest@3,
                                                                                Boundary,
                                                                                Fields@1
                                                                            );

                                                                        true ->
                                                                            {ok,
                                                                                Fields@1}
                                                                    end
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
                end) end
    ).

-file("src/multipart_form/form.gleam", 23).
-spec from_bit_array(bitstring(), binary()) -> {ok,
        list({binary(), multipart_form@field:form_body()})} |
    {error, binary()}.
from_bit_array(Form, Boundary) ->
    _pipe = parse_field(Form, Boundary, []),
    gleam@result:map(_pipe, fun lists:reverse/1).
