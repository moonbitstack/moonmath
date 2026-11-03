// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The half is a storage format, so the tests are about the encoding: the bits
// of the values a file format names, the round trip through `Float` for every
// one of the sixty-five thousand and five hundred encodings, and the rounding
// the standard asks for at the ties.

///|
test "the encoding of the values every consumer names" {
  assert_eq(Half::from_float(0.0).to_bits().to_int(), 0x0000)
  assert_eq(Half::from_float(-0.0).to_bits().to_int(), 0x8000)
  assert_eq(Half::from_float(1.0).to_bits().to_int(), 0x3C00)
  assert_eq(Half::from_float(-1.0).to_bits().to_int(), 0xBC00)
  assert_eq(Half::from_float(2.0).to_bits().to_int(), 0x4000)
  assert_eq(Half::from_float(0.5).to_bits().to_int(), 0x3800)
  assert_eq(Half::from_float(65504.0).to_bits().to_int(), 0x7BFF)
  // The two infinities and a NaN, from the floats with those bit patterns.
  assert_eq(
    Half::from_float(Float::reinterpret_from_int(0x7F800000)).to_bits().to_int(),
    0x7C00,
  )
  assert_eq(
    Half::from_float(Float::reinterpret_from_int(-8388608)).to_bits().to_int(),
    0xFC00,
  )
  assert_true(
    Half::from_float(Float::reinterpret_from_int(0x7FC00000)).is_nan(),
  )
}

///|
test "every non-NaN encoding round-trips through Float" {
  let mut i : Int32 = 0
  let mut checked = 0
  while i < 65536 {
    let half = Half::from_bits(i.to_uint16())
    if !half.is_nan() {
      let back = Half::from_float(half.to_float())
      if back.to_bits() != half.to_bits() {
        abort(
          "the half 0x\{half.to_bits().to_string(radix=16)} did not round-trip",
        )
      }
      checked = checked + 1
    }
    i = i + 1
  }
  // Two NaN encodings per sign: every exponent of all ones with a fraction.
  assert_eq(checked, 65536 - 2 * 1023)
}

///|
test "conversion rounds to nearest, and a tie goes to the even fraction" {
  // 1 + 2^-11 sits exactly between 1.0 and the next half, and 1.0 has an even
  // fraction: the tie rounds down.
  let down = Float::reinterpret_from_int(0x3F801000)
  assert_eq(Half::from_float(down).to_bits().to_int(), 0x3C00)
  // Just above the tie, it rounds up.
  let up = Float::reinterpret_from_int(0x3F801002)
  assert_eq(Half::from_float(up).to_bits().to_int(), 0x3C01)
  // The same tie with an odd fraction rounds up to the even one.
  let odd = Float::reinterpret_from_int(0x3F803000)
  assert_eq(Half::from_float(odd).to_bits().to_int(), 0x3C02)
  // 2049 is exactly between two halves, and rounds to the even one.
  assert_eq(Half::from_float(2049.0).to_float(), 2048.0)
}

///|
test "values past the ends of the range become an infinity or a zero" {
  assert_eq(Half::from_float(100000.0).to_bits().to_int(), 0x7C00)
  assert_eq(Half::from_float(-100000.0).to_bits().to_int(), 0xFC00)
  // Below the reach of the smallest subnormal, the nearest is zero.
  assert_eq(Half::from_float(1.0e-8).to_bits().to_int(), 0x0000)
  // A little above it, the smallest subnormal.
  assert_eq(Half::from_float(6.0e-8).to_bits().to_int(), 0x0001)
}

///|
test "the constants hold the values the standard names" {
  assert_eq(Half::one().to_float(), 1.0)
  assert_eq(Half::zero().to_float(), 0.0)
  assert_eq(Half::max().to_float(), 65504.0)
  assert_eq(Half::lowest().to_float(), -65504.0)
  // The smallest positive normal, 2^-14.
  assert_eq(Half::min().to_float(), 6.103515625e-5)
  // The gap at one, 2^-10.
  assert_eq(Half::epsilon().to_float(), 0.0009765625)
  // The smallest positive subnormal, 2^-24.
  assert_eq(Half::denorm_min().to_float(), 5.960464477539063e-8)
  assert_true(Half::pos_infinity().is_inf())
  assert_true(Half::neg_infinity().is_inf())
  assert_true(Half::nan().is_nan())
}

///|
test "classification agrees with the bits" {
  assert_true(Half::from_float(1.0).is_normal())
  assert_true(Half::from_float(0.0).is_finite())
  assert_false(Half::from_float(0.0).is_normal())
  assert_true(Half::from_float(6.0e-8).is_denormal())
  assert_false(Half::from_float(1.0).is_denormal())
  assert_true(Half::pos_infinity().is_inf())
  assert_false(Half::pos_infinity().is_finite())
  assert_false(Half::pos_infinity().is_nan())
  assert_true(Half::nan().is_nan())
  assert_false(Half::nan().is_finite())
  assert_false(Half::nan().is_inf())
}

///|
test "approx compares the values the halves stand for" {
  let near = Half::from_float(1.0)
  let next = Half::from_float(1.0009765625)
  assert_true(near.approx(Half::from_float(1.0)))
  assert_false(near.approx(next))
  assert_true(near.approx(next, eps=0.001))
  assert_false(Half::nan().approx(Half::nan()))
}
