// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The gamma family over `Ops`: the logarithm from the Stirling expansion with
// the Bernoulli corrections, everything else built from it. One body serves both
// precisions, and the expansion is chosen by `ops.digits` so a hundred-digit
// `Fixed` runs it far enough out while a double stops after a dozen terms.

///|
/// `ln Γ(x)` for any real `x`, over `Ops`.
///
/// The Stirling expansion is asymptotic — its terms shrink, reach a minimum and
/// then grow — so the argument is first raised to `stirling_shift` by the
/// recurrence `Γ(x) = Γ(x + 1) / x`, and the logarithms the shift added are
/// subtracted at the end. The reflection `Γ(x) Γ(1 - x) = π / sin(π x)` covers
/// the half-line below one half. A pole at a non-positive integer is a division
/// by zero and comes back as an infinity, as it should.
pub fn[T] lgamma(x : T, ops : Ops[T]) -> T {
  let half = (ops.from_decimal)("0.5")
  if (ops.lt)(x, half) {
    let pi = ops.pi
    let sine = (ops.sin)((ops.mul)(pi, x))
    let first = (ops.sub)((ops.ln)(pi), (ops.ln)((ops.abs)(sine)))
    return (ops.sub)(first, lgamma((ops.sub)(ops.one, x), ops))
  }
  let shift = stirling_shift(ops.digits)
  let terms = stirling_terms(ops.digits)
  let mut z = x
  let mut correction = ops.zero
  while (ops.lt)(z, (ops.from_int)(shift)) {
    correction = (ops.add)(correction, (ops.ln)(z))
    z = (ops.add)(z, ops.one)
  }
  let two = (ops.from_int)(2)
  let mut sum = (ops.mul)((ops.sub)(z, half), (ops.ln)(z))
  sum = (ops.sub)(sum, z)
  sum = (ops.add)(sum, (ops.mul)(half, (ops.ln)((ops.mul)(two, ops.pi))))
  // The corrections are `B_2k / (2k (2k - 1) z^(2k - 1))`; `power` walks down
  // the odd powers of `1/z` and a matching term is one multiplication away.
  let inverse_square = (ops.div)(ops.one, (ops.mul)(z, z))
  let mut power = (ops.div)(ops.one, z)
  let mut k : Int32 = 1
  while k <= terms {
    let denominator = (ops.from_int)(2 * k * (2 * k - 1))
    let term = (ops.div)((ops.mul)((ops.bernoulli)(k), power), denominator)
    sum = (ops.add)(sum, term)
    power = (ops.mul)(power, inverse_square)
    k = k + 1
  }
  (ops.sub)(sum, correction)
}

///|
/// `Γ(x)`, the continuous extension of the factorial.
///
/// Above one half it is `exp(ln Γ(x))`; below, the reflection is used instead,
/// which keeps the sign of the result and avoids the cancellation that exponentiating
/// a large negative logarithm would bring for `x` just below a pole.
pub fn[T] gamma(x : T, ops : Ops[T]) -> T {
  let half = (ops.from_decimal)("0.5")
  if (ops.lt)(x, half) {
    let pi = ops.pi
    let sine = (ops.sin)((ops.mul)(pi, x))
    return (ops.div)(pi, (ops.mul)(sine, gamma((ops.sub)(ops.one, x), ops)))
  }
  (ops.exp)(lgamma(x, ops))
}

///|
/// `ln B(a, b)`, the logarithm of the Euler beta function.
pub fn[T] lbeta(a : T, b : T, ops : Ops[T]) -> T {
  let sum = (ops.add)(a, b)
  (ops.sub)((ops.add)(lgamma(a, ops), lgamma(b, ops)), lgamma(sum, ops))
}

///|
/// `B(a, b) = Γ(a) Γ(b) / Γ(a + b)`.
pub fn[T] beta(a : T, b : T, ops : Ops[T]) -> T {
  (ops.exp)(lbeta(a, b, ops))
}

