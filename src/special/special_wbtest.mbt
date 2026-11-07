// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The library against the reference values in `special_data_wbtest.mbt`. The
// references come from `mpmath` at sixty digits, rounded once to a double, so a
// match is a match against a different implementation rather than the same
// formula run twice.

///|
/// Whether two doubles agree to the twelve digits a series that cancels a little
/// still leaves.
fn close(got : Double, want : Double) -> Bool {
  if got == want {
    true
  } else if want == 0.0 {
    // A value that is mathematically zero comes back as the rounding of a
    // cancellation, not as exactly zero.
    got.abs() <= 1.0e-13
  } else {
    (got - want).abs() <= 1.0e-12 * want.abs()
  }
}

///|
/// One comparison, with the arguments in the message so a failure says which case.
fn check(label : String, got : Double, want : Double) -> Unit {
  if !close(got, want) {
    abort("\{label}: got \{got}, want \{want}")
  }
}

///|
/// The same comparison at a stated relative tolerance, for the functions that
/// need one of their own.
///
/// The Bessel functions used to need a loose one here: the series lost six or
/// seven digits to cancellation once the argument was well past the order. They
/// no longer do — the continued fractions in `special/generic` closed that — but
/// the tighter check lives in `boost_check_wbtest`, against Boost's tables and
/// across the whole range rather than at five points, so this one stays at what
/// the sampled points need.
fn check_within(
  label : String,
  got : Double,
  want : Double,
  tolerance : Double,
) -> Unit {
  let error = (got - want).abs()
  if error > tolerance * want.abs() {
    abort("\{label}: got \{got}, want \{want}, relative \{error / want.abs()}")
  }
}

///|
test "the error functions match the reference" {
  for pair in erf_cases {
    let (x, want) = pair
    check("erf(\{x})", erf(x), want)
  }
  for pair in erfc_cases {
    let (x, want) = pair
    check("erfc(\{x})", erfc(x), want)
  }
  for pair in erfcx_cases {
    let (x, want) = pair
    check("erfcx(\{x})", erfcx(x), want)
  }
  for pair in erfi_cases {
    let (x, want) = pair
    check("erfi(\{x})", erfi(x), want)
  }
  for pair in erfinv_cases {
    let (x, want) = pair
    check("erfinv(\{x})", erfinv(x), want)
  }
}

///|
test "the gamma family matches the reference" {
  for pair in gamma_cases {
    let (x, want) = pair
    check("gamma(\{x})", gamma(x), want)
  }
  for pair in lgamma_cases {
    let (x, want) = pair
    check("lgamma(\{x})", lgamma(x), want)
  }
  for pair in digamma_cases {
    let (x, want) = pair
    check("digamma(\{x})", digamma(x), want)
  }
  for triple in beta_cases {
    let (a, b, want) = triple
    check("beta(\{a}, \{b})", beta(a, b), want)
  }
  for triple in lbeta_cases {
    let (a, b, want) = triple
    check("lbeta(\{a}, \{b})", lbeta(a, b), want)
  }
  for triple in polygamma_cases {
    let (n, x, want) = triple
    check("polygamma(\{n}, \{x})", polygamma(n.to_int(), x), want)
  }
}

///|
test "the incomplete gamma and beta match the reference" {
  for triple in gammainc_cases {
    let (a, x, want) = triple
    check("gammainc(\{a}, \{x})", gammainc(a, x), want)
  }
  for triple in gammaincc_cases {
    let (a, x, want) = triple
    check("gammaincc(\{a}, \{x})", gammaincc(a, x), want)
  }
  for quad in incbeta_cases {
    let (a, b, x, want) = quad
    check("incbeta(\{a}, \{b}, \{x})", incbeta(a, b, x), want)
  }
}

