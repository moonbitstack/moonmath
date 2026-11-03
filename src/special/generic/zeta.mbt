// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Riemann zeta. Above one it is Euler-Maclaurin: a short direct sum, the
// integral the sum leaves out, and the Bernoulli corrections that make the tail
// exact to the width. Below one the series does not converge at all, so the
// functional equation carries the value across from `1 - s`.

///|
/// The Riemann zeta function `ζ(s)`.
///
/// `ζ(s) = Σ n^(-s)` for `s > 1`, by Euler-Maclaurin: the sum to `N`, the
/// integral `N^(1-s)/(s-1)`, the half term, and the Bernoulli corrections. `N`
/// and the number of corrections both grow with the working precision, because
/// the correction series is asymptotic and has to be truncated where its terms
/// stop shrinking.
///
/// Below one the same value is reached through
/// `ζ(s) = 2^s π^(s-1) sin(πs/2) Γ(1 - s) ζ(1 - s)`, which is the analytic
/// continuation; the negative even integers are its trivial zeros.
pub fn[T] zeta(s : T, ops : Ops[T]) -> T {
  let one = ops.one
  // Zero is the one point the continuation cannot reach numerically: the
  // reflection multiplies a vanishing sine by the pole of `ζ(1 - s)`, and the
  // limit is this rational value.
  if (ops.is_zero)(s) {
    return (ops.from_decimal)("-0.5")
  }
  // Below zero the direct sum diverges and the functional equation is the only
  // way in. Between zero and one the sum still converges — slowly, but
  // Euler-Maclaurin is valid for every `s > 0` — so the recurrence through the
  // functional equation, which maps that interval onto itself, is not used there.
  if (ops.lt)(s, ops.zero) {
    return zeta_continued(s, ops)
  }
  let digits = ops.digits
  let terms = if digits < 30 { 30 } else { digits }
  let corrections = if digits < 20 { 14 } else if digits < 60 { 26 } else { 40 }
  let n = (ops.from_int)(terms)
  let mut sum = ops.zero
  let mut index : Int32 = 1
  while index < terms {
    sum = (ops.add)(sum, (ops.pow)((ops.from_int)(index), (ops.neg)(s)))
    index = index + 1
  }
  // The integral and the half term.
  sum = (ops.add)(
    sum,
    (ops.div)((ops.pow)(n, (ops.sub)(one, s)), (ops.sub)(s, one)),
  )
  sum = (ops.add)(
    sum,
    (ops.mul)((ops.from_decimal)("0.5"), (ops.pow)(n, (ops.neg)(s))),
  )
  // `Σ B_2k/(2k)! (s)_(2k-1) N^(-s-2k+1)`.
  let mut rising = s
  let mut power = (ops.pow)(n, (ops.sub)((ops.neg)(s), one))
  let inverse_square = (ops.div)(one, (ops.mul)(n, n))
  let mut factorial = (ops.from_int)(2)
  let mut k : Int32 = 1
  while k <= corrections {
    if k > 1 {
      factorial = (ops.mul)(
        factorial,
        (ops.mul)((ops.from_int)(2 * k - 1), (ops.from_int)(2 * k)),
      )
      rising = (ops.mul)(
        rising,
        (ops.mul)(
          (ops.add)(s, (ops.from_int)(2 * k - 3)),
          (ops.add)(s, (ops.from_int)(2 * k - 2)),
        ),
      )
      power = (ops.mul)(power, inverse_square)
    }
    let coefficient = (ops.div)((ops.bernoulli)(k), factorial)
    sum = (ops.add)(sum, (ops.mul)((ops.mul)(coefficient, rising), power))
    k = k + 1
  }
  sum
}

///|
/// `ζ(s)` below zero, through the functional equation `ζ(s) = 2^s π^(s-1)
/// sin(πs/2) Γ(1 - s) ζ(1 - s)`, whose right-hand side lands above one.
fn[T] zeta_continued(s : T, ops : Ops[T]) -> T {
  // The trivial zeros: `sin(πs/2)` vanishes at every negative even integer, and
  // that factor is what the formula contributes there.
  let value = (ops.to_double)(s)
  let rounded = value.round()
  if (value - rounded).abs() < 1.0e-12 &&
    rounded <= 0.0 &&
    rounded.to_int() % 2 == 0 {
    return ops.zero
  }
  let one = ops.one
  let two = (ops.from_int)(2)
  let pi = ops.pi
  let reflected = (ops.sub)(one, s)
  let first = (ops.pow)(two, s)
  let second = (ops.pow)(pi, (ops.sub)(s, one))
  let third = (ops.sin)((ops.div)((ops.mul)(pi, s), two))
  let fourth = gamma(reflected, ops)
  (ops.mul)(
    (ops.mul)((ops.mul)(first, second), (ops.mul)(third, fourth)),
    zeta(reflected, ops),
  )
}
