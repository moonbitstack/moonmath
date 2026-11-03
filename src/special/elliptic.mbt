// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The complete elliptic integrals, by the arithmetic-geometric mean. The mean
// doubles the correct digits every step, so a few iterations reach the limit of
// a double for the whole parameter range, and the second integral comes out of
// the same recurrence at no extra cost.

///|
/// The complete elliptic integral of the first kind, `K(m)`.
///
/// `K(m) = ∫_0^(π/2) (1 - m sin²θ)^(-1/2) dθ`, with `m` the parameter (the
/// squared modulus). It is `π/2` at `m = 0`, rises to meet `π/2 / sqrt(1 - m)`
/// near `m = 1`, and is undefined from there on. Real for `m < 1`.
pub fn ellipk(m : Double) -> Double {
  let (k, _) = agm_pair(m)
  k
}

///|
/// The complete elliptic integral of the second kind, `E(m)`.
///
/// `E(m) = ∫_0^(π/2) (1 - m sin²θ)^(1/2) dθ`. It starts at `π/2` and falls to
/// one at `m = 1`, and is the length of a quarter of an ellipse whose
/// eccentricity the parameter names. Real for `m < 1`.
pub fn ellipe(m : Double) -> Double {
  let (_, e) = agm_pair(m)
  e
}

///|
/// `K(m)` and `E(m)` together from one run of the arithmetic-geometric mean.
fn agm_pair(m : Double) -> (Double, Double) {
  let mut a = 1.0
  let mut b = (1.0 - m).sqrt()
  let mut weight = 1.0
  // The sum starts at `c_0 = sqrt(m)`, weighted by 2^(0-1) = 1/2.
  let mut sum = 0.5 * m
  let mut i = 0
  // The mean doubles the correct digits every step, so twenty is far past the
  // limit of a double. The break matters: past convergence `c` sits at the noise
  // floor, and the doubling weight would turn those last terms into error.
  while i < 20 {
    let c = (a - b) * 0.5
    sum = sum + weight * c * c
    weight = weight * 2.0
    let next = (a + b) * 0.5
    b = (a * b).sqrt()
    a = next
    if c == 0.0 || c.abs() <= a * 1.0e-16 {
      break
    }
    i = i + 1
  }
  let k = pi_value / (2.0 * a)
  (k, k * (1.0 - sum))
}
