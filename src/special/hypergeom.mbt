// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The hypergeometric functions at double precision, from the bodies in
// `special/generic`.
//
// A hypergeometric series cancels: with parameters well past the argument its
// terms run far above the result and come back to it, and the double that
// carries them keeps only the digits left over. Each body here reports the
// largest term it formed beside the value, so this face — which can see
// `moonnum`'s arbitrary-precision `BigFloat` — can measure how many digits the
// run kept and re-run the sum at a width that holds them, then round once. The
// result is the double-precision answer, computed in the precision it needs.
//
// How much wider is decided by the run itself rather than fixed in advance. The
// `2F1` transformation around one asks for about twenty more digits than the two
// halves it cancelled, which is forty-five or so for the parameters Boost's table
// reaches; the large-parameter `1F1` region the uniform asymptotic expansion
// answers wants a hundred or more, and the escalation finds that width for the
// rows it still has to carry.

///|
/// `x`, at the width the escalation runs at.
///
/// The value is read as a `BigFloat` at the run's width, not held as a literal
/// and widened: a `double` carries fifty-three bits of it, and a run at a hundred
/// digits wants the whole of those rather than the last digit the text kept.
fn widened(x : Double, digits : Int32) -> @moonnum.BigFloat {
  @moonnum.BigFloat::of_double(x).round(
    context=@moonnum.Context::new(@generic.digits_to_precision(digits)),
  )
}

///|
/// Whether the double run kept too few digits to be worth returning.
///
/// The test is on the terms, not on the answer: a sum whose largest term ran
/// past the result by `10^d` kept `15 - d` digits of it, so `10^3` is the point
/// where a third of them are gone — more than the checks beside this file allow.
/// A `NaN` or an infinity — the other way a double run fails here, by
/// overflowing on the way — counts as poor as well.
fn poor(value : Double, largest : Double) -> Bool {
  if value != value {
    return true
  }
  let size = value.abs()
  if size > 1.0e307 {
    return true
  }
  if largest != largest {
    return true
  }
  largest > size * 1.0e3
}

///|
/// The narrowest width the escalation starts at.
///
/// Forty-five digits covers the `2F1` table's worst row with twenty to spare, and
/// is the width the `1F1` escalation has always used.
let first_width : Int32 = 45

///|
/// The widest the escalation will go. Past it the cost of a wide `BigFloat` run
/// stops being worth reaching for, and the answer is returned with the digits it
/// has rather than widened again.
///
/// The ceiling is a thousand because a `1F1` in the large-parameter region can
/// cancel further than four hundred: `1F1(-13547.7; 19.05; 15.87)` is `3.9e-31`
/// and the terms of its sum climb to `10^450` on the way, so a run at four
/// hundred digits has none of it left. Only the rows whose gap survives four
/// hundred pay for the wider rung, because the escalation stops as soon as a run
/// comes back whole.
let last_width : Int32 = 1000

///|
/// The digits a wide run has to leave above its own worst step before the answer
/// is taken.
let margin : Int32 = 20

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
/// `e^x 1F1(b - a; b; -x)` past `x = -4`. Past the point where the series's terms
/// run beyond what any width this package will pay for holds — the large-parameter
/// region, where a numerator of a few hundred thousand cancels a denominator of a
/// million — the routing in `special/generic` picks a method for the point
/// instead: Luke's rational continued fraction, the A&S 13.3.6 uniform expansion,
/// the large-argument asymptotic, or the sum at the argument where the numerator
/// is small enough for it to settle in a handful of terms. Where the terms still
/// run a thousandfold past the result the sum is redone at a width that holds the
/// digits the cancellation took.
pub fn hyper1f1(a : Double, b : Double, x : Double) -> Double {
  let pair = @generic.hyper1f1_scaled(a, b, x, @generic.double_algebra)
  let (value, largest) = pair
  if !poor(value, largest) {
    return value
  }
  widen(first_width, fn(digits) {
    let ops = @generic.bigfloat_ops(digits)
    @generic.hyper1f1_scaled(
      widened(a, digits),
      widened(b, digits),
      widened(x, digits),
      ops,
    )
  })
}

