// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The large-parameter side of Kummer's confluent hypergeometric `1F1`.
//
// The plain series answers the parameters the table reaches without a uniform
// method, but once `a`, `b` and `x` run into the hundreds and millions the
// series terms grow far past the result and cancel, and the width is not wide
// enough to hold them: the run walks off to the ceiling rather than to the
// value. This file answers that region with the methods that do, each written
// once against `Ops[T]` like the rest of the package, and the routing in
// `hypergeom` says which for a point.
//
// Every method reports the value together with the largest magnitude it formed
// beside it, the same contract the series reports. That pair is what the
// double-precision face reads to decide whether its double is worth returning:
// a factor that underflowed to zero on the way — `e^-1043` at a width that
// cannot hold it — takes the whole value with it, and is reported as a loss so
// that the caller widens and the run is redone at a width that holds the
// factor. At the wide precision the escalation reaches, a value a double cannot
// hold is held easily, so the factors are formed directly and only the width of
// the running sum has to be earned.

///|
/// Whether a parameter sits on a non-positive integer, where the series of a
/// `1F1` whose numerator is such an integer ends — and the reflection and the
/// uniform methods are no longer identities, so the series where the argument
/// stands is the answer. The value is read as a double, which is enough to name
/// the integer and is what `to_double` is for.
fn[T] nonpos_int(x : T, ops : Ops[T]) -> Bool {
  let value = (ops.to_double)(x)
  value <= 0.0 && value > -1.0e15 && value == @math.floor(value)
}

