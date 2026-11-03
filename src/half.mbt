// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The half is fixed at sixteen bits, so it has no double-precision twin: the
// `f64` package is the same library at `Double`, and a half is a half in
// either. This template is emitted for single precision only, which is how it
// stays out of `src/f64/`.

///|
/// A 16-bit IEEE 754 binary16 value: the half precision a texture, a packed
/// vertex or a GPU buffer carries when thirty-two bits are more than the data
/// needs and sixteen are enough.
///
/// The value is the sixteen bits themselves, so a half read from a buffer is
/// `from_bits` and one written back is `to_bits`. Arithmetic runs at `Float`,
/// the precision the rest of this library works in: a half is a storage format,
/// not a second arithmetic. Conversion rounds to nearest with ties to even, as
/// the standard and the graphics formats do, and the special values — signed
/// zeros, the two infinities, a quiet NaN and the subnormals — survive the round
/// trip.
///
/// Fixed at sixteen bits, this type has no double-precision counterpart; it
/// lives only in the single-precision package.
#derive(Eq)
pub struct Half {
  /// The sixteen bits, sign, exponent and fraction, in that order.
  bits : UInt16
}

///|
pub extend Half with Eq::{equal, not_equal}

///|
/// The half made of the sixteen raw bits, as a buffer holds it.
pub fn Half::from_bits(bits : UInt16) -> Half {
  { bits, }
}

///|
/// The sixteen raw bits, in the order a buffer expects.
pub fn Half::to_bits(self : Half) -> UInt16 {
  self.bits
}

///|
/// The 16-bit encoding of `value`, rounded to the nearest representable half,
/// ties to even.
///
/// Values beyond the largest finite half become an infinity of the same sign;
/// values below the smallest subnormal become a signed zero; a NaN stays a NaN.
pub fn Half::from_float(value : Float) -> Half {
  let bits : Int32 = value.reinterpret_as_int()
  let one : Int32 = 1
  let sign : Int32 = (bits >> 16) & 0x8000
  let exponent : Int32 = (bits >> 23) & 0xFF
  let mantissa : Int32 = bits & 0x7FFFFF
  // The infinity and the NaNs: keep the sign, and a NaN's payload with it.
  if exponent == 0xFF {
    if mantissa == 0 {
      return make(sign | 0x7C00)
    }
    return make(sign | 0x7E00 | (mantissa >> 13))
  }
  // The exponent the value would carry as a half, biased by fifteen.
  let e : Int32 = exponent - 112
  if e >= 0x1F {
    // Past the largest finite half; the nearest is an infinity.
    return make(sign | 0x7C00)
  }
  if e >= 1 {
    // A normal half: ten bits of mantissa, the thirteenth bit below them is the
    // round bit and everything under it is the sticky bit.
    let kept : Int32 = mantissa >> 13
    let discarded : Int32 = mantissa & 0x1FFF
    let mut half_mantissa : Int32 = kept
    if discarded > 0x1000 || (discarded == 0x1000 && (kept & one) != 0) {
      half_mantissa = half_mantissa + one
    }
    let mut field : Int32 = e
    if half_mantissa >= 0x400 {
      // Rounding the mantissa overflowed it into the exponent.
      half_mantissa = 0
      field = field + one
    }
    if field >= 0x1F {
      return make(sign | 0x7C00)
    }
    return make(sign | (field << 10) | half_mantissa)
  }
  // Subnormal or zero. Below the rounding reach of the smallest subnormal, the
  // nearest value is a signed zero.
  if e < -10 {
    return make(sign)
  }
  let shift : Int32 = 14 - e
  let numerator : Int32 = mantissa | 0x800000
  let mut half_mantissa : Int32 = numerator >> shift
  let remainder : Int32 = numerator & ((one << shift) - one)
  let halfway : Int32 = one << (shift - one)
  if remainder > halfway || (remainder == halfway && (half_mantissa & one) != 0) {
    half_mantissa = half_mantissa + one
  }
  if half_mantissa >= 0x400 {
    // Rounded up to the smallest normal.
    return make(sign | 0x0400)
  }
  make(sign | half_mantissa)
}

