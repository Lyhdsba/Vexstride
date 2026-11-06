///|
/// Park-Miller multiplicative generator, multiplier 48271, modulus 2^31-1.
pub struct Generator {
  mut state : Int64
}

///|
/// Callers validate seeds in 1..2147483646.
pub fn Generator::new(seed : Int32) -> Generator {
  { state: seed.to_int64(), }
}

///|
/// Rejection sampling avoids modulo bias. Bound must be in 1..2147483646.
pub fn Generator::bounded(self : Generator, bound : Int32) -> Int32 {
  let width = bound.to_int64()
  let limit = 2147483646L / width * width
  for ;; {
    self.state = self.state * 48271L % 2147483647L
    let value = self.state - 1L
    if value < limit {
      return (value % width).to_int()
    }
  }
}