///|
test "the elliptic integrals match the reference" {
  for pair in ellipk_cases {
    let (m, want) = pair
    check("ellipk(\{m})", ellipk(m), want)
  }
  for pair in ellipe_cases {
    let (m, want) = pair
    check("ellipe(\{m})", ellipe(m), want)
  }
  for pair in ellipkm1_cases {
    let (m, want) = pair
    check("ellipkm1(\{m})", ellipkm1(m), want)
  }
  for triple in ellipkinc_cases {
    let (phi, m, want) = triple
    check("ellipkinc(\{phi}, \{m})", ellipkinc(phi, m), want)
  }
  for triple in ellipeinc_cases {
    let (phi, m, want) = triple
    check("ellipeinc(\{phi}, \{m})", ellipeinc(phi, m), want)
  }
  for quad in elliprf_cases {
    let (x, y, z, want) = quad
    check("elliprf(\{x}, \{y}, \{z})", elliprf(x, y, z), want)
  }
  for quad in elliprd_cases {
    let (x, y, z, want) = quad
    check("elliprd(\{x}, \{y}, \{z})", elliprd(x, y, z), want)
  }
  for triple in elliprc_cases {
    let (x, y, want) = triple
    check("elliprc(\{x}, \{y})", elliprc(x, y), want)
  }
  for case in elliprj_cases {
    let (x, y, z, p, want) = case
    check("elliprj(\{x}, \{y}, \{z}, \{p})", elliprj(x, y, z, p), want)
  }
  for quad in elliprg_cases {
    let (x, y, z, want) = quad
    check("elliprg(\{x}, \{y}, \{z})", elliprg(x, y, z), want)
  }
}

///|
test "the Bessel functions match the reference" {
  for triple in bessel_j_cases {
    let (v, x, want) = triple
    check_within("bessel_j(\{v}, \{x})", bessel_j(v, x), want, 1.0e-12)
  }
  for triple in bessel_y_cases {
    let (v, x, want) = triple
    check_within("bessel_y(\{v}, \{x})", bessel_y(v, x), want, 1.0e-11)
  }
  for triple in bessel_i_cases {
    let (v, x, want) = triple
    check_within("bessel_i(\{v}, \{x})", bessel_i(v, x), want, 1.0e-12)
  }
  for triple in bessel_k_cases {
    let (v, x, want) = triple
    check_within("bessel_k(\{v}, \{x})", bessel_k(v, x), want, 1.0e-12)
  }
}

///|
test "the hypergeometric functions match the reference" {
  for triple in hyper0f1_cases {
    let (b, x, want) = triple
    check("hyper0f1(\{b}, \{x})", hyper0f1(b, x), want)
  }
  for quad in hyper1f1_cases {
    let (a, b, x, want) = quad
    check("hyper1f1(\{a}, \{b}, \{x})", hyper1f1(a, b, x), want)
  }
  for case in hyper2f1_cases {
    let (a, b, c, x, want) = case
    check("hyper2f1(\{a}, \{b}, \{c}, \{x})", hyper2f1(a, b, c, x), want)
  }
}

///|
test "the hypergeometric edges" {
  // A numerator at a non-positive integer ends the series, and a third
  // parameter at one of its own poles stops being a division by zero when the
  // numerator ends first: `2F1(-2, 1/2; -3; 1/2)` is the three-term polynomial
  // `1 + 1/6 + 1/32`.
  assert_true(close(hyper2f1(-2.0, 0.5, -3.0, 0.5), 1.1979166666666667))
  // A `c - a - b` at an integer leaves the transformation around one with a
  // logarithm in it; the series at the argument answers it, and here the
  // argument is close enough to one that the series has to run for it.
  assert_true(close(hyper2f1(0.5, 1.0, 1.5, 0.95), 2.234860132717379))
  // A denominator at a non-positive integer is a pole, unless the numerator
  // ends before it: Kummer's transformation is not an identity in that case,
  // and `1F1(-4; -7; -18)` would come back a million times too small if it
  // were applied.
  assert_true(close(hyper1f1(-4.0, -7.0, -18.0), 50.885714285714286))
}

