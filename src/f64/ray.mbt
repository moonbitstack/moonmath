// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The `index` component of a `Vec2`, counted from zero.
fn component2(v : Vec2, index : Int32) -> Double {
  if index == 0 {
    v.x
  } else {
    v.y
  }
}

///|
/// The `index` component of a `Vec3`, counted from zero.
fn component3(v : Vec3, index : Int32) -> Double {
  if index == 0 {
    v.x
  } else if index == 1 {
    v.y
  } else {
    v.z
  }
}

///|
/// A half-line in the plane: a start and a direction.
///
/// `origin + direction * t` for `t >= 0`. The direction is not normalized here —
/// a ray whose direction carries the speed of something travelling along it is
/// as useful as a unit one, and `t` then reads as time.
///
/// Values are immutable.
pub(all) struct Ray2 {
  /// Where the ray starts.
  origin : Vec2
  /// Which way it goes. The intersections report `t` in units of this vector, so a unit direction makes `t` a distance.
  direction : Vec2
} derive(Eq)

///|
pub extend Ray2 with Eq::{equal, not_equal}

///|
/// The ray starting at `origin` and heading along `direction`.
pub fn Ray2::new(origin : Vec2, direction : Vec2) -> Ray2 {
  { origin, direction, }
}

///|
/// The point `t` along the ray.
pub fn Ray2::at(self : Ray2, t : Double) -> Vec2 {
  self.origin + self.direction.scale(t)
}

///|
/// Where the ray first meets the box, as a `t`, or `None` when it misses.
///
/// A ray that starts inside the box meets its surface on the way out, and that
/// crossing is the one reported — the nearest one at `t >= 0`, rather than "the
/// one in front of the origin in the direction of travel".
pub fn Ray2::intersect_aabb(self : Ray2, box : Aabb2) -> Double? {
  match self.intersect_aabb_interval(box) {
    None => None
    Some((entry, exit)) =>
      if entry >= 0.0 {
        Some(entry)
      } else if exit >= 0.0 {
        Some(exit)
      } else {
        None
      }
  }
}

///|
/// The stretch of the ray that lies inside the box, as a pair of `t` values.
///
/// A ray that starts inside the box is already inside at `t = 0`, and the entry
/// is then negative — the point was inside before the ray started, and the
/// interval says from where. `None` when the ray misses the box.
pub fn Ray2::intersect_aabb_interval(
  self : Ray2,
  box : Aabb2,
) -> (Double, Double)? {
  let mut entry : Double = -1.7976931348623157e308
  let mut exit : Double = 1.7976931348623157e308
  for axis in 0..<2 {
    let d = component2(self.direction, axis)
    let origin = component2(self.origin, axis)
    let low = component2(box.min, axis)
    let high = component2(box.max, axis)
    if d == 0.0 {
      if origin < low || origin > high {
        return None
      }
    } else {
      let inv : Double = 1.0 / d
      let mut near = (low - origin) * inv
      let mut far = (high - origin) * inv
      if near > far {
        let swap = near
        near = far
        far = swap
      }
      if near > entry {
        entry = near
      }
      if far < exit {
        exit = far
      }
      if entry > exit {
        return None
      }
    }
  }
  Some((entry, exit))
}

///|
/// Where the ray first meets the rectangle, as a `t`, or `None` when it misses.
pub fn Ray2::intersect_rect(self : Ray2, rect : Rect) -> Double? {
  self.intersect_aabb(rect.to_aabb())
}

///|
/// Where the ray first meets the circle, as a `t`, or `None` when it misses.
///
/// A ray that starts inside the circle meets it on the way out.
pub fn Ray2::intersect_circle(
  self : Ray2,
  center : Vec2,
  radius : Double,
) -> Double? {
  let offset = self.origin - center
  let a = self.direction.length_squared()
  if a == 0.0 {
    return None
  }
  let b = offset.dot(self.direction)
  let c = offset.length_squared() - radius * radius
  let discriminant = b * b - a * c
  if discriminant < 0.0 {
    return None
  }
  let root = discriminant.sqrt()
  let far = (-b + root) / a
  let near = (-b - root) / a
  if near >= 0.0 {
    Some(near)
  } else if far >= 0.0 {
    Some(far)
  } else {
    None
  }
}

///|
/// Whether the two rays start at the same point and head the same way.
pub fn Ray2::approx(self : Ray2, other : Ray2, eps? : Double) -> Bool {
  self.origin.approx(other.origin, eps?) &&
  self.direction.approx(other.direction, eps?)
}

///|
pub impl Show for Ray2 with fn output(self, logger) {
  logger.write_string("Ray2(\{self.origin}, \{self.direction})")
}

///|
pub extend Ray2 with Show::{output, to_string}

///|
pub impl Debug for Ray2 with fn to_repr(self) {
  @debug.Repr::ctor("Ray2", [
    (Some("origin"), self.origin.to_repr()),
    (Some("direction"), self.direction.to_repr()),
  ])
}

///|
pub extend Ray2 with Debug::{to_repr}

///|
/// A half-line in space: a start and a direction.
///
/// What a picking click, a mouse cursor in a 3D scene and a photon all are. The
/// tests here return the parameter `t` of the first surface crossing rather than
/// the point, because the caller usually needs the distance and the point is one
/// multiplication away.
///
/// Values are immutable.
pub(all) struct Ray3 {
  /// Where the ray starts.
  origin : Vec3
  /// Which way it goes. The intersections report `t` in units of this vector, so a unit direction makes `t` a distance.
  direction : Vec3
} derive(Eq)

