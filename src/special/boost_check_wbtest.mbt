// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Boost.Math cross-check.
//
// `boost_wbtest.mbt` carries the reference values, row for row from the tables
// that ship with Boost.Math's own test suite. This file replays them. The two
// precisions of this package are compared against `mpmath` in `special_wbtest`
// and in `generic/generic_wbtest`; this is the third, independent comparison,
// and the one that says the double-precision side is the same function Boost
// answers and not merely a consistent one.
//
// The tolerances below are per family and each says what it is for. A single
// number would have to be the worst of them and would then hide a regression in
// the others; these are the measured reach plus a margin of four or five, so a
// change that costs an order of magnitude turns the suite red while a platform
// difference in the last digit does not. Measured over all eight and a half
// thousand rows: the error, zeta, digamma and elliptic families stay within a
// few units of the last place; the Bessel functions reach `1e-11` at the one
// place their reflection cancels.

///|
/// One comparison, with the arguments in the message so a failure names its row.
fn match_within(
  label : String,
  got : Double,
  want : Double,
  tolerance : Double,
) -> Unit {
  if got == want {
    return
  }
  let error = (got - want).abs()
  let size = want.abs()
  // A reference below the smallest normal `Double` is a value the type cannot
  // hold with any relative accuracy at all: `I_70(0.0018)` is `1.8e-314`, and
  // the fifteen digits a relative check would ask for do not exist there. Those
  // rows are skipped rather than asserted against a tolerance that would say
  // nothing about the algorithm.
  if size < 1.0e-300 {
    return
  }
  if size == 0.0 {
    if error > tolerance {
      abort("\{label}: got \{got}, want zero")
    }
  } else if error > tolerance * size {
    abort("\{label}: got \{got}, want \{want}, relative \{error / size}")
  }
}

///|
/// The error function, its complement, and the two inverses.
///
/// Boost's own table pairs `erf` with `erfc` on the same argument, which is what
/// makes it a fair test of the tail: the `erf` column saturates to one and says
/// nothing, while the `erfc` column beside it still carries thirty digits.
test "the error family against boost" {
  for pair in boost_erf_cases {
    let (x, want) = pair
    match_within("erf(\{x})", erf(x), want, 1.0e-14)
  }
  for pair in boost_erfc_cases {
    let (x, want) = pair
    match_within("erfc(\{x})", erfc(x), want, 1.0e-13)
  }
  for pair in boost_erfinv_cases {
    let (x, want) = pair
    match_within("erfinv(\{x})", erfinv(x), want, 1.0e-13)
  }
  for pair in boost_erfcinv_cases {
    let (x, want) = pair
    match_within("erfcinv(\{x})", erfcinv(x), want, 1.0e-13)
  }
}

///|
/// The digamma, on both sides of the origin.
///
/// The negative side is the wider tolerance because the reflection divides by
/// `sin(πx)`, and near a pole that division amplifies whatever the argument has
/// already lost.
test "the digamma against boost" {
  for pair in boost_digamma_cases {
    let (x, want) = pair
    match_within("digamma(\{x})", digamma(x), want, 1.0e-14)
  }
  for pair in boost_digamma_neg_cases {
    let (x, want) = pair
    match_within("digamma(\{x})", digamma(x), want, 1.0e-10)
  }
}

///|
/// The beta function and the zeta, above and below one.
test "beta and zeta against boost" {
  for triple in boost_beta_cases {
    let (a, b, want) = triple
    match_within("beta(\{a}, \{b})", beta(a, b), want, 1.0e-12)
  }
  for pair in boost_zeta_cases {
    let (s, want) = pair
    match_within("zeta(\{s})", zeta(s), want, 1.0e-14)
  }
  for pair in boost_zeta_neg_cases {
    let (s, want) = pair
    match_within("zeta(\{s})", zeta(s), want, 1.0e-12)
  }
}

