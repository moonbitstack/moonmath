// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "the generic error function runs on Double" {
  let got = erf(1.0, double_ops())
  assert_true((got - 0.8427007929497149).abs() < 1.0e-13)
}

///|
test "the same body runs at fifty digits on BigFloat" {
  let bits = @arb.BigFloat::bits_for_digits(50)
  let got = erf(@arb.BigFloat::from_int(1, bits), bigfloat_ops(bits))
  let want = @arb.BigFloat::from_scaled(
    "84270079294971486934122063508260925929606699796630", 50, bits,
  )
  let tolerance = @arb.BigFloat::from_scaled("1", 45, bits)
  assert_true(got.approx(want, tolerance))
}
