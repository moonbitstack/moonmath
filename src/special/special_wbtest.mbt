// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The library against the reference values in `special_data_wbtest.mbt`. The
// references come from an independent implementation — Python's `math` for the
// gamma and error families, a high-precision `decimal` series for the elliptic
// and zeta values — so a match is a match against different code, not against
// the same formula run twice.

///|
fn close(got : Double, want : Double) -> Bool {
  if got == want {
    true
  } else {
    (got - want).abs() <= 1.0e-13 * want.abs().max(1.0)
  }
}

///|
fn check(name : String, x : Double, got : Double, want : Double) -> Unit {
  if !close(got, want) {
    abort("\{name}(\{x}): got \{got}, want \{want}")
  }
}

///|
test "erf matches the reference" {
  for pair in erf_cases {
    let (x, want) = pair
    check("erf", x, erf(x), want)
  }
}

///|
test "erfc matches the reference" {
  for pair in erfc_cases {
    let (x, want) = pair
    check("erfc", x, erfc(x), want)
  }
}

///|
test "gamma matches the reference" {
  for pair in gamma_cases {
    let (x, want) = pair
    check("gamma", x, gamma(x), want)
  }
}

///|
test "lgamma matches the reference" {
  for pair in lgamma_cases {
    let (x, want) = pair
    check("lgamma", x, lgamma(x), want)
  }
}

///|
test "beta matches the reference" {
  for triple in beta_cases {
    let (a, b, want) = triple
    let got = beta(a, b)
    if !close(got, want) {
      abort("beta(\{a}, \{b}): got \{got}, want \{want}")
    }
  }
}

///|
test "the complete elliptic integral of the first kind matches the reference" {
  for pair in ellipk_cases {
    let (m, want) = pair
    check("ellipk", m, ellipk(m), want)
  }
}

///|
test "the complete elliptic integral of the second kind matches the reference" {
  for pair in ellipe_cases {
    let (m, want) = pair
    check("ellipe", m, ellipe(m), want)
  }
}

///|
test "zeta matches the reference" {
  for pair in zeta_cases {
    let (s, want) = pair
    check("zeta", s, zeta(s), want)
  }
}

///|
test "the special values and the poles" {
  // The small-argument limits.
  assert_true(close(gamma(1.0), 1.0))
  assert_eq(gamma(5.0).round(), 24.0)
  assert_eq(erf(0.0), 0.0)
  assert_eq(erfc(0.0), 1.0)
  // The pole of the zeta at one runs off to positive infinity.
  assert_true(zeta(1.0).is_inf())
  assert_true(zeta(1.0) > 0.0)
  // The elliptic integral at the parameter zero is a quarter turn.
  assert_true(close(ellipk(0.0), 1.5707963267948966))
  assert_true(close(ellipe(0.0), 1.5707963267948966))
}
