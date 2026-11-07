// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions. Each is its power series, which is all a
// hypergeometric is, plus the transformation that keeps the series inside the
// radius where it converges quickly: `1F1` moves a negative argument to a
// positive one by Kummer, and `2F1` moves an argument past a half to `1 - x` by
// the linear transformation.
//
// Both also report the largest magnitude the run formed beside the value. That
// pair is what lets a double-precision caller decide whether the double it holds
// is worth returning, and it is the whole of the escalation story: a sum whose
// terms ran `10^d` past its result kept `width - d` digits of that result, and a
// caller with a wider type can spend `d` more digits and round once.

///|
/// The confluent limit `0F1(; b; x) = Σ x^k / ((b)_k k!)`.
pub fn[T] hyper0f1(b : T, x : T, ops : Ops[T]) -> T {
  let hold = settle([b], ops)
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
    if k > hold &&
      (ops.lt)((ops.abs)(term), (ops.mul)((ops.abs)(sum), tiny(ops))) {
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
  hyper1f1_scaled(a, b, x, ops).0
}

///|
/// `1F1` together with the largest term the sum formed.
///
/// The pair is what a caller needs to judge the answer: a sum whose terms ran
/// past the result by `10^d` kept `width - d` digits of it, and a caller with a
/// wider type available can spend them. The double-precision face does exactly
/// that — see `special/hypergeom.mbt`.
pub fn[T] hyper1f1_scaled(a : T, b : T, x : T, ops : Ops[T]) -> (T, T) {
  // A series whose numerator ends before its denominator's own pole is a
  // polynomial and is summed as one; without that, a `b` at a non-positive
  // integer has no value here, and the sum would divide by the zero.
  let ends = last_term(a, ops)
  let pole = last_term(b, ops)
  if pole >= 0 && (ends < 0 || ends > pole) {
    abort(
      "hyper1f1: the second parameter is a non-positive integer and the series does not end before it",
    )
  }
  // The switch is where the series would start to cancel; below it the direct
  // sum is already the better of the two. Kummer's transformation moves a
  // negative argument to a positive one, but it is an identity of the infinite
  // series: at a `b` of a non-positive integer the series ends early and the two
  // sides part company, so that case is summed where it stands.
  let threshold = (ops.neg)((ops.from_int)(4))
  if (ops.lt)(x, threshold) && pole < 0 {
    // The prefactor rides on the first term rather than multiplying the sum, for
    // the reason `2F1` gives: `e^-1043` is below what a narrow width holds while
    // the answer is of order one, and a run that multiplies afterwards loses it.
    let scale = (ops.exp)(x)
    return with_scope(
      hyper1f1_series(
        (ops.sub)(b, a),
        b,
        (ops.neg)(x),
        last_term((ops.sub)(b, a), ops),
        scale,
        ops,
      ),
      scale,
      ops,
    )
  }
  hyper1f1_series(a, b, x, ends, ops.one, ops)
}

///|
/// The `1F1` series, without the transformation, with its largest term.
fn[T] hyper1f1_series(
  a : T,
  b : T,
  x : T,
  ends : Int32,
  start : T,
  ops : Ops[T],
) -> (T, T) {
  // A numerator at a non-positive integer ends the series at that count, and the
  // count is also the point past which the convergence test may look: before it
  // the terms are still the ones the sum is made of.
  let stop = if ends >= 0 { ends + 2 } else { 5000 }
  let hold = if ends >= 0 { stop } else { settle([a, b], ops) }
  let mut term = start
  let mut sum = start
  let mut largest = (ops.abs)(start)
  let mut k : Int32 = 0
  while k < stop {
    k = k + 1
    let numerator = (ops.mul)((ops.add)(a, (ops.from_int)(k - 1)), x)
    let denominator = (ops.mul)(
      (ops.add)(b, (ops.from_int)(k - 1)),
      (ops.from_int)(k),
    )
    term = (ops.mul)(term, (ops.div)(numerator, denominator))
    sum = (ops.add)(sum, term)
    let size = (ops.abs)(term)
    if (ops.lt)(largest, size) {
      largest = size
    }
    if (ops.is_zero)(term) {
      break
    }
    if k > hold && (ops.lt)(size, (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  (sum, largest)
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x) = Σ (a)_k (b)_k / ((c)_k k!) x^k`,
/// for `|x| < 1`.
///
/// Three representations cover the unit interval, and the argument decides which:
///
/// - a negative one takes Pfaff's transformation
///   `2F1(a,b;c;x) = (1-x)^(-a) 2F1(a,c-b;c;x/(x-1))`, which halves it and
///   leaves a positive one;
/// - up to a half the series is summed where it stands, at a ratio no larger
///   than a half;
/// - past a half the linear transformation around one is used,
///   `2F1(a,b;c;x) = Γ(c)Γ(c-a-b)/(Γ(c-a)Γ(c-b)) 2F1(a,b;a+b-c+1;1-x)
///    + (1-x)^(c-a-b) Γ(c)Γ(a+b-c)/(Γ(a)Γ(b)) 2F1(c-a,c-b;c-a-b+1;1-x)`,
///   whose two series run on `1 - x`.
///
/// Every scale is folded into the first term of the series it multiplies rather
/// than applied afterwards. That is not a detail: with parameters of order a
/// hundred a scale is `10^-60` while the terms of the series it multiplies reach
/// `10^55`, and a type that has to hold both at once needs a hundred and thirty
/// digits before it can add them. Multiplying as the series runs keeps every
/// partial sum at the size of the answer, and leaves only the cancellation the
/// answer itself is made of.
pub fn[T] hyper2f1(a : T, b : T, c : T, x : T, ops : Ops[T]) -> T {
  hyper2f1_scaled(a, b, c, x, ops).0
}

///|
/// `2F1` together with the largest magnitude any term of the run reached.
pub fn[T] hyper2f1_scaled(a : T, b : T, c : T, x : T, ops : Ops[T]) -> (T, T) {
  let one = ops.one
  let zero = ops.zero
  if (ops.le)(one, (ops.abs)(x)) {
    abort("hyper2f1: the argument must lie inside -1 .. 1")
  }
  // A numerator that is a non-positive integer ends the series, and a `c` at one
  // of its own poles does not matter then: the sum stops before the denominator
  // it would have divided by reaches zero.
  let ends = last_term(a, ops)
  let from_b = last_term(b, ops)
  let stop = if ends < 0 {
    from_b
  } else if from_b < 0 {
    ends
  } else if ends < from_b {
    ends
  } else {
    from_b
  }
  let pole = last_term(c, ops)
  if pole >= 0 && (stop < 0 || stop > pole) {
    abort(
      "hyper2f1: the third parameter is a non-positive integer and the series does not end before it",
    )
  }
  if stop >= 0 {
    return hyper2f1_series(a, b, c, x, stop + 2, one, ops)
  }
  if (ops.lt)(x, zero) {
    // Pfaff. The argument becomes `x/(x-1)`, inside `-1/2 .. 0`, and the
    // prefactor is folded into the first term of the sum.
    let argument = (ops.div)(x, (ops.sub)(x, one))
    let exponent = (ops.mul)((ops.neg)(a), (ops.ln)((ops.sub)(one, x)))
    return scaled_series(
      a,
      (ops.sub)(c, b),
      c,
      argument,
      (ops.exp)(exponent),
      20000,
      ops,
    )
  }
  let half = (ops.from_decimal)("0.5")
  if (ops.le)(x, half) {
    return hyper2f1_series(a, b, c, x, 20000, one, ops)
  }
  let gap = (ops.sub)((ops.sub)(c, a), b)
  // The connection formula at one, and the one the argument is near. When
  // `c - a - b` is a non-negative integer the coefficient of the second power in
  // that formula collapses to zero and leaves a logarithm in its place: the two
  // powers are linearly dependent there, and the series at the argument answers
  // the case slowly — like `x^k`, so a run that reaches the answer needs terms
  // on the order of `1 / (1 - x)`, which walks off as the argument closes on one.
  // The logarithmic form answers it instead: a terminating sum on `1 - x` plus
  // one power of `1 - x` against its own logarithm, which stays bounded for every
  // argument inside the interval.
  let gap_int = gap_to_int(gap, ops)
  if gap_int >= 0 {
    return hyper2f1_degenerate(a, b, c, x, gap_int, ops)
  }
  // A gamma factor at a pole is the same degeneracy seen from the other side, and
  // there is no logarithmic form for it: the series at the argument is the only
  // answer, and it is slow.
  let unusable = at_pole((ops.sub)(c, a), ops) || at_pole((ops.sub)(c, b), ops)
  if unusable {
    return hyper2f1_series(a, b, c, x, series_limit(x, ops), one, ops)
  }
  let near = (ops.sub)(one, x)
  let first_log = gamma_log(
    [(c, true), (gap, true), ((ops.sub)(c, a), false), ((ops.sub)(c, b), false)],
    ops,
  )
  let second_log = gamma_log(
    [(c, true), ((ops.neg)(gap), true), (a, false), (b, false)],
    ops,
  )
  // `(1-x)^(c-a-b)` and the gamma ratio are one exponent, not two factors: an
  // `exp` truncates the mantissa where it lands, so forming one is half the loss
  // of forming two.
  let second_exponent = (ops.add)(second_log.0, (ops.mul)(gap, (ops.ln)(near)))
  let first = scaled_series(
    a,
    b,
    (ops.sub)(one, gap),
    near,
    (ops.mul)((ops.exp)(first_log.0), first_log.1),
    20000,
    ops,
  )
  let second = scaled_series(
    (ops.sub)(c, a),
    (ops.sub)(c, b),
    (ops.add)(gap, one),
    near,
    (ops.mul)((ops.exp)(second_exponent), second_log.1),
    20000,
    ops,
  )
  let value = (ops.add)(first.0, second.0)
  let mut largest = (ops.abs)(value)
  for candidate in [first.1, second.1] {
    if (ops.lt)(largest, candidate) {
      largest = candidate
    }
  }
  (value, largest)
}

///|
/// A `2F1` series whose every term is multiplied by `scale`, reporting the
/// largest term it reached.
///
/// The scale multiplies the first term and rides along, which is what keeps the
/// sum inside one dynamic range. It costs digits all the same: a scale below one
/// is held to `2^-bits` like everything else, so the sum carries the scale's own
/// relative error and that is the same as having multiplied a term as large as
/// the series itself. The largest term reported is therefore the larger of the
/// two readings — the scaled terms the run formed and the terms it would have
/// formed at unit scale — and a caller reading it sees the whole loss.
///
/// A scale that underflows to zero at this width takes the whole sum with it;
/// neither factor is zero mathematically, since a gamma at a pole and a zero
/// power were both turned away before this is reached, so the run reports a
/// largest term far above anything it formed and the caller widens.
fn[T] scaled_series(
  a : T,
  b : T,
  c : T,
  x : T,
  scale : T,
  stop : Int32,
  ops : Ops[T],
) -> (T, T) {
  with_scope(hyper2f1_series(a, b, c, x, stop, scale, ops), scale, ops)
}

///|
/// A run whose terms all carry `scale`, read back as a loss.
///
/// A scale below one is held to `2^-bits` like everything else, so the sum
/// carries the scale's own relative error, and that is the same as having
/// multiplied a term as large as the series itself would have been at unit
/// scale. The largest term reported is therefore the larger of the two readings.
/// A scale that underflowed to zero took the whole sum with it and is reported as
/// a loss as well — neither scale is zero mathematically, since a gamma at a
/// pole and a zero power were both turned away before this is reached.
fn[T] with_scope(pair : (T, T), scale : T, ops : Ops[T]) -> (T, T) {
  if (ops.is_zero)(scale) {
    return (ops.zero, (ops.from_decimal)("1e999"))
  }
  let size = (ops.abs)(scale)
  if (ops.lt)(ops.one, size) {
    return pair
  }
  (pair.0, (ops.div)(pair.1, size))
}

///|
/// The `2F1` series, from a first term that carries whatever multiplies the whole
/// sum, with the largest term it formed.
///
/// `stop` is the count of terms worth forming: an exact degree for a series a
/// non-positive integer ends, otherwise a ceiling that the convergence test is
/// expected to reach first.
fn[T] hyper2f1_series(
  a : T,
  b : T,
  c : T,
  x : T,
  stop : Int32,
  start : T,
  ops : Ops[T],
) -> (T, T) {
  let hold = settle([a, b, c], ops)
  let mut term = start
  let mut sum = start
  let mut largest = (ops.abs)(start)
  let mut k : Int32 = 0
  while k < stop {
    k = k + 1
    let index = (ops.from_int)(k - 1)
    let numerator = (ops.mul)(
      (ops.mul)((ops.add)(a, index), (ops.add)(b, index)),
      x,
    )
    let denominator = (ops.mul)((ops.add)(c, index), (ops.from_int)(k))
    term = (ops.mul)(term, (ops.div)(numerator, denominator))
    sum = (ops.add)(sum, term)
    let size = (ops.abs)(term)
    if (ops.lt)(largest, size) {
      largest = size
    }
    if (ops.is_zero)(term) {
      break
    }
    if k > hold && (ops.lt)(size, (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
  }
  (sum, largest)
}

///|
/// The degenerate Gauss hypergeometric, for `c - a - b = n` a non-negative
/// integer, from DLMF 15.4.20.
///
/// When the gap `c - a - b` is a non-negative integer the two powers of the
/// connection formula at one are linearly dependent and its second coefficient
/// vanishes, leaving a logarithm in its place. The series at the argument
/// answers the case slowly, like `x^k`, so a run that reaches the answer needs
/// terms on the order of `1 / (1 - x)`, which walks off as the argument closes
/// on one. This form answers it instead: with `c = a + b + n`, the value is a
/// terminating sum of length `n` on `1 - x` plus one power of `1 - x` against a
/// convergent series that carries the logarithm, and both stay bounded for
/// every argument inside the unit interval.
///
/// ```text
/// 2F1(a, b; a + b + n; x) = S1(a, b, n; 1 - x)
///   + Γ(c) / (Γ(n + 1) Γ(a) Γ(b)) (1 - x)^n
///     Σ_{m ≥ 0} (a + n)_m (b + n)_m / ((n + 1)_m m!) (1 - x)^m
///     · ((-1)^(n + 1) ln(1 - x) + (-1)^n ψ_m)
/// where S1 is a terminating sum of `n` terms and
/// ψ_m = ψ(n + 1 + m) + ψ(m + 1) - ψ(a + n + m) - ψ(b + n + m).
/// ```
fn[T] hyper2f1_degenerate(
  a : T,
  b : T,
  c : T,
  x : T,
  n : Int32,
  ops : Ops[T],
) -> (T, T) {
  let one = ops.one
  let zero = ops.zero
  let near = (ops.sub)(one, x)
  // `A = Γ(c) Γ(n) / (Γ(a + n) Γ(b + n))` carries the first (length-`n`) sum.
  // It is a ratio of gammas formed as a logarithm with its sign, because the
  // parameters this is called for reach into the hundreds, where a single
  // factor is past what a narrow width holds while the ratio is unremarkable.
  // For `n = 0` the first sum is empty and the whole answer is the logarithmic
  // part below, so `A` is not formed at all.
  let mut first : T = if n == 0 {
    zero
  } else {
    let log_a = gamma_log(
      [
        (c, true),
        ((ops.from_int)(n), true),
        ((ops.add)(a, (ops.from_int)(n)), false),
        ((ops.add)(b, (ops.from_int)(n)), false),
      ],
      ops,
    )
    (ops.mul)((ops.exp)(log_a.0), log_a.1)
  }
  let mut largest = (ops.abs)(first)
  // The rest of the first sum is a recurrence: the `k`-th term (counting from
  // zero) is the previous one times `- (1 - x)(a + k - 1)(b + k - 1) /
  // ((n - k) k)`, so a run over `k = 1 .. n - 1` reaches the whole sum, which
  // is `n` terms long.
  let mut k : Int32 = 1
  let mut term = first
  while k < n {
    let index = (ops.from_int)(k - 1)
    let numerator = (ops.mul)(
      (ops.mul)((ops.add)(a, index), (ops.add)(b, index)),
      near,
    )
    let denominator = (ops.mul)((ops.from_int)(n - k), (ops.from_int)(k))
    term = (ops.mul)(term, (ops.neg)((ops.div)(numerator, denominator)))
    first = (ops.add)(first, term)
    let size = (ops.abs)(term)
    if (ops.lt)(largest, size) {
      largest = size
    }
    k = k + 1
  }
  // The logarithmic part: `Γ(c) / (Γ(n + 1) Γ(a) Γ(b)) (1 - x)^n` times a
  // convergent series on `1 - x`. Its argument `1 - x` is inside `0 .. 1/2`
  // here (this path is reached only past a half), so the series converges like
  // a half to a power and the run needs few terms.
  let log_coeff = gamma_log(
    [(c, true), ((ops.from_int)(n + 1), false), (a, false), (b, false)],
    ops,
  )
  let coeff = (ops.mul)((ops.exp)(log_coeff.0), log_coeff.1)
  let sign_even = if n % 2 == 0 { one } else { (ops.neg)(one) }
  let sign_odd = (ops.neg)(sign_even)
  let log_t = (ops.ln)(near)
  let hold = settle([a, b, (ops.from_int)(n + 1)], ops)
  let mut second_sum = zero
  let mut am = one
  let mut m : Int32 = 0
  while m < 100000 {
    let nm = (ops.add)((ops.from_int)(n), (ops.from_int)(m))
    let psi = (ops.sub)(
      (ops.add)(
        digamma((ops.from_int)(n + m + 1), ops),
        digamma((ops.from_int)(m + 1), ops),
      ),
      (ops.add)(digamma((ops.add)(a, nm), ops), digamma((ops.add)(b, nm), ops)),
    )
    let inner = (ops.add)((ops.mul)(sign_odd, log_t), (ops.mul)(sign_even, psi))
    second_sum = (ops.add)(second_sum, (ops.mul)(am, inner))
    let size = (ops.abs)(am)
    if (ops.lt)(largest, size) {
      largest = size
    }
    if m > hold && (ops.lt)(size, (ops.mul)((ops.abs)(second_sum), tiny(ops))) {
      break
    }
    let denominator = (ops.mul)(
      (ops.add)((ops.from_int)(n + 1), (ops.from_int)(m)),
      (ops.from_int)(m + 1),
    )
    let numerator = (ops.mul)(
      (ops.mul)((ops.add)(a, nm), (ops.add)(b, nm)),
      near,
    )
    am = (ops.mul)(am, (ops.div)(numerator, denominator))
    m = m + 1
  }
  let power_n = (ops.pow)(near, (ops.from_int)(n))
  let second = (ops.mul)(coeff, (ops.mul)(power_n, second_sum))
  let value = (ops.add)(first, second)
  // The answer is the difference of the two parts, so a caller judging it also
  // reads how large each part ran; the larger of the three is the whole loss.
  for candidate in [(ops.abs)(first), (ops.abs)(second)] {
    if (ops.lt)(largest, candidate) {
      largest = candidate
    }
  }
  (value, largest)
}

///|
/// The term count below which the convergence test may not fire.
///
/// A term is a running product, and a parameter that is negative makes that
/// product pass through zero at the parameter's own index: the terms fall away
/// and then come back. `2F1(2.9, 12.4; -60.6; 0.32)` is down to `1e-20` at
/// forty terms and up to `1e11` at sixty, so stopping on the first small term
/// would throw away everything the series has to add after it. The sum is
/// therefore held open until it is past every such crossing, which is where the
/// last of the parameters reaches its own zero.
fn[T] settle(parameters : Array[T], ops : Ops[T]) -> Int32 {
  let mut count : Int32 = 0
  for parameter in parameters {
    let value = (ops.to_double)(parameter)
    if value < 0.0 && value > -1.0e6 {
      let crossing = @math.ceil(0.0 - value).to_int() + 1
      if count < crossing {
        count = crossing
      }
    }
  }
  count
}

///|
/// The largest term count a series may take, for an argument that decides how
/// slowly it converges.
///
/// A `2F1` series at `x` close to one converges like `x^k`, so the count it needs
/// grows as `1/(1-x)`. That only matters on the degenerate path, where the
/// transformation around one is unavailable and the series has to run where it
/// is; the ceiling below keeps such a call finite rather than letting it walk
/// off.
fn[T] series_limit(x : T, ops : Ops[T]) -> Int32 {
  let slack = 1.0 - (ops.to_double)((ops.abs)(x))
  if slack <= 0.0 {
    return 200000
  }
  let wanted_terms = Double::from_int(ops.digits) * 60.0 / slack
  if wanted_terms > 200000.0 {
    200000
  } else if wanted_terms < 20000.0 {
    20000
  } else {
    wanted_terms.to_int()
  }
}

///|
/// `-n` when `x` is the non-positive integer `-n`, and `-1` when it is not.
///
/// The series of a hypergeometric whose numerator parameter is such an integer
/// ends at `n`, which is what turns an infinite sum into a polynomial and lets a
/// `c` at one of its own poles be answered rather than refused.
fn[T] last_term(x : T, ops : Ops[T]) -> Int32 {
  let value = (ops.to_double)(x)
  if value > 0.0 || value < -1.0e15 || value != @math.floor(value) {
    return -1
  }
  (0.0 - value).to_int()
}

///|
/// `x` as a non-negative integer, or `-1` when it is not one.
///
/// The degenerate form of `2F1` is indexed by this: the connection formula at
/// one carries a logarithm exactly when `c - a - b` is a non-negative integer,
/// and the logarithm sits at that count. The value is read as a double, which is
/// enough to name the integer and is what `to_double` is for.
///
/// The gap is *computed*, and a double `c - a - b` that is mathematically an
/// integer comes back within a unit in the last place of it — `4.4 - 1.3 - 2.1`
/// is `0.9999999999999998`, not `1.0`. The comparison is therefore to the nearest
/// integer at the width's own relative tolerance rather than to the exact value:
/// a gap that is not within a few parts in a billion of an integer is genuinely
/// not one, and the two-power form that the tolerance would otherwise be routed
/// away from is the one that diverges at the near-integer gap it sits beside.
fn[T] gap_to_int(x : T, ops : Ops[T]) -> Int32 {
  let value = (ops.to_double)(x)
  if value < 0.0 || value > 1.0e15 {
    return -1
  }
  let nearest = @math.round(value)
  let scale = if value.abs() > 1.0 { value.abs() } else { 1.0 }
  let tolerance = 1.0e-9 * scale
  if (value - nearest).abs() > tolerance {
    return -1
  }
  nearest.to_int()
}

///|
/// Whether a gamma factor in the transformation stands at one of its poles.
///
/// A pole is a zero of the reciprocal, and the ratio the factor is part of is
/// then either nothing or a limit that has to be taken; the series where the
/// argument stands answers this case without either.
fn[T] at_pole(x : T, ops : Ops[T]) -> Bool {
  let value = (ops.to_double)(x)
  value <= 0.0 && value > -1.0e15 && value == @math.floor(value)
}

///|
/// A product of gamma factors, as the logarithm of its magnitude and its sign.
///
/// Multiplying the factors directly is not an option at the parameters this is
/// called with: with three parameters of order a hundred the argument of one
/// gamma reaches two hundred, and `Γ(200)` is past `10^370` — a double holds no
/// such number, while the ratio of two of them is unremarkable. The logarithm
/// costs the digits its own magnitude carries, which is why the caller that
/// needs the last few escalates rather than trusting this at double width.
///
/// The exponent comes back beside the sign rather than inside a value because
/// the caller has a second exponent to add to it before exponentiating, and
/// every `exp` truncates where it lands.
fn[T] gamma_log(factors : Array[(T, Bool)], ops : Ops[T]) -> (T, T) {
  let mut log = ops.zero
  let mut sign = ops.one
  for entry in factors {
    let (x, numerator) = entry
    if numerator {
      log = (ops.add)(log, lgamma(x, ops))
    } else {
      log = (ops.sub)(log, lgamma(x, ops))
    }
    sign = (ops.mul)(sign, gamma_sign(x, ops))
  }
  (log, sign)
}

///|
/// The sign of `Γ(x)` as `+1` or `-1`.
///
/// `Γ` alternates in sign between consecutive poles below zero and is positive
/// above them, so the count of unit intervals between `x` and the origin gives
/// the parity. The value is read as a double, which is enough to count intervals
/// and is what `to_double` is for.
fn[T] gamma_sign(x : T, ops : Ops[T]) -> T {
  let value = (ops.to_double)(x)
  if value > 0.0 {
    return ops.one
  }
  let crossed = @math.ceil(0.0 - value).to_int()
  if crossed % 2 == 1 {
    (ops.neg)(ops.one)
  } else {
    ops.one
  }
}
