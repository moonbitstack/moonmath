// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The Bessel functions. Two regimes, and the boundary is where each stops being
// usable: the power series cancels once `x` is well past the order, and the
// asymptotic expansion only becomes accurate once `x` is well past it. Integer
// order has closed forms with logarithms that the real order reaches as a limit,
// so those are written out rather than approached.

///|
/// The Bessel function of the first kind `J_v(x)`, for `x > 0` and `v >= 0`.
///
/// `J_v(x) = Σ (-1)^k (x/2)^(2k+v) / (k! Γ(k + v + 1))`. The series is used
/// while `x` is near the order, where it converges before its alternating terms
/// have grown far past the result; past that the asymptotic expansion takes over,
/// and its terms are summed until they begin to grow.
pub fn[T] bessel_j(v : T, x : T, ops : Ops[T]) -> T {
  // At the origin the series is a single term: `J_0(0) = 1` and every other
  // order vanishes.
  if (ops.is_zero)(x) {
    return if (ops.is_zero)(v) { ops.one } else { ops.zero }
  }
  let pair = bessel_jy(v, x, ops)
  pair.0
}

///|
/// The Bessel function of the second kind `Y_v(x)`, for `x > 0` and `v >= 0`.
///
/// For an integer order this is the limit of `(J_v cos vπ - J_-v) / sin vπ`,
/// written out as the logarithm series `Y_n(x) =
/// -(1/π) Σ_(k<n) (n-k-1)!/k! (x/2)^(2k-n) + (2/π) ln(x/2) J_n(x)
///  - (1/π)(x/2)^n Σ_k (ψ(k+1) + ψ(n+k+1)) / (k! (n+k)!) (-x²/4)^k`,
/// which is finite where the limit form is `0/0`.
pub fn[T] bessel_y(v : T, x : T, ops : Ops[T]) -> T {
  let pair = bessel_jy(v, x, ops)
  pair.1
}

///|
/// The modified Bessel function of the first kind `I_v(x)`, for `x > 0`.
///
/// The series is the same one as `J_v` without the alternating sign, so it never
/// cancels and is used everywhere; the exponential in it is what eventually runs
/// past what the width holds.
pub fn[T] bessel_i(v : T, x : T, ops : Ops[T]) -> T {
  if (ops.is_zero)(x) {
    return if (ops.is_zero)(v) { ops.one } else { ops.zero }
  }
  if use_series(v, x, ops) {
    bessel_i_series(v, x, ops)
  } else {
    let pair = bessel_ik_asymptotic(v, x, ops)
    pair.0
  }
}

///|
/// The modified Bessel function of the second kind `K_v(x)`, for `x > 0`.
///
/// For an integer order it is the limit of `(π/2)(I_-v - I_v)/sin vπ`, written
/// out as `K_n(x) = (1/2)(x/2)^(-n) Σ_(k<n) (n-k-1)!/k! (-x²/4)^k
///  + (-1)^(n+1) ln(x/2) I_n(x)
///  + (-1)^n (1/2)(x/2)^n Σ_k (ψ(k+1) + ψ(n+k+1)) / (k! (n+k)!) (x²/4)^k`.
pub fn[T] bessel_k(v : T, x : T, ops : Ops[T]) -> T {
  // `K` is the one function whose two regimes both degrade with `x`. The series
  // loses a digit for every factor the answer is smaller than the terms that
  // form it — about `0.43 x` digits — while the asymptotic expansion's first
  // omitted term falls like `e^-2x`. They cross near `x = digits / 1.3`, and on
  // either side of that point the better of the two is a long way the better.
  let crossing = (ops.mul)(x, (ops.from_int)(13))
  let threshold = (ops.from_int)(ops.digits * 10)
  if use_series(v, x, ops) && (ops.le)(crossing, threshold) {
    bessel_k_series(v, x, ops)
  } else {
    let pair = bessel_ik_asymptotic(v, x, ops)
    pair.1
  }
}

