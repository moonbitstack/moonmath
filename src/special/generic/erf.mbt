// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The error function and the tail that a probability wants instead. The two are
// one function seen from both ends: the power series is exact but cancels in the
// tail, so past one the tail is taken from its continued fraction and the series
// is left to the middle of the range.

///|
/// The error function `erf(x) = (2/sqrt π) ∫_0^x e^(-t²) dt`.
///
/// Below one the power series converges without cancellation. Past it the tail
/// is the better-behaved quantity, so `erf(x) = 1 - erfc(x)` is used and the
/// digits come from the continued fraction rather than from subtracting two
/// numbers that are both nearly one.
pub fn[T] erf(x : T, ops : Ops[T]) -> T {
  let one = ops.one
  let negative = (ops.lt)(x, ops.zero)
  let magnitude = (ops.abs)(x)
  let value = if (ops.lt)(magnitude, erfc_crossover(ops)) {
    erf_series(magnitude, ops)
  } else {
    (ops.sub)(one, erfc_tail(magnitude, ops))
  }
  if negative {
    (ops.neg)(value)
  } else {
    value
  }
}

///|
/// The complementary error function `erfc(x) = 1 - erf(x)`.
pub fn[T] erfc(x : T, ops : Ops[T]) -> T {
  let one = ops.one
  if (ops.lt)(x, ops.zero) {
    let two = (ops.from_int)(2)
    return (ops.sub)(two, erfc((ops.neg)(x), ops))
  }
  if (ops.lt)(x, erfc_crossover(ops)) {
    (ops.sub)(one, erf_series(x, ops))
  } else {
    erfc_tail(x, ops)
  }
}

///|
/// The scaled complementary error function `erfcx(x) = e^(x²) erfc(x)`.
///
/// The exponential is what makes the tail representable: `erfc(30)` is around
/// `1e-392`, past what a double holds, while `erfcx(30)` is a perfectly ordinary
/// `0.0188`.
pub fn[T] erfcx(x : T, ops : Ops[T]) -> T {
  let one = ops.one
  if (ops.lt)(x, ops.zero) {
    // `erfcx(-x) = 2 e^(x²) - erfcx(x)`; the exponential dominates there.
    let squared = (ops.mul)(x, x)
    let two = (ops.from_int)(2)
    return (ops.sub)(
      (ops.mul)(two, (ops.exp)(squared)),
      erfcx((ops.neg)(x), ops),
    )
  }
  if (ops.lt)(x, erfc_crossover(ops)) {
    (ops.mul)((ops.exp)((ops.mul)(x, x)), (ops.sub)(one, erf_series(x, ops)))
  } else {
    erfc_tail_scaled(x, ops)
  }
}

