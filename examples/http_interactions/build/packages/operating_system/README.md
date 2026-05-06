# operating_system

[![Package Version](https://img.shields.io/hexpm/v/operating_system)](https://hex.pm/packages/operating_system)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/operating_system/)

Note: In a while, this package might look abandoned. I can assure you - if Gleam v2 did not drop - it works.

```sh
gleam add operating_system@1
```

```gleam
import operating_system

pub type OS {
  Windows
  Linux
  MacOs
}

pub fn main() -> Nil {
  let os_name = operating_system.name()
  let os = case os_name {
    "windows_nt" -> Windows
    "linux" -> Linux
    "darwin" -> MacOs
    _ -> Linux
  }
}
```

Further documentation can be found at <https://hexdocs.pm/operating_system>.
