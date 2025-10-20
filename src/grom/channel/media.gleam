import gleam/int

// TYPES -----------------------------------------------------------------------

pub type Flag {
  RequiresTag
  HideMediaDownloadOptions
}

// FLAGS -----------------------------------------------------------------------

@internal
pub fn bits_flags() -> List(#(Int, Flag)) {
  [
    #(int.bitwise_shift_left(1, 4), RequiresTag),
    #(int.bitwise_shift_left(1, 15), HideMediaDownloadOptions),
  ]
}