///|
/// The Gauss hypergeometric `2F1(a, b; c; x)`, for `|x| < 1`.
///
/// Past a half the argument is moved to `1 - x` by the linear transformation, and
/// a negative argument takes Pfaff's; the body in `special/generic` says which
/// and why. When `c - a - b` is an integer that transformation has a logarithm in
/// it instead of two powers, and the degenerate path answers the case by a limit
/// of the connection formula rather than the two-power form. Both halves of the
/// transformation are formed as logarithms of gamma factors, because with
/// parameters of order a hundred a single factor is past `10^370` while the ratio
/// of two of them is not.
///
/// The two halves also cancel, and by more than a double can spare: against
/// Boost's own table, which lies wholly in this region, the worst row loses
/// twenty-three digits. Those rows are re-run wider, which is what makes the
/// table pass at `1e-12`.
pub fn hyper2f1(a : Double, b : Double, c : Double, x : Double) -> Double {
  let pair = @generic.hyper2f1_scaled(a, b, c, x, @generic.double_algebra)
  let (value, largest) = pair
  if !poor(value, largest) {
    return value
  }
  widen(first_width, fn(digits) {
    let ops = @generic.bigfloat_ops(digits)
    @generic.hyper2f1_scaled(
      widened(a, digits),
      widened(b, digits),
      widened(c, digits),
      widened(x, digits),
      ops,
    )
  })
}

///|
/// A run at the first width, then wider while it is either short of digits or
/// has not yet stopped moving.
///
/// Two things end it. The first is a run whose gap fits inside its own width and
/// whose value agrees with the run half as wide — that pair is a sum that has
/// converged. The second is the ceiling, where a row that still has not is
/// returned with the digits it has.
///
/// The gap alone is not enough, and that is not a detail: at a width below the
/// cancellation the sum comes back as the noise of its own terms, and noise has a
/// small gap. `1F1(-9057.9; 19.05; 15.87)` is `1.0e-29`; at forty-five digits it
/// reads `5.8e245` and reports a gap of twenty-one, which is twenty-four good
/// digits of nothing. A width where the gap is wider than the width is a run that
/// does not know its own answer, so the next width is double rather than the one
/// the gap asks for.
fn widen(
  start : Int32,
  run : (Int32) -> (@moonnum.BigFloat, @moonnum.BigFloat),
) -> Double {
  let mut digits = start
  let mut best = 0.0
  let mut prior = 0.0
  let mut seen = false
  for _ in 0..<9 {
    let pair = run(digits)
    let (value, largest) = pair
    best = value.to_double()
    let ops = @generic.bigfloat_ops(digits)
    let floor = (ops.from_decimal)("1e\{ops.digits - margin}")
    let short = (ops.lt)((ops.mul)((ops.abs)(value), floor), (ops.abs)(largest))
    // A run that reported a gap is not the same as a run that is converged. Where
    // the cancellation is deeper than the width, the sum comes back as the noise
    // of the terms rather than their sum: `1F1(-9057.9; 19.05; 15.87)` is
    // `1.0e-29` and reads `5.8e245` at forty-five digits, `-2.0e200` at ninety
    // and `-4.5e111` at a hundred and eighty. Two widths that agree is a run
    // that has stopped moving, and that is the one to return.
    // A run that came back zero agrees with the one before it for the wrong
    // reason: both lost the value, and no width was enough. Zero is never the
    // answer here — the closed forms are answered before this is reached — so it
    // is not allowed to settle anything.
    let agree = seen &&
      best != 0.0 &&
      (best - prior).abs() <= best.abs() * 1.0e-10
    if (agree && !short) || digits >= last_width {
      return best
    }
    // The gap the run reports is the count of digits it lost, so the next width
    // is that count plus the margin rather than twice the last: a row that needs
    // three hundred digits gets them in one more run instead of three. But a run
    // whose gap is wider than its width has not told the truth about the gap —
    // its value is noise — and the only honest move there is to double.
    let next = if short {
      digits * 2
    } else {
      wanted(largest.to_double(), value.to_double(), digits)
    }
    let grown = if next > digits * 3 {
      digits * 3
    } else if next > digits {
      next
    } else {
      digits * 2
    }
    let capped = if grown > last_width { last_width } else { grown }
    digits = if capped <= digits { digits * 2 } else { capped }
    if digits > last_width {
      digits = last_width
    }
    prior = best
    seen = true
  }
  best
}

///|
/// The width a run needs, read off the gap between its worst term and its answer.
///
/// Both readings are doubles and either may have overflowed on the way out of the
/// wide run, which is itself a statement that the width was far too narrow; the
/// doubling below covers that case, so the answer here is never below what the
/// run already had.
fn wanted(largest : Double, value : Double, digits : Int32) -> Int32 {
  if largest != largest || value != value || value == 0.0 {
    return digits * 2
  }
  let ratio = (largest / value).abs()
  if ratio <= 1.0 {
    return digits
  }
  let needed = @math.log10(ratio) + Double::from_int(margin) + 4.0
  if needed > 1.0e3 {
    return 1000
  }
  if needed < Double::from_int(digits) {
    return digits
  }
  needed.to_int()
}
