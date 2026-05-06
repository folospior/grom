# bigi

[![Package Version](https://img.shields.io/hexpm/v/bigi)](https://hex.pm/packages/bigi)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/bigi/)

Arbitrary precision integer arithmetic for Gleam.

In the Erlang target, all integers are automatically "big integers" that are subject to
arbitrary precision arithmetic. This means there is no need for this package if you are only
targeting Erlang.

In JavaScript, Gleam's `Int` type corresponds to the `number` type, which is implemented using
floating-point arithmetic. That means it's subject to the following limits:

- [Maximum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
  and
  [minimum safe integer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER)
  beyond which the accuracy of arithmetic suffers, and
- [maximum value](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_VALUE)
  and
  [minimum value](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_VALUE)
  beyond which the numbers are converted to `Infinity` or `-Infinity`.

This package thus provides big integers for the JavaScript target and additionally provides a
consistent interface for packages that target both Erlang and JavaScript. In Erlang, regular
integers are used. In JavaScript, the
[`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt)
type is used.

```sh
gleam add bigi
```

```gleam
import bigi

pub fn main() {
  bigi.power(
    bigi.from_int(2),
    bigi.from_int(65_535)
  )

  // Ok(1001764965203423232489536175780127875223912737784875709632508486855447029778...)
}
```

Further documentation can be found at <https://hexdocs.pm/bigi>.

## Limitations

Erlang does have [a limit for big integers at around 4 megabits](https://elixirforum.com/t/is-there-an-integer-size-limit/65647/8?u=nicd),
as demonstrated below:

```gleam
import bigi

pub fn main() {
  // Works
  bigi.power(bigi.from_int(2), bigi.from_int(4_194_239))

  // Blows up
  bigi.power(bigi.from_int(2), bigi.from_int(4_194_240))
}
```

For Node.js, the limit is somewhere higher.

`bigi` has no facilities to warn about or handle errors due to these system limits. It is up to the developer
to be mindful of them.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