///|
/// The `Float` the half stands for.
///
/// Exact: every half is a `Float`, though not every `Float` is a half.
pub fn Half::to_float(self : Half) -> Float {
  let bits : Int32 = self.bits.to_int()
  let one : Int32 = 1
  let sign : Int32 = (bits & 0x8000) << 16
  let exponent : Int32 = (bits >> 10) & 0x1F
  let mantissa : Int32 = bits & 0x3FF
  if exponent == 0 {
    if mantissa == 0 {
      // A signed zero.
      return Float::reinterpret_from_int(sign)
    }
    // A subnormal: normalise the ten-bit mantissa into the wider fraction.
    let mut position : Int32 = 9
    while (mantissa & (one << position)) == 0 {
      position = position - one
    }
    let implicit : Int32 = one << position
    let fraction : Int32 = (mantissa - implicit) << (23 - position)
    let field : Int32 = 103 + position
    return Float::reinterpret_from_int(sign | (field << 23) | fraction)
  }
  if exponent == 0x1F {
    if mantissa == 0 {
      return Float::reinterpret_from_int(sign | 0x7F800000)
    }
    return Float::reinterpret_from_int(sign | 0x7FC00000)
  }
  let field : Int32 = exponent + 112
  let fraction : Int32 = mantissa << 13
  Float::reinterpret_from_int(sign | (field << 23) | fraction)
}

///|
/// Whether the half is neither an infinity nor a NaN.
pub fn Half::is_finite(self : Half) -> Bool {
  (self.bits.to_int() & 0x7C00) != 0x7C00
}

///|
/// Whether the half is a NaN.
pub fn Half::is_nan(self : Half) -> Bool {
  let bits : Int32 = self.bits.to_int()
  (bits & 0x7C00) == 0x7C00 && (bits & 0x3FF) != 0
}

///|
/// Whether the half is an infinity, of either sign.
pub fn Half::is_inf(self : Half) -> Bool {
  let bits : Int32 = self.bits.to_int()
  (bits & 0x7C00) == 0x7C00 && (bits & 0x3FF) == 0
}

///|
/// Whether the half is a normal number: not zero, not subnormal, not infinite.
pub fn Half::is_normal(self : Half) -> Bool {
  let exponent : Int32 = (self.bits.to_int() >> 10) & 0x1F
  exponent != 0 && exponent != 0x1F
}

///|
/// Whether the half is a subnormal: non-zero, smaller than the smallest normal.
pub fn Half::is_denormal(self : Half) -> Bool {
  let bits : Int32 = self.bits.to_int()
  (bits & 0x7C00) == 0 && (bits & 0x3FF) != 0
}

///|
/// Positive infinity.
pub fn Half::pos_infinity() -> Half {
  make(0x7C00)
}

///|
/// Negative infinity.
pub fn Half::neg_infinity() -> Half {
  make(0xFC00)
}

///|
/// A quiet NaN.
pub fn Half::nan() -> Half {
  make(0x7E00)
}

///|
/// Positive zero.
pub fn Half::zero() -> Half {
  make(0x0000)
}

///|
/// One.
pub fn Half::one() -> Half {
  make(0x3C00)
}

///|
/// The smallest positive normal, `2^-14`.
pub fn Half::min() -> Half {
  make(0x0400)
}

///|
/// The largest finite half, `65504`.
pub fn Half::max() -> Half {
  make(0x7BFF)
}

///|
/// The most negative finite half, `-65504`.
pub fn Half::lowest() -> Half {
  make(0xFBFF)
}

///|
/// The smallest number that, added to one, gives a half different from one:
/// `2^-10`.
pub fn Half::epsilon() -> Half {
  make(0x1400)
}

///|
/// The smallest positive subnormal, `2^-24`.
pub fn Half::denorm_min() -> Half {
  make(0x0001)
}

///|
/// Whether the two halves hold the same value to within `eps`, compared at
/// `Float` precision.
pub fn Half::approx(self : Half, other : Half, eps? : Float) -> Bool {
  approx(self.to_float(), other.to_float(), eps?)
}

///|
/// The half as the number it holds; a NaN or an infinity prints as it does at
/// `Float`.
pub impl Show for Half with fn output(self, logger) {
  logger.write_string("Half(\{self.to_float()})")
}

///|
pub extend Half with Show::{output, to_string}

///|
/// The bits and the value, so a debugger shows the encoding behind the number.
pub impl Debug for Half with fn to_repr(self) {
  @debug.Repr::ctor("Half", [
    (Some("bits"), @debug.Repr::integer(self.bits.to_string(radix=16))),
    (Some("value"), @debug.Repr::float(self.to_float())),
  ])
}

///|
pub extend Half with Debug::{to_repr}

///|
/// The half from the sixteen bits as an integer, for the constants above.
fn make(bits : Int32) -> Half {
  { bits: bits.to_uint16(), }
}
