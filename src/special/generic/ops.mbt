// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The algebra a special function is written against. It is a record of values
// and closures rather than a trait so that the same functions can be read as
// plain data: an `Ops` value is what a caller passes to choose the number type,
// and nothing about the algorithms changes between them.

///|
/// The operations and constants a special-function body needs from its number
/// type.
///
/// One value of this record is one number type. `double_ops` is the built-in
/// precision and `bigfloat_ops` the arbitrary precision; a third type needs a
/// third value and no change to the bodies.
///
/// `digits` is the working precision in decimal digits. It is not used to
/// compute anything — it only tells a body how far its series has to run and
/// where a truncation term becomes noise, which a body cannot see from `T`
/// alone.
pub struct Ops[T] {
  /// The additive identity.
  zero : T
  /// The multiplicative identity.
  one : T
  /// An integer as a value of `T`.
  from_int : (Int32) -> T
  /// A decimal literal as a value of `T`, e.g. `"-0.5772156649"`.
  from_decimal : (String) -> T
  /// Addition.
  add : (T, T) -> T
  /// Subtraction.
  sub : (T, T) -> T
  /// Multiplication.
  mul : (T, T) -> T
  /// Division.
  div : (T, T) -> T
  /// Negation.
  neg : (T) -> T
  /// Absolute value.
  abs : (T) -> T
  /// Square root.
  sqrt : (T) -> T
  /// The exponential.
  exp : (T) -> T
  /// The natural logarithm.
  ln : (T) -> T
  /// `x^y` for a positive `x`.
  pow : (T, T) -> T
  /// The sine.
  sin : (T) -> T
  /// The cosine.
  cos : (T) -> T
  /// The arctangent.
  atan : (T) -> T
  /// `B_2k`, the even Bernoulli numbers, for `k` from one.
  bernoulli : (Int32) -> T
  /// Pi.
  pi : T
  /// Whether the first is less than the second.
  lt : (T, T) -> Bool
  /// Whether the first is at most the second.
  le : (T, T) -> Bool
  /// Whether the value is exactly zero.
  is_zero : (T) -> Bool
  /// The working precision, in decimal digits.
  digits : Int32
  /// The value as a double, for a caller that wants a quick look.
  to_double : (T) -> Double
}

///|
/// The algebra of `Double`.
pub fn double_ops() -> Ops[Double] {
  {
    zero: 0.0,
    one: 1.0,
    from_int: fn(i) { Double::from_int(i) },
    from_decimal: fn(text) { decimal_to_double(text) },
    add: fn(a, b) { a + b },
    sub: fn(a, b) { a - b },
    mul: fn(a, b) { a * b },
    div: fn(a, b) { a / b },
    neg: fn(x) { -x },
    abs: fn(x) { x.abs() },
    sqrt: fn(x) { x.sqrt() },
    exp: fn(x) { @math.exp(x) },
    ln: fn(x) { @math.ln(x) },
    pow: fn(x, y) { @math.pow(x, y) },
    sin: fn(x) { @math.sin(x) },
    cos: fn(x) { @math.cos(x) },
    atan: fn(x) { @math.atan(x) },
    bernoulli: parse_bernoulli(fn(text) { decimal_to_double(text) }),
    pi: 3.141592653589793,
    lt: fn(a, b) { a < b },
    le: fn(a, b) { a <= b },
    is_zero: fn(x) { x == 0.0 },
    digits: 15,
    to_double: fn(x) { x },
  }
}

///|
/// The `Double` algebra, built once so that every double-precision entry point
/// shares one record instead of rebuilding it per call.
pub let double_algebra : Ops[Double] = double_ops()

///|
/// A decimal literal as a double: the digits are accumulated and the exponent
/// applied once, so a constant written to more places than a double holds still
/// arrives at the nearest double.
fn decimal_to_double(text : String) -> Double {
  let length = text.length()
  let mut index = 0
  let mut negative = false
  if length > 0 && text.get_char(0) == Some('-') {
    negative = true
    index = 1
  }
  let mut mantissa = 0.0
  let mut places = 0
  let mut after_point = false
  let mut exponent = 0
  let mut exponent_negative = false
  let mut in_exponent = false
  while index < length {
    let c = text.get_char(index).unwrap()
    if c == '.' {
      after_point = true
    } else if c == 'e' || c == 'E' {
      in_exponent = true
      index = index + 1
      if index < length && text.get_char(index) == Some('-') {
        exponent_negative = true
        index = index + 1
      }
      continue
    } else if in_exponent {
      exponent = exponent * 10 + (c.to_int() - 48)
    } else {
      mantissa = mantissa * 10.0 + (c.to_int() - 48).to_double()
      if after_point {
        places = places + 1
      }
    }
    index = index + 1
  }
  let scale = if exponent_negative {
    exponent + places
  } else {
    places - exponent
  }
  let value = mantissa * @math.pow(10.0, -scale.to_double())
  if negative {
    -value
  } else {
    value
  }
}

///|
/// The algebra of a `BigFloat` at `bits` fractional bits.
pub fn bigfloat_ops(bits : Int32) -> Ops[@moonnum.BigFloat] {
  {
    zero: @moonnum.BigFloat::zero(bits),
    one: @moonnum.BigFloat::one(bits),
    from_int: fn(i) { @moonnum.BigFloat::of_int(i, bits) },
    from_decimal: fn(text) { @moonnum.BigFloat::of_decimal(text, bits) },
    add: fn(a, b) { a.add(b) },
    sub: fn(a, b) { a.sub(b) },
    mul: fn(a, b) { a.mul(b) },
    div: fn(a, b) { a.div(b) },
    neg: fn(x) { x.neg() },
    abs: fn(x) { x.abs() },
    sqrt: fn(x) { x.sqrt() },
    exp: fn(x) { x.exp() },
    ln: fn(x) { x.ln() },
    pow: fn(x, y) { x.pow(y) },
    sin: fn(x) { x.sin() },
    cos: fn(x) { x.cos() },
    atan: fn(x) { x.atan() },
    bernoulli: parse_bernoulli(fn(text) {
      @moonnum.BigFloat::of_decimal(text, bits)
    }),
    pi: @moonnum.BigFloat::pi(bits),
    lt: fn(a, b) { a.lt(b) },
    le: fn(a, b) { a.le(b) },
    is_zero: fn(x) { x.is_zero() },
    digits: @moonnum.BigFloat::digits_for_bits(bits),
    to_double: fn(x) { x.to_double() },
  }
}
