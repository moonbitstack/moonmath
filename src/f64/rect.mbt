// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A rectangle given by its corner and its size: the shape a layout hands out.
///
/// A layout thinks in "here, this big", not in two opposite corners, which is
/// why this is not `Aabb2` — the two describe the same set of points and answer
/// different questions. `origin` is the corner with the smaller coordinates and
/// `size` the extent from it, so a `size` with a negative component describes
/// the same points as the equivalent positive one, with the corners swapped.
///
/// Values are immutable.
pub(all) struct Rect {
  origin : Vec2
  size : Vec2
} derive(Eq)

///|
pub extend Rect with Eq::{equal, not_equal}

///|
/// The rectangle at `origin` extending `size`.
pub fn Rect::new(origin : Vec2, size : Vec2) -> Rect {
  { origin, size, }
}

///|
/// The rectangle with its top-left corner at `x`, `y` and the given extent.
///
/// The usual spelling for a layout node; which way is "top" is the caller's
/// convention, as everywhere else here.
pub fn Rect::from_xywh(
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> Rect {
  { origin: { x, y, }, size: { x: width, y: height, }, }
}

///|
/// The rectangle spanning two opposite corners, in either order.
pub fn Rect::from_edges(
  left : Double,
  top : Double,
  right : Double,
  bottom : Double,
) -> Rect {
  {
    origin: { x: left.min(right), y: top.min(bottom), },
    size: { x: (right - left).abs(), y: (bottom - top).abs(), },
  }
}

///|
/// The corner with the smaller coordinates.
pub fn Rect::min(self : Rect) -> Vec2 {
  {
    x: self.origin.x.min(self.origin.x + self.size.x),
    y: self.origin.y.min(self.origin.y + self.size.y),
  }
}

///|
/// The corner with the larger coordinates.
pub fn Rect::max(self : Rect) -> Vec2 {
  {
    x: self.origin.x.max(self.origin.x + self.size.x),
    y: self.origin.y.max(self.origin.y + self.size.y),
  }
}

///|
/// The point in the middle.
pub fn Rect::center(self : Rect) -> Vec2 {
  let half : Double = 0.5
  self.origin + self.size.scale(half)
}

///|
/// The extent along `x`, always non-negative.
pub fn Rect::width(self : Rect) -> Double {
  self.size.x.abs()
}

///|
/// The extent along `y`, always non-negative.
pub fn Rect::height(self : Rect) -> Double {
  self.size.y.abs()
}

///|
/// The area the rectangle covers.
pub fn Rect::area(self : Rect) -> Double {
  self.width() * self.height()
}

///|
/// Whether the rectangle covers no area at all.
///
/// A zero width or height is empty: it is a line or a point, and nothing inside
/// it can be drawn or hit.
pub fn Rect::is_empty(self : Rect) -> Bool {
  self.width() == 0.0 || self.height() == 0.0
}

///|
/// Whether the point is inside or on the edge.
pub fn Rect::contains(self : Rect, point : Vec2) -> Bool {
  let low = self.min()
  let high = self.max()
  point.x >= low.x && point.x <= high.x && point.y >= low.y && point.y <= high.y
}

///|
/// Whether the two rectangles share any area.
///
/// Touching edges share no area and do not count; an empty rectangle intersects
/// nothing.
pub fn Rect::intersects(self : Rect, other : Rect) -> Bool {
  if self.is_empty() || other.is_empty() {
    false
  } else {
    let a0 = self.min()
    let a1 = self.max()
    let b0 = other.min()
    let b1 = other.max()
    a0.x < b1.x && b0.x < a1.x && a0.y < b1.y && b0.y < a1.y
  }
}

///|
/// The area the two share, or `None` when they share none.
pub fn Rect::intersection(self : Rect, other : Rect) -> Rect? {
  let a0 = self.min()
  let a1 = self.max()
  let b0 = other.min()
  let b1 = other.max()
  let low : Vec2 = { x: a0.x.max(b0.x), y: a0.y.max(b0.y), }
  let high : Vec2 = { x: a1.x.min(b1.x), y: a1.y.min(b1.y), }
  if high.x <= low.x || high.y <= low.y {
    None
  } else {
    Some({ origin: low, size: high - low, })
  }
}

///|
/// The smallest rectangle containing both.
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  let low = self.min().min(other.min())
  let high = self.max().max(other.max())
  { origin: low, size: high - low, }
}

///|
/// The same rectangle with every edge moved in by `amount`.
///
/// A positive amount shrinks it, a negative one grows it; shrinking past the
/// middle leaves an empty rectangle at the centre rather than a negative one.
pub fn Rect::inset(self : Rect, amount : Double) -> Rect {
  let twice : Double = 2.0
  let width = self.width() - twice * amount
  let height = self.height() - twice * amount
  let center = self.center()
  let size : Vec2 = { x: width.max(0.0), y: height.max(0.0), }
  let half : Double = 0.5
  { origin: center - size.scale(half), size, }
}

///|
/// The same rectangle moved by `offset`.
pub fn Rect::translate(self : Rect, offset : Vec2) -> Rect {
  { origin: self.origin + offset, size: self.size, }
}

///|
/// The same points as an axis-aligned box.
pub fn Rect::to_aabb(self : Rect) -> Aabb2 {
  { min: self.min(), max: self.max(), }
}

///|
/// The four corners, starting at `origin` and going counter-clockwise.
pub fn Rect::corners(self : Rect) -> FixedArray[Vec2] {
  let low = self.min()
  let high = self.max()
  [low, { x: high.x, y: low.y, }, high, { x: low.x, y: high.y, }]
}

///|
/// Whether the two rectangles cover the same points to within `eps`.
pub fn Rect::approx(self : Rect, other : Rect, eps? : Double) -> Bool {
  self.min().approx(other.min(), eps?) && self.max().approx(other.max(), eps?)
}

///|
pub impl Show for Rect with fn output(self, logger) {
  logger.write_string("Rect(\{self.origin}, \{self.size})")
}

///|
pub extend Rect with Show::{output, to_string}

///|
pub impl Debug for Rect with fn to_repr(self) {
  @debug.Repr::ctor("Rect", [
    (Some("origin"), self.origin.to_repr()),
    (Some("size"), self.size.to_repr()),
  ])
}

///|
pub extend Rect with Debug::{to_repr}