///|
/// The digamma `ψ(x) = d/dx ln Γ(x)`.
///
/// The reflection `ψ(1 - x) - ψ(x) = π cot(π x)` reaches the half-line below one
/// half; above it the recurrence `ψ(x) = ψ(x + 1) - 1/x` raises the argument to
/// the asymptotic expansion `ln z - 1/(2z) - Σ B_2k / (2k z^(2k))`.
pub fn[T] digamma(x : T, ops : Ops[T]) -> T {
  let half = (ops.from_decimal)("0.5")
  if (ops.lt)(x, half) {
    let pi = ops.pi
    let angle = (ops.mul)(pi, x)
    let cotangent = (ops.div)((ops.cos)(angle), (ops.sin)(angle))
    return (ops.sub)(
      digamma((ops.sub)(ops.one, x), ops),
      (ops.mul)(pi, cotangent),
    )
  }
  let shift = stirling_shift(ops.digits)
  let terms = stirling_terms(ops.digits)
  let mut z = x
  let mut reciprocal = ops.zero
  while (ops.lt)(z, (ops.from_int)(shift)) {
    reciprocal = (ops.add)(reciprocal, (ops.div)(ops.one, z))
    z = (ops.add)(z, ops.one)
  }
  let two = (ops.from_int)(2)
  let mut sum = (ops.ln)(z)
  sum = (ops.sub)(sum, (ops.div)(ops.one, (ops.mul)(two, z)))
  let inverse_square = (ops.div)(ops.one, (ops.mul)(z, z))
  let mut power = (ops.div)(ops.one, (ops.mul)(z, z))
  let mut k : Int32 = 1
  while k <= terms {
    let term = (ops.div)(
      (ops.mul)((ops.bernoulli)(k), power),
      (ops.from_int)(2 * k),
    )
    sum = (ops.sub)(sum, term)
    power = (ops.mul)(power, inverse_square)
    k = k + 1
  }
  (ops.sub)(sum, reciprocal)
}

///|
/// The polygamma `ψ^(n)(x)`, the `n`-th derivative of the digamma.
///
/// `n = 0` is the digamma itself. For `n >= 1` the recurrence
/// `ψ^(n)(x) = ψ^(n)(x + 1) - (-1)^n n! / x^(n+1)` raises the argument, and the
/// expansion is the term-by-term derivative of the one `digamma` uses.
pub fn[T] polygamma(n : Int32, x : T, ops : Ops[T]) -> T {
  if n == 0 {
    return digamma(x, ops)
  }
  let shift = stirling_shift(ops.digits)
  let terms = stirling_terms(ops.digits)
  let mut z = x
  let mut factorial = ops.one
  let mut i : Int32 = 0
  while i < n {
    i = i + 1
    factorial = (ops.mul)(factorial, (ops.from_int)(i))
  }
  // The recurrence subtracts `(-1)^n n! / x^(n+1)` at every step up. It holds
  // for every `x` that is not a pole, so no reflection is needed here.
  let mut reciprocal = ops.zero
  while (ops.lt)(z, (ops.from_int)(shift)) {
    let mut power = ops.one
    let mut j : Int32 = 0
    while j <= n {
      power = (ops.mul)(power, z)
      j = j + 1
    }
    let term = (ops.div)(factorial, power)
    if n % 2 == 0 {
      reciprocal = (ops.add)(reciprocal, term)
    } else {
      reciprocal = (ops.sub)(reciprocal, term)
    }
    z = (ops.add)(z, ops.one)
  }
  // `(-1)^(n-1) (n-1)! / z^n`
  let mut leading = ops.one
  let mut j : Int32 = 1
  while j < n {
    leading = (ops.mul)(leading, (ops.from_int)(j))
    j = j + 1
  }
  let mut power_n = ops.one
  let mut m : Int32 = 0
  while m < n {
    power_n = (ops.mul)(power_n, z)
    m = m + 1
  }
  let mut sum = (ops.div)(leading, power_n)
  if n % 2 == 0 {
    sum = (ops.neg)(sum)
  }
  // `- (1/2) (-1)^n n! / z^(n+1)`
  let power_next = (ops.mul)(power_n, z)
  let half_term = (ops.div)(factorial, (ops.mul)((ops.from_int)(2), power_next))
  if n % 2 == 0 {
    sum = (ops.sub)(sum, half_term)
  } else {
    sum = (ops.add)(sum, half_term)
  }
  // `- (-1)^n Σ B_2k / (2k) · (2k)(2k+1)…(2k+n-1) / z^(2k+n)`
  let inverse = (ops.div)(ops.one, z)
  let mut power = (ops.div)(ops.one, power_n)
  let mut k : Int32 = 1
  while k <= terms {
    let two_k = 2 * k
    power = (ops.mul)(power, (ops.mul)(inverse, inverse))
    // `(2k)(2k+1)…(2k+n-1)` for the current `k`.
    let mut rising = ops.one
    let mut t : Int32 = 0
    while t < n {
      rising = (ops.mul)(rising, (ops.from_int)(two_k + t))
      t = t + 1
    }
    let coefficient = (ops.div)(
      (ops.mul)((ops.bernoulli)(k), rising),
      (ops.from_int)(two_k),
    )
    let term = (ops.mul)(coefficient, power)
    if n % 2 == 0 {
      sum = (ops.sub)(sum, term)
    } else {
      sum = (ops.add)(sum, term)
    }
    k = k + 1
  }
  (ops.sub)(sum, reciprocal)
}

