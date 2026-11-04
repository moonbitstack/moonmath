// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions at double precision, from the bodies in
// `special/generic`.
//
// These three are the ones in the package with a stated domain rather than a
// range: each is summed from its own series, and a series with parameters well
// past the argument cancels the answer away before it arrives. Measured against
// Boost.Math's tables, which live entirely in that hard region, `1F1` and `2F1`
// reach `1e-12` for parameters up to about ten and lose five digits by the time
// the parameters are twenty. The transformations that would carry them further —
// Miller's backward recurrence, the fifteen quadratic ones — are their own
// piece of work, and the doc comments say where the boundary is instead of
// letting a caller discover it from a wrong answer.

///|
/// The confluent limit `0F1(; b; x) = Σ x^k / ((b)_k k!)`.
pub fn hyper0f1(b : Double, x : Double) -> Double {
  @generic.hyper0f1(b, x, @generic.double_algebra)
}

///|
/// Kummer's confluent hypergeometric `1F1(a; b; x) = Σ (a)_k / ((b)_k k!) x^k`.
///
/// The series is summed directly, which is accurate while `a`, `b` and `x` stay
/// within a few units of each other and loses digits as they part: at
/// `max(|a|, |b|, |x|) = 20` the terms grow past the answer by four orders
/// before they come back, and five of the fifteen digits go with them. The
/// negative-`x` transformation `e^x 1F1(b - a; b; -x)` is used past `x = -4`,
/// where the plain sum would cancel harder still.
pub fn hyper1f1(a : Double, b : Double, x : Double) -> Double {
  @generic.hyper1f1(a, b, x, @generic.double_algebra)
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x)`, for `|x| < 1`.
///
/// The same caveat as `1F1`: the series is summed directly, with Pfaff's
/// transformation to keep the argument below one half where it applies. It is
/// accurate for parameters of order one to ten, and it does not claim the
/// large-parameter region, where the connection formulae between the fifteen
/// solutions of the hypergeometric equation are what a caller needs.
pub fn hyper2f1(a : Double, b : Double, c : Double, x : Double) -> Double {
  @generic.hyper2f1(a, b, c, x, @generic.double_algebra)
}
