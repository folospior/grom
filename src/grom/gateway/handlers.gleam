import grom

pub type Handlers(a) {
  Handlers(error_handler: fn(grom.Error) -> a)
}

pub fn new() {
  Handlers(error_handler: fn(_error) { Nil })
}
