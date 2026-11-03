// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Riemann zeta, on the half-plane where its series converges, by the
// Euler-Maclaurin formula. A short direct sum plus the integral and a handful of
// Bernoulli corrections reaches double precision, and the correction terms are
// the Bernoulli numbers over the matching factorials, kept here so the formula
// reads as the one in the references.

///|
/// The even Bernoulli numbers `B_2, B_4, ...`, up to `B_16`.
let bernoulli : Array[Double] = [
  1.0 / 6.0,
  -1.0 / 30.0,
  1.0 / 42.0,
  -1.0 / 30.0,
  5.0 / 66.0,
  -691.0 / 2730.0,
  7.0 / 6.0,
  -3617.0 / 510.0,
]

///|
/// The factorials `2!, 4!, ...`, to match the Bernoulli numbers above.
let even_factorial : Array[Double] = [
  2.0, 24.0, 720.0, 40320.0, 3628800.0, 479001600.0, 87178291200.0, 20922789888000.0,
]

///|
/// The Riemann zeta function `ζ(s)`, for `s > 1`.
///
/// `ζ(s) = Σ n^(-s)`, the sum a caller meets in the normalisation of a
/// distribution or the tail of a probability. Computed by Euler-Maclaurin: thirty
/// terms of the sum, the integral they leave out, and eight Bernoulli
/// corrections, which is enough for a double across `s > 1`. The pole at `s = 1`
/// comes back as an infinity; the analytic continuation below one is not
/// implemented here, and `s <= 0` gives a NaN.
pub fn zeta(s : Double) -> Double {
  if s == 1.0 {
    // The simple pole: the function runs off to positive infinity.
    return 1.0 / 0.0
  }
  if s <= 0.0 {
    return 0.0 / 0.0
  }
  let terms : Double = 30.0
  let mut sum = 0.0
  let mut n : Double = 1.0
  while n < terms {
    sum = sum + @math.pow(n, -s)
    n = n + 1.0
  }
  sum = sum + @math.pow(terms, 1.0 - s) / (s - 1.0) + 0.5 * @math.pow(terms, -s)
  // The Bernoulli corrections; `rising` is (s)_{2i+1}, the rising factorial the
  // formula multiplies each number by.
  let mut rising = s
  let mut offset : Double = 0.0
  for i in 0..<8 {
    let coefficient = bernoulli[i] / even_factorial[i]
    let power = @math.pow(terms, -s - offset - 1.0)
    sum = sum + coefficient * rising * power
    rising = rising * (s + offset + 1.0) * (s + offset + 2.0)
    offset = offset + 2.0
  }
  sum
}
