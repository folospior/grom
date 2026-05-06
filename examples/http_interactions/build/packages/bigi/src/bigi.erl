-module(bigi).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/bigi.gleam").
-export([zero/0, one/0, negative_one/0, ten/0, from_int/1, from_string/1, from_bytes/3, to_int/1, to_string/1, to_bytes/4, compare/2, absolute/1, negate/1, add/2, subtract/2, multiply/2, divide/2, divide_no_zero/2, remainder/2, floor_divide/2, remainder_no_zero/2, modulo/2, modulo_no_zero/2, power/2, do_decode/1, decoder/0, bitwise_and/2, bitwise_exclusive_or/2, bitwise_not/1, bitwise_or/2, bitwise_shift_left/2, bitwise_shift_right/2, is_odd/1, max/2, min/2, clamp/3, sum/1, product/1, undigits/2, digits/1, from_base2/1, from_base8/1, from_base16/1, from_base/3, to_base2/1, to_base8/1, to_base16/1, to_base/3]).
-export_type([big_int/0, endianness/0, signedness/0]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-type big_int() :: any().

-type endianness() :: little_endian | big_endian.

-type signedness() :: signed | unsigned.

-file("src/bigi.gleam", 28).
?DOC(" Create a big integer representing zero.\n").
-spec zero() -> big_int().
zero() ->
    bigi_ffi:zero().

-file("src/bigi.gleam", 33).
?DOC(" Create a big integer representing one.\n").
-spec one() -> big_int().
one() ->
    bigi_ffi:one().

-file("src/bigi.gleam", 38).
?DOC(" Create a big integer representing negative one.\n").
-spec negative_one() -> big_int().
negative_one() ->
    bigi_ffi:n_one().

-file("src/bigi.gleam", 43).
?DOC(" Create a big integer representing ten.\n").
-spec ten() -> big_int().
ten() ->
    bigi_ffi:ten().

-file("src/bigi.gleam", 56).
?DOC(
    " Create a big integer from a regular integer.\n"
    "\n"
    " Note that in the JavaScript target, if your integer is bigger than the\n"
    " [maximum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)\n"
    " or smaller than the\n"
    " [minimum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER),\n"
    " you may lose precision when operating on it, including when converting it\n"
    " into a big integer (as the JavaScript Number type has already reduced the\n"
    " precision of the value).\n"
).
-spec from_int(integer()) -> big_int().
from_int(Int) ->
    bigi_ffi:from(Int).

-file("src/bigi.gleam", 64).
?DOC(
    " Convert a string into a big integer.\n"
    "\n"
    " If the string does not represent a big integer in base 10, an error is\n"
    " returned. Trailing non-digit content is not allowed.\n"
).
-spec from_string(binary()) -> {ok, big_int()} | {error, nil}.
from_string(Str) ->
    bigi_ffi:from_string(Str).

-file("src/bigi.gleam", 72).
?DOC(
    " Convert raw bytes into a big integer.\n"
    " \n"
    " If the bit array does not contain a whole number of bytes then an error is\n"
    " returned.\n"
).
-spec from_bytes(bitstring(), endianness(), signedness()) -> {ok, big_int()} |
    {error, nil}.
from_bytes(Bytes, Endianness, Signedness) ->
    bigi_ffi:from_bytes(Bytes, Endianness, Signedness).

-file("src/bigi.gleam", 87).
?DOC(
    " Convert a big integer to a regular integer.\n"
    "\n"
    " In Erlang, this cannot fail, as all Erlang integers are big integers. In the\n"
    " JavaScript target, this will fail if the integer is bigger than the\n"
    " [maximum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)\n"
    " or smaller than the\n"
    " [minimum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER).\n"
).
-spec to_int(big_int()) -> {ok, integer()} | {error, nil}.
to_int(Bigint) ->
    bigi_ffi:to(Bigint).

-file("src/bigi.gleam", 92).
?DOC(" Convert the big integer into a simple string - a sequence of digits.\n").
-spec to_string(big_int()) -> binary().
to_string(Bigint) ->
    erlang:integer_to_binary(Bigint).

-file("src/bigi.gleam", 101).
?DOC(
    " Convert a big integer to raw bytes.\n"
    " \n"
    " The size of the returned bit array is specified by `byte_count`, e.g. 8 will\n"
    " return a bit array containing 8 bytes (64 bits). If the big integer doesn't\n"
    " fit in the specified number of bytes then an error is returned.\n"
).
-spec to_bytes(big_int(), endianness(), signedness(), integer()) -> {ok,
        bitstring()} |
    {error, nil}.
to_bytes(Bigint, Endianness, Signedness, Byte_count) ->
    bigi_ffi:to_bytes(Bigint, Endianness, Signedness, Byte_count).

-file("src/bigi.gleam", 112).
?DOC(
    " Compare two big integers, returning an order that denotes if the first\n"
    " argument is lower, bigger than, or equal to the second.\n"
).
-spec compare(big_int(), big_int()) -> gleam@order:order().
compare(A, B) ->
    bigi_ffi:compare(A, B).

-file("src/bigi.gleam", 117).
?DOC(" Get the absolute value of a big integer.\n").
-spec absolute(big_int()) -> big_int().
absolute(Bigint) ->
    erlang:abs(Bigint).

-file("src/bigi.gleam", 122).
?DOC(" Returns the negative of the value provided.\n").
-spec negate(big_int()) -> big_int().
negate(Bigint) ->
    bigi_ffi:negate(Bigint).

-file("src/bigi.gleam", 127).
?DOC(" Add two big integers together.\n").
-spec add(big_int(), big_int()) -> big_int().
add(A, B) ->
    bigi_ffi:add(A, B).

-file("src/bigi.gleam", 132).
?DOC(" Subtract the subtrahend from the minuend.\n").
-spec subtract(big_int(), big_int()) -> big_int().
subtract(A, B) ->
    bigi_ffi:subtract(A, B).

-file("src/bigi.gleam", 137).
?DOC(" Multiply two big integers together.\n").
-spec multiply(big_int(), big_int()) -> big_int().
multiply(A, B) ->
    bigi_ffi:multiply(A, B).

-file("src/bigi.gleam", 144).
?DOC(
    " Divide the dividend with the divisor using integer division.\n"
    "\n"
    " Follows the standard Gleam divide-by-zero rule of 0 when the divisor is 0.\n"
).
-spec divide(big_int(), big_int()) -> big_int().
divide(A, B) ->
    bigi_ffi:divide(A, B).

-file("src/bigi.gleam", 177).
?DOC(
    " Divide the dividend with the divisor using integer division.\n"
    "\n"
    " Returns an error if the divisor is 0.\n"
).
-spec divide_no_zero(big_int(), big_int()) -> {ok, big_int()} | {error, nil}.
divide_no_zero(A, B) ->
    bigi_ffi:divide_no_zero(A, B).

-file("src/bigi.gleam", 188).
?DOC(
    " Divide the dividend with the divisor using integer division and return the\n"
    " remainder.\n"
    "\n"
    " Follows the standard Gleam divide-by-zero rule of 0 when the divisor is 0.\n"
).
-spec remainder(big_int(), big_int()) -> big_int().
remainder(A, B) ->
    bigi_ffi:remainder(A, B).

-file("src/bigi.gleam", 153).
?DOC(
    " Performs a *floored* integer division, which means that the result will\n"
    " always be rounded towards negative infinity.\n"
    "\n"
    " If you want to perform truncated integer division (rounding towards zero),\n"
    " use `divide` or `divide_no_zero` instead.\n"
    "\n"
    " Returns an error if the divisor is 0.\n"
).
-spec floor_divide(big_int(), big_int()) -> {ok, big_int()} | {error, nil}.
floor_divide(Dividend, Divisor) ->
    Z = bigi_ffi:zero(),
    case Divisor =:= Z of
        true ->
            {error, nil};

        false ->
            case bigi_ffi:compare(bigi_ffi:multiply(Dividend, Divisor), Z) of
                lt ->
                    case bigi_ffi:remainder(Dividend, Divisor) /= Z of
                        true ->
                            {ok,
                                bigi_ffi:subtract(
                                    bigi_ffi:divide(Dividend, Divisor),
                                    bigi_ffi:one()
                                )};

                        false ->
                            {ok, bigi_ffi:divide(Dividend, Divisor)}
                    end;

                _ ->
                    {ok, bigi_ffi:divide(Dividend, Divisor)}
            end
    end.

-file("src/bigi.gleam", 196).
?DOC(
    " Divide the dividend with the divisor using integer division and return the\n"
    " remainder.\n"
    "\n"
    " Returns an error if the divisor is 0.\n"
).
-spec remainder_no_zero(big_int(), big_int()) -> {ok, big_int()} | {error, nil}.
remainder_no_zero(A, B) ->
    bigi_ffi:remainder_no_zero(A, B).

-file("src/bigi.gleam", 206).
?DOC(
    " Calculate a mathematical modulo operation.\n"
    "\n"
    " Follows the standard Gleam divide-by-zero rule of 0 when the divisor is 0.\n"
).
-spec modulo(big_int(), big_int()) -> big_int().
modulo(A, B) ->
    bigi_ffi:modulo(A, B).

-file("src/bigi.gleam", 213).
?DOC(
    " Calculate a mathematical modulo operation.\n"
    "\n"
    " Returns an error if the divisor is 0.\n"
).
-spec modulo_no_zero(big_int(), big_int()) -> {ok, big_int()} | {error, nil}.
modulo_no_zero(A, B) ->
    bigi_ffi:modulo_no_zero(A, B).

-file("src/bigi.gleam", 223).
?DOC(
    " Raise the base to the exponent.\n"
    "\n"
    " If the exponent is negative, an error is returned.\n"
).
-spec power(big_int(), big_int()) -> {ok, big_int()} | {error, nil}.
power(A, B) ->
    bigi_ffi:power(A, B).

-file("src/bigi.gleam", 242).
?DOC(false).
-spec do_decode(gleam@dynamic:dynamic_()) -> {ok, big_int()} |
    {error, big_int()}.
do_decode(Dyn) ->
    bigi_ffi:decode(Dyn).

-file("src/bigi.gleam", 234).
?DOC(
    " Returns a decoder that decodes a Dynamic value into a big integer, if\n"
    " possible.\n"
).
-spec decoder() -> gleam@dynamic@decode:decoder(big_int()).
decoder() ->
    gleam@dynamic@decode:new_primitive_decoder(
        <<"BigInt"/utf8>>,
        fun bigi_ffi:decode/1
    ).

-file("src/bigi.gleam", 251).
?DOC(" Calculates the bitwise AND of its arguments.\n").
-spec bitwise_and(big_int(), big_int()) -> big_int().
bitwise_and(A, B) ->
    bigi_ffi:bitwise_and(A, B).

-file("src/bigi.gleam", 256).
?DOC(" Calculates the bitwise XOR of its arguments.\n").
-spec bitwise_exclusive_or(big_int(), big_int()) -> big_int().
bitwise_exclusive_or(A, B) ->
    bigi_ffi:bitwise_exclusive_or(A, B).

-file("src/bigi.gleam", 261).
?DOC(" Calculates the bitwise NOT of its argument.\n").
-spec bitwise_not(big_int()) -> big_int().
bitwise_not(Bigint) ->
    bigi_ffi:bitwise_not(Bigint).

-file("src/bigi.gleam", 266).
?DOC(" Calculates the bitwise OR of its arguments.\n").
-spec bitwise_or(big_int(), big_int()) -> big_int().
bitwise_or(A, B) ->
    bigi_ffi:bitwise_or(A, B).

-file("src/bigi.gleam", 271).
?DOC(" Calculates the result of an arithmetic left bitshift by the given amount.\n").
-spec bitwise_shift_left(big_int(), integer()) -> big_int().
bitwise_shift_left(Bigint, Amount) ->
    bigi_ffi:bitwise_shift_left(Bigint, Amount).

-file("src/bigi.gleam", 276).
?DOC(" Calculates the result of an arithmetic right bitshift by the given amount.\n").
-spec bitwise_shift_right(big_int(), integer()) -> big_int().
bitwise_shift_right(Bigint, Amount) ->
    bigi_ffi:bitwise_shift_right(Bigint, Amount).

-file("src/bigi.gleam", 286).
?DOC(" Returns whether the big integer provided is odd.\n").
-spec is_odd(big_int()) -> boolean().
is_odd(Bigint) ->
    bigi_ffi:remainder(Bigint, bigi_ffi:from(2)) /= bigi_ffi:zero().

-file("src/bigi.gleam", 291).
?DOC(" Compares two big integers, returning the larger of the two.\n").
-spec max(big_int(), big_int()) -> big_int().
max(A, B) ->
    case bigi_ffi:compare(A, B) of
        lt ->
            B;

        _ ->
            A
    end.

-file("src/bigi.gleam", 299).
?DOC(" Compares two big integers, returning the smaller of the two.\n").
-spec min(big_int(), big_int()) -> big_int().
min(A, B) ->
    case bigi_ffi:compare(A, B) of
        lt ->
            A;

        _ ->
            B
    end.

-file("src/bigi.gleam", 279).
?DOC(" Restricts a big integer between a lower and upper bound.\n").
-spec clamp(big_int(), big_int(), big_int()) -> big_int().
clamp(Bigint, Min_bound, Max_bound) ->
    _pipe = Bigint,
    _pipe@1 = min(_pipe, Max_bound),
    max(_pipe@1, Min_bound).

-file("src/bigi.gleam", 309).
?DOC(
    " Sums a list of big integers.\n"
    "\n"
    " Returns 0 if the list was empty.\n"
).
-spec sum(list(big_int())) -> big_int().
sum(Bigints) ->
    gleam@list:fold(Bigints, bigi_ffi:zero(), fun bigi_ffi:add/2).

-file("src/bigi.gleam", 316).
?DOC(
    " Multiplies a list of big integers.\n"
    "\n"
    " Returns 1 if the list was empty.\n"
).
-spec product(list(big_int())) -> big_int().
product(Bigints) ->
    gleam@list:fold(Bigints, bigi_ffi:one(), fun bigi_ffi:multiply/2).

-file("src/bigi.gleam", 323).
?DOC(
    " Joins a list of digits into a single value. Returns an error if the base is\n"
    " less than 2 or if the list contains a digit greater than or equal to the\n"
    " specified base.\n"
).
-spec undigits(list(integer()), integer()) -> {ok, big_int()} | {error, nil}.
undigits(Digits, Base) ->
    case Base < 2 of
        true ->
            {error, nil};

        false ->
            Base@1 = bigi_ffi:from(Base),
            gleam@list:try_fold(
                Digits,
                bigi_ffi:zero(),
                fun(Acc, Digit) ->
                    Digit@1 = bigi_ffi:from(Digit),
                    case bigi_ffi:compare(Digit@1, Base@1) of
                        gt ->
                            {error, nil};

                        eq ->
                            {error, nil};

                        _ ->
                            {ok,
                                bigi_ffi:add(
                                    bigi_ffi:multiply(Acc, Base@1),
                                    Digit@1
                                )}
                    end
                end
            )
    end.

-file("src/bigi.gleam", 339).
-spec get_digit(big_int(), list(integer()), big_int()) -> list(integer()).
get_digit(Bigint, Digits, Divisor) ->
    case bigi_ffi:compare(Bigint, Divisor) of
        lt ->
            Digit@1 = case bigi_ffi:to(Bigint) of
                {ok, Digit} -> Digit;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"bigi"/utf8>>,
                                function => <<"get_digit"/utf8>>,
                                line => 342,
                                value => _assert_fail,
                                start => 11791,
                                'end' => 11828,
                                pattern_start => 11802,
                                pattern_end => 11811})
            end,
            [Digit@1 | Digits];

        _ ->
            Digit@3 = case begin
                _pipe = bigi_ffi:remainder(Bigint, Divisor),
                bigi_ffi:to(_pipe)
            end of
                {ok, Digit@2} -> Digit@2;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"bigi"/utf8>>,
                                function => <<"get_digit"/utf8>>,
                                line => 346,
                                value => _assert_fail@1,
                                start => 11876,
                                'end' => 11953,
                                pattern_start => 11887,
                                pattern_end => 11896})
            end,
            Digits@1 = [Digit@3 | Digits],
            get_digit(bigi_ffi:divide(Bigint, Divisor), Digits@1, Divisor)
    end.

