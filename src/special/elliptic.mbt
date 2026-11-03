// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The elliptic integrals at double precision, built on the Carlson symmetric
// forms in `special/generic`. The parameter is `m` throughout, `m = k²`, which is
// the convention the rest of this package keeps and the one `Imath` does not:
// a caller with a modulus squares it once at the call.

///|
/// The Carlson symmetric integral of the first kind `R_F(x, y, z)`.
pub fn elliprf(x : Double, y : Double, z : Double) -> Double {
  @generic.elliprf(x, y, z, @generic.double_algebra)
}

///|
/// The Carlson symmetric integral of the second kind `R_D(x, y, z)`.
pub fn elliprd(x : Double, y : Double, z : Double) -> Double {
  @generic.elliprd(x, y, z, @generic.double_algebra)
}

///|
/// The Carlson symmetric integral of the third kind, degenerate form
/// `R_C(x, y) = R_F(x, y, y)`.
pub fn elliprc(x : Double, y : Double) -> Double {
  @generic.elliprc(x, y, @generic.double_algebra)
}

///|
/// The Carlson symmetric integral of the second kind, completely symmetric form
/// `R_G(x, y, z)`.
pub fn elliprg(x : Double, y : Double, z : Double) -> Double {
  @generic.elliprg(x, y, z, @generic.double_algebra)
}

///|
/// The complete elliptic integral of the first kind `K(m)`, with `m` the
/// parameter.
pub fn ellipk(m : Double) -> Double {
  @generic.ellipk(m, @generic.double_algebra)
}

///|
/// The complete elliptic integral of the second kind `E(m)`.
pub fn ellipe(m : Double) -> Double {
  @generic.ellipe(m, @generic.double_algebra)
}

///|
/// The complete elliptic integral of the first kind from the complementary
/// parameter, `K(1 - m)`.
pub fn ellipkm1(m : Double) -> Double {
  @generic.ellipkm1(m, @generic.double_algebra)
}

///|
/// The incomplete elliptic integral of the first kind
/// `F(phi, m) = ∫_0^phi dθ / sqrt(1 - m sin²θ)`.
pub fn ellipkinc(phi : Double, m : Double) -> Double {
  @generic.ellipkinc(phi, m, @generic.double_algebra)
}

///|
/// The incomplete elliptic integral of the second kind
/// `E(phi, m) = ∫_0^phi sqrt(1 - m sin²θ) dθ`.
pub fn ellipeinc(phi : Double, m : Double) -> Double {
  @generic.ellipeinc(phi, m, @generic.double_algebra)
}
