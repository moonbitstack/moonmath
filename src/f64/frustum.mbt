// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The six planes bounding what a camera can see, each facing inwards.
///
/// A view-projection matrix describes the visible volume as a set of
/// inequalities in clip space; each of the six becomes one plane in world space,
/// and culling is then a signed distance per plane per object. That is the
/// cheapest test that still rejects most of a scene, which is why it is the one
/// every renderer starts with.
///
/// The planes are built for a matrix whose depth range is `0..1`. For an
/// OpenGL-style matrix, whose near plane sits at -1, use `from_matrix_gl`.
pub struct Frustum {
  /// The six planes, in the order left, right, bottom, top, near, far.
  planes : FixedArray[Plane]
}

///|
/// Whether the two hold the same six planes, exactly.
pub impl Eq for Frustum with fn equal(self, other) {
  for i in 0..<6 {
    if self.planes[i] != other.planes[i] {
      return false
    }
  }
  true
}

///|
pub extend Frustum with Eq::{equal, not_equal}

///|
/// The planes of the frustum, in the order left, right, bottom, top, near, far.
///
/// A copy: the array the frustum holds cannot be reached from outside, so a
/// caller cannot break the six-plane invariant by writing into it.
pub fn Frustum::planes(self : Frustum) -> FixedArray[Plane] {
  let copy = FixedArray::make(6, self.planes[0])
  for i in 0..<6 {
    copy[i] = self.planes[i]
  }
  copy
}

///|
/// The plane at `index`, counted from zero in the order left, right, bottom,
/// top, near, far.
pub fn Frustum::plane(self : Frustum, index : Int32) -> Plane {
  self.planes[index]
}

///|
/// The frustum of a view-projection matrix whose depth range is `0..1`, or
/// `None` when the matrix does not describe one.
///
/// The six planes are the six clip-space inequalities pulled back into world
/// space: the left plane is the row `w + x` of the matrix, and so on. A matrix
/// that is singular or degenerate — a projection with no near plane, say — gives
/// a plane with no normal, and there is no frustum to return.
///
/// ```mbt check
/// test {
///   let projection = @f64.Mat4::perspective(@f64.half_pi, 1.0, 0.1, 100.0)
///   let frustum = @f64.Frustum::from_matrix(projection).unwrap()
///   // A point just in front of the camera is inside, one behind it is not.
///   assert_true(frustum.contains_point(@f64.Vec3::new(0.0, 0.0, -1.0)))
///   assert_false(frustum.contains_point(@f64.Vec3::new(0.0, 0.0, 1.0)))
/// }
/// ```
pub fn Frustum::from_matrix(m : Mat4) -> Frustum? {
  let r0 = m.row(0)
  let r1 = m.row(1)
  let r2 = m.row(2)
  let r3 = m.row(3)
  Frustum::from_clip_rows(r3 + r0, r3 - r0, r3 + r1, r3 - r1, r2, r3 - r2)
}

///|
/// The frustum of a view-projection matrix whose depth range is `-1..1`.
pub fn Frustum::from_matrix_gl(m : Mat4) -> Frustum? {
  let r0 = m.row(0)
  let r1 = m.row(1)
  let r2 = m.row(2)
  let r3 = m.row(3)
  Frustum::from_clip_rows(r3 + r0, r3 - r0, r3 + r1, r3 - r1, r3 + r2, r3 - r2)
}

///|
/// The six planes from six clip-space rows, normalized, or `None` when one of
/// them names no plane.
fn Frustum::from_clip_rows(
  left : Vec4,
  right : Vec4,
  bottom : Vec4,
  top : Vec4,
  near : Vec4,
  far : Vec4,
) -> Frustum? {
  let rows = [left, right, bottom, top, near, far]
  let planes = FixedArray::make(6, Plane::new(Vec3::unit_z(), 0.0))
  for i in 0..<6 {
    let row = rows[i]
    let normal = row.xyz()
    match normal.try_normalize() {
      None => return None
      Some(unit) => {
        let scale : Double = 1.0 / normal.length()
        planes[i] = { normal: unit, distance: -row.w * scale, }
      }
    }
  }
  Some({ planes, })
}

