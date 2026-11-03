// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The gamma family. The Lanczos approximation with the reflection formula is
// the standard way to reach double precision over the whole real line without a
// table: nine coefficients at `g = 7` give about fifteen digits, which is all a
// double holds.

///|
/// Pi, to more digits than a double keeps.
let pi_value : Double = 3.14159265358979323846

///|
/// The Lanczos coefficients for `g = 7`, `n = 9`.
let lanczos : Array[Double] = [
  0.99999999999980993, 676.5203681218851, -1259.1392167224028, 771.32342877765313,
  -176.61502916214059, 12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6,
  1.5056327351493116e-7,
]

///|
/// The gamma function `Γ(x)`, the continuous extension of the factorial.
///
/// `Γ(n) = (n - 1)!` for a positive integer, and the function is the integral
/// `∫ t^(x-1) e^(-t) dt` for `x > 0`. Below one half it is computed through the
/// reflection `Γ(x) Γ(1 - x) = π / sin(π x)`, so the whole real line is covered
/// by one Lanczos evaluation. A pole at a non-positive integer comes back as an
/// infinity, as it should.
pub fn gamma(x : Double) -> Double {
  if x < 0.5 {
    pi_value / (@math.sin(pi_value * x) * gamma(1.0 - x))
  } else {
    let z = x - 1.0
    let mut sum = lanczos[0]
    let mut offset : Double = 1.0
    for i in 1..<9 {
      sum = sum + lanczos[i] / (z + offset)
      offset = offset + 1.0
    }
    let t = z + 7.5
    let two_pi = 2.0 * pi_value
    two_pi.sqrt() * @math.pow(t, z + 0.5) * @math.exp(-t) * sum
  }
}

///|
/// The natural logarithm of the absolute value of the gamma function.
///
/// The log form is what a caller wants when `Γ(x)` itself would overflow a
/// double: `lgamma(1000)` is about `5905`, while `gamma(1000)` is past the
/// largest finite double. The same reflection as `gamma` covers `x < 1/2`.
pub fn lgamma(x : Double) -> Double {
  if x < 0.5 {
    @math.ln(pi_value) -
    @math.ln(@math.sin(pi_value * x).abs()) -
    lgamma(1.0 - x)
  } else {
    let z = x - 1.0
    let mut sum = lanczos[0]
    let mut offset : Double = 1.0
    for i in 1..<9 {
      sum = sum + lanczos[i] / (z + offset)
      offset = offset + 1.0
    }
    let t = z + 7.5
    let two_pi = 2.0 * pi_value
    0.5 * @math.ln(two_pi) + (z + 0.5) * @math.ln(t) - t + @math.ln(sum)
  }
}

///|
/// The Euler beta function `B(a, b)`, from the gamma function.
///
/// `B(a, b) = Γ(a) Γ(b) / Γ(a + b)`, defined for positive `a` and `b`. It is the
/// normalising constant of the beta distribution and the value of the integral
/// `∫ t^(a-1) (1-t)^(b-1) dt` over `0..1`.
pub fn beta(a : Double, b : Double) -> Double {
  @math.exp(lbeta(a, b))
}

///|
/// The natural logarithm of the beta function.
///
/// The log form stays finite where `beta` itself would overflow or underflow.
pub fn lbeta(a : Double, b : Double) -> Double {
  lgamma(a) + lgamma(b) - lgamma(a + b)
}
