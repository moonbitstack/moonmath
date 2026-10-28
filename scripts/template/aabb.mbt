// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// An axis-aligned box in the plane, given by two opposite corners.
///
/// Broad-phase collision and culling ask "is this thing anywhere near that
/// thing", and a box around each answers it without touching the contents. The
/// corners are `min` and `max` rather than a corner and a size because that is
/// the form the tests read, and because merging two boxes is then two component
/// comparisons.
///
/// Values are immutable.
pub(all) struct Aabb2 {
  min : Vec2
  max : Vec2
} derive(Eq)

///|
pub extend Aabb2 with Eq::{equal, not_equal}

///|
/// The box with the two given corners.
pub fn Aabb2::new(min : Vec2, max : Vec2) -> Aabb2 {
  { min, max }
}

///|
/// The box with the given centre and half-extents.
pub fn Aabb2::from_center_half_extents(center : Vec2, half_extents : Vec2) -> Aabb2 {
  { min: center - half_extents, max: center + half_extents }
}

///|
/// The smallest box around the points, or `None` when there are none.
pub fn Aabb2::from_points(points : FixedArray[Vec2]) -> Aabb2? {
  if points.length() == 0 {
    return None
  }
  let mut low = points[0]
  let mut high = points[0]
  for point in points {
    low = low.min(point)
    high = high.max(point)
  }
  Some({ min: low, max: high })
}

///|
/// A box with nothing in it: the identity for `union`.
///
/// Its corners are the wrong way round on purpose, so that merging anything into
/// it gives that thing back unchanged.
pub fn Aabb2::empty() -> Aabb2 {
  let infinity : {{S}} = {{INF}}
  {
    min: { x: infinity, y: infinity },
    max: { x: -infinity, y: -infinity },
  }
}

///|
/// The point in the middle.
pub fn Aabb2::center(self : Aabb2) -> Vec2 {
  let half : {{S}} = 0.5
  (self.min + self.max).scale(half)
}

///|
/// The full extent along each axis.
pub fn Aabb2::size(self : Aabb2) -> Vec2 {
  self.max - self.min
}

///|
/// The half extent along each axis: the distance from the middle to a face.
pub fn Aabb2::extents(self : Aabb2) -> Vec2 {
  let half : {{S}} = 0.5
  self.size().scale(half)
}

///|
/// The area the box covers, zero when it is empty.
pub fn Aabb2::area(self : Aabb2) -> {{S}} {
  let size = self.size()
  size.x.max(0.0) * size.y.max(0.0)
}

///|
/// Whether the box holds nothing.
pub fn Aabb2::is_empty(self : Aabb2) -> Bool {
  self.min.x > self.max.x || self.min.y > self.max.y
}

///|
/// Whether the point is inside or on the boundary.
pub fn Aabb2::contains_point(self : Aabb2, point : Vec2) -> Bool {
  point.x >= self.min.x &&
  point.x <= self.max.x &&
  point.y >= self.min.y &&
  point.y <= self.max.y
}

///|
/// Whether `other` lies entirely inside this box.
pub fn Aabb2::contains(self : Aabb2, other : Aabb2) -> Bool {
  other.min.x >= self.min.x &&
  other.max.x <= self.max.x &&
  other.min.y >= self.min.y &&
  other.max.y <= self.max.y
}

///|
/// Whether the two boxes overlap in positive area.
pub fn Aabb2::intersects(self : Aabb2, other : Aabb2) -> Bool {
  self.min.x < other.max.x &&
  other.min.x < self.max.x &&
  self.min.y < other.max.y &&
  other.min.y < self.max.y
}

///|
/// The overlapping box, or `None` when they do not overlap.
pub fn Aabb2::intersection(self : Aabb2, other : Aabb2) -> Aabb2? {
  let low = self.min.max(other.min)
  let high = self.max.min(other.max)
  if low.x >= high.x || low.y >= high.y {
    None
  } else {
    Some({ min: low, max: high })
  }
}

///|
/// The smallest box containing both.
pub fn Aabb2::union(self : Aabb2, other : Aabb2) -> Aabb2 {
  { min: self.min.min(other.min), max: self.max.max(other.max) }
}

