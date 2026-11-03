// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Bessel functions at double precision, from the bodies in
// `special/generic`: the power series where `x` is near the order, the
// asymptotic expansion where it is well past it.

///|
/// The Bessel function of the first kind `J_v(x)`, for `x > 0` and real `v`.
pub fn bessel_j(v : Double, x : Double) -> Double {
  @generic.bessel_j(v, x, @generic.double_algebra)
}

///|
/// The Bessel function of the second kind `Y_v(x)`, for `x > 0` and real `v`.
pub fn bessel_y(v : Double, x : Double) -> Double {
  @generic.bessel_y(v, x, @generic.double_algebra)
}

///|
/// The modified Bessel function of the first kind `I_v(x)`, for `x > 0`.
///
/// It grows like `e^x`, so a large argument runs past the largest finite double.
pub fn bessel_i(v : Double, x : Double) -> Double {
  @generic.bessel_i(v, x, @generic.double_algebra)
}

///|
/// The modified Bessel function of the second kind `K_v(x)`, for `x > 0`.
///
/// It decays like `e^-x`: `bessel_k(0, 40)` is about `8.4e-19`, and the tail
/// keeps falling from there.
pub fn bessel_k(v : Double, x : Double) -> Double {
  @generic.bessel_k(v, x, @generic.double_algebra)
}
