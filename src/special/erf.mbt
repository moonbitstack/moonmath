// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The error function and its tail, at double precision, from the bodies in
// `special/generic`.

///|
/// The error function `erf(x) = (2/sqrt π) ∫_0^x e^(-t²) dt`.
pub fn erf(x : Double) -> Double {
  @generic.erf(x, @generic.double_algebra)
}

///|
/// The complementary error function `erfc(x) = 1 - erf(x)`.
///
/// It is the one to call in the tail, where `1 - erf(x)` would lose every digit
/// the result has.
pub fn erfc(x : Double) -> Double {
  @generic.erfc(x, @generic.double_algebra)
}

///|
/// The scaled complementary error function `erfcx(x) = e^(x²) erfc(x)`, which
/// stays representable where `erfc` itself has long underflowed.
pub fn erfcx(x : Double) -> Double {
  @generic.erfcx(x, @generic.double_algebra)
}

///|
/// The imaginary error function `erfi(x) = -i erf(i x)`.
pub fn erfi(x : Double) -> Double {
  @generic.erfi(x, @generic.double_algebra)
}

///|
/// The inverse of the error function: the `y` with `erf(y) = x`, for `x` in
/// `-1 .. 1`.
pub fn erfinv(x : Double) -> Double {
  @generic.erfinv(x, @generic.double_algebra)
}

///|
/// The inverse of the complementary error function: the `y` with `erfc(y) = x`,
/// for `x` in `0 .. 2`.
pub fn erfcinv(x : Double) -> Double {
  @generic.erfcinv(x, @generic.double_algebra)
}