///|
/// The uniform dispatcher for the large-parameter region: the routing that
/// chooses a method for a point, mirroring how the methods split the plane. It
/// is reached only for parameters well past the ones the plain series answers
/// (the caller gates it), and it falls back to the series — run at whatever
/// width the caller gave it — for the points it has no method for yet, so a
/// missing method degrades to the width's best effort rather than to a wrong
/// answer.
pub fn[T] hyper1f1_uniform(a : T, b : T, x : T, ops : Ops[T]) -> (T, T) {
  let one = ops.one
  let zero = ops.zero
  let bma = (ops.sub)(b, a)
  // The closed forms that are answers at any parameter size.
  if (ops.is_zero)(x) || (ops.is_zero)(a) {
    return (one, one)
  }
  if (ops.is_zero)(bma) {
    return ((ops.exp)(x), (ops.exp)(x))
  }
  // A numerator under a hundredth against a `b` past one. The terms fall a
  // factor `|a| (|x|/b)^k / k` apart once the numerator's own product has
  // settled, so the sum is a few dozen terms when the argument is small against
  // `b` and thousands when it is not — either way a count this can work out, and
  // the reflection in particular would carry a `e^x` that a narrow width cannot
  // hold. Note the `(k-1)!` of `(a)_k` cancels only one `k!`: with `|x|` past
  // `b` the terms climb to `10^122` before they turn over, and the answer with
  // them.
  if (ops.lt)((ops.abs)(a), (ops.from_decimal)("0.01")) && (ops.lt)(one, b) {
    let count = series_count(a, b, x, ops)
    if count > 0 {
      return hyper1f1_terms(a, b, x, count, count, one, ops)
    }
  }
  if (ops.is_zero)((ops.sub)(bma, (ops.neg)(one))) {
    if (ops.lt)(a, zero) {
      let whole = (ops.to_double)(a)
      if whole == @math.ceil(whole) && (ops.lt)(a, (ops.neg)(one)) {
        // A negative integer numerator ends the series, so sum it as the
        // polynomial it is rather than take the closed form, which the pole
        // beside it would divide by.
        return hyper1f1_series(a, b, x, last_term(a, ops), one, ops)
      }
    }
    let value = (ops.div)((ops.mul)((ops.add)(b, x), (ops.exp)(x)), b)
    return (value, (ops.abs)(value))
  }
  // A numerator small against the denominator at a negative argument. The terms
  // fall a factor about `|a||x|/(|b|k)` apart, so the sum settles in a few
  // hundred terms whatever the argument is, and nothing is formed on its own to
  // underflow. It is checked before the asymptotic, which also accepts these
  // points and answers them from the wrong side: its series is in powers of
  // `1/z` and needs `a` far smaller than this to be the better tool.
  if (ops.lt)(x, zero) &&
    (ops.lt)((ops.mul)((ops.abs)(a), (ops.from_int)(50)), (ops.abs)(b)) {
    let count = series_count(a, b, x, ops)
    if count > 0 {
      return hyper1f1_terms(a, b, x, count, count, one, ops)
    }
  }
  // The large-argument asymptotic, where the argument dominates both
  // parameters: a small `a` against a `z` of four hundred or more.
  if is_large_z_region(a, b, x, ops) {
    return hyper1f1_asym_z(a, b, x, ops)
  }
  // The uniform Bessel expansion, A&S 13.3.6, for a negative argument where `a`
  // is tiny against `b`: the argument is moved to a positive one and the `e^x`
  // of the reflection rides the first term. It is checked before the rational
  // approximation, which would also accept the point, because its tenth-term
  // ratio is the better tool where the Bessel terms shrink fast.
  if is_1336_region(a, b, x, ops) {
    let scale = (ops.exp)(x)
    let inner = hyper1f1_bessel_i(bma, b, (ops.neg)(x), a, ops)
    let value = (ops.mul)(scale, inner.0)
    let mut largest = (ops.abs)(scale)
    if (ops.lt)(largest, (ops.abs)(value)) {
      largest = (ops.abs)(value)
    }
    // The expansion's own worst term rides the same `e^x`, and it is the one the
    // caller has to hear about: a series that climbed past its answer inside the
    // bracket lost that many digits of it, whatever the bracket multiplied out to.
    let carried = (ops.mul)((ops.abs)(scale), inner.1)
    if (ops.lt)(largest, carried) {
      largest = carried
    }
    return (value, largest)
  }
  // The rational approximation, where its continued fraction converges: the
  // argument small against `b`, the first term of order one or smaller, and
  // `a` not so small as to be swallowed in the first step (or `b` deep enough
  // that the small `a` does not matter).
  if (ops.lt)(
      (ops.abs)((ops.div)((ops.mul)(a, x), b)),
      (ops.from_decimal)("3.5"),
    ) &&
    (ops.lt)((ops.mul)((ops.abs)(x), (ops.from_int)(100)), (ops.abs)(b)) &&
    (
      (ops.lt)((ops.abs)(a), (ops.from_decimal)("0.01")) == false ||
      (ops.lt)(b, (ops.from_int)(-5))
    ) {
    return hyper1f1_rational(a, b, x, ops)
  }
  // A negative `a` against a positive `b` at a negative argument: `(a)_k` and
  // `x^k` take their signs together at every `k`, so every term of the series is
  // positive. Nothing cancels and the running sum never passes the answer, so
  // no width is spent on digits that are then thrown away; the only question is
  // how far the terms climb before they turn over, and that is a count this can
  // work out. The reflection below would answer the same point by moving it to
  // an `a` and a `b` within a percent of each other at a positive argument,
  // where the series climbs to the argument itself — an order of magnitude
  // further — before it comes back down.
  if (ops.lt)(a, zero) && (ops.lt)(zero, b) && (ops.lt)(x, zero) {
    let count = series_count(a, b, x, ops)
    if count > 0 {
      return hyper1f1_terms(a, b, x, count, count, one, ops)
    }
  }
  // A negative argument is the trouble: Kummer's relation
  // `1F1(a;b;z) = e^z 1F1(b-a; b; -z)` brings it to a positive one, and the
  // reflected point is answered by the same routing.
  if needs_kummer(a, b, x, ops) {
    if nonpos_int(b, ops) {
      // At a `b` of a non-positive integer the relation is no longer an
      // identity: the series ends before the reflection's pole, so it is summed
      // where it stands.
      return hyper1f1_series(a, b, x, last_term(a, ops), one, ops)
    }
    let scale = (ops.exp)(x)
    // A `e^x` that underflowed to zero at this width took the value with it:
    // the true answer is small but not zero, and the run here cannot say how
    // small, so report a loss and let the caller widen rather than return zero.
    if (ops.is_zero)(scale) && (ops.lt)(x, (ops.neg)((ops.from_int)(50))) {
      return (zero, (ops.from_decimal)("1e999"))
    }
    let inner = hyper1f1_uniform((ops.sub)(b, a), b, (ops.neg)(x), ops)
    let value = (ops.mul)(scale, inner.0)
    let mut largest = (ops.abs)(scale)
    if (ops.lt)(largest, (ops.abs)(value)) {
      largest = (ops.abs)(value)
    }
    // The reflected run's own worst term rides the same `e^x`. Reporting only the
    // bracket would say the reflection kept every digit when the sum inside it
    // kept none, and the caller would never be told to widen.
    let carried = (ops.mul)((ops.abs)(scale), inner.1)
    if (ops.lt)(largest, carried) {
      largest = carried
    }
    // The reflected point is not always the kinder one. Where `b - a` lands
    // within a percent of `b` at a positive argument, the series there climbs to
    // the argument itself before it turns over and comes back down to a value it
    // has long since passed: the run reports a factor far above its answer, and
    // what it carries of that answer is what the two ends had in common. The
    // point as it stands is often the cheaper sum. Both are tried when the
    // reflection comes back that way, and the one that kept more of its digits is
    // the one returned.
    if (ops.lt)((ops.mul)((ops.abs)(value), (ops.from_decimal)("1e6")), largest) {
      let count = series_count(a, b, x, ops)
      if count > 0 {
        let direct = hyper1f1_terms(a, b, x, count, count, one, ops)
        if (ops.lt)(
            (ops.mul)(direct.1, (ops.abs)(value)),
            (ops.mul)(largest, (ops.abs)(direct.0)),
          ) {
          return direct
        }
      }
    }
    return (value, largest)
  }
  // Otherwise the series, run at the width the caller gave it: at the wide
  // precision the escalation reaches, its terms are held rather than
  // overflowed, and this is the best effort for the points no uniform method
  // has been written for yet. It is given the count its own ratio walk asks for
  // rather than the five-thousand borrow of a series that has not settled: a
  // point with `a` within a percent of `b` at a large positive argument climbs to
  // the argument itself before it turns over, and five thousand terms stop it
  // half way up.
  let ends = last_term(a, ops)
  let reach = series_count(a, b, x, ops)
  let stop = if reach > 0 { reach } else { 5000 }
  // A run whose term count this worked out has already looked past the peak, so
  // the convergence test may look from there; a terminating polynomial must not
  // be tested before its own end.
  let hold = if ends >= 0 || reach > 0 { stop } else { settle([a, b], ops) }
  hyper1f1_terms(a, b, x, hold, stop, one, ops)
}

