// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The samples are fixed inputs, so the tests are deterministic: they check the
// property each distribution promises, not a sequence a generator produced.

///|
test "a point on the unit sphere is a unit vector" {
  let one : Double = 1.0
  let tolerance : Double = 0.00001
  let directions : Array[Vec3] = [
    Vec3::random_on_sphere(0.5, 0.5),
    Vec3::random_on_sphere(0.0, 0.0),
    Vec3::random_on_sphere(0.999, 0.0),
    Vec3::random_on_sphere(0.25, 0.75),
  ]
  for direction in directions {
    assert_true(approx(direction.length(), one, eps=tolerance))
  }
}

///|
test "a point in the unit ball stays inside it" {
  let one : Double = 1.0
  let tolerance : Double = 0.00001
  let points : Array[Vec3] = [
    Vec3::random_in_ball(0.3, 0.6, 0.2),
    Vec3::random_in_ball(0.9, 0.1, 0.8),
    Vec3::random_in_ball(0.5, 0.5, 0.999),
  ]
  for point in points {
    assert_true(point.length() <= one + tolerance)
  }
}

///|
test "a point in the box is in the box" {
  let box = Aabb3::new(Vec3::new(-1.0, 0.0, 2.0), Vec3::new(3.0, 4.0, 5.0))
  let point = box.random_point(0.25, 0.5, 0.75)
  assert_true(box.contains_point(point))
}

///|
test "a point on the sphere sits at the radius" {
  let center = Vec3::new(1.0, 2.0, 3.0)
  let sphere = Sphere::new(center, 2.0)
  let tolerance : Double = 0.00001
  let radius : Double = 2.0
  let on_surface = sphere.random_on_surface(0.5, 0.25)
  assert_true(approx(on_surface.distance(center), radius, eps=tolerance))
  let inside = sphere.random_inside(0.5, 0.5, 0.5)
  assert_true(inside.distance(center) <= radius + tolerance)
}

///|
test "a random rotation is a unit quaternion" {
  let one : Double = 1.0
  let tolerance : Double = 0.00001
  let rotations : Array[Quat] = [
    Quat::random(0.1, 0.2, 0.3),
    Quat::random(0.9, 0.4, 0.7),
    Quat::random(0.5, 0.5, 0.5),
  ]
  for rotation in rotations {
    assert_true(approx(rotation.length(), one, eps=tolerance))
  }
}
