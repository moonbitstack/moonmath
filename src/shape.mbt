// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// An infinite plane in space: the set of points `p` with `dot(normal, p) ==
/// distance`, where the normal is a unit vector.
///
/// The offset form rather than point-and-normal, because the signed distance of
/// a point is then a dot product and no subtraction, which is what a frustum
/// does six times per box.
///
/// Values are immutable.
pub(all) struct Plane {
  normal : Vec3
  distance : Float
} derive(Eq)

///|
pub extend Plane with Eq::{equal, not_equal}

///|
/// The plane whose normal is `normal` and whose signed distance from the origin
/// is `distance`.
///
/// `normal` is normalized, and `distance` scaled with it, so that
/// `signed_distance` counts the same units as the coordinates. A zero normal
/// names no plane and aborts: there is no answer to give back.
pub fn Plane::new(normal : Vec3, distance : Float) -> Plane {
  match normal.try_normalize() {
    None => abort("Plane::new with a zero normal")
    Some(unit) => { normal: unit, distance: distance / normal.length(), }
  }
}

///|
/// The plane through `point` with the given normal.
pub fn Plane::from_point_normal(point : Vec3, normal : Vec3) -> Plane? {
  match normal.try_normalize() {
    None => None
    Some(unit) => Some({ normal: unit, distance: unit.dot(point), })
  }
}

///|
/// The plane through the three points, or `None` when they are collinear.
///
/// The normal faces the way the points wind, by the right-hand rule, so the
/// winding order decides which side is positive.
pub fn Plane::from_points(a : Vec3, b : Vec3, c : Vec3) -> Plane? {
  match (b - a).cross(c - a).try_normalize() {
    None => None
    Some(normal) => Some({ normal, distance: normal.dot(a), })
  }
}

///|
/// The distance from the plane to the point, positive on the side the normal
/// points to.
pub fn Plane::signed_distance(self : Plane, point : Vec3) -> Float {
  self.normal.dot(point) - self.distance
}

///|
/// The point of the plane closest to `point`: the point projected onto it.
pub fn Plane::project(self : Plane, point : Vec3) -> Vec3 {
  point - self.normal.scale(self.signed_distance(point))
}

///|
/// Where the ray meets the plane, as a `t`, or `None` when it runs parallel or
/// the crossing is behind the origin.
pub fn Plane::intersect_ray(self : Plane, ray : Ray3) -> Float? {
  let denominator = self.normal.dot(ray.direction)
  if denominator == 0.0 {
    return None
  }
  let t = (self.distance - self.normal.dot(ray.origin)) / denominator
  if t >= 0.0 {
    Some(t)
  } else {
    None
  }
}

///|
/// The same plane with the other side facing out.
pub fn Plane::flip(self : Plane) -> Plane {
  { normal: -self.normal, distance: -self.distance, }
}

///|
/// Whether the normal and the distance are finite.
pub fn Plane::is_finite(self : Plane) -> Bool {
  self.normal.is_finite() && !(self.distance.is_nan() || self.distance.is_inf())
}

///|
/// Whether the two planes are the same to within `eps`.
pub fn Plane::approx(self : Plane, other : Plane, eps? : Float) -> Bool {
  self.normal.approx(other.normal, eps?) &&
  approx(self.distance, other.distance, eps?)
}

///|
pub impl Show for Plane with fn output(self, logger) {
  logger.write_string("Plane(\{self.normal}, \{self.distance})")
}

///|
pub extend Plane with Show::{output, to_string}

///|
pub impl Debug for Plane with fn to_repr(self) {
  @debug.Repr::ctor("Plane", [
    (Some("normal"), self.normal.to_repr()),
    (Some("distance"), @debug.Repr::float(self.distance)),
  ])
}

///|
pub extend Plane with Debug::{to_repr}

///|
/// A sphere: a centre and a radius.
///
/// Values are immutable.
pub(all) struct Sphere {
  center : Vec3
  radius : Float
} derive(Eq)

///|
pub extend Sphere with Eq::{equal, not_equal}

///|
/// The sphere with the given centre and radius.
pub fn Sphere::new(center : Vec3, radius : Float) -> Sphere {
  { center, radius, }
}

///|
/// Whether the point is inside or on the surface.
pub fn Sphere::contains_point(self : Sphere, point : Vec3) -> Bool {
  point.distance_squared(self.center) <= self.radius * self.radius
}

///|
/// Whether the two spheres overlap or touch.
pub fn Sphere::intersects_sphere(self : Sphere, other : Sphere) -> Bool {
  let reach = self.radius + other.radius
  self.center.distance_squared(other.center) <= reach * reach
}

