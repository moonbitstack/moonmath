// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "an interval holds its two ends" {
  let range = Interval::new(1.0, 3.0)
  assert_eq(range.size(), 2.0)
  assert_eq(range.center(), 2.0)
  assert_true(range.contains(1.0))
  assert_true(range.contains(3.0))
  assert_false(range.contains(4.0))
}

///|
test "the empty interval is the identity of union" {
  let range = Interval::new(1.0, 3.0)
  assert_true(Interval::empty().is_empty())
  assert_eq(Interval::empty().size(), 0.0)
  assert_true(Interval::empty().union(range).approx(range))
  // Growing the empty interval from a point gives that point alone.
  assert_true(Interval::empty().extend_by(5.0).approx(Interval::new(5.0, 5.0)))
}

///|
test "intervals meet, overlap or miss" {
  let first = Interval::new(0.0, 2.0)
  let second = Interval::new(1.0, 3.0)
  assert_true(first.intersects(second))
  assert_true(
    first.intersection(second).unwrap().approx(Interval::new(1.0, 2.0)),
  )
  assert_true(first.union(second).approx(Interval::new(0.0, 3.0)))
  let apart = Interval::new(5.0, 6.0)
  assert_false(first.intersects(apart))
  assert_true(first.intersection(apart) is None)
  // An interval meeting the empty one meets nothing.
  assert_false(first.intersects(Interval::empty()))
}

///|
test "expanding moves both ends out" {
  let range = Interval::new(1.0, 2.0).expand(0.5)
  assert_true(range.approx(Interval::new(0.5, 2.5)))
}