///|
/// The regularised lower incomplete gamma `P(a, x) = γ(a, x) / Γ(a)`.
///
/// The power series `x^a e^-x Σ x^n / (a(a+1)…(a+n))` converges quickly while
/// `x` is below `a + 1`; past that the continued fraction for the upper tail is
/// the better one, and `P = 1 - Q` completes the range.
pub fn[T] gammainc(a : T, x : T, ops : Ops[T]) -> T {
  if (ops.le)(x, ops.zero) {
    return ops.zero
  }
  let one = ops.one
  let threshold = (ops.add)(a, one)
  if (ops.lt)(x, threshold) {
    let mut term = (ops.div)(one, a)
    let mut sum = term
    let mut n : Int32 = 0
    while n < 1000 {
      n = n + 1
      term = (ops.div)((ops.mul)(term, x), (ops.add)(a, (ops.from_int)(n)))
      sum = (ops.add)(sum, term)
      if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
        break
      }
    }
    let leading = (ops.exp)(
      (ops.add)(
        (ops.sub)((ops.mul)(a, (ops.ln)(x)), x),
        (ops.neg)(lgamma(a, ops)),
      ),
    )
    (ops.mul)(sum, leading)
  } else {
    (ops.sub)(one, gammainc_upper(a, x, ops))
  }
}

///|
/// The regularised upper incomplete gamma `Q(a, x)`, by the continued fraction
/// of Legendre, evaluated with the modified Lentz algorithm.
pub fn[T] gammaincc(a : T, x : T, ops : Ops[T]) -> T {
  if (ops.le)(x, ops.zero) {
    return ops.one
  }
  let one = ops.one
  let threshold = (ops.add)(a, one)
  if (ops.lt)(x, threshold) {
    (ops.sub)(one, gammainc(a, x, ops))
  } else {
    gammainc_upper(a, x, ops)
  }
}

///|
/// `Q(a, x) = e^-x x^a / Γ(a) · 1 / (x + 1 - a - 1·(1-a) / (x + 3 - a - ...))`.
fn[T] gammainc_upper(a : T, x : T, ops : Ops[T]) -> T {
  let one = ops.one
  let tiny_value = lentz_floor(ops)
  let mut b = (ops.add)((ops.sub)(x, a), one)
  let mut c = (ops.div)(one, tiny_value)
  let mut d = (ops.div)(one, b)
  let mut h = d
  let mut i : Int32 = 1
  while i < 1000 {
    let i_value = (ops.from_int)(i)
    let an = (ops.neg)((ops.mul)(i_value, (ops.sub)(i_value, a)))
    b = (ops.add)(b, (ops.from_int)(2))
    d = (ops.add)((ops.mul)(an, d), b)
    if (ops.lt)((ops.abs)(d), tiny_value) {
      d = tiny_value
    }
    c = (ops.add)(b, (ops.div)(an, c))
    if (ops.lt)((ops.abs)(c), tiny_value) {
      c = tiny_value
    }
    d = (ops.div)(one, d)
    let delta = (ops.mul)(d, c)
    h = (ops.mul)(h, delta)
    if (ops.lt)((ops.abs)((ops.sub)(delta, one)), tiny(ops)) {
      break
    }
    i = i + 1
  }
  let leading = (ops.exp)(
    (ops.add)(
      (ops.sub)((ops.mul)(a, (ops.ln)(x)), x),
      (ops.neg)(lgamma(a, ops)),
    ),
  )
  (ops.mul)(h, leading)
}