///|
/// How many terms of `1F1(a; b; x)` the plain series needs before its terms
/// have fallen below the running sum, or `-1` where that is further than a run
/// can afford and a uniform method is the better tool.
///
/// The terms turn over where `(|a| + k)|x|` crosses `(|b| + k)(k + 1)`, so the
/// count is read by walking the ratio of one term's magnitude to the next until
/// their product has fallen by the working width. Where the terms are of one
/// sign the sum is at least the largest of them, so that product bounds the
/// fraction of the answer still to come; where they are not, the sum tests
/// against its own running total as it goes, and this only has to say how far it
/// may run. Either way it is done in double, because a count is all it decides
/// and the width of the sum is not.
fn[T] series_count(a : T, b : T, x : T, ops : Ops[T]) -> Int32 {
  let ad = (ops.to_double)(a)
  let bd = (ops.to_double)(b)
  let xd = (ops.to_double)(x)
  if ad != ad || bd != bd || xd != xd || bd == 0.0 || xd == 0.0 {
    return -1
  }
  // The product of the term ratios is followed as a logarithm, and the ratio is
  // the one the sum itself uses rather than its magnitude: with `a` within a
  // percent of `b` at an argument of `10^4` the product climbs past `10^7000` on
  // the way to the peak, which a double holds as an infinity and would read as a
  // walk that never comes down; and with `b` negative the `(b)_k` passes through
  // the origin at `k = -b`, where the ratio shoots up and only a walk that goes
  // past it finds the count the sum needs.
  let floor_log = -2.302585092994046 * (ops.digits + 2).to_double()
  // A negative denominator has a zero of its own at `k = -b`, and the terms climb
  // again after it: `1F1(-835; -1252.5; 1043.8)` is `-1.9e294`, and its terms fall
  // by eighteen orders before the crossing and then rise to `10^292`. The walk
  // may not stop on that first dip, so it is not allowed to stop before the
  // crossing at all.
  let crossing = if bd < 0.0 { -bd + 2.0 } else { 0.0 }
  let mut count : Int32 = 0
  let mut climb = 0.0
  while count < 60000 {
    count = count + 1
    let k = count.to_double()
    let numerator = (ad + k - 1.0) * xd
    let denominator = (bd + k - 1.0) * k
    if denominator == 0.0 {
      return -1
    }
    if numerator != 0.0 {
      climb = climb + @math.ln(numerator.abs()) - @math.ln(denominator.abs())
    }
    if climb <= floor_log && k >= crossing {
      break
    }
  }
  count = count + 20
  if count > 60000 {
    return -1
  }
  count
}

