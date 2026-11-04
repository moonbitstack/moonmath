// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions at double precision, from the bodies in
// `special/generic`.
//
// A hypergeometric series cancels: with parameters well past the argument its
// terms run far above the result and come back to it, and the double that
// carries them keeps only the digits left over. `1F1` reports the largest term
// it formed beside the value, and this face — which can see `moonnum`'s
// arbitrary-precision `BigFloat` — re-runs the sum at forty-five digits when the
// terms ran far past the answer, then rounds once. The result is the
// double-precision answer, computed in the precision that can hold it.
//
// `2F1` has no such rescue and says so: its transformation needs six hundred
// digits of dynamic range at parameters of order a hundred, which no fixed point
// supplies.

///|
/// `x`, at the width the escalation runs at.
fn widened(x : Double, bits : Int32) -> @moonnum.BigFloat {
  @moonnum.BigFloat::of_decimal(x.to_string(), bits)
}

///|
/// Whether the double sum kept too few digits to be worth returning.
///
/// The test is on the terms, not on the answer: a sum whose largest term ran
/// past the result by `10^d` kept `15 - d` digits of it, so `10^3` is the point
/// where a third of them are gone — more than the check beside this file allows.
/// A `NaN` or an infinity — the other way a double sum fails here, by
/// overflowing on the way — counts as poor as well.
fn poor(value : Double, largest : Double) -> Bool {
  if value != value {
    return true
  }
  let size = value.abs()
  if size > 1.0e307 {
    return true
  }
  largest > size * 1.0e3
}

///|
/// The confluent limit `0F1(; b; x) = Σ x^k / ((b)_k k!)`.
///
/// Its terms are all positive for `b > 0` and `x > 0`, so it does not cancel and
/// is summed directly.
pub fn hyper0f1(b : Double, x : Double) -> Double {
  @generic.hyper0f1(b, x, @generic.double_algebra)
}

///|
/// Kummer's confluent hypergeometric `1F1(a; b; x) = Σ (a)_k / ((b)_k k!) x^k`.
///
/// The series is summed directly, with Kummer's transformation
/// `e^x 1F1(b - a; b; -x)` past `x = -4`. Where the terms run a millionfold past
/// the result the sum is redone at forty-five digits and rounded once, which is
/// what carries the large-parameter region: `1F1(-19; 24.8; 32.5)` is `-2.2e-8`,
/// formed from terms around `1e4`.
pub fn hyper1f1(a : Double, b : Double, x : Double) -> Double {
  let pair = @generic.hyper1f1_scaled(a, b, x, @generic.double_algebra)
  let (value, largest) = pair
  if !poor(value, largest) {
    return value
  }
  let bits = @moonnum.BigFloat::bits_for_digits(45)
  let ops = @generic.bigfloat_ops(bits)
  @generic.hyper1f1(widened(a, bits), widened(b, bits), widened(x, bits), ops).to_double()
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x)`, for `|x| < 1`.
///
/// Past a half the series converges too slowly to be worth summing, so the
/// argument is moved to `1 - x` by the linear transformation, and a negative
/// argument takes Pfaff's.
///
/// This one has no escalation, and the reason is worth stating: with parameters
/// of order a hundred and the argument near one, the two halves of the
/// transformation sit around `10^450` either side of a result of order one. A
/// fixed point of forty-five digits carries neither, so the wider type is not a
/// rescue here — it is a different algorithm that is needed, and the doc comment
/// on the body says what it is. A caller in that region should not read a double
/// from this function and believe it.
pub fn hyper2f1(a : Double, b : Double, c : Double, x : Double) -> Double {
  @generic.hyper2f1(a, b, c, x, @generic.double_algebra)
}
