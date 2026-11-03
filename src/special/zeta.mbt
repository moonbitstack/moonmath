// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Riemann zeta at double precision, from the body in `special/generic`.

///|
/// The Riemann zeta function `ζ(s)`.
///
/// `ζ(s) = Σ n^(-s)` for `s > 1`, by Euler-Maclaurin. Below one the analytic
/// continuation fills in through the functional equation, so a negative argument
/// answers as well; the trivial zeros at the negative even integers come back as
/// exactly zero. The simple pole at `s = 1` is a positive infinity.
pub fn zeta(s : Double) -> Double {
  if s == 1.0 {
    return 1.0 / 0.0
  }
  @generic.zeta(s, @generic.double_algebra)
}