///|
/// Whether the large-argument asymptotic is the tool for the point: the
/// argument large against the parameters, with a tenth-term ratio under a
/// three-quarters, and the `a` not a negative integer the series would want to
/// end at.
fn[T] is_large_z_region(a : T, b : T, x : T, ops : Ops[T]) -> Bool {
  let one = ops.one
  let half = (ops.from_decimal)("16")
  if (ops.lt)((ops.abs)(a), (ops.from_decimal)("0.001")) {
    return false
  }
  let xabs = (ops.abs)(x)
  if (ops.lt)(xabs, (ops.from_int)(40)) {
    return false
  }
  let bma = (ops.sub)(b, a)
  if (ops.lt)(bma, ops.zero) {
    let whole = (ops.to_double)(bma)
    if whole <= 0.0 && whole == @math.floor(whole) {
      return false
    }
  }
  if (ops.lt)(x, ops.zero) {
    let a1 = (ops.sub)(one, bma)
    let product = (ops.mul)(a1, a)
    if (ops.lt)(product, ops.zero) &&
      (ops.lt)((ops.div)(product, x), (ops.from_decimal)("0.5")) {
      return false
    }
    let ratio = (ops.div)(
      (ops.mul)((ops.add)(a1, half), (ops.add)(a, half)),
      (ops.mul)(half, x),
    )
    return (ops.lt)((ops.abs)(ratio), (ops.from_decimal)("0.7"))
  }
  // A negative-integer numerator or denominator is a point the approximation
  // does not cover.
  let ad = (ops.to_double)(a)
  if ad < 0.0 && ad == @math.floor(ad) {
    return false
  }
  let bd = (ops.to_double)(b)
  if bd < 0.0 && bd == @math.floor(bd) {
    return false
  }
  let oa = (ops.sub)(one, a)
  let ratio = (ops.div)(
    (ops.mul)((ops.add)(oa, half), (ops.add)(bma, half)),
    (ops.mul)(half, x),
  )
  if (ops.lt)((ops.abs)(ratio), (ops.from_decimal)("0.7")) {
    if (ops.lt)(oa, ops.zero) || (ops.lt)(bma, ops.zero) {
      let product = (ops.mul)(oa, bma)
      if (ops.lt)(product, ops.zero) &&
        (ops.lt)((ops.div)(product, x), (ops.from_decimal)("0.5")) {
        return false
      }
    }
    return true
  }
  false
}

///|
/// Whether Kummer's relation moves a negative argument to a positive one here:
/// past `-1` always, and between `-1` and `0` when the series at the argument
/// is divergent or its tenth term is of order one or smaller.
fn[T] needs_kummer(a : T, b : T, x : T, ops : Ops[T]) -> Bool {
  let one = ops.one
  let ten = (ops.from_int)(10)
  if (ops.lt)(ops.zero, x) {
    return false
  }
  if (ops.lt)(x, (ops.neg)(one)) {
    return true
  }
  if (ops.lt)(ops.zero, a) {
    if (ops.lt)(ops.zero, b) {
      let ratio = (ops.div)(
        (ops.mul)((ops.add)(a, ten), x),
        (ops.mul)(ten, (ops.add)(b, ten)),
      )
      return (ops.lt)((ops.abs)(ratio), one)
    }
    return true
  }
  (ops.lt)(b, ops.zero)
}