///|
/// Whether the power series is the better of the two regimes here. The series
/// loses about `x/ln 10` digits to cancellation, and the asymptotic needs `x`
/// several times the order before its first terms dominate, so the crossover is
/// where both are still worth their rounding.
fn[T] use_series(v : T, x : T, ops : Ops[T]) -> Bool {
  let limit = (ops.add)((ops.from_int)(12), (ops.mul)((ops.from_int)(2), v))
  (ops.le)(x, limit)
}

///|
/// The order as an integer, or `-1` when it is not a non-negative integer.
fn[T] bessel_integer_order(v : T, ops : Ops[T]) -> Int32 {
  let value = (ops.to_double)(v)
  let rounded = value.round()
  if (value - rounded).abs() < 1.0e-9 && rounded >= 0.0 && rounded < 200.0 {
    rounded.to_int()
  } else {
    -1
  }
}

///|
/// `J_v` and `Y_v` together: the asymptotic expansion answers both from one
/// pair of auxiliary sums, and the series answers each on its own.
fn[T] bessel_jy(v : T, x : T, ops : Ops[T]) -> (T, T) {
  if (ops.le)(x, ops.zero) {
    abort("bessel_j: x must be positive")
  }
  let order = bessel_integer_order(v, ops)
  if !use_series(v, x, ops) {
    return bessel_jy_asymptotic(v, x, ops)
  }
  let j = bessel_j_series(v, x, ops)
  let y = if order >= 0 {
    bessel_y_order(order, x, ops)
  } else {
    let pi = ops.pi
    let angle = (ops.mul)(pi, v)
    let numerator = (ops.sub)(
      (ops.mul)(j, (ops.cos)(angle)),
      bessel_j_series((ops.neg)(v), x, ops),
    )
    (ops.div)(numerator, (ops.sin)(angle))
  }
  (j, y)
}