///|
/// Whether the point is inside all six planes, boundary included.
pub fn Frustum::contains_point(self : Frustum, point : Vec3) -> Bool {
  for i in 0..<6 {
    if self.planes[i].signed_distance(point) < 0.0 {
      return false
    }
  }
  true
}

///|
/// Whether the box lies entirely inside the frustum.
///
/// The corner furthest from each plane — the one the normal points away from —
/// decides: if even that corner is inside, all eight are.
pub fn Frustum::contains_aabb(self : Frustum, box : Aabb3) -> Bool {
  for i in 0..<6 {
    let plane = self.planes[i]
    // The corner the plane's normal points away from: the one that is nearest
    // to being outside. Built by component rather than as a `Vec3`, which would
    // be one heap value per plane.
    let x = if plane.normal.x >= 0.0 { box.min.x } else { box.max.x }
    let y = if plane.normal.y >= 0.0 { box.min.y } else { box.max.y }
    let z = if plane.normal.z >= 0.0 { box.min.z } else { box.max.z }
    let distance = plane.normal.x * x +
      plane.normal.y * y +
      plane.normal.z * z -
      plane.distance
    if distance < 0.0 {
      return false
    }
  }
  true
}

///|
/// Whether the frustum overlaps any part of the box.
///
/// The opposite corner from `contains_aabb`, for the opposite question: a box is
/// out only when it lies wholly behind one plane.
pub fn Frustum::intersects_aabb(self : Frustum, box : Aabb3) -> Bool {
  for i in 0..<6 {
    let plane = self.planes[i]
    // The corner the normal points towards: the last one that can still be
    // inside. When even that one is out, the whole box is behind the plane.
    let x = if plane.normal.x >= 0.0 { box.max.x } else { box.min.x }
    let y = if plane.normal.y >= 0.0 { box.max.y } else { box.min.y }
    let z = if plane.normal.z >= 0.0 { box.max.z } else { box.min.z }
    let distance = plane.normal.x * x +
      plane.normal.y * y +
      plane.normal.z * z -
      plane.distance
    if distance < 0.0 {
      return false
    }
  }
  true
}

///|
/// Whether the sphere lies entirely inside the frustum.
pub fn Frustum::contains_sphere(self : Frustum, sphere : Sphere) -> Bool {
  for i in 0..<6 {
    if self.planes[i].signed_distance(sphere.center) < sphere.radius {
      return false
    }
  }
  true
}

///|
/// Whether the frustum overlaps any part of the sphere.
pub fn Frustum::intersects_sphere(self : Frustum, sphere : Sphere) -> Bool {
  for i in 0..<6 {
    if self.planes[i].signed_distance(sphere.center) < -sphere.radius {
      return false
    }
  }
  true
}

///|
/// Whether two frusta have the same six planes to within `eps`.
pub fn Frustum::approx(self : Frustum, other : Frustum, eps? : Double) -> Bool {
  for i in 0..<6 {
    if !self.planes[i].approx(other.planes[i], eps?) {
      return false
    }
  }
  true
}

///|
pub impl Show for Frustum with fn output(self, logger) {
  logger.write_string("Frustum[")
  for i in 0..<6 {
    if i > 0 {
      logger.write_string(", ")
    }
    self.planes[i].output(logger)
  }
  logger.write_string("]")
}

///|
pub extend Frustum with Show::{output, to_string}

///|
pub impl Debug for Frustum with fn to_repr(self) {
  let children : Array[@debug.Repr] = Array(capacity=6)
  for i in 0..<6 {
    children.push(self.planes[i].to_repr())
  }
  @debug.Repr::ctor("Frustum", [(None, @debug.Repr::array(children))])
}

///|
pub extend Frustum with Debug::{to_repr}