-file("src/bigi.gleam", 228).
?DOC(
    " Get the digits in a given bigint as a list of integers in base 10.\n"
    "\n"
    " The list is ordered starting from the most significant digit.\n"
).
-spec digits(big_int()) -> list(integer()).
digits(Bigint) ->
    get_digit(Bigint, [], bigi_ffi:ten()).

-file("src/bigi.gleam", 364).
?DOC(
    " Parse a binary string into a big integer.\n"
    "\n"
    " The string may contain an optional dash at the start to denote a negative\n"
    " number, followed by an optional `0b` prefix. Following those, only 0 and 1\n"
    " are allowed. The string is NOT trimmed for whitespace.\n"
    "\n"
    " Note that no conversion is done for the number. This means that it is always\n"
    " treated as unsigned, and will only be negative if it is preceded by a dash.\n"
    " As an example, `\"0b100\"` returns 4, and `\"-0b100\"` returns -4.\n"
).
-spec from_base2(binary()) -> {ok, big_int()} | {error, nil}.
from_base2(Base2) ->
    {Sign, Rest@1} = case Base2 of
        <<"-"/utf8, Rest/binary>> ->
            {bigi_ffi:n_one(), Rest};

        _ ->
            {bigi_ffi:one(), Base2}
    end,
    Maybe_parsed = case Rest@1 of
        <<"0b"/utf8, Rest@2/binary>> ->
            bigi_ffi:from_base2(Rest@2);

        _ ->
            bigi_ffi:from_base2(Rest@1)
    end,
    gleam@result:'try'(
        Maybe_parsed,
        fun(Parsed) -> {ok, bigi_ffi:multiply(Sign, Parsed)} end
    ).