///|
/// The rational approximation to `1F1(a; b; z)`, the continued fraction of
/// Luke's `R1F1P`: the value is the ratio of two sequences that each obey a
/// three-term recurrence, and the ratio converges where the plain series does
/// not. Every term stays of order one, so no logarithm is needed and the width
/// is not stressed — this is the workhorse for the largest share of the
/// large-parameter rows, together with the largest magnitude its two sequences
/// reached.
fn[T] hyper1f1_rational(a : T, b : T, z : T, ops : Ops[T]) -> (T, T) {
  let z = (ops.neg)(z)
  let z2 = (ops.div)(z, (ops.from_int)(2))
  let ct1 = (ops.mul)(a, (ops.div)(z, b))
  let mut ct2 = (ops.div)(z2, (ops.add)(ops.one, b))
  let mut xn3 = ops.zero
  let mut xn2 = ops.one
  let mut xn1 = (ops.from_int)(2)
  let mut xn0 = (ops.from_int)(3)
  let mut b1 = ops.one
  let mut a1 = ops.one
  let b2 = (ops.add)(
    ops.one,
    (ops.mul)((ops.add)(ops.one, a), (ops.div)(z2, b)),
  )
  let a2 = (ops.sub)(b2, ct1)
  let b3 = (ops.add)(
    ops.one,
    (ops.mul)(
      (ops.add)((ops.from_int)(2), b2),
      (ops.mul)(
        (ops.div)((ops.add)((ops.from_int)(2), a), (ops.from_int)(3)),
        ct2,
      ),
    ),
  )
  let a3 = (ops.sub)(b3, (ops.mul)((ops.add)(ops.one, ct2), ct1))
  let mut ct1 = (ops.from_int)(3)
  let mut a4 = ops.zero
  let mut b4 = ops.zero
  let mut result = ops.zero
  let mut prev = (ops.div)(a3, b3)
  let mut b3r = b3
  let mut a3r = a3
  let mut b2r = b2
  let mut a2r = a2
  let noise = (ops.from_decimal)("1e-\{ops.digits}")
  let mut k : Int32 = 2
  while k < 1000000 {
    ct2 = (ops.div)((ops.div)(z2, ct1), (ops.add)(b, xn1))
    let g1 = (ops.add)(ops.one, (ops.mul)(ct2, (ops.sub)(xn2, a)))
    ct2 = (ops.mul)(ct2, (ops.div)((ops.add)(a, xn1), (ops.add)(b, xn2)))
    let g2 = (ops.mul)(
      ct2,
      (ops.add)(
        (ops.sub)(b, xn1),
        (ops.mul)(
          (ops.div)((ops.add)(a, xn0), (ops.add)(ct1, (ops.from_int)(2))),
          z2,
        ),
      ),
    )
    let g3 = (ops.mul)(
      (ops.mul)(
        (ops.mul)(ct2, z2),
        (ops.mul)(
          (ops.div)((ops.div)(z2, ct1), (ops.sub)(ct1, (ops.from_int)(2))),
          (ops.div)((ops.add)(a, xn2), (ops.add)(b, xn3)),
        ),
      ),
      (ops.sub)(a, xn2),
    )
    b4 = (ops.add)(
      (ops.add)((ops.mul)(g1, b3r), (ops.mul)(g2, b2r)),
      (ops.mul)(g3, b1),
    )
    a4 = (ops.add)(
      (ops.add)((ops.mul)(g1, a3r), (ops.mul)(g2, a2r)),
      (ops.mul)(g3, a1),
    )
    prev = result
    result = (ops.div)(a4, b4)
    // The stop: the relative change has fallen to the width's own noise floor.
    // The change is read in magnitude, the same way the reference reads it — a
    // signed difference would fall below the floor on every other term and stop
    // the fraction half converged.
    let denominator = (ops.abs)(result)
    if (ops.is_zero)(denominator) ||
      (ops.lt)(
        (ops.div)((ops.abs)((ops.sub)(result, prev)), denominator),
        (ops.mul)((ops.abs)(result), noise),
      ) {
      break
    }
    b1 = b2r
    b2r = b3r
    b3r = b4
    a1 = a2r
    a2r = a3r
    a3r = a4
    xn3 = xn2
    xn2 = xn1
    xn1 = xn0
    xn0 = (ops.add)(xn0, ops.one)
    ct1 = (ops.add)(ct1, (ops.from_int)(2))
    k = k + 1
  }
  (result, (ops.abs)(result))
}

