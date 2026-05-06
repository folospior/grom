//// This package exposes a function - `name`, which returns the name of the
//// current operating system, as reported by `uname`.

/// Returns the operating system name, as returned by `uname -s`, in lowercase.
@external(erlang, "operating_system_ffi", "name")
@external(javascript, "./operating_system_ffi.mjs", "name")
pub fn name() -> String