-file("src/bigi.gleam", 384).
?DOC(
    " Parse an octal string into a big integer.\n"
    "\n"
    " The string may contain an optional dash at the start to denote a negative\n"
    " number, followed by an optional `0o` prefix. Following those, only numbers 0\n"
    " through 7 are allowed. The string is NOT trimmed for whitespace.\n"
).
-spec from_base8(binary()) -> {ok, big_int()} | {error, nil}.
from_base8(Base8) ->
    {Sign, Rest@1} = case Base8 of
        <<"-"/utf8, Rest/binary>> ->
            {bigi_ffi:n_one(), Rest};

        _ ->
            {bigi_ffi:one(), Base8}
    end,
    Maybe_parsed = case Rest@1 of
        <<"0o"/utf8, Rest@2/binary>> ->
            bigi_ffi:from_base8(Rest@2);

        _ ->
            bigi_ffi:from_base8(Rest@1)
    end,
    gleam@result:'try'(
        Maybe_parsed,
        fun(Parsed) -> {ok, bigi_ffi:multiply(Sign, Parsed)} end
    ).

-file("src/bigi.gleam", 406).
?DOC(
    " Parse a hexadecimal string into a big integer.\n"
    "\n"
    " The string may contain an optional dash at the start to denote a negative\n"
    " number, followed by an optional `0x` prefix. Following those, only numbers 0\n"
    " through 9 and letters _a_ through _f_ are allowed. The string is NOT trimmed\n"
    " for whitespace. The string may be upper, lower, or mixed case, but the\n"
    " prefix `0x` must always be lower case.\n"
).
-spec from_base16(binary()) -> {ok, big_int()} | {error, nil}.
from_base16(Base16) ->
    {Sign, Rest@1} = case Base16 of
        <<"-"/utf8, Rest/binary>> ->
            {bigi_ffi:n_one(), Rest};

        _ ->
            {bigi_ffi:one(), Base16}
    end,
    Maybe_parsed = case Rest@1 of
        <<"0x"/utf8, Rest@2/binary>> ->
            bigi_ffi:from_base16(Rest@2);

        _ ->
            bigi_ffi:from_base16(Rest@1)
    end,
    gleam@result:'try'(
        Maybe_parsed,
        fun(Parsed) -> {ok, bigi_ffi:multiply(Sign, Parsed)} end
    ).