///|
/// The imaginary error function `erfi(x) = -i erf(i x) = (2/sqrt π) ∫_0^x e^(t²) dt`.
///
/// Every term of its series is positive, so it needs no range split; it is the
/// exponential that eventually runs past what the width holds.
pub fn[T] erfi(x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let scale = (ops.div)(two, (ops.sqrt)(ops.pi))
  let squared = (ops.mul)(x, x)
  let mut term = x
  let mut sum = x
  let mut n : Int32 = 0
  while n < 2000 {
    n = n + 1
    term = (ops.div)((ops.mul)(term, squared), (ops.from_int)(n))
    let add = (ops.div)(term, (ops.from_int)(2 * n + 1))
    sum = (ops.add)(sum, add)
    if (ops.lt)((ops.abs)(add), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  (ops.mul)(scale, sum)
}

///|
/// The inverse of `erf`: the `y` with `erf(y) = x`, for `x` in `-1 .. 1`.
///
/// There is no closed form, so the value is bracketed and then polished by
/// Newton's method. The bracket doubles until it contains the answer, which
/// costs nothing and keeps the method honest near the ends of the range, where
/// the inverse runs off to infinity.
pub fn[T] erfinv(x : T, ops : Ops[T]) -> T {
  let one = ops.one
  // The bracket and the Newton steps both land near zero there, and near zero
  // is not the same answer: `erf` is odd, and so is its inverse.
  if (ops.is_zero)(x) {
    return ops.zero
  }
  let magnitude = (ops.abs)(x)
  if (ops.le)(one, magnitude) {
    abort("erfinv: the argument must lie in -1 .. 1")
  }
  let mut low = (ops.neg)(one)
  let mut high = one
  // The inverse grows without bound as the argument reaches one, so the bracket
  // is widened until `erf` clears it.
  while (ops.lt)(erf(high, ops), x) {
    high = (ops.mul)(high, (ops.from_int)(2))
  }
  while (ops.lt)(x, erf(low, ops)) {
    low = (ops.mul)(low, (ops.from_int)(2))
  }
  // Eight halvings take the bracket from width two to a few thousandths, and
  // Newton squares that the rest of the way; more halvings would only re-derive
  // the same digits at the price of the tail evaluation each one costs.
  let mut steps : Int32 = 0
  while steps < 8 {
    let middle = (ops.div)((ops.add)(low, high), (ops.from_int)(2))
    if (ops.lt)(erf(middle, ops), x) {
      low = middle
    } else {
      high = middle
    }
    steps = steps + 1
  }
  let y = (ops.div)((ops.add)(low, high), (ops.from_int)(2))
  newton_erf(y, x, false, ops)
}

///|
/// The inverse of `erfc`: the `y` with `erfc(y) = x`, for `x` in `0 .. 2`.
pub fn[T] erfcinv(x : T, ops : Ops[T]) -> T {
  let zero = ops.zero
  let two = (ops.from_int)(2)
  if (ops.le)(two, x) || (ops.le)(x, zero) {
    abort("erfcinv: the argument must lie in 0 .. 2")
  }
  let mut low = (ops.neg)(two)
  let mut high = (ops.from_int)(8)
  while (ops.lt)(x, erfc(high, ops)) {
    high = (ops.mul)(high, (ops.from_int)(2))
  }
  // Eight halvings take the bracket from width two to a few thousandths, and
  // Newton squares that the rest of the way; more halvings would only re-derive
  // the same digits at the price of the tail evaluation each one costs.
  let mut steps : Int32 = 0
  while steps < 8 {
    let middle = (ops.div)((ops.add)(low, high), (ops.from_int)(2))
    // `erfc` falls, so the root is to the right when the value is still above
    // the target.
    if (ops.lt)(x, erfc(middle, ops)) {
      low = middle
    } else {
      high = middle
    }
    steps = steps + 1
  }
  let y = (ops.div)((ops.add)(low, high), (ops.from_int)(2))
  newton_erf(y, x, true, ops)
}

///|
/// A few Newton steps on `erf(y) - target` (or `erfc(y) - target`), each of which
/// roughly doubles the digits the bracket left.
fn[T] newton_erf(y0 : T, target : T, complementary : Bool, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let scale = (ops.div)(two, (ops.sqrt)(ops.pi))
  let mut y = y0
  let mut i : Int32 = 0
  while i < 12 {
    let value = if complementary { erfc(y, ops) } else { erf(y, ops) }
    let residual = (ops.sub)(value, target)
    if (ops.is_zero)(residual) {
      break
    }
    let magnitude = (ops.mul)(scale, (ops.exp)((ops.neg)((ops.mul)(y, y))))
    // `erfc` falls where `erf` rises, so the derivative changes sign with the
    // function being inverted.
    let slope = if complementary { (ops.neg)(magnitude) } else { magnitude }
    let step = (ops.div)(residual, slope)
    y = (ops.sub)(y, step)
    if (ops.lt)((ops.abs)(step), (ops.mul)((ops.abs)(y), tiny(ops))) {
      break
    }
    i = i + 1
  }
  y
}

///|
/// Where `erfc` stops taking the tail from the continued fraction and starts
/// taking it from `1 - erf`.
///
/// The fraction converges like `x^-n`, so at small `x` it needs more terms than a
/// wide computation can afford; the series costs instead the digits the answer is
/// smaller than one, which at `x = 3` is five and at `x = 1` is one. A double
/// needs a handful of terms either way and takes the fraction from one; a wide
/// width takes the series out to three, where both are still comfortable.
fn[T] erfc_crossover(ops : Ops[T]) -> T {
  if ops.digits > 30 {
    (ops.from_int)(3)
  } else {
    ops.one
  }
}

///|
/// `erf` from its power series, valid for `|x|` up to about one.
fn[T] erf_series(x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let scale = (ops.div)(two, (ops.sqrt)(ops.pi))
  let squared = (ops.mul)(x, x)
  let mut term = x
  let mut sum = x
  let mut n : Int32 = 0
  while n < 2000 {
    n = n + 1
    term = (ops.div)((ops.mul)(term, squared), (ops.from_int)(n))
    let add = (ops.div)(term, (ops.from_int)(2 * n + 1))
    sum = if n % 2 == 1 { (ops.sub)(sum, add) } else { (ops.add)(sum, add) }
    if (ops.lt)((ops.abs)(add), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  (ops.mul)(scale, sum)
}

///|
/// `erfc(x)` for `x >= 1`, from the continued fraction
/// `e^(-x²)/sqrt π · 1/(x + 1/2 / (x + 1 / (x + 3/2 / (x + ...))))`,
/// evaluated by the modified Lentz algorithm.
fn[T] erfc_tail(x : T, ops : Ops[T]) -> T {
  let leading = (ops.div)(
    (ops.exp)((ops.neg)((ops.mul)(x, x))),
    (ops.sqrt)(ops.pi),
  )
  (ops.mul)(leading, erfc_fraction(x, ops))
}

///|
/// The same tail without the `e^(-x²)` factor, for `erfcx`.
fn[T] erfc_tail_scaled(x : T, ops : Ops[T]) -> T {
  (ops.div)(erfc_fraction(x, ops), (ops.sqrt)(ops.pi))
}

///|
/// The continued fraction `1/(x + 1/2 / (x + 1 / (x + 3/2 / (x + ...))))`.
fn[T] erfc_fraction(x : T, ops : Ops[T]) -> T {
  let one = ops.one
  let two = (ops.from_int)(2)
  let floor_value = lentz_floor(ops)
  let mut f = x
  let mut c = f
  let mut d = ops.zero
  let mut n : Int32 = 0
  while n < 2000 {
    n = n + 1
    let a = (ops.div)((ops.from_int)(n), two)
    d = (ops.add)(x, (ops.mul)(a, d))
    if (ops.lt)((ops.abs)(d), floor_value) {
      d = floor_value
    }
    d = (ops.div)(one, d)
    c = (ops.add)(x, (ops.div)(a, c))
    if (ops.lt)((ops.abs)(c), floor_value) {
      c = floor_value
    }
    let delta = (ops.mul)(c, d)
    f = (ops.mul)(f, delta)
    if (ops.lt)((ops.abs)((ops.sub)(delta, one)), tiny(ops)) {
      break
    }
  }
  (ops.div)(one, f)
}
