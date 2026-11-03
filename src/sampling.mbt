// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The random geometry, in the sense that matters here: the caller brings the
// random numbers and this only turns them into a point with the right
// distribution. A source that gives uniform values in `[0, 1)` is the whole
// contract, so these can be tested against fixed inputs, and no generator is
// baked into the library.

///|
/// A point uniformly distributed over the surface of the unit sphere.
///
/// `u1` and `u2` are independent uniform samples in `[0, 1)`. The height is
/// sampled uniformly rather than the polar angle, which is what keeps the
/// distribution even: sampling the angle uniformly would crowd the poles.
pub fn Vec3::random_on_sphere(u1 : Float, u2 : Float) -> Vec3 {
  let z : Float = 1.0 - 2.0 * u1
  let one : Float = 1.0
  let radius : Float = (one - z * z).max(0.0).sqrt()
  let phi : Float = tau * u2
  { x: radius * @math.cosf(phi), y: radius * @math.sinf(phi), z, }
}

///|
/// A point uniformly distributed through the unit ball.
///
/// `u1`, `u2` and `u3` are independent uniform samples in `[0, 1)`. The radius is
/// the cube root of `u3`, not `u3` itself: the volume grows as the cube of the
/// radius, so a linear radius would pile the points near the centre.
pub fn Vec3::random_in_ball(u1 : Float, u2 : Float, u3 : Float) -> Vec3 {
  let direction = Vec3::random_on_sphere(u1, u2)
  let third : Float = 1.0 / 3.0
  let radius : Float = @math.powf(u3, third)
  direction.scale(radius)
}

///|
/// A point uniformly distributed through the box.
///
/// `u1`, `u2` and `u3` are independent uniform samples in `[0, 1)`, one per axis.
pub fn Aabb3::random_point(
  self : Aabb3,
  u1 : Float,
  u2 : Float,
  u3 : Float,
) -> Vec3 {
  let extent = self.size()
  {
    x: self.min.x + extent.x * u1,
    y: self.min.y + extent.y * u2,
    z: self.min.z + extent.z * u3,
  }
}

///|
/// A point uniformly distributed over the surface of the sphere.
///
/// `u1` and `u2` are independent uniform samples in `[0, 1)`, as for
/// `Vec3::random_on_sphere`.
pub fn Sphere::random_on_surface(self : Sphere, u1 : Float, u2 : Float) -> Vec3 {
  self.center + Vec3::random_on_sphere(u1, u2).scale(self.radius)
}

///|
/// A point uniformly distributed through the sphere.
///
/// `u1`, `u2` and `u3` are independent uniform samples in `[0, 1)`, as for
/// `Vec3::random_in_ball`.
pub fn Sphere::random_inside(
  self : Sphere,
  u1 : Float,
  u2 : Float,
  u3 : Float,
) -> Vec3 {
  self.center + Vec3::random_in_ball(u1, u2, u3).scale(self.radius)
}

///|
/// A uniformly distributed random rotation.
///
/// `u1`, `u2` and `u3` are independent uniform samples in `[0, 1)`. The result is
/// a unit quaternion spread evenly over the rotation group — the construction
/// that makes it even is not obvious, and a quaternion built from three evenly
/// sampled angles would not be.
pub fn Quat::random(u1 : Float, u2 : Float, u3 : Float) -> Quat {
  let one : Float = 1.0
  let a : Float = (one - u1).max(0.0).sqrt()
  let b : Float = u1.max(0.0).sqrt()
  let phi : Float = tau * u2
  let theta : Float = tau * u3
  {
    x: a * @math.sinf(phi),
    y: a * @math.cosf(phi),
    z: b * @math.sinf(theta),
    w: b * @math.cosf(theta),
  }
}