-file("src/bigi.gleam", 441).
?DOC(
    " Parse a big integer from an arbitrary base.\n"
    "\n"
    " The passed alphabet function must return `Ok(n)` for a given character,\n"
    " where _n_ is the base-10 numerical value of that character. This allows\n"
    " using any kind of alphabet. The alphabet must contain enough characters to\n"
    " cover the entire value range of the chosen base.\n"
    "\n"
    " The base must be positive and larger than 1.\n"
).
-spec from_base(
    binary(),
    integer(),
    fun((binary()) -> {ok, integer()} | {error, nil})
) -> {ok, big_int()} | {error, nil}.
from_base(Input, Base, Alphabet) ->
    gleam@bool:guard(
        Base =< 1,
        {error, nil},
        fun() ->
            Base_b = bigi_ffi:from(Base),
            Res = begin
                _pipe = Input,
                _pipe@1 = gleam@string:to_graphemes(_pipe),
                _pipe@2 = lists:reverse(_pipe@1),
                gleam@list:try_fold(
                    _pipe@2,
                    {bigi_ffi:zero(), bigi_ffi:zero()},
                    fun(Acc, Char) ->
                        {Value, I} = Acc,
                        case Alphabet(Char) of
                            {ok, Int} when Int >= Base ->
                                {error, nil};

                            {ok, Int@1} ->
                                P@1 = case bigi_ffi:power(Base_b, I) of
                                    {ok, P} -> P;
                                    _assert_fail ->
                                        erlang:error(
                                                #{gleam_error => let_assert,
                                                    message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                                    file => <<?FILEPATH/utf8>>,
                                                    module => <<"bigi"/utf8>>,
                                                    function => <<"from_base"/utf8>>,
                                                    line => 460,
                                                    value => _assert_fail,
                                                    start => 15697,
                                                    'end' => 15732,
                                                    pattern_start => 15708,
                                                    pattern_end => 15713}
                                            )
                                end,
                                Value@1 = begin
                                    _pipe@3 = Int@1,
                                    _pipe@4 = bigi_ffi:from(_pipe@3),
                                    _pipe@5 = bigi_ffi:multiply(_pipe@4, P@1),
                                    bigi_ffi:add(_pipe@5, Value)
                                end,
                                {ok, {Value@1, bigi_ffi:add(I, bigi_ffi:one())}};

                            {error, nil} ->
                                {error, nil}
                        end
                    end
                )
            end,
            case Res of
                {ok, {Res@1, _}} ->
                    {ok, Res@1};

                {error, nil} ->
                    {error, nil}
            end
        end
    ).

