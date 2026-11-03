// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "the foot of the perpendicular is the closest point" {
  let line = Line3::new(Vec3::zero(), Vec3::unit_x())
  let foot = line.closest_point_to(Vec3::new(3.0, 4.0, 0.0))
  assert_true(foot.approx(Vec3::new(3.0, 0.0, 0.0)))
  assert_true(approx(line.distance_to_point(Vec3::new(3.0, 4.0, 0.0)), 4.0))
}

///|
test "two lines are as far apart as their common perpendicular" {
  // The x axis, and a line along z at y = 3: the shortest join is along y.
  let horizontal = Line3::new(Vec3::zero(), Vec3::unit_x())
  let lifted = Line3::new(Vec3::new(0.0, 3.0, 0.0), Vec3::unit_z())
  assert_true(approx(horizontal.distance_to_line(lifted), 3.0))
  let foot = horizontal.closest_point_to_line(lifted)
  assert_true(foot.approx(Vec3::zero()))
}

///|
test "a line cuts a plane once" {
  // The plane y = 2, and the y axis through the origin.
  let plane = Plane::new(Vec3::unit_y(), 2.0)
  let line = Line3::new(Vec3::zero(), Vec3::unit_y())
  let hit = line.intersect_plane(plane).unwrap()
  assert_true(hit.approx(Vec3::new(0.0, 2.0, 0.0)))
}

///|
test "a line parallel to a plane misses it" {
  let plane = Plane::new(Vec3::unit_y(), 2.0)
  let line = Line3::new(Vec3::zero(), Vec3::unit_x())
  assert_true(line.intersect_plane(plane) is None)
}

///|
test "a line through the view volume meets the frustum" {
  let projection = Mat4::perspective(half_pi, 1.0, 0.1, 100.0)
  let frustum = Frustum::from_matrix(projection).unwrap()
  // The view axis runs straight through it.
  assert_true(frustum.intersects_line(Line3::new(Vec3::zero(), Vec3::unit_z())))
  // A line off to the side, parallel to the image plane, does not.
  let aside = Line3::new(Vec3::new(1000.0, 0.0, 0.0), Vec3::unit_x())
  assert_false(frustum.intersects_line(aside))
}