///|
/// The same box grown by `amount` in every direction.
pub fn Aabb2::expand(self : Aabb2, amount : {{S}}) -> Aabb2 {
  let padding : Vec2 = { x: amount, y: amount }
  { min: self.min - padding, max: self.max + padding }
}

///|
/// The four corners, starting at `min` and going counter-clockwise.
pub fn Aabb2::corners(self : Aabb2) -> FixedArray[Vec2] {
  [
    self.min,
    { x: self.max.x, y: self.min.y },
    self.max,
    { x: self.min.x, y: self.max.y },
  ]
}

///|
/// The same points as a rectangle.
pub fn Aabb2::to_rect(self : Aabb2) -> Rect {
  { origin: self.min, size: self.size() }
}

///|
/// Whether the two boxes agree to within `eps`.
pub fn Aabb2::approx(self : Aabb2, other : Aabb2, eps? : {{S}}) -> Bool {
  self.min.approx(other.min, eps?) && self.max.approx(other.max, eps?)
}

///|
pub impl Show for Aabb2 with output(self, logger) {
  logger.write_string("Aabb2[\{self.min}, \{self.max}]")
}

///|
pub extend Aabb2 with Show::{output, to_string}

///|
pub impl Debug for Aabb2 with to_repr(self) {
  @debug.Repr::ctor("Aabb2", [
    (Some("min"), self.min.to_repr()),
    (Some("max"), self.max.to_repr()),
  ])
}

///|
pub extend Aabb2 with Debug::{to_repr}

///|
/// An axis-aligned box in space, given by two opposite corners.
///
/// The same broad-phase role as `Aabb2`, with a third axis: a frustum is tested
/// against one of these per object per frame, so the tests here are written to
/// read the extremes of a plane's distance rather than to visit eight corners.
///
/// Values are immutable.
pub(all) struct Aabb3 {
  min : Vec3
  max : Vec3
} derive(Eq)

///|
pub extend Aabb3 with Eq::{equal, not_equal}

///|
/// The box with the two given corners.
pub fn Aabb3::new(min : Vec3, max : Vec3) -> Aabb3 {
  { min, max }
}

///|
/// The box with the given centre and half-extents.
pub fn Aabb3::from_center_half_extents(center : Vec3, half_extents : Vec3) -> Aabb3 {
  { min: center - half_extents, max: center + half_extents }
}

///|
/// The smallest box around the points, or `None` when there are none.
pub fn Aabb3::from_points(points : FixedArray[Vec3]) -> Aabb3? {
  if points.length() == 0 {
    return None
  }
  let mut low = points[0]
  let mut high = points[0]
  for point in points {
    low = low.min(point)
    high = high.max(point)
  }
  Some({ min: low, max: high })
}

///|
/// A box with nothing in it: the identity for `union`.
pub fn Aabb3::empty() -> Aabb3 {
  let infinity : {{S}} = {{INF}}
  {
    min: { x: infinity, y: infinity, z: infinity },
    max: { x: -infinity, y: -infinity, z: -infinity },
  }
}

///|
/// The point in the middle.
pub fn Aabb3::center(self : Aabb3) -> Vec3 {
  let half : {{S}} = 0.5
  (self.min + self.max).scale(half)
}

///|
/// The full extent along each axis.
pub fn Aabb3::size(self : Aabb3) -> Vec3 {
  self.max - self.min
}

///|
/// The half extent along each axis.
pub fn Aabb3::extents(self : Aabb3) -> Vec3 {
  let half : {{S}} = 0.5
  self.size().scale(half)
}

///|
/// The volume the box encloses, zero when it is empty.
pub fn Aabb3::volume(self : Aabb3) -> {{S}} {
  let size = self.size()
  size.x.max(0.0) * size.y.max(0.0) * size.z.max(0.0)
}

///|
/// The total area of the six faces, zero when it is empty.
pub fn Aabb3::surface_area(self : Aabb3) -> {{S}} {
  let size = self.size()
  let twice : {{S}} = 2.0
  let x = size.x.max(0.0)
  let y = size.y.max(0.0)
  let z = size.z.max(0.0)
  twice * (x * y + y * z + z * x)
}

