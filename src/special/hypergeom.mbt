// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions at double precision, from the bodies in
// `special/generic`.

///|
/// The confluent limit `0F1(; b; x) = Σ x^k / ((b)_k k!)`.
pub fn hyper0f1(b : Double, x : Double) -> Double {
  @generic.hyper0f1(b, x, @generic.double_algebra)
}

///|
/// Kummer's confluent hypergeometric `1F1(a; b; x) = Σ (a)_k / ((b)_k k!) x^k`.
pub fn hyper1f1(a : Double, b : Double, x : Double) -> Double {
  @generic.hyper1f1(a, b, x, @generic.double_algebra)
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x)`, for `|x| < 1`.
pub fn hyper2f1(a : Double, b : Double, c : Double, x : Double) -> Double {
  @generic.hyper2f1(a, b, c, x, @generic.double_algebra)
}