///|
/// Whether the sphere and the box overlap or touch.
///
/// The point of the box closest to the centre is the one that decides it: if
/// that point is within the radius, the two meet. Testing the centre against
/// the box alone would call a sphere near a corner a miss.
pub fn Sphere::intersects_aabb(self : Sphere, box : Aabb3) -> Bool {
  let closest = self.center.clamp(box.min, box.max)
  closest.distance_squared(self.center) <= self.radius * self.radius
}

///|
/// The area of the surface.
pub fn Sphere::surface_area(self : Sphere) -> Float {
  let four : Float = 4.0
  four * pi * self.radius * self.radius
}

///|
/// The volume it encloses.
pub fn Sphere::volume(self : Sphere) -> Float {
  let four_thirds : Float = 4.0 / 3.0
  four_thirds * pi * self.radius * self.radius * self.radius
}

///|
/// Whether the two spheres agree to within `eps`.
pub fn Sphere::approx(self : Sphere, other : Sphere, eps? : Float) -> Bool {
  self.center.approx(other.center, eps?) &&
  approx(self.radius, other.radius, eps?)
}

///|
pub impl Show for Sphere with fn output(self, logger) {
  logger.write_string("Sphere(\{self.center}, \{self.radius})")
}

///|
pub extend Sphere with Show::{output, to_string}

///|
pub impl Debug for Sphere with fn to_repr(self) {
  @debug.Repr::ctor("Sphere", [
    (Some("center"), self.center.to_repr()),
    (Some("radius"), @debug.Repr::float(self.radius)),
  ])
}

///|
pub extend Sphere with Debug::{to_repr}

///|
/// A triangle in space: three corners in winding order.
///
/// The winding decides which side the normal faces, by the right-hand rule.
///
/// Values are immutable.
pub(all) struct Triangle {
  a : Vec3
  b : Vec3
  c : Vec3
} derive(Eq)

///|
pub extend Triangle with Eq::{equal, not_equal}

///|
/// The triangle with the three given corners.
pub fn Triangle::new(a : Vec3, b : Vec3, c : Vec3) -> Triangle {
  { a, b, c, }
}

///|
/// The unit normal, facing the way the corners wind.
///
/// A triangle with no area — three collinear points — has no normal, and comes
/// back as the zero vector rather than a NaN.
pub fn Triangle::normal(self : Triangle) -> Vec3 {
  (self.b - self.a).cross(self.c - self.a).normalize()
}

///|
/// The area.
pub fn Triangle::area(self : Triangle) -> Float {
  let half : Float = 0.5
  half * (self.b - self.a).cross(self.c - self.a).length()
}

///|
/// The barycentric coordinates of a point with respect to the triangle.
///
/// The three weights sum to one, and a point inside has all three in `0..1`. The
/// point is projected onto the triangle's plane first, so a point off the plane
/// still has coordinates — they are those of the closest point on the plane.
/// `None` when the triangle has no area to weight against.
pub fn Triangle::barycentric(self : Triangle, point : Vec3) -> Vec3? {
  let v0 = self.b - self.a
  let v1 = self.c - self.a
  let v2 = point - self.a
  let d00 = v0.dot(v0)
  let d01 = v0.dot(v1)
  let d11 = v1.dot(v1)
  let d20 = v2.dot(v0)
  let d21 = v2.dot(v1)
  let denominator = d00 * d11 - d01 * d01
  if denominator == 0.0 {
    None
  } else {
    let inv : Float = 1.0 / denominator
    let v = (d11 * d20 - d01 * d21) * inv
    let w = (d00 * d21 - d01 * d20) * inv
    let one : Float = 1.0
    Some({ x: one - v - w, y: v, z: w, })
  }
}

///|
/// Where the ray meets the triangle, as a `t`, or `None` when it misses.
///
/// The same test as `Ray3::intersect_triangle`, written from this side for code
/// that already has the triangle.
pub fn Triangle::intersect_ray(self : Triangle, ray : Ray3) -> Float? {
  ray.intersect_triangle(self)
}

///|
/// Whether the two triangles have the same corners to within `eps`.
pub fn Triangle::approx(
  self : Triangle,
  other : Triangle,
  eps? : Float,
) -> Bool {
  self.a.approx(other.a, eps?) &&
  self.b.approx(other.b, eps?) &&
  self.c.approx(other.c, eps?)
}

///|
pub impl Show for Triangle with fn output(self, logger) {
  logger.write_string("Triangle(\{self.a}, \{self.b}, \{self.c})")
}

///|
pub extend Triangle with Show::{output, to_string}

///|
pub impl Debug for Triangle with fn to_repr(self) {
  @debug.Repr::ctor("Triangle", [
    (Some("a"), self.a.to_repr()),
    (Some("b"), self.b.to_repr()),
    (Some("c"), self.c.to_repr()),
  ])
}

///|
pub extend Triangle with Debug::{to_repr}
