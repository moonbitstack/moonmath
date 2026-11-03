// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions. Each is its power series, which is all a
// hypergeometric is, plus the transformation that keeps the series inside the
// radius where it converges quickly: `1F1` moves a negative argument to a
// positive one by Kummer, and `2F1` moves an argument past a half to `1 - x` by
// the linear transformation.

///|
/// The confluent limit `0F1(; b; x) = Σ x^k / ((b)_k k!)`.
pub fn[T] hyper0f1(b : T, x : T, ops : Ops[T]) -> T {
  let mut term = ops.one
  let mut sum = ops.one
  let mut k : Int32 = 0
  while k < 5000 {
    k = k + 1
    term = (ops.div)(
      (ops.mul)(term, x),
      (ops.mul)((ops.add)(b, (ops.from_int)(k - 1)), (ops.from_int)(k)),
    )
    sum = (ops.add)(sum, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  sum
}

///|
/// Kummer's confluent hypergeometric `1F1(a; b; x) = Σ (a)_k / ((b)_k k!) x^k`.
///
/// A large negative argument makes the series alternate with terms much larger
/// than the result; Kummer's transformation `1F1(a; b; x) = e^x 1F1(b - a; b; -x)`
/// turns it into a positive argument, where every term adds.
pub fn[T] hyper1f1(a : T, b : T, x : T, ops : Ops[T]) -> T {
  // The switch is where the series would start to cancel; below it the direct
  // sum is already the better of the two.
  let threshold = (ops.neg)((ops.from_int)(4))
  if (ops.lt)(x, threshold) {
    let mirrored = (ops.sub)(b, a)
    let value = hyper1f1_series(mirrored, b, (ops.neg)(x), ops)
    return (ops.mul)((ops.exp)(x), value)
  }
  hyper1f1_series(a, b, x, ops)
}

///|
/// The `1F1` series, without the transformation.
fn[T] hyper1f1_series(a : T, b : T, x : T, ops : Ops[T]) -> T {
  let mut term = ops.one
  let mut sum = ops.one
  let mut k : Int32 = 0
  while k < 5000 {
    k = k + 1
    let numerator = (ops.mul)((ops.add)(a, (ops.from_int)(k - 1)), x)
    let denominator = (ops.mul)(
      (ops.add)(b, (ops.from_int)(k - 1)),
      (ops.from_int)(k),
    )
    term = (ops.mul)(term, (ops.div)(numerator, denominator))
    sum = (ops.add)(sum, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  sum
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x) = Σ (a)_k (b)_k / ((c)_k k!) x^k`,
/// for `|x| < 1`.
///
/// Past a half the series converges too slowly to be worth summing, so the
/// argument is moved to `1 - x` by the linear transformation
/// `2F1(a,b;c;x) = Γ(c)Γ(c-a-b)/(Γ(c-a)Γ(c-b)) 2F1(a,b;a+b-c+1;1-x)
///  + (1-x)^(c-a-b) Γ(c)Γ(a+b-c)/(Γ(a)Γ(b)) 2F1(c-a,c-b;c-a-b+1;1-x)`,
/// which is the one that keeps both halves inside the fast range. A negative
/// argument takes Pfaff's transformation instead, which moves it towards zero.
pub fn[T] hyper2f1(a : T, b : T, c : T, x : T, ops : Ops[T]) -> T {
  let one = ops.one
  let magnitude = (ops.abs)(x)
  if (ops.le)(one, magnitude) {
    abort("hyper2f1: the argument must lie inside -1 .. 1")
  }
  let half = (ops.from_decimal)("0.5")
  if (ops.lt)(x, ops.zero) {
    // Pfaff: `2F1(a,b;c;x) = (1-x)^(-a) 2F1(a, c-b; c; x/(x-1))`.
    let argument = (ops.div)(x, (ops.sub)(x, one))
    let factor = (ops.pow)((ops.sub)(one, x), (ops.neg)(a))
    let value = hyper2f1_series(a, (ops.sub)(c, b), c, argument, ops)
    return (ops.mul)(factor, value)
  }
  if (ops.le)(x, half) {
    return hyper2f1_series(a, b, c, x, ops)
  }
  // The linear transformation around one. The two gamma denominators vanish when
  // `c - a - b` is an integer, and there the plain series is used instead.
  let gap = (ops.sub)((ops.sub)(c, a), b)
  if (ops.lt)((ops.abs)(gap), (ops.from_decimal)("1e-25")) {
    return hyper2f1_series(a, b, c, x, ops)
  }
  let near = (ops.sub)(one, x)
  let first_gamma = (ops.div)(
    (ops.mul)(gamma(c, ops), gamma(gap, ops)),
    (ops.mul)(gamma((ops.sub)(c, a), ops), gamma((ops.sub)(c, b), ops)),
  )
  let first = (ops.mul)(
    first_gamma,
    hyper2f1_series(a, b, (ops.sub)(one, gap), near, ops),
  )
  let second_gamma = (ops.div)(
    (ops.mul)(gamma(c, ops), gamma((ops.neg)(gap), ops)),
    (ops.mul)(gamma(a, ops), gamma(b, ops)),
  )
  let second = (ops.mul)(
    (ops.mul)((ops.pow)(near, gap), second_gamma),
    hyper2f1_series(
      (ops.sub)(c, a),
      (ops.sub)(c, b),
      (ops.add)((ops.neg)(gap), one),
      near,
      ops,
    ),
  )
  (ops.add)(first, second)
}

///|
/// The `2F1` series, without any transformation.
fn[T] hyper2f1_series(a : T, b : T, c : T, x : T, ops : Ops[T]) -> T {
  let mut term = ops.one
  let mut sum = ops.one
  let mut k : Int32 = 0
  while k < 20000 {
    k = k + 1
    let index = (ops.from_int)(k - 1)
    let numerator = (ops.mul)(
      (ops.mul)((ops.add)(a, index), (ops.add)(b, index)),
      x,
    )
    let denominator = (ops.mul)((ops.add)(c, index), (ops.from_int)(k))
    term = (ops.mul)(term, (ops.div)(numerator, denominator))
    sum = (ops.add)(sum, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  sum
}
