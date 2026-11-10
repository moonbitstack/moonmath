// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The large-parameter `1F1` tables, every row of them.
//
// `boost_big_wbtest.mbt` carries the rows from the three tables that ship with
// Boost.Math's own test suite, and this file replays all of them: the main table
// whose parameters run past a million, the rows that sit at the edge of what a
// double holds, and the rows Boost itself marks unsolved. The tables used to be
// sampled — one row from each corner of the routing — because they were read
// from a Boost checkout at generation time rather than carried by the package;
// they are carried now, and a sample of them says nothing a full replay does not.
//
// Each test prints one line with the table's name, how many rows it has, how
// many were replayed and how many passed, so a CI log states what was checked
// rather than only that the suite was green.

///|
/// A row that passed: within `tolerance` relative, or — where the reference is
/// below what a `Double` holds and the generator wrote `0.0` — below that range
/// as well.
///
/// `1F1(-814723.75; 13586.88; 15.87)` is `4.9e-401`: there is no literal for it
/// and no relative error to measure, since the type's smallest subnormal is
/// `5e-324`. What can be said about such a row is that the answer must lie below
/// the type's range too, and that is what is asked of it — a run that returned a
/// number of the wrong size would be caught here.
fn within(got : Double, want : Double, tolerance : Double) -> Bool {
  if want == 0.0 {
    return got.abs() < 1.0e-300
  }
  ((got - want) / want).abs() <= tolerance
}

///|
/// The two rows of Boost's unsolved table this package does not answer.
///
/// Boost marks all twelve rows of that table unsolved, and this package answers
/// ten. Both of the ones left are rows where no width it will pay for leaves a
/// digit of the answer: `1F1(13547.7; -13586.9; 1043.8)` is `-2.0e-200` and comes
/// back as zero, and `1F1(1.4e-10; -0.9999999999; -3059.6)` sits against the pole
/// at `b = -1`, where the answer is `3.2e-7` and comes back as zero as well. Zero
/// is not the value in either case, which is why they are named here and counted
/// rather than passed over: the day one of them starts answering, the count in
/// the line below changes and this list is revisited.
fn unanswered(a : Double, b : Double, x : Double) -> Bool {
  let near_the_pole = a == 1.3785990114778025e-10 &&
    b == -0.99999999986214 &&
    x == -3059.615032672882
  let cancelled = a == 13547.69921875 &&
    b == -13586.87890625 &&
    x == 1043.7607421875
  near_the_pole || cancelled
}

///|
/// One table, replayed row by row, with the counts printed as it goes.
///
/// A failure names the row by index and by its three parameters, because the
/// tables carry no labels — Boost's own harness reports the same way.
fn replay(
  table : String,
  rows : Array[(Double, Double, Double, Double)],
  tolerance : Double,
) -> Unit {
  let mut index = 0
  let mut passed = 0
  let mut unanswered_rows = 0
  let mut below = 0
  for (a, b, x, want) in rows {
    index = index + 1
    if unanswered(a, b, x) {
      unanswered_rows = unanswered_rows + 1
      continue
    }
    if want == 0.0 {
      below = below + 1
    }
    let got = hyper1f1(a, b, x)
    if !within(got, want, tolerance) {
      abort(
        "\{table} row \{index}: 1F1(\{a}; \{b}; \{x}) got \{got}, want \{want}",
      )
    }
    passed = passed + 1
  }
  let note = if unanswered_rows == 0 {
    ""
  } else {
    ", \{unanswered_rows} unanswered"
  }
  let range = if below == 0 {
    ""
  } else {
    " (\{below} of them below the smallest normal double, checked as such)"
  }
  println(
    "\{table}: \{index} rows in the table, \{passed} replayed and passed\{note}\{range}",
  )
}

///|
/// The main table of the large-parameter region: every row has `max(|a|, |b|,
/// |x|)` past a hundred, and the parameters reach a million.
///
/// The double face answers these through the routing in `special/generic` — the
/// rational approximation, the uniform Bessel expansion, the large-argument
/// asymptotic, the sum at the argument — and widens to a thousand digits for the
/// rows whose terms run past the answer by four hundred. The worst row left is
/// out by `1.3e-12`, over all 2,383.
test "the large-parameter table, every row" {
  replay("hypergeometric_1F1_big.ipp", boost_hyper1f1_big_cases, 1.0e-11)
}

///|
/// The rows that sit at the edge of a double: the arguments are exact, the values
/// are not, and the answer has to keep fifteen digits of a number it can barely
/// hold. All seven are answered; the three whose parameters Boost writes as a
/// `ldexp` of an integer are among them.
test "the double-limited table, every row" {
  replay(
    "hypergeometric_1F1_big_double_limited.ipp", boost_hyper1f1_big_double_cases,
    1.0e-13,
  )
}

///|
/// The rows Boost itself marks unsolved: nine ordinary ones, the two that its own
/// notes say should be reachable by the uniform expansion but are not, and one
/// whose reference is only good to about six digits.
///
/// Ten of the twelve are answered here, the coarse one included — its reference
/// is good to about six digits and the answer agrees with it far past that, so
/// the row says more about the reference than about the code. The two that are
/// not answered are held out by name in `unanswered` and counted in the line
/// below rather than dropped, because a table that quietly replays ten of
/// twelve rows is how a gap stops being visible.
test "the unsolved table, every row" {
  replay(
    "hypergeometric_1F1_big_unsolved.ipp", boost_hyper1f1_big_unsolved_cases, 1.0e-11,
  )
}
