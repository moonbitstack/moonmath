// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A one-dimensional range between two numbers, `min` at or below `max`.
///
/// It is the one-dimensional case of an axis-aligned box, and what a timeline,
/// an exposure or a depth range is. An empty interval — no numbers at all — is
/// the one with `min` above `max`, which is how the union of nothing starts and
/// how `empty` builds it; every operation here treats it as the identity the
/// set operations expect.
///
/// Values are immutable.
#derive(Eq)
pub(all) struct Interval {
  /// The low end, inclusive.
  min : Float
  /// The high end, inclusive.
  max : Float
}

///|
pub extend Interval with Eq::{equal, not_equal}

///|
/// The interval from `min` to `max`; the two are not reordered, so passing them
/// the other way round gives the empty interval.
pub fn Interval::new(min : Float, max : Float) -> Interval {
  { min, max, }
}

///|
/// The interval with no numbers in it, which every union starts from.
pub fn Interval::empty() -> Interval {
  { min: 3.4028234663852886e38, max: -3.4028234663852886e38, }
}

///|
/// Whether the interval holds no numbers: `min` above `max`.
pub fn Interval::is_empty(self : Interval) -> Bool {
  self.min > self.max
}

///|
/// The distance from `min` to `max`, or zero for the empty interval.
pub fn Interval::size(self : Interval) -> Float {
  if self.is_empty() {
    0.0
  } else {
    self.max - self.min
  }
}

///|
/// The midpoint of the interval.
pub fn Interval::center(self : Interval) -> Float {
  let half : Float = 0.5
  (self.min + self.max) * half
}

///|
/// Whether `value` lies in the interval, ends included.
pub fn Interval::contains(self : Interval, value : Float) -> Bool {
  value >= self.min && value <= self.max
}

///|
/// Whether the two intervals share at least one point.
pub fn Interval::intersects(self : Interval, other : Interval) -> Bool {
  !self.is_empty() &&
  !other.is_empty() &&
  self.min <= other.max &&
  other.min <= self.max
}

///|
/// The overlap of the two, or `None` when they do not meet.
pub fn Interval::intersection(self : Interval, other : Interval) -> Interval? {
  if self.intersects(other) {
    Some(Interval::new(self.min.max(other.min), self.max.min(other.max)))
  } else {
    None
  }
}

///|
/// The smallest interval holding both; the empty interval is the identity.
pub fn Interval::union(self : Interval, other : Interval) -> Interval {
  if self.is_empty() {
    other
  } else if other.is_empty() {
    self
  } else {
    Interval::new(self.min.min(other.min), self.max.max(other.max))
  }
}

///|
/// The interval grown to include `value`; the empty interval becomes `[value,
/// value]`.
pub fn Interval::extend_by(self : Interval, value : Float) -> Interval {
  if self.is_empty() {
    Interval::new(value, value)
  } else {
    Interval::new(self.min.min(value), self.max.max(value))
  }
}

///|
/// The interval grown by `amount` at both ends; a negative amount shrinks it.
pub fn Interval::expand(self : Interval, amount : Float) -> Interval {
  Interval::new(self.min - amount, self.max + amount)
}

///|
/// Whether both ends are finite.
pub fn Interval::is_finite(self : Interval) -> Bool {
  !(self.min.is_nan() ||
  self.min.is_inf() ||
  self.max.is_nan() ||
  self.max.is_inf())
}

///|
/// Whether the two intervals agree end for end to within `eps`.
pub fn Interval::approx(
  self : Interval,
  other : Interval,
  eps? : Float,
) -> Bool {
  approx(self.min, other.min, eps?) && approx(self.max, other.max, eps?)
}

///|
pub impl Show for Interval with fn output(self, logger) {
  logger.write_string("Interval(\{self.min}, \{self.max})")
}

///|
pub extend Interval with Show::{output, to_string}

///|
pub impl Debug for Interval with fn to_repr(self) {
  @debug.Repr::ctor("Interval", [
    (Some("min"), @debug.Repr::float(self.min)),
    (Some("max"), @debug.Repr::float(self.max)),
  ])
}

///|
pub extend Interval with Debug::{to_repr}