///|
pub extend Ray3 with Eq::{equal, not_equal}

///|
/// The ray starting at `origin` and heading along `direction`.
pub fn Ray3::new(origin : Vec3, direction : Vec3) -> Ray3 {
  { origin, direction, }
}

///|
/// The point `t` along the ray.
pub fn Ray3::at(self : Ray3, t : Double) -> Vec3 {
  self.origin + self.direction.scale(t)
}

///|
/// Where the ray first meets the box, as a `t`, or `None` when it misses.
///
/// A ray that starts inside the box reports its exit.
pub fn Ray3::intersect_aabb(self : Ray3, box : Aabb3) -> Double? {
  match self.intersect_aabb_interval(box) {
    None => None
    Some((entry, exit)) =>
      if entry >= 0.0 {
        Some(entry)
      } else if exit >= 0.0 {
        Some(exit)
      } else {
        None
      }
  }
}

///|
/// The stretch of the ray that lies inside the box, as a pair of `t` values.
///
/// A ray that starts inside has an entry before its origin. This is the slab test: for each axis the ray is inside the box over an
/// interval, and the intersection of the three intervals is the stretch wanted.
/// A ray parallel to a face never leaves that axis' slab, or never enters it.
pub fn Ray3::intersect_aabb_interval(
  self : Ray3,
  box : Aabb3,
) -> (Double, Double)? {
  let mut entry : Double = -1.7976931348623157e308
  let mut exit : Double = 1.7976931348623157e308
  for axis in 0..<3 {
    let d = component3(self.direction, axis)
    let origin = component3(self.origin, axis)
    let low = component3(box.min, axis)
    let high = component3(box.max, axis)
    if d == 0.0 {
      if origin < low || origin > high {
        return None
      }
    } else {
      let inv : Double = 1.0 / d
      let mut near = (low - origin) * inv
      let mut far = (high - origin) * inv
      if near > far {
        let swap = near
        near = far
        far = swap
      }
      if near > entry {
        entry = near
      }
      if far < exit {
        exit = far
      }
      if entry > exit {
        return None
      }
    }
  }
  Some((entry, exit))
}

///|
/// Where the ray first meets the sphere, as a `t`, or `None` when it misses.
///
/// A ray that starts inside the sphere reports its exit.
pub fn Ray3::intersect_sphere(self : Ray3, sphere : Sphere) -> Double? {
  let offset = self.origin - sphere.center
  let a = self.direction.length_squared()
  if a == 0.0 {
    return None
  }
  let b = offset.dot(self.direction)
  let c = offset.length_squared() - sphere.radius * sphere.radius
  let discriminant = b * b - a * c
  if discriminant < 0.0 {
    return None
  }
  let root = discriminant.sqrt()
  let far = (-b + root) / a
  let near = (-b - root) / a
  if near >= 0.0 {
    Some(near)
  } else if far >= 0.0 {
    Some(far)
  } else {
    None
  }
}

///|
/// Where the ray meets the plane, as a `t`, or `None` when it runs parallel.
///
/// A ray lying inside the plane meets it everywhere and nowhere in particular;
/// that comes back as `None` too.
pub fn Ray3::intersect_plane(self : Ray3, plane : Plane) -> Double? {
  let denominator = plane.normal.dot(self.direction)
  if denominator == 0.0 {
    return None
  }
  let t = (plane.distance - plane.normal.dot(self.origin)) / denominator
  if t >= 0.0 {
    Some(t)
  } else {
    None
  }
}

///|
/// Where the ray meets the triangle, as a `t`, or `None` when it misses.
///
/// Möller–Trumbore: the ray is solved against the triangle's barycentric
/// coordinates directly, without building the plane first, and a hit behind the
/// origin or outside the triangle gives `None`.
pub fn Ray3::intersect_triangle(self : Ray3, triangle : Triangle) -> Double? {
  let edge1 = triangle.b - triangle.a
  let edge2 = triangle.c - triangle.a
  let h = self.direction.cross(edge2)
  let determinant = edge1.dot(h)
  if determinant.abs() < default_epsilon {
    // The ray runs parallel to the triangle's plane.
    return None
  }
  let inv_determinant : Double = 1.0 / determinant
  let s = self.origin - triangle.a
  let u = s.dot(h) * inv_determinant
  let one : Double = 1.0
  if u < 0.0 || u > one {
    return None
  }
  let q = s.cross(edge1)
  let v = self.direction.dot(q) * inv_determinant
  if v < 0.0 || u + v > one {
    return None
  }
  let t = edge2.dot(q) * inv_determinant
  if t >= 0.0 {
    Some(t)
  } else {
    None
  }
}

///|
/// Whether the two rays start at the same point and head the same way.
pub fn Ray3::approx(self : Ray3, other : Ray3, eps? : Double) -> Bool {
  self.origin.approx(other.origin, eps?) &&
  self.direction.approx(other.direction, eps?)
}

///|
pub impl Show for Ray3 with fn output(self, logger) {
  logger.write_string("Ray3(\{self.origin}, \{self.direction})")
}

///|
pub extend Ray3 with Show::{output, to_string}

///|
pub impl Debug for Ray3 with fn to_repr(self) {
  @debug.Repr::ctor("Ray3", [
    (Some("origin"), self.origin.to_repr()),
    (Some("direction"), self.direction.to_repr()),
  ])
}

///|
pub extend Ray3 with Debug::{to_repr}
