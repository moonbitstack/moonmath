// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The error function and its complement. Below one the power series is exact and
// converges fast; from one up the series loses digits to cancellation, so the
// complement comes from the Laplace continued fraction, whose convergence the
// modified Lentz recurrence handles without the caller guessing a term count.

///|
/// The square root of pi, to more digits than a double keeps.
let sqrt_pi : Double = 1.7724538509055160273

///|
/// `2 / sqrt(pi)`, the constant in front of the error series.
let two_over_sqrt_pi : Double = 1.1283791670955125739

///|
/// The error function `erf(x)`: the integral of the normal density from zero to
/// `x`, scaled so that it tends to one.
///
/// `erf(x) = 2/sqrt(pi) ∫_0^x e^(-t²) dt`. It is odd, reaches `±1` at infinity,
/// and is the cumulative distribution of a normal with mean zero and variance
/// one half.
pub fn erf(x : Double) -> Double {
  if x == 0.0 {
    return x
  }
  let sign : Double = if x < 0.0 { -1.0 } else { 1.0 }
  let magnitude = x.abs()
  if magnitude < 1.0 {
    sign * erf_series(magnitude)
  } else {
    sign * (1.0 - erfc_fraction(magnitude))
  }
}

///|
/// The complementary error function `erfc(x) = 1 - erf(x)`.
///
/// Computed from its own continued fraction above one, so the small values a
/// tail probability needs keep their digits instead of being the difference of
/// two numbers near one.
pub fn erfc(x : Double) -> Double {
  if x < 0.0 {
    2.0 - erfc(-x)
  } else if x < 1.0 {
    1.0 - erf_series(x)
  } else {
    erfc_fraction(x)
  }
}

///|
/// `erf` of a non-negative value below one, from the alternating power series.
fn erf_series(x : Double) -> Double {
  let squared = x * x
  let mut term = x
  let mut sum = x
  let mut n : Double = 0.0
  while true {
    n = n + 1.0
    term = term * squared / n
    let add = term / (2.0 * n + 1.0)
    if n % 2.0 == 1.0 {
      sum = sum - add
    } else {
      sum = sum + add
    }
    if add < 1.0e-18 {
      break
    }
  }
  two_over_sqrt_pi * sum
}

///|
/// `erfc` of a value at least one, from the Laplace continued fraction.
fn erfc_fraction(x : Double) -> Double {
  let tiny = 1.0e-300
  let mut f = x
  let mut c = x
  let mut d = 0.0
  let mut n : Double = 0.0
  while true {
    n = n + 1.0
    let a = n * 0.5
    d = x + a * d
    if d.abs() < tiny {
      d = tiny
    }
    c = x + a / c
    if c.abs() < tiny {
      c = tiny
    }
    d = 1.0 / d
    let delta = c * d
    f = f * delta
    if (delta - 1.0).abs() < 1.0e-17 {
      break
    }
    if n > 400.0 {
      break
    }
  }
  @math.exp(-x * x) / sqrt_pi / f
}
