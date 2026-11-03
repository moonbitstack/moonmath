// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The gamma family at double precision. The bodies are in `special/generic`,
// written against the `Ops` algebra; each function here hands them the double
// one, so the same code answers at fifty digits when the arbitrary-precision
// package asks.

///|
/// The gamma function `Γ(x)`, the continuous extension of the factorial.
///
/// `Γ(n) = (n - 1)!` for a positive integer, and the function is the integral
/// `∫ t^(x-1) e^(-t) dt` for `x > 0`. The whole real line is covered by the
/// Stirling expansion plus the reflection `Γ(x) Γ(1 - x) = π / sin(π x)`. A pole
/// at a non-positive integer comes back as an infinity, as it should.
pub fn gamma(x : Double) -> Double {
  @generic.gamma(x, @generic.double_algebra)
}

///|
/// The natural logarithm of the absolute value of the gamma function.
///
/// The log form is what a caller wants when `Γ(x)` itself would overflow a
/// double: `lgamma(1000)` is about `5905`, while `gamma(1000)` is past the
/// largest finite double.
pub fn lgamma(x : Double) -> Double {
  @generic.lgamma(x, @generic.double_algebra)
}

///|
/// The Euler beta function `B(a, b) = Γ(a) Γ(b) / Γ(a + b)`, for positive
/// arguments.
///
/// It is the normalising constant of the beta distribution and the value of the
/// integral `∫ t^(a-1) (1-t)^(b-1) dt` over `0..1`.
pub fn beta(a : Double, b : Double) -> Double {
  @generic.beta(a, b, @generic.double_algebra)
}

///|
/// The natural logarithm of the beta function.
///
/// The log form stays finite where `beta` itself would overflow or underflow.
pub fn lbeta(a : Double, b : Double) -> Double {
  @generic.lbeta(a, b, @generic.double_algebra)
}

///|
/// The digamma `ψ(x) = d/dx ln Γ(x)`, the logarithmic derivative of the gamma
/// function.
pub fn digamma(x : Double) -> Double {
  @generic.digamma(x, @generic.double_algebra)
}

///|
/// The polygamma `ψ^(n)(x)`, the `n`-th derivative of the digamma.
///
/// `n = 0` is the digamma itself; `n = 1` the trigamma and `n = 2` the
/// tetragamma, the names a caller meets when a sum over `1/(k + x)^(n+1)` has to
/// be closed.
pub fn polygamma(n : Int32, x : Double) -> Double {
  @generic.polygamma(n, x, @generic.double_algebra)
}

///|
/// The regularised lower incomplete gamma `P(a, x) = γ(a, x) / Γ(a)`, the
/// cumulative distribution of the gamma distribution with unit rate.
pub fn gammainc(a : Double, x : Double) -> Double {
  @generic.gammainc(a, x, @generic.double_algebra)
}

///|
/// The regularised upper incomplete gamma `Q(a, x) = Γ(a, x) / Γ(a) = 1 - P(a, x)`.
pub fn gammaincc(a : Double, x : Double) -> Double {
  @generic.gammaincc(a, x, @generic.double_algebra)
}

///|
/// The regularised incomplete beta `I_x(a, b)`, the cumulative distribution of
/// the beta distribution.
pub fn incbeta(a : Double, b : Double, x : Double) -> Double {
  @generic.incbeta(a, b, x, @generic.double_algebra)
}
