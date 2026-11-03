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
pub struct Ops[T] {
  /// The additive identity.
  zero : T
  /// The multiplicative identity.
  one : T
  /// An integer as a value of `T`.
  from_int : (Int32) -> T
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
  /// Pi.
  pi : T
  /// Whether the first is less than the second.
  lt : (T, T) -> Bool
  /// Whether the value is exactly zero.
  is_zero : (T) -> Bool
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
    add: fn(a, b) { a + b },
    sub: fn(a, b) { a - b },
    mul: fn(a, b) { a * b },
    div: fn(a, b) { a / b },
    neg: fn(x) { -x },
    abs: fn(x) { x.abs() },
    sqrt: fn(x) { x.sqrt() },
    exp: fn(x) { @math.exp(x) },
    ln: fn(x) { @math.ln(x) },
    pi: 3.141592653589793,
    lt: fn(a, b) { a < b },
    is_zero: fn(x) { x == 0.0 },
    to_double: fn(x) { x },
  }
}

///|
/// The algebra of a `BigFloat` at `bits` fractional bits.
pub fn bigfloat_ops(bits : Int32) -> Ops[@arb.BigFloat] {
  {
    zero: @arb.BigFloat::zero(bits),
    one: @arb.BigFloat::one(bits),
    from_int: fn(i) { @arb.BigFloat::from_int(i, bits) },
    add: fn(a, b) { a.add(b) },
    sub: fn(a, b) { a.sub(b) },
    mul: fn(a, b) { a.mul(b) },
    div: fn(a, b) { a.div(b) },
    neg: fn(x) { x.neg() },
    abs: fn(x) { x.abs() },
    sqrt: fn(x) { x.sqrt() },
    exp: fn(x) { x.exp() },
    ln: fn(x) { x.ln() },
    pi: @arb.BigFloat::pi(bits),
    lt: fn(a, b) { a.lt(b) },
    is_zero: fn(x) { x.is_zero() },
    to_double: fn(x) { x.to_double() },
  }
}
