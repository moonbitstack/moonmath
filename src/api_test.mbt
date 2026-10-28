// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The surface as a consumer sees it.
//
// Everything here is reached through the package name, the way code outside this
// repository has to reach it: a missing `pub`, or a `pub extend` that was
// forgotten, shows up in this file and nowhere else. The other tests are white
// box — they can see the inside of the package — so this one exists for the
// things they cannot prove.

///|
test "a camera, a click and a box, from outside" {
  let eye = @moonmath.Vec3::new(0.0, 1.0, 5.0)
  let view = @moonmath.Mat4::look_at(
    eye,
    @moonmath.Vec3::zero(),
    @moonmath.Vec3::unit_y(),
  )
  let projection = @moonmath.Mat4::perspective(
    @moonmath.to_radians(60.0),
    16.0 / 9.0,
    0.1,
    100.0,
  )
  let view_projection = projection * view
  // The origin is in front of the camera, so its depth is positive and less
  // than one.
  let origin = view_projection.transform_point(@moonmath.Vec3::zero())
  assert_true(origin.z > 0.0 && origin.z < 1.0)
  // And it is in the middle of the screen.
  assert_true(origin.x.abs() < 1.0e-5)
  assert_true(origin.y.abs() < 1.0e-5)
}

///|
test "the operators are visible from outside" {
  let a = @moonmath.Vec3::new(1.0, 2.0, 3.0)
  let b = @moonmath.Vec3::splat(2.0)
  assert_eq(a + b, @moonmath.Vec3::new(3.0, 4.0, 5.0))
  assert_eq(a - b, @moonmath.Vec3::new(-1.0, 0.0, 1.0))
  assert_eq(a * b, @moonmath.Vec3::new(2.0, 4.0, 6.0))
  assert_eq(b / b, @moonmath.Vec3::one())
  assert_eq(-a, @moonmath.Vec3::new(-1.0, -2.0, -3.0))
  // The trait methods are reachable as methods too, which is what the `extend`
  // declarations are for.
  assert_eq(a.to_string(), "Vec3(1, 2, 3)")
  let matrix = @moonmath.Mat4::from_translation(@moonmath.Vec3::unit_x())
  assert_eq(
    matrix.transform_point(@moonmath.Vec3::zero()),
    @moonmath.Vec3::unit_x(),
  )
}

///|
test "the geometry answers from outside" {
  let box = @moonmath.Aabb3::new(
    @moonmath.Vec3::splat(-1.0),
    @moonmath.Vec3::one(),
  )
  let ray = @moonmath.Ray3::new(
    @moonmath.Vec3::new(0.0, 0.0, 5.0),
    -@moonmath.Vec3::unit_z(),
  )
  let hit = ray.intersect_aabb(box).unwrap()
  assert_true(@moonmath.approx(hit, 4.0))
  let sphere = @moonmath.Sphere::new(@moonmath.Vec3::zero(), 1.0)
  assert_true(box.contains_point(sphere.center))
  let rotation = @moonmath.Quat::from_axis_angle(
    @moonmath.Vec3::unit_z(),
    @moonmath.half_pi,
  )
  assert_true(
    rotation.rotate(@moonmath.Vec3::unit_x()).approx(@moonmath.Vec3::unit_y()),
  )
}