///|
/// The `J` power series, which converges for every `x` and every order.
fn[T] bessel_j_series(v : T, x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let four = (ops.from_int)(4)
  let half = (ops.div)(x, two)
  let mut term = (ops.div)(
    (ops.pow)(half, v),
    gamma((ops.add)(v, ops.one), ops),
  )
  let mut sum = term
  let quarter_square = (ops.div)((ops.mul)(x, x), four)
  let mut k : Int32 = 0
  while k < 5000 {
    k = k + 1
    let denominator = (ops.mul)(
      (ops.from_int)(k),
      (ops.add)(v, (ops.from_int)(k)),
    )
    term = (ops.neg)((ops.mul)(term, (ops.div)(quarter_square, denominator)))
    sum = (ops.add)(sum, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  sum
}

///|
/// The `I` power series: the same recurrence with no sign change.
fn[T] bessel_i_series(v : T, x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let four = (ops.from_int)(4)
  let half = (ops.div)(x, two)
  let mut term = (ops.div)(
    (ops.pow)(half, v),
    gamma((ops.add)(v, ops.one), ops),
  )
  let mut sum = term
  let quarter_square = (ops.div)((ops.mul)(x, x), four)
  let mut k : Int32 = 0
  while k < 5000 {
    k = k + 1
    let denominator = (ops.mul)(
      (ops.from_int)(k),
      (ops.add)(v, (ops.from_int)(k)),
    )
    term = (ops.mul)(term, (ops.div)(quarter_square, denominator))
    sum = (ops.add)(sum, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  sum
}

///|
/// `Y_n` for a non-negative integer order.
///
/// Orders zero and one come from the logarithmic series directly; the rest are
/// raised from them by `Y_(n+1) = Y_(n-1) + (2n/x) Y_n`. The recurrence is the
/// stable direction for `Y` — it is the dominant solution of the pair, and the
/// forward direction follows it — and it avoids the finite sum in the series,
/// which is the cancellation such a small result would otherwise carry.
fn[T] bessel_y_order(n : Int32, x : T, ops : Ops[T]) -> T {
  if n <= 1 {
    return bessel_y_integer(n, x, ops)
  }
  let two = (ops.from_int)(2)
  let mut previous = bessel_y_integer(0, x, ops)
  let mut current = bessel_y_integer(1, x, ops)
  let mut k : Int32 = 1
  while k < n {
    let step = (ops.mul)(
      (ops.div)((ops.mul)(two, (ops.from_int)(k)), x),
      current,
    )
    let next = (ops.sub)(step, previous)
    previous = current
    current = next
    k = k + 1
  }
  current
}

///|
/// `Y_n` for a non-negative integer order, from the logarithmic series.
fn[T] bessel_y_integer(n : Int32, x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let pi = ops.pi
  let half = (ops.div)(x, two)
  let j = bessel_j_series((ops.from_int)(n), x, ops)
  // The finite sum: `-(1/π) Σ_(k<n) (n-k-1)!/k! (x/2)^(2k-n)`.
  let mut finite = ops.zero
  let mut k : Int32 = 0
  while k < n {
    let ratio = (ops.div)(factorial(n - k - 1, ops), factorial(k, ops))
    let power = power_of(half, 2 * k - n, ops)
    finite = (ops.add)(finite, (ops.mul)(ratio, power))
    k = k + 1
  }
  let first = (ops.neg)((ops.div)(finite, pi))
  let second = (ops.mul)((ops.div)(two, pi), (ops.mul)((ops.ln)(half), j))
  // The infinite sum: `-(1/π)(x/2)^n Σ_k (ψ(k+1)+ψ(n+k+1))/(k!(n+k)!) (-x²/4)^k`.
  let quarter_square = (ops.neg)((ops.div)((ops.mul)(x, x), (ops.from_int)(4)))
  let mut power = ops.one
  let mut factorial_k = ops.one
  let mut factorial_nk = factorial(n, ops)
  let mut series = ops.zero
  // `ψ(k+1)` and `ψ(n+k+1)` step by `ψ(x+1) = ψ(x) + 1/x`, so the loop calls the
  // digamma twice in all rather than twice per term — and a digamma costs a
  // shifted logarithm.
  let mut psi_k = digamma(ops.one, ops)
  let mut psi_nk = digamma((ops.from_int)(n + 1), ops)
  let mut k : Int32 = 0
  while k < 5000 {
    let coefficient = (ops.div)(
      (ops.add)(psi_k, psi_nk),
      (ops.mul)(factorial_k, factorial_nk),
    )
    let term = (ops.mul)(coefficient, power)
    series = (ops.add)(series, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(series), tiny(ops))) {
      break
    }
    k = k + 1
    power = (ops.mul)(power, quarter_square)
    factorial_k = (ops.mul)(factorial_k, (ops.from_int)(k))
    factorial_nk = (ops.mul)(factorial_nk, (ops.from_int)(n + k))
    psi_k = (ops.add)(psi_k, (ops.div)(ops.one, (ops.from_int)(k)))
    psi_nk = (ops.add)(psi_nk, (ops.div)(ops.one, (ops.from_int)(n + k)))
  }
  let third = (ops.div)(
    (ops.mul)((ops.pow)(half, (ops.from_int)(n)), series),
    pi,
  )
  (ops.sub)((ops.add)(first, second), third)
}

///|
/// `K_v` from the logarithmic series for an integer order, and from the limit
/// `(π/2)(I_-v - I_v)/sin vπ` otherwise.
fn[T] bessel_k_series(v : T, x : T, ops : Ops[T]) -> T {
  let order = bessel_integer_order(v, ops)
  if order < 0 {
    let pi = ops.pi
    let angle = (ops.mul)(pi, v)
    let numerator = (ops.sub)(
      bessel_i_series((ops.neg)(v), x, ops),
      bessel_i_series(v, x, ops),
    )
    return (ops.div)(
      (ops.mul)((ops.div)(pi, (ops.from_int)(2)), numerator),
      (ops.sin)(angle),
    )
  }
  let n = order
  if n >= 2 {
    // `K` is the dominant solution of its recurrence and the modified functions
    // carry the opposite sign to the ordinary ones, so the step adds:
    // `K_(n+1) = K_(n-1) + (2n/x) K_n`. Raised this way it skips the finite sum
    // in the series, which is where the cancellation would come from.
    let two = (ops.from_int)(2)
    let mut previous = bessel_k_direct(0, x, ops)
    let mut current = bessel_k_direct(1, x, ops)
    let mut k : Int32 = 1
    while k < n {
      let step = (ops.mul)(
        (ops.div)((ops.mul)(two, (ops.from_int)(k)), x),
        current,
      )
      let next = (ops.add)(previous, step)
      previous = current
      current = next
      k = k + 1
    }
    return current
  }
  bessel_k_direct(n, x, ops)
}

///|
/// `K_n` for order zero or one, straight from the logarithmic series.
fn[T] bessel_k_direct(n : Int32, x : T, ops : Ops[T]) -> T {
  let two = (ops.from_int)(2)
  let half = (ops.div)(x, two)
  let i_n = bessel_i_series((ops.from_int)(n), x, ops)
  // `(1/2)(x/2)^(-n) Σ_(k<n) (n-k-1)!/k! (-x²/4)^k`
  let mut finite = ops.zero
  let mut k : Int32 = 0
  while k < n {
    let ratio = (ops.div)(factorial(n - k - 1, ops), factorial(k, ops))
    let power = power_of(
      (ops.neg)((ops.div)((ops.mul)(x, x), (ops.from_int)(4))),
      k,
      ops,
    )
    finite = (ops.add)(finite, (ops.mul)(ratio, power))
    k = k + 1
  }
  let leading = (ops.mul)(
    (ops.div)(ops.one, two),
    (ops.mul)(power_of(half, 0 - n, ops), finite),
  )
  // `(-1)^(n+1) ln(x/2) I_n(x)`
  let log_term = (ops.mul)((ops.ln)(half), i_n)
  let log_term = if n % 2 == 0 { (ops.neg)(log_term) } else { log_term }
  // `(-1)^n (1/2)(x/2)^n Σ_k (ψ(k+1)+ψ(n+k+1))/(k!(n+k)!) (x²/4)^k`
  let quarter_square = (ops.div)((ops.mul)(x, x), (ops.from_int)(4))
  let mut power = ops.one
  let mut factorial_k = ops.one
  let mut factorial_nk = factorial(n, ops)
  let mut series = ops.zero
  // `ψ(k+1)` and `ψ(n+k+1)` step by `ψ(x+1) = ψ(x) + 1/x`, so the loop calls the
  // digamma twice in all rather than twice per term — and a digamma costs a
  // shifted logarithm.
  let mut psi_k = digamma(ops.one, ops)
  let mut psi_nk = digamma((ops.from_int)(n + 1), ops)
  let mut k : Int32 = 0
  while k < 5000 {
    let coefficient = (ops.div)(
      (ops.add)(psi_k, psi_nk),
      (ops.mul)(factorial_k, factorial_nk),
    )
    let term = (ops.mul)(coefficient, power)
    series = (ops.add)(series, term)
    if (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(series), tiny(ops))) {
      break
    }
    k = k + 1
    power = (ops.mul)(power, quarter_square)
    factorial_k = (ops.mul)(factorial_k, (ops.from_int)(k))
    factorial_nk = (ops.mul)(factorial_nk, (ops.from_int)(n + k))
    psi_k = (ops.add)(psi_k, (ops.div)(ops.one, (ops.from_int)(k)))
    psi_nk = (ops.add)(psi_nk, (ops.div)(ops.one, (ops.from_int)(n + k)))
  }
  let tail = (ops.mul)(
    (ops.div)(ops.one, two),
    (ops.mul)(power_of(half, n, ops), series),
  )
  let tail = if n % 2 == 0 { tail } else { (ops.neg)(tail) }
  (ops.add)((ops.add)(leading, log_term), tail)
}

///|
/// `J_v` and `Y_v` from the asymptotic expansion
/// `sqrt(2/(πx)) (cos χ P - sin χ Q)` and `sqrt(2/(πx)) (sin χ P + cos χ Q)`,
/// with `χ = x - (v/2 + 1/4)π` and the auxiliary sums `P` and `Q`.
fn[T] bessel_jy_asymptotic(v : T, x : T, ops : Ops[T]) -> (T, T) {
  let four = (ops.from_int)(4)
  let two = (ops.from_int)(2)
  let mu = (ops.mul)(four, (ops.mul)(v, v))
  let eight_x = (ops.mul)((ops.from_int)(8), x)
  let square = (ops.mul)(eight_x, eight_x)
  // The terms are carried as a ratio to the one before, not rebuilt from
  // factorials: a hundred terms of `(2m)!` run past what a double holds long
  // before the series is done, and `inf / inf` is a NaN rather than a term.
  let mut p = ops.one
  let mut q = (ops.div)((ops.sub)(mu, ops.one), eight_x)
  let mut term_p = (ops.neg)(
    (ops.div)(
      (ops.mul)((ops.sub)(mu, ops.one), (ops.sub)(mu, (ops.from_int)(9))),
      (ops.mul)(two, square),
    ),
  )
  let mut previous_size = (ops.abs)(term_p)
  let mut term_q = (ops.div)(
    (ops.neg)(
      (ops.mul)(
        (ops.mul)(
          (ops.sub)(mu, (ops.from_int)(1)),
          (ops.sub)(mu, (ops.from_int)(9)),
        ),
        (ops.sub)(mu, (ops.from_int)(25)),
      ),
    ),
    (ops.mul)((ops.from_int)(6), (ops.mul)(eight_x, square)),
  )
  let mut m : Int32 = 1
  while m <= 200 {
    if m > 1 {
      // `P` gains the factors `(μ - (4m-3)²)(μ - (4m-1)²)` over `(2m-1)(2m)(8x)²`.
      let low = (ops.from_int)(4 * m - 3)
      let high = (ops.from_int)(4 * m - 1)
      let ratio = (ops.div)(
        (ops.mul)(
          (ops.sub)(mu, (ops.mul)(low, low)),
          (ops.sub)(mu, (ops.mul)(high, high)),
        ),
        (ops.mul)(
          (ops.mul)((ops.from_int)(2 * m - 1), (ops.from_int)(2 * m)),
          square,
        ),
      )
      term_p = (ops.neg)((ops.mul)(term_p, ratio))
      // `Q` gains `(μ - (4m-1)²)(μ - (4m+1)²)` over `(2m)(2m+1)(8x)²`.
      let next = (ops.from_int)(4 * m + 1)
      let ratio_q = (ops.div)(
        (ops.mul)(
          (ops.sub)(mu, (ops.mul)(high, high)),
          (ops.sub)(mu, (ops.mul)(next, next)),
        ),
        (ops.mul)(
          (ops.mul)((ops.from_int)(2 * m), (ops.from_int)(2 * m + 1)),
          square,
        ),
      )
      term_q = (ops.neg)((ops.mul)(term_q, ratio_q))
    }
    // The series is asymptotic: once a term stops shrinking it is time to stop.
    if m > 1 && (ops.lt)(previous_size, (ops.abs)(term_p)) {
      break
    }
    p = (ops.add)(p, term_p)
    q = (ops.add)(q, term_q)
    previous_size = (ops.abs)(term_p)
    m = m + 1
  }
  let pi = ops.pi
  let scale = (ops.sqrt)((ops.div)(two, (ops.mul)(pi, x)))
  let chi = (ops.sub)(
    x,
    (ops.mul)((ops.add)((ops.div)(v, two), (ops.div)(ops.one, four)), pi),
  )
  let cosine = (ops.cos)(chi)
  let sine = (ops.sin)(chi)
  let j = (ops.mul)(scale, (ops.sub)((ops.mul)(cosine, p), (ops.mul)(sine, q)))
  let y = (ops.mul)(scale, (ops.add)((ops.mul)(sine, p), (ops.mul)(cosine, q)))
  (j, y)
}

///|
/// `I_v` and `K_v` from `e^x/sqrt(2πx)` and `sqrt(π/(2x)) e^-x` times the
/// expansion in `a_m(μ)/(m! (8x)^m)`, which differs from the `P`/`Q` pair only
/// in how the rising product is stepped.
fn[T] bessel_ik_asymptotic(v : T, x : T, ops : Ops[T]) -> (T, T) {
  let four = (ops.from_int)(4)
  let two = (ops.from_int)(2)
  let mu = (ops.mul)(four, (ops.mul)(v, v))
  let eight_x = (ops.mul)((ops.from_int)(8), x)
  // The same ratio form as `J` and `Y`: `a_m / (m! (8x)^m)` is one multiplication
  // from the term before it, which keeps the intermediates the size of the terms
  // instead of the size of the factorial.
  let mut sum = ops.one
  let mut term = (ops.neg)((ops.div)((ops.sub)(mu, ops.one), eight_x))
  let mut previous = (ops.abs)(term)
  let mut k_sum = ops.one
  let mut k_term = (ops.div)((ops.sub)(mu, ops.one), eight_x)
  let mut m : Int32 = 1
  while m <= 200 {
    if m > 1 {
      let factor = (ops.from_int)(2 * m - 1)
      let ratio = (ops.neg)(
        (ops.div)(
          (ops.sub)(mu, (ops.mul)(factor, factor)),
          (ops.mul)((ops.from_int)(m), eight_x),
        ),
      )
      term = (ops.mul)(term, ratio)
      k_term = (ops.mul)(k_term, (ops.neg)(ratio))
    }
    // The series is asymptotic: once a term stops shrinking it is time to stop.
    if m > 1 && (ops.lt)(previous, (ops.abs)(term)) {
      break
    }
    sum = (ops.add)(sum, term)
    k_sum = (ops.add)(k_sum, k_term)
    previous = (ops.abs)(term)
    m = m + 1
  }
  let pi = ops.pi
  let growth = (ops.div)(
    (ops.exp)(x),
    (ops.sqrt)((ops.mul)((ops.mul)(two, pi), x)),
  )
  let decay = (ops.mul)(
    (ops.sqrt)((ops.div)(pi, (ops.mul)(two, x))),
    (ops.exp)((ops.neg)(x)),
  )
  ((ops.mul)(growth, sum), (ops.mul)(decay, k_sum))
}

///|
/// A base raised to a whole exponent, by repeated squaring.
///
/// The polynomial pieces of `Y_n` and `K_n` raise a negative base to a whole
/// power, which `Ops::pow` does not promise to do — it is `exp(y ln x)` and
/// wants a positive base. An integer exponent needs neither.
fn[T] power_of(base : T, exponent : Int32, ops : Ops[T]) -> T {
  if exponent == 0 {
    return ops.one
  }
  let magnitude = if exponent < 0 { 0 - exponent } else { exponent }
  let mut result = ops.one
  let mut square = base
  let mut remaining = magnitude
  while remaining > 0 {
    if remaining % 2 == 1 {
      result = (ops.mul)(result, square)
    }
    square = (ops.mul)(square, square)
    remaining = remaining / 2
  }
  if exponent < 0 {
    (ops.div)(ops.one, result)
  } else {
    result
  }
}

///|
/// `n!`, by the only way that works for a value the width cannot hold as a
/// double: one multiplication at a time.
fn[T] factorial(n : Int32, ops : Ops[T]) -> T {
  let mut value = ops.one
  let mut i : Int32 = 2
  while i <= n {
    value = (ops.mul)(value, (ops.from_int)(i))
    i = i + 1
  }
  value
}
