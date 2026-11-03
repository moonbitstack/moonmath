// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The bodies, written once over `Ops`. `erf` is the worked example: its series
// needs only the four operations and a constant, so the same code that answers at
// double precision answers at fifty digits when handed the `BigFloat` algebra.
// The remaining functions of the double package follow the same shape.

///|
/// The error function, over any `Ops` number type.
///
/// The alternating power series `(2/sqrt(pi)) Σ (-1)^n x^(2n+1) / (n! (2n+1))`,
/// which is exact and quick for the moderate arguments a test or an editor
/// reaches for; for large `|x|` the cancellation of the alternating terms costs
/// digits, so the double package's own `erf` switches to a continued fraction
/// there.
pub fn[T] erf(x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let scale = (ops.div)(two, (ops.sqrt)(ops.pi))
  let squared = (ops.mul)(x, x)
  let mut term = x
  let mut sum = x
  let mut n : Int32 = 0
  while n < 800 {
    n = n + 1
    term = (ops.div)((ops.mul)(term, squared), (ops.from_int)(n))
    let add = (ops.div)(term, (ops.from_int)(2 * n + 1))
    if n % 2 == 1 {
      sum = (ops.sub)(sum, add)
    } else {
      sum = (ops.add)(sum, add)
    }
    if (ops.is_zero)(add) {
      break
    }
  }
  (ops.mul)(scale, sum)
}