-file("src/bigi.gleam", 480).
?DOC(
    " Stringify a big integer into a binary string.\n"
    "\n"
    " A dash is added at the front if the number is negative. The number that\n"
    " follows will always be an unsigned binary number.\n"
).
-spec to_base2(big_int()) -> binary().
to_base2(Int) ->
    bigi_ffi:to_base2(Int).

-file("src/bigi.gleam", 487).
?DOC(
    " Stringify a big integer into an octal string.\n"
    "\n"
    " A dash is added at the front if the number is negative.\n"
).
-spec to_base8(big_int()) -> binary().
to_base8(Int) ->
    bigi_ffi:to_base8(Int).

-file("src/bigi.gleam", 494).
?DOC(
    " Stringify a big integer into a hexadecimal string.\n"
    "\n"
    " A dash is added at the front if the number is negative. The resulting string\n"
    " will be lower case.\n"
).
-spec to_base16(big_int()) -> binary().
to_base16(Int) ->
    _pipe = bigi_ffi:to_base16(Int),
    string:lowercase(_pipe).

-file("src/bigi.gleam", 525).
-spec do_to_base(
    binary(),
    big_int(),
    big_int(),
    fun((integer()) -> {ok, binary()} | {error, nil})
) -> {ok, binary()} | {error, nil}.
do_to_base(Acc, Value, Base, Alphabet) ->
    case bigi_ffi:compare(Value, Base) of
        lt ->
            I@1 = case bigi_ffi:to(Value) of
                {ok, I} -> I;
                _assert_fail ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"bigi"/utf8>>,
                                function => <<"do_to_base"/utf8>>,
                                line => 534,
                                value => _assert_fail,
                                start => 17930,
                                'end' => 17962,
                                pattern_start => 17941,
                                pattern_end => 17946})
            end,
            case Alphabet(I@1) of
                {ok, C} ->
                    {ok, <<C/binary, Acc/binary>>};

                {error, nil} ->
                    {error, nil}
            end;

        _ ->
            Rem = bigi_ffi:remainder(Value, Base),
            Mod_i@1 = case bigi_ffi:to(Rem) of
                {ok, Mod_i} -> Mod_i;
                _assert_fail@1 ->
                    erlang:error(#{gleam_error => let_assert,
                                message => <<"Pattern match failed, no pattern matched the value."/utf8>>,
                                file => <<?FILEPATH/utf8>>,
                                module => <<"bigi"/utf8>>,
                                function => <<"do_to_base"/utf8>>,
                                line => 545,
                                value => _assert_fail@1,
                                start => 18217,
                                'end' => 18251,
                                pattern_start => 18228,
                                pattern_end => 18237})
            end,
            case Alphabet(Mod_i@1) of
                {ok, C@1} ->
                    Acc@1 = <<C@1/binary, Acc/binary>>,
                    New_value = bigi_ffi:divide(
                        bigi_ffi:subtract(Value, Rem),
                        Base
                    ),
                    do_to_base(Acc@1, New_value, Base, Alphabet);

                {error, nil} ->
                    {error, nil}
            end
    end.

-file("src/bigi.gleam", 509).
?DOC(
    " Stringify a big integer into a number of arbitrary base.\n"
    "\n"
    " The passed alphabet function must return `Ok(c)` for a given base-10\n"
    " integer, where _c_ is the symbol of that integer in the given base. This\n"
    " allows using any kind of alphabet. The alphabet must contain enough symbols\n"
    " to cover the entire value range of the chosen base.\n"
    "\n"
    " The base must be positive and larger than 1.\n"
).
-spec to_base(
    big_int(),
    integer(),
    fun((integer()) -> {ok, binary()} | {error, nil})
) -> {ok, binary()} | {error, nil}.
to_base(Input, Base, Alphabet) ->
    gleam@bool:guard(
        Base =< 1,
        {error, nil},
        fun() ->
            gleam@result:'try'(
                do_to_base(<<""/utf8>>, Input, bigi_ffi:from(Base), Alphabet),
                fun(Res) ->
                    Sign = case bigi_ffi:compare(Input, bigi_ffi:zero()) of
                        lt ->
                            <<"-"/utf8>>;

                        _ ->
                            <<""/utf8>>
                    end,
                    {ok, <<Sign/binary, Res/binary>>}
                end
            )
        end
    ).
