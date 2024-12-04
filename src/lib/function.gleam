/// Negate a predicate.
pub fn not(f: fn(a) -> Bool) {
  fn(x) { !f(x) }
}

/// Return a predicate that returns true if an input value equals the given value.
pub fn equals(val: a) -> fn(a) -> Bool {
  fn(x) { x == val }
}