///|
/// The regularised incomplete beta `I_x(a, b)`.
///
/// The continued fraction is evaluated for whichever of `x` and `1 - x` is the
/// smaller, and the symmetry `I_x(a, b) = 1 - I_(1-x)(b, a)` supplies the rest,
/// so the fraction always runs where it converges.
pub fn[T] incbeta(a : T, b : T, x : T, ops : Ops[T]) -> T {
  if (ops.le)(x, ops.zero) {
    return ops.zero
  }
  if (ops.le)(ops.one, x) {
    return ops.one
  }
  let one = ops.one
  let front = (ops.exp)(
    (ops.add)(
      (ops.add)(
        (ops.sub)(
          (ops.sub)(lgamma((ops.add)(a, b), ops), lgamma(a, ops)),
          lgamma(b, ops),
        ),
        (ops.mul)(a, (ops.ln)(x)),
      ),
      (ops.mul)(b, (ops.ln)((ops.sub)(one, x))),
    ),
  )
  let two = (ops.from_int)(2)
  let pivot = (ops.div)((ops.add)(a, one), (ops.add)((ops.add)(a, b), two))
  if (ops.lt)(x, pivot) {
    (ops.div)((ops.mul)(front, beta_fraction(a, b, x, ops)), a)
  } else {
    (ops.sub)(
      one,
      (ops.div)(
        (ops.mul)(front, beta_fraction(b, a, (ops.sub)(one, x), ops)),
        b,
      ),
    )
  }
}

///|
/// The continued fraction the incomplete beta is evaluated through, by the
/// modified Lentz algorithm.
fn[T] beta_fraction(a : T, b : T, x : T, ops : Ops[T]) -> T {
  let one = ops.one
  let tiny_value = lentz_floor(ops)
  let sum = (ops.add)(a, b)
  let plus = (ops.add)(a, one)
  let minus = (ops.sub)(a, one)
  let mut c = one
  let mut d = (ops.sub)(one, (ops.div)((ops.mul)(sum, x), plus))
  if (ops.lt)((ops.abs)(d), tiny_value) {
    d = tiny_value
  }
  d = (ops.div)(one, d)
  let mut h = d
  let mut m : Int32 = 1
  while m < 1000 {
    let m2 = 2 * m
    let m_value = (ops.from_int)(m)
    // The even step.
    let numerator = (ops.mul)((ops.mul)(m_value, (ops.sub)(b, m_value)), x)
    let denominator = (ops.mul)(
      (ops.add)(minus, (ops.from_int)(m2)),
      (ops.add)(a, (ops.from_int)(m2)),
    )
    let aa = (ops.div)(numerator, denominator)
    d = (ops.add)(one, (ops.mul)(aa, d))
    if (ops.lt)((ops.abs)(d), tiny_value) {
      d = tiny_value
    }
    c = (ops.add)(one, (ops.div)(aa, c))
    if (ops.lt)((ops.abs)(c), tiny_value) {
      c = tiny_value
    }
    d = (ops.div)(one, d)
    h = (ops.mul)(h, (ops.mul)(d, c))
    // The odd step.
    let numerator2 = (ops.mul)(
      (ops.neg)((ops.add)(a, m_value)),
      (ops.add)(sum, m_value),
    )
    let denominator2 = (ops.mul)(
      (ops.add)(a, (ops.from_int)(m2)),
      (ops.add)(plus, (ops.from_int)(m2)),
    )
    let aa2 = (ops.div)((ops.mul)(numerator2, x), denominator2)
    d = (ops.add)(one, (ops.mul)(aa2, d))
    if (ops.lt)((ops.abs)(d), tiny_value) {
      d = tiny_value
    }
    c = (ops.add)(one, (ops.div)(aa2, c))
    if (ops.lt)((ops.abs)(c), tiny_value) {
      c = tiny_value
    }
    d = (ops.div)(one, d)
    let delta = (ops.mul)(d, c)
    h = (ops.mul)(h, delta)
    if (ops.lt)((ops.abs)((ops.sub)(delta, one)), tiny(ops)) {
      break
    }
    m = m + 1
  }
  h
}

///|
/// The convergence threshold for this width, as a fraction of the running sum.
///
/// It is set just past the last digit the width holds rather than a couple of
/// digits inside it: a series whose terms are much larger than its result — the
/// logarithmic series of an integer-order Bessel function is the example — hands
/// those digits back to the cancellation, and stopping early would throw away
/// more than the cancellation already did.
fn[T] tiny(ops : Ops[T]) -> T {
  (ops.from_decimal)("1e-\{ops.digits + 2}")
}

///|
/// The floor a modified Lentz step divides by. It only has to be a value the
/// width can hold and that no legitimate denominator reaches; a hundred-digit
/// `Fixed` cannot hold `1e-300`, so the floor is stated at its own width.
fn[T] lentz_floor(ops : Ops[T]) -> T {
  if ops.digits <= 20 {
    (ops.from_decimal)("1e-300")
  } else {
    (ops.from_decimal)("1e-\{ops.digits - 2}")
  }
}