///|
/// Whether the box holds nothing.
pub fn Aabb3::is_empty(self : Aabb3) -> Bool {
  self.min.x > self.max.x || self.min.y > self.max.y || self.min.z > self.max.z
}

///|
/// Whether the point is inside or on the boundary.
pub fn Aabb3::contains_point(self : Aabb3, point : Vec3) -> Bool {
  point.x >= self.min.x &&
  point.x <= self.max.x &&
  point.y >= self.min.y &&
  point.y <= self.max.y &&
  point.z >= self.min.z &&
  point.z <= self.max.z
}

///|
/// Whether `other` lies entirely inside this box.
pub fn Aabb3::contains(self : Aabb3, other : Aabb3) -> Bool {
  other.min.x >= self.min.x &&
  other.max.x <= self.max.x &&
  other.min.y >= self.min.y &&
  other.max.y <= self.max.y &&
  other.min.z >= self.min.z &&
  other.max.z <= self.max.z
}

///|
/// Whether the two boxes overlap in positive volume.
pub fn Aabb3::intersects(self : Aabb3, other : Aabb3) -> Bool {
  self.min.x < other.max.x &&
  other.min.x < self.max.x &&
  self.min.y < other.max.y &&
  other.min.y < self.max.y &&
  self.min.z < other.max.z &&
  other.min.z < self.max.z
}

///|
/// The overlapping box, or `None` when they do not overlap.
pub fn Aabb3::intersection(self : Aabb3, other : Aabb3) -> Aabb3? {
  let low = self.min.max(other.min)
  let high = self.max.min(other.max)
  if low.x >= high.x || low.y >= high.y || low.z >= high.z {
    None
  } else {
    Some({ min: low, max: high })
  }
}

///|
/// The smallest box containing both.
pub fn Aabb3::union(self : Aabb3, other : Aabb3) -> Aabb3 {
  { min: self.min.min(other.min), max: self.max.max(other.max) }
}

///|
/// The same box grown by `amount` in every direction.
pub fn Aabb3::expand(self : Aabb3, amount : {{S}}) -> Aabb3 {
  let padding : Vec3 = { x: amount, y: amount, z: amount }
  { min: self.min - padding, max: self.max + padding }
}

///|
/// The eight corners.
pub fn Aabb3::corners(self : Aabb3) -> FixedArray[Vec3] {
  let low = self.min
  let high = self.max
  [
    { x: low.x, y: low.y, z: low.z },
    { x: high.x, y: low.y, z: low.z },
    { x: high.x, y: high.y, z: low.z },
    { x: low.x, y: high.y, z: low.z },
    { x: low.x, y: low.y, z: high.z },
    { x: high.x, y: low.y, z: high.z },
    { x: high.x, y: high.y, z: high.z },
    { x: low.x, y: high.y, z: high.z },
  ]
}

///|
/// The box around the transformed box.
///
/// A box turned by a rotation is no longer axis-aligned, so the result is the
/// smallest axis-aligned box around the turned one: correct, and looser than it
/// was before the turn.
pub fn Aabb3::transform(self : Aabb3, m : Mat4) -> Aabb3 {
  let points = FixedArray::make(8, Vec3::zero())
  let corners = self.corners()
  for i in 0..<8 {
    points[i] = m.transform_point(corners[i])
  }
  match Aabb3::from_points(points) {
    Some(box) => box
    None => self
  }
}

///|
/// Whether the two boxes agree to within `eps`.
pub fn Aabb3::approx(self : Aabb3, other : Aabb3, eps? : {{S}}) -> Bool {
  self.min.approx(other.min, eps?) && self.max.approx(other.max, eps?)
}

///|
pub impl Show for Aabb3 with output(self, logger) {
  logger.write_string("Aabb3[\{self.min}, \{self.max}]")
}

///|
pub extend Aabb3 with Show::{output, to_string}

///|
pub impl Debug for Aabb3 with to_repr(self) {
  @debug.Repr::ctor("Aabb3", [
    (Some("min"), self.min.to_repr()),
    (Some("max"), self.max.to_repr()),
  ])
}

///|
pub extend Aabb3 with Debug::{to_repr}
