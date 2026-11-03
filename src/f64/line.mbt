// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// An infinite line in space: a point and a direction.
///
/// A ray has a start and runs one way; a line has neither end, which is what a
/// construction axis, a normal or the intersection of two planes is. The
/// direction need not be a unit vector — the results are the same whatever its
/// length — but a zero direction names no line, and every operation treats it as
/// the single point `point`.
///
/// Values are immutable.
#derive(Eq)
pub(all) struct Line3 {
  /// A point on the line.
  point : Vec3
  /// The direction it runs in; its length does not matter.
  direction : Vec3
}

///|
pub extend Line3 with Eq::{equal, not_equal}

///|
/// The line through `point` in `direction`.
pub fn Line3::new(point : Vec3, direction : Vec3) -> Line3 {
  { point, direction, }
}

///|
/// The point `t` of the direction from `point`; `t` may be any number.
pub fn Line3::at(self : Line3, t : Double) -> Vec3 {
  self.point + self.direction.scale(t)
}

///|
/// The point of the line closest to `other`.
///
/// The perpendicular foot: the vector from it to `other` is perpendicular to the
/// direction. A zero direction leaves the line a point, and the answer is that
/// point.
pub fn Line3::closest_point_to(self : Line3, other : Vec3) -> Vec3 {
  let along = self.direction.length_squared()
  if along == 0.0 {
    self.point
  } else {
    self.at((other - self.point).dot(self.direction) / along)
  }
}

///|
/// The distance from the line to the point.
pub fn Line3::distance_to_point(self : Line3, other : Vec3) -> Double {
  other.distance(self.closest_point_to(other))
}

///|
/// The point of this line closest to the other line.
///
/// For two lines that meet or are skew, the closest points are the pair joined by
/// the common perpendicular; this is the one on this line. Parallel lines have a
/// whole family of closest pairs and the foot from the other line's point is
/// returned. A degenerate line — a zero direction — gives its point.
pub fn Line3::closest_point_to_line(self : Line3, other : Line3) -> Vec3 {
  let d1 = self.direction
  let d2 = other.direction
  let a = d1.dot(d1)
  if a == 0.0 {
    return self.point
  }
  let b = d1.dot(d2)
  let c = d2.dot(d2)
  let w = self.point - other.point
  let d = d1.dot(w)
  let e = d2.dot(w)
  let denominator = a * c - b * b
  if denominator == 0.0 {
    // Parallel, or the other line is a point: the foot from its point.
    self.closest_point_to(other.point)
  } else {
    self.at((b * e - c * d) / denominator)
  }
}

///|
/// The distance between the two lines: zero when they meet.
pub fn Line3::distance_to_line(self : Line3, other : Line3) -> Double {
  let cross = self.direction.cross(other.direction)
  let area = cross.length_squared()
  if area == 0.0 {
    // Parallel, or one of them degenerate: the distance to the other's point
    // is the distance between them.
    if self.direction.length_squared() == 0.0 {
      other.distance_to_point(self.point)
    } else {
      self.distance_to_point(other.point)
    }
  } else {
    let w = other.point - self.point
    w.dot(cross).abs() / cross.length()
  }
}

///|
/// Where the line cuts the plane, or `None` when it runs parallel to it.
///
/// A line has no ends, so any crossing counts, on either side of `point`.
pub fn Line3::intersect_plane(self : Line3, plane : Plane) -> Vec3? {
  let denominator = plane.normal.dot(self.direction)
  if denominator == 0.0 {
    None
  } else {
    let t = (plane.distance - plane.normal.dot(self.point)) / denominator
    Some(self.at(t))
  }
}

///|
/// Whether the point and the direction are finite.
pub fn Line3::is_finite(self : Line3) -> Bool {
  self.point.is_finite() && self.direction.is_finite()
}

///|
/// Whether the two lines have the same point and direction to within `eps`.
pub fn Line3::approx(self : Line3, other : Line3, eps? : Double) -> Bool {
  self.point.approx(other.point, eps?) &&
  self.direction.approx(other.direction, eps?)
}

///|
pub impl Show for Line3 with fn output(self, logger) {
  logger.write_string("Line3(\{self.point}, \{self.direction})")
}

///|
pub extend Line3 with Show::{output, to_string}

///|
pub impl Debug for Line3 with fn to_repr(self) {
  @debug.Repr::ctor("Line3", [
    (Some("point"), self.point.to_repr()),
    (Some("direction"), self.direction.to_repr()),
  ])
}

///|
pub extend Line3 with Debug::{to_repr}

///|
/// Whether the infinite line meets the frustum at all.
///
/// Each of the six planes is a linear inequality in the line's parameter, so the
/// part of the line inside the frustum is the intersection of six half-lines:
/// one interval. The line meets the frustum exactly when that interval is not
/// empty, which is the honest test an infinite line needs — unlike a ray, it has
/// no start that could already be outside one plane while inside another.
pub fn Frustum::intersects_line(self : Frustum, line : Line3) -> Bool {
  let mut low : Double = -1.7976931348623157e308
  let mut high : Double = 1.7976931348623157e308
  for i in 0..<6 {
    let plane = self.planes[i]
    let slope = plane.normal.dot(line.direction)
    let offset = plane.signed_distance(line.point)
    if slope == 0.0 {
      if offset < 0.0 {
        return false
      }
    } else {
      let crossing = -offset / slope
      if slope > 0.0 {
        if crossing > low {
          low = crossing
        }
      } else if crossing < high {
        high = crossing
      }
      if low > high {
        return false
      }
    }
  }
  true
}