///|
/// The degenerate `2F1`, where `c - a - b` is a non-negative integer. The
/// transformation around one carries a logarithm in that case and the series at
/// the argument answers it slowly, like `x^k`: at `x = 0.999999` it would need
/// hundreds of thousands of terms. The logarithmic form answers every one of
/// these with a sum on `1 - x` that stays bounded as the argument closes on one,
/// and the arguments are taken close enough to one that only that form keeps
/// the run inside the ceiling.
test "the degenerate hypergeometric, the gap an integer" {
  // A gap of one: the closed form `1F1(1; 3 - 2 - 1; x)` has no logarithm, but
  // the form still answers it and the argument is close enough to one that the
  // series at the argument does not reach it.
  assert_true(close(hyper2f1(1.0, 1.0, 3.0, 0.9), 1.65368269308789))
  // A gap of two, past a half, where the logarithmic part is present.
  assert_true(close(hyper2f1(2.5, 1.5, 6.0, 0.995), 3.050222298722096))
  // A gap of three, with a negative second numerator so the gamma sign is not
  // the obvious one.
  assert_true(close(hyper2f1(0.6, 1.2, 4.8, 0.999), 1.236929465119876))
  // A gap of one with parameters large enough that a single gamma factor is
  // past a double's range while the ratio that matters is not.
  assert_true(close(hyper2f1(1.3, 2.1, 4.4, 0.97), 3.2787963588763085))
  // The argument an order of ten closer to one than the edges test above: the
  // series at the argument would walk off to the ceiling here and the
  // logarithmic form is the only answer that does not.
  assert_true(close(hyper2f1(1.0, 1.0, 2.0, 0.999999), 13.815524373459892))
}

///|
test "panic hyper2f1 outside the unit interval" {
  let _ = hyper2f1(0.5, 0.5, 1.5, 1.0)
}

///|
test "panic hyper2f1 at a pole the series reaches" {
  let _ = hyper2f1(0.5, 0.5, -1.0, 0.5)
}

///|
test "panic hyper1f1 at a pole the series reaches" {
  let _ = hyper1f1(0.5, -1.0, 0.5)
}

///|
test "zeta matches the reference on and below one" {
  for pair in zeta_cases {
    let (s, want) = pair
    check("zeta(\{s})", zeta(s), want)
  }
}

///|
test "the special values and the poles" {
  // The small-argument limits.
  assert_true(close(gamma(1.0), 1.0))
  assert_eq(gamma(5.0).round(), 24.0)
  assert_eq(erf(0.0), 0.0)
  assert_eq(erfc(0.0), 1.0)
  assert_eq(erfi(0.0), 0.0)
  assert_eq(erfinv(0.0), 0.0)
  // The pole of the zeta at one runs off to positive infinity.
  assert_true(zeta(1.0).is_inf())
  assert_true(zeta(1.0) > 0.0)
  // The trivial zeros are exact.
  assert_eq(zeta(-2.0), 0.0)
  assert_eq(zeta(-4.0), 0.0)
  // The elliptic integral at the parameter zero is a quarter turn.
  assert_true(close(ellipk(0.0), 1.5707963267948966))
  assert_true(close(ellipe(0.0), 1.5707963267948966))
  // The Bessel functions at zero, where the series has one term.
  assert_true(close(bessel_j(0.0, 0.0), 1.0))
  assert_true(close(bessel_j(1.0, 0.0), 0.0))
  assert_true(close(bessel_i(0.0, 0.0), 1.0))
  // The hypergeometric family at the origin.
  assert_true(close(hyper0f1(1.5, 0.0), 1.0))
  assert_true(close(hyper1f1(0.5, 1.5, 0.0), 1.0))
  assert_true(close(hyper2f1(0.5, 1.0, 1.5, 0.0), 1.0))
  // The incomplete gamma and beta at the ends of their ranges.
  assert_eq(gammainc(2.0, 0.0), 0.0)
  assert_eq(gammaincc(2.0, 0.0), 1.0)
  assert_eq(incbeta(2.0, 3.0, 0.0), 0.0)
  assert_eq(incbeta(2.0, 3.0, 1.0), 1.0)
}