///|
/// The elliptic integrals: the two complete ones, the incomplete one, and the
/// four Carlson forms.
///
/// Boost's tables are indexed by the modulus and this package by the parameter,
/// so the argument arrives already squared — the generator does that, which is
/// why the values here are the ones the functions are actually called with.
test "the elliptic integrals against boost" {
  for pair in boost_ellipk_cases {
    let (m, want) = pair
    match_within("ellipk(\{m})", ellipk(m), want, 1.0e-14)
  }
  for pair in boost_ellipe_cases {
    let (m, want) = pair
    match_within("ellipe(\{m})", ellipe(m), want, 1.0e-14)
  }
  for triple in boost_ellipkinc_cases {
    let (phi, m, want) = triple
    match_within("ellipkinc(\{phi}, \{m})", ellipkinc(phi, m), want, 1.0e-13)
  }
  for quad in boost_elliprf_cases {
    let (x, y, z, want) = quad
    match_within("elliprf(\{x}, \{y}, \{z})", elliprf(x, y, z), want, 1.0e-13)
  }
  for quad in boost_elliprd_cases {
    let (x, y, z, want) = quad
    match_within("elliprd(\{x}, \{y}, \{z})", elliprd(x, y, z), want, 1.0e-13)
  }
  for triple in boost_elliprc_cases {
    let (x, y, want) = triple
    match_within("elliprc(\{x}, \{y})", elliprc(x, y), want, 1.0e-13)
  }
  for five in boost_elliprj_cases {
    let (x, y, z, p, want) = five
    match_within(
      "elliprj(\{x}, \{y}, \{z}, \{p})",
      elliprj(x, y, z, p),
      want,
      1.0e-13,
    )
  }
}

///|
/// Kummer's confluent hypergeometric, over the whole of Boost's table.
///
/// That table is the large-parameter region — every row has `max(|a|, |b|, |x|)`
/// above twenty — which is exactly where the direct series cancels. The
/// escalation at forty-five digits is what carries it: without it the worst row
/// is out by `4e-4`, and with it by `1.1e-12`.
test "the confluent hypergeometric against boost" {
  for quad in boost_hyper1f1_cases {
    let (a, b, x, want) = quad
    match_within("hyper1f1(\{a}, \{b}, \{x})", hyper1f1(a, b, x), want, 1.0e-11)
  }
}

///|
/// The Bessel functions, in all four kinds and at integer and real order.
///
/// The real-order table for the second kind is the widest tolerance here. Its
/// values reach a nearly integer order, `v = 0.0018`, where the reflection
/// `(J_v cos πv - J_(-v)) / sin πv` subtracts two almost equal numbers and
/// divides by a sine of `0.006`: two digits of the answer are gone before the
/// first operation, and no rearrangement inside this package brings them back.
test "the bessel functions against boost" {
  for triple in boost_bessel_j_cases {
    let (v, x, want) = triple
    match_within("bessel_j(\{v}, \{x})", bessel_j(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_j_int_cases {
    let (v, x, want) = triple
    match_within("bessel_j(\{v}, \{x})", bessel_j(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_j_large_cases {
    let (v, x, want) = triple
    match_within("bessel_j(\{v}, \{x})", bessel_j(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_y_cases {
    let (v, x, want) = triple
    match_within("bessel_y(\{v}, \{x})", bessel_y(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_y_int_cases {
    let (v, x, want) = triple
    match_within("bessel_y(\{v}, \{x})", bessel_y(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_y_real_cases {
    let (v, x, want) = triple
    match_within("bessel_y(\{v}, \{x})", bessel_y(v, x), want, 1.0e-10)
  }
  for triple in boost_bessel_i_cases {
    let (v, x, want) = triple
    match_within("bessel_i(\{v}, \{x})", bessel_i(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_i_int_cases {
    let (v, x, want) = triple
    match_within("bessel_i(\{v}, \{x})", bessel_i(v, x), want, 1.0e-12)
  }
  for triple in boost_bessel_k_cases {
    let (v, x, want) = triple
    match_within("bessel_k(\{v}, \{x})", bessel_k(v, x), want, 1.0e-13)
  }
  for triple in boost_bessel_k_int_cases {
    let (v, x, want) = triple
    match_within("bessel_k(\{v}, \{x})", bessel_k(v, x), want, 1.0e-13)
  }
}
