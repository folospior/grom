-module(bigi_ffi).

-export([
    from/1,
    from_string/1,
    from_bytes/3,
    to/1,
    to_bytes/4,
    zero/0,
    one/0,
    n_one/0,
    ten/0,
    compare/2,
    negate/1,
    add/2,
    subtract/2,
    multiply/2,
    divide/2,
    divide_no_zero/2,
    remainder/2,
    remainder_no_zero/2,
    modulo/2,
    modulo_no_zero/2,
    power/2,
    decode/1,
    bitwise_and/2,
    bitwise_exclusive_or/2,
    bitwise_not/1,
    bitwise_or/2,
    bitwise_shift_left/2,
    bitwise_shift_right/2,
    from_base2/1,
    from_base8/1,
    from_base16/1,
    to_base2/1,
    to_base8/1,
    to_base16/1
]).

from(Int) -> Int.

from_string(Str) ->
    case string:to_integer(Str) of
        {_, Rest} when Rest /= <<"">> -> {error, nil};
        {Int, _} -> {ok, Int}
    end.

from_bytes(Bytes, Endianness, Signedness) ->
    BitSize = erlang:bit_size(Bytes),

    case BitSize rem 8 of
        0 ->
            case Endianness of
                little_endian ->
                    case Signedness of
                        signed ->
                            <<Int:BitSize/little-signed-integer>> = Bytes,
                            {ok, Int};
                        unsigned ->
                            <<Int:BitSize/little-unsigned-integer>> = Bytes,
                            {ok, Int}
                    end;
                big_endian ->
                    case Signedness of
                        signed ->
                            <<Int:BitSize/big-signed-integer>> = Bytes,
                            {ok, Int};
                        unsigned ->
                            <<Int:BitSize/big-unsigned-integer>> = Bytes,
                            {ok, Int}
                    end
            end;
        _ ->
            {error, nil}
    end.

to(BigInt) -> {ok, BigInt}.

to_bytes(BigInt, Endianness, Signedness, ByteCount) ->
    case ByteCount * 8 of
        BitCount when BitCount >= 8 ->
            RangeMin =
                case Signedness of
                    signed -> -(1 bsl (BitCount - 1));
                    unsigned -> 0
                end,

            RangeMax =
                case Signedness of
                    signed -> (1 bsl (BitCount - 1)) - 1;
                    unsigned -> (1 bsl BitCount) - 1
                end,

            % Error if the value is out of range for the available bits
            case BigInt >= RangeMin andalso BigInt =< RangeMax of
                true ->
                    case Endianness of
                        little_endian -> {ok, <<BigInt:BitCount/little-integer>>};
                        big_endian -> {ok, <<BigInt:BitCount/big-integer>>}
                    end;
                false ->
                    {error, nil}
            end;
        _ ->
            {error, nil}
    end.

zero() -> 0.
one() -> 1.
n_one() -> -1.
ten() -> 10.

compare(A, B) when A < B -> lt;
compare(A, B) when A > B -> gt;
compare(_, _) -> eq.

negate(A) -> -A.

add(A, B) -> A + B.

subtract(A, B) -> A - B.

multiply(A, B) -> A * B.

divide(_, 0) -> 0;
divide(A, B) -> A div B.

divide_no_zero(_, 0) -> {error, nil};
divide_no_zero(A, B) -> {ok, divide(A, B)}.

remainder(_, 0) -> 0;
remainder(A, B) -> A rem B.

remainder_no_zero(_, 0) -> {error, nil};
remainder_no_zero(A, B) -> {ok, remainder(A, B)}.

modulo(_, 0) -> 0;
modulo(A, B) -> ((A rem B) + B) rem B.

modulo_no_zero(_, 0) -> {error, nil};
modulo_no_zero(A, B) -> {ok, modulo(A, B)}.

power(_, Exp) when Exp < 0 -> {error, nil};
power(Base, Exp) -> {ok, do_power(Base, Exp)}.

do_power(_, 0) ->
    1;
do_power(A, 1) ->
    A;
do_power(A, N) ->
    B = do_power(A, N div 2),
    B * B *
        (case N rem 2 of
            0 -> 1;
            1 -> A
        end).

decode(Dyn) when is_integer(Dyn) -> {ok, Dyn};
decode(_Dyn) -> {error, 0}.

bitwise_and(A, B) -> A band B.

bitwise_exclusive_or(A, B) -> A bxor B.

bitwise_not(A) -> bnot A.

bitwise_or(A, B) -> A bor B.

bitwise_shift_left(A, B) -> A bsl B.

bitwise_shift_right(A, B) -> A bsr B.

from_base2(Str) ->
    try
        Res = binary_to_integer(Str, 2),
        {ok, Res}
    catch
        error:badarg -> {error, nil}
    end.

from_base8(Str) ->
    try
        Res = binary_to_integer(Str, 8),
        {ok, Res}
    catch
        error:badarg -> {error, nil}
    end.

from_base16(Str) ->
    try
        Res = binary_to_integer(Str, 16),
        {ok, Res}
    catch
        error:badarg -> {error, nil}
    end.

to_base2(Int) -> integer_to_binary(Int, 2).

to_base8(Int) -> integer_to_binary(Int, 8).

to_base16(Int) -> integer_to_binary(Int, 16).