///|
/// The uniform Bessel expansion of `1F1` for the gap small against `b`, A&S
/// 13.3.6: `e^(z/2) Γ(gap - 1/2)(z/4)^(1/2 - gap)` times a series whose `n`-th
/// term carries `I_{gap - 1/2 + n}(z/2)`. The `n`-th term is of order one, so
/// the width is not stressed by the exponential that would otherwise sit in the
/// Bessel — the value a double cannot hold is held easily by the type, and only
/// the running sum has to be earned. The gap is the fourth argument rather than
/// read as `b - a`, because the two call forms of the expansion pass it
/// differently.
fn[T] hyper1f1_bessel_i(a : T, b : T, z : T, gap : T, ops : Ops[T]) -> (T, T) {
  let one = ops.one
  let zero = ops.zero
  if (ops.is_zero)(gap) {
    let value = (ops.exp)(z)
    return (value, value)
  }
  let half = (ops.from_decimal)("0.5")
  let half_z = (ops.div)(z, (ops.from_int)(2))
  let mut term = one
  let mut sign = one
  let mut p1 = (ops.sub)((ops.mul)(gap, (ops.from_int)(2)), one)
  let mut p2 = (ops.sub)(gap, a)
  let mut bp = b
  let mut total = zero
  let mut last = one
  let mut n : Int32 = 0
  while n < 2000000 {
    let order = (ops.add)((ops.sub)(gap, half), (ops.from_int)(n))
    let bi = bessel_i(order, half_z, ops)
    let res = (ops.mul)((ops.mul)(term, (ops.mul)(order, sign)), bi)
    n = n + 1
    term = (ops.mul)(term, p1)
    p1 = if n == 1 {
      (ops.mul)(gap, (ops.from_int)(2))
    } else {
      (ops.add)(p1, one)
    }
    term = (ops.mul)(term, p2)
    p2 = (ops.add)(p2, one)
    term = (ops.div)(term, (ops.from_int)(n))
    term = (ops.div)(term, bp)
    bp = (ops.add)(bp, one)
    sign = (ops.neg)(sign)
    let size = (ops.abs)(res)
    if (ops.lt)(last, size) && n > 100 {
      break
    }
    last = size
    total = (ops.add)(total, res)
    if n > 20 && (ops.lt)(size, (ops.mul)((ops.abs)(total), tiny(ops))) {
      break
    }
  }
  // The prefix `e^(z/2) Γ(gap - 1/2)(z/4)^(1/2 - gap)`, formed directly.
  let prefix = (ops.mul)(
    (ops.exp)(half_z),
    (ops.mul)(
      gamma((ops.sub)(gap, half), ops),
      (ops.pow)(
        (ops.div)(z, (ops.from_int)(4)),
        (ops.add)(half, (ops.neg)(gap)),
      ),
    ),
  )
  let value = (ops.mul)(prefix, total)
  let mut largest = (ops.abs)(value)
  if (ops.lt)(largest, (ops.abs)(prefix)) {
    largest = (ops.abs)(prefix)
  }
  (value, largest)
}

///|
/// Whether the uniform Bessel expansion, A&S 13.3.6, is the tool for the point
/// with a negative argument: `a` tiny against `b`, the first terms well
/// behaved, and the shrinkage rate of the Bessel terms fast enough that the
/// series converges by its tenth term.
fn[T] is_1336_region(a : T, b : T, z : T, ops : Ops[T]) -> Bool {
  let one = ops.one
  let two = (ops.from_int)(2)
  let ten = (ops.from_int)(10)
  // The region is a negative argument, `a` tiny against `b` (not a half), and
  // the first terms well behaved: the first Bessel term not too divergent, and
  // the series converging by its tenth term at the Bessel shrinkage rate.
  if (ops.lt)(z, ops.zero) == false {
    return false
  }
  if (ops.is_zero)((ops.sub)((ops.abs)(a), (ops.from_decimal)("0.5"))) {
    return false
  }
  if (ops.lt)((ops.abs)((ops.div)((ops.mul)(a, ten), b)), one) == false {
    return false
  }
  if (ops.lt)((ops.abs)(a), (ops.from_int)(50)) == false {
    return false
  }
  // The shrinkage rate of the Bessel terms against the argument.
  let shrinkage = if (ops.lt)(z, (ops.neg)((ops.from_int)(160))) {
    one
  } else if (ops.lt)(z, (ops.neg)((ops.from_int)(40))) {
    (ops.from_decimal)("0.75")
  } else if (ops.lt)(z, (ops.neg)((ops.from_int)(20))) {
    (ops.from_decimal)("0.5")
  } else if (ops.lt)(z, (ops.neg)((ops.from_int)(7))) {
    (ops.from_decimal)("0.25")
  } else if (ops.lt)(z, (ops.neg)((ops.from_int)(2))) {
    (ops.from_decimal)("0.1")
  } else {
    (ops.from_decimal)("0.05")
  }
  // `| (2a-1)(2a-b) / b | < 2`: the first Bessel term not too divergent.
  let first = (ops.lt)(
    (ops.abs)(
      (ops.div)(
        (ops.mul)(
          (ops.sub)((ops.mul)(a, two), one),
          (ops.sub)((ops.mul)(a, two), b),
        ),
        b,
      ),
    ),
    (ops.mul)(two, one),
  )
  // `| shrinkage (2a+9)(2a-b+10) / (10 (b+10)) | < 0.75`: the series converging
  // by its tenth term.
  let numerator = (ops.mul)(
    (ops.mul)(shrinkage, (ops.add)((ops.mul)(a, two), (ops.from_int)(9))),
    (ops.add)((ops.sub)((ops.mul)(a, two), b), ten),
  )
  let denominator = (ops.mul)(ten, (ops.add)(b, ten))
  let second = (ops.lt)(
    (ops.abs)((ops.div)(numerator, denominator)),
    (ops.from_decimal)("0.75"),
  )
  first && second
}

///|
/// The large-argument asymptotic of `1F1`, DLMF 13.7: `e^z Γ(b)/Γ(a) z^(a - b)`
/// times a `2F0` in `1/z`, with the argument reflected to a positive one by
/// Kummer where it is negative. The factors are formed directly — at the width
/// this is run at, a value a double cannot hold is held easily by the type, so
/// only the width of the running `2F0` sum (of order one) has to be earned.
fn[T] hyper1f1_asym_z(a : T, b : T, z : T, ops : Ops[T]) -> (T, T) {
  let zero = ops.zero
  let one = ops.one
  // A negative argument is reflected to a positive one; Kummer's relation
  // supplies the `e^z` the expansion already carries, so the parameters swap and
  // no separate prefactor is needed.
  let positive = if (ops.lt)(z, zero) { (ops.neg)(z) } else { z }
  let ap = if (ops.lt)(z, zero) { (ops.sub)(b, a) } else { a }
  // The `e^z` of the expansion. For a positive argument it stays as the
  // dominant factor; for a negative one it is cancelled by the Kummer
  // reflection that brings the argument positive, so the prefactor is unity
  // and the parameters are swapped.
  let exponential = if (ops.lt)(z, zero) { one } else { (ops.exp)(z) }
  // The prefix `e^z z^(a-b) Γ(b)/Γ(a)`, formed directly.
  let prefix = (ops.mul)(
    exponential,
    (ops.mul)(
      (ops.pow)(positive, (ops.sub)(ap, b)),
      (ops.div)(gamma(b, ops), gamma(ap, ops)),
    ),
  )
  // The `2F0`: a divergent asymptotic series, summed until its terms stop
  // shrinking, so it is run out to the width and stopped the moment a term
  // begins to grow.
  let mut a1 = (ops.sub)(one, ap)
  let mut a2 = (ops.sub)(b, ap)
  let mut term = one
  let mut sum = zero
  let mut last = zero
  let mut k : Int32 = 0
  while k < 100000 {
    sum = (ops.add)(sum, term)
    last = term
    term = (ops.div)(
      (ops.mul)(term, (ops.mul)(a1, a2)),
      (ops.mul)((ops.from_int)(k + 1), positive),
    )
    a1 = (ops.add)(a1, one)
    a2 = (ops.add)(a2, one)
    k = k + 1
    // Stop when the new term is past the width's noise floor of the sum, or the
    // series turns (a term larger than the last, past the first few).
    if (ops.lt)(term, (ops.mul)((ops.abs)(sum), tiny(ops))) {
      break
    }
    if k > 10 && (ops.lt)(last, term) {
      break
    }
  }
  let value = (ops.mul)(prefix, sum)
  let mut largest = (ops.abs)(value)
  if (ops.lt)(largest, (ops.abs)(prefix)) {
    largest = (ops.abs)(prefix)
  }
  (value, largest)
}
