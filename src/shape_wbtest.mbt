// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The geometry: rectangles, boxes, rays, planes, spheres, triangles and the
// frustum. Most of these cases have an answer that can be worked out on paper,
// which is what they are checked against.

///|
test "a rectangle knows its corners and its middle" {
  let rect = Rect::from_xywh(0.0, 0.0, 10.0, 4.0)
  assert_true(rect.min().approx(Vec2::zero()))
  assert_true(rect.max().approx(Vec2::new(10.0, 4.0)))
  assert_true(rect.center().approx(Vec2::new(5.0, 2.0)))
  assert_eq(rect.width(), 10.0)
  assert_eq(rect.height(), 4.0)
  assert_eq(rect.area(), 40.0)
  assert_false(rect.is_empty())
  assert_eq(rect.corners()[2], Vec2::new(10.0, 4.0))
}

///|
test "a rectangle with a negative size covers the same points" {
  let flipped = Rect::new(Vec2::new(10.0, 4.0), Vec2::new(-10.0, -4.0))
  assert_true(flipped.min().approx(Vec2::zero()))
  assert_true(flipped.max().approx(Vec2::new(10.0, 4.0)))
  assert_eq(flipped.width(), 10.0)
  assert_eq(flipped.area(), 40.0)
  // Building one from two corners in either order gives the same rectangle.
  let from_edges = Rect::from_edges(10.0, 4.0, 0.0, 0.0)
  assert_true(from_edges.min().approx(Vec2::zero()))
  assert_true(from_edges.max().approx(Vec2::new(10.0, 4.0)))
}

///|
test "containing a point, and sharing area with another rectangle" {
  let rect = Rect::from_xywh(0.0, 0.0, 10.0, 10.0)
  assert_true(rect.contains(Vec2::new(5.0, 5.0)))
  assert_true(rect.contains(Vec2::zero()))
  assert_true(rect.contains(Vec2::new(10.0, 10.0)))
  assert_false(rect.contains(Vec2::new(10.5, 5.0)))
  assert_false(rect.contains(Vec2::new(-0.5, 5.0)))
  let overlapping = Rect::from_xywh(5.0, 5.0, 10.0, 10.0)
  assert_true(rect.intersects(overlapping))
  let overlap = rect.intersection(overlapping).unwrap()
  assert_true(overlap.min().approx(Vec2::new(5.0, 5.0)))
  assert_true(overlap.max().approx(Vec2::new(10.0, 10.0)))
  assert_eq(overlap.area(), 25.0)
  let beyond = rect.union(overlapping)
  assert_true(beyond.min().approx(Vec2::zero()))
  assert_true(beyond.max().approx(Vec2::new(15.0, 15.0)))
  // Touching edges share no area.
  let beside = Rect::from_xywh(10.0, 0.0, 5.0, 10.0)
  assert_false(rect.intersects(beside))
  assert_eq(rect.intersection(beside), None)
  assert_false(rect.union(beside).is_empty())
}

///|
test "insetting a rectangle keeps it centred and never turns it inside out" {
  let rect = Rect::from_xywh(0.0, 0.0, 10.0, 10.0)
  let smaller = rect.inset(1.0)
  assert_true(smaller.min().approx(Vec2::splat(1.0)))
  assert_true(smaller.max().approx(Vec2::splat(9.0)))
  // Growing is insetting by a negative amount.
  let larger = rect.inset(-1.0)
  assert_true(larger.min().approx(Vec2::splat(-1.0)))
  assert_true(larger.max().approx(Vec2::splat(11.0)))
  // Inset past the middle, and it collapses to a point at the centre rather
  // than to a negative extent.
  let gone = rect.inset(6.0)
  assert_true(gone.is_empty())
  assert_true(gone.center().approx(rect.center()))
}

///|
test "a rectangle and a box describe the same points" {
  let rect = Rect::from_xywh(1.0, 2.0, 3.0, 4.0)
  let box = rect.to_aabb()
  assert_true(box.min.approx(Vec2::new(1.0, 2.0)))
  assert_true(box.max.approx(Vec2::new(4.0, 6.0)))
  assert_true(box.to_rect().approx(rect))
  assert_true(
    rect.translate(Vec2::new(1.0, 1.0)).min().approx(Vec2::new(2.0, 3.0)),
  )
}

///|
test "a box around some points, and one around nothing" {
  let points : FixedArray[Vec2] = [
    Vec2::new(1.0, 1.0),
    Vec2::new(3.0, 5.0),
    Vec2::new(2.0, -1.0),
  ]
  let box = Aabb2::from_points(points).unwrap()
  assert_true(box.min.approx(Vec2::new(1.0, -1.0)))
  assert_true(box.max.approx(Vec2::new(3.0, 5.0)))
  assert_eq(Aabb2::from_points([]), None)
  assert_true(Aabb2::empty().is_empty())
  // The empty box is the identity for a union, because its corners are the
  // wrong way round on purpose.
  assert_true(Aabb2::empty().union(box).approx(box))
  assert_true(box.union(Aabb2::empty()).approx(box))
}

///|
test "a box grows, shrinks and answers questions about itself" {
  let box = Aabb2::from_center_half_extents(
    Vec2::new(1.0, 1.0),
    Vec2::new(2.0, 3.0),
  )
  assert_true(box.min.approx(Vec2::new(-1.0, -2.0)))
  assert_true(box.max.approx(Vec2::new(3.0, 4.0)))
  assert_true(box.center().approx(Vec2::new(1.0, 1.0)))
  assert_true(box.size().approx(Vec2::new(4.0, 6.0)))
  assert_true(box.extents().approx(Vec2::new(2.0, 3.0)))
  assert_eq(box.area(), 24.0)
  assert_true(box.contains_point(Vec2::new(0.0, 0.0)))
  assert_false(box.contains_point(Vec2::new(4.0, 0.0)))
  assert_true(box.expand(1.0).contains(box))
  let inner = Aabb2::new(Vec2::zero(), Vec2::splat(0.5))
  assert_true(box.contains(inner))
  assert_false(inner.contains(box))
  assert_true(box.intersects(inner))
  assert_true(box.intersection(inner).unwrap().approx(inner))
}

///|
test "a box in space measures volume and surface" {
  let box = Aabb3::new(Vec3::zero(), Vec3::new(2.0, 3.0, 4.0))
  assert_eq(box.volume(), 24.0)
  assert_eq(box.surface_area(), 52.0)
  assert_true(box.center().approx(Vec3::new(1.0, 1.5, 2.0)))
  assert_eq(box.corners().length(), 8)
  assert_true(box.corners()[7].approx(Vec3::new(0.0, 3.0, 4.0)))
  let moved = box.transform(Mat4::from_translation(Vec3::new(5.0, 0.0, 0.0)))
  assert_true(moved.min.approx(Vec3::new(5.0, 0.0, 0.0)))
  assert_true(moved.max.approx(Vec3::new(7.0, 3.0, 4.0)))
  // A quarter turn about z takes the x extent onto y and leaves the box the
  // same size, with the x extent now running backwards.
  let turned = box.transform(Mat4::from_axis_angle(Vec3::unit_z(), half_pi))
  assert_true(turned.min.approx(Vec3::new(-3.0, 0.0, 0.0), eps=1.0e-5))
  assert_true(turned.max.approx(Vec3::new(0.0, 2.0, 4.0), eps=1.0e-5))
  assert_eq(Aabb3::from_points([]), None)
  assert_true(Aabb3::empty().union(box).approx(box))
}

///|
test "a ray in the plane meets boxes and circles" {
  let box = Aabb2::new(Vec2::zero(), Vec2::splat(2.0))
  let from_outside = Ray2::new(Vec2::new(-1.0, 1.0), Vec2::unit_x())
  assert_true(approx(from_outside.intersect_aabb(box).unwrap(), 1.0))
  assert_true(from_outside.at(1.0).approx(Vec2::new(0.0, 1.0)))
  // From inside, the surface it meets is the one on the way out.
  let from_inside = Ray2::new(Vec2::splat(1.0), Vec2::unit_x())
  assert_true(approx(from_inside.intersect_aabb(box).unwrap(), 1.0))
  assert_eq(
    Ray2::new(Vec2::new(-1.0, 3.0), Vec2::unit_x()).intersect_aabb(box),
    None,
  )
  // A ray running along a face it is outside of never enters.
  assert_eq(
    Ray2::new(Vec2::new(3.0, -1.0), Vec2::unit_y()).intersect_aabb(box),
    None,
  )
  // The interval says where it is inside, which can start behind the origin.
  let inside_interval = from_inside.intersect_aabb_interval(box).unwrap()
  // The point was inside before the ray started, so the stretch starts behind
  // the origin and ends on the face it leaves by.
  assert_true(inside_interval.0 < 0.0)
  assert_true(approx(inside_interval.1, 1.0))
  // The same against the rectangle that covers the box.
  assert_true(approx(from_outside.intersect_rect(box.to_rect()).unwrap(), 1.0))
  let through_centre = Ray2::new(Vec2::new(-2.0, 0.0), Vec2::unit_x())
  assert_true(
    approx(through_centre.intersect_circle(Vec2::zero(), 0.5).unwrap(), 1.5),
  )
  // A ray that starts inside a circle leaves it on the far side.
  assert_true(
    approx(
      Ray2::new(Vec2::zero(), Vec2::unit_x())
      .intersect_circle(Vec2::zero(), 0.5)
      .unwrap(),
      0.5,
    ),
  )
  assert_eq(
    Ray2::new(Vec2::new(-1.0, 3.0), Vec2::unit_x()).intersect_circle(
      Vec2::zero(),
      0.5,
    ),
    None,
  )
}

///|
test "a ray in space meets boxes, spheres, planes and triangles" {
  let box = Aabb3::new(-Vec3::one(), Vec3::one())
  let down = Ray3::new(Vec3::new(0.0, 0.0, 5.0), -Vec3::unit_z())
  assert_true(approx(down.intersect_aabb(box).unwrap(), 4.0))
  assert_true(down.at(4.0).approx(Vec3::new(0.0, 0.0, 1.0)))
  // From inside the box, the exit.
  let from_inside = Ray3::new(Vec3::zero(), Vec3::unit_z())
  assert_true(approx(from_inside.intersect_aabb(box).unwrap(), 1.0))
  assert_eq(
    Ray3::new(Vec3::new(0.0, 2.0, 5.0), -Vec3::unit_z()).intersect_aabb(box),
    None,
  )
  let interval = down.intersect_aabb_interval(box).unwrap()
  assert_true(approx(interval.0, 4.0))
  assert_true(approx(interval.1, 6.0))

  let sphere = Sphere::new(Vec3::zero(), 1.0)
  assert_true(approx(down.intersect_sphere(sphere).unwrap(), 4.0))
  assert_true(
    approx(
      Ray3::new(Vec3::zero(), Vec3::unit_x()).intersect_sphere(sphere).unwrap(),
      1.0,
    ),
  )
  assert_eq(
    Ray3::new(Vec3::new(2.0, 0.0, 5.0), -Vec3::unit_z()).intersect_sphere(
      sphere,
    ),
    None,
  )

  let ground = Plane::new(Vec3::unit_z(), 0.0)
  assert_true(approx(down.intersect_plane(ground).unwrap(), 5.0))
  assert_eq(
    Ray3::new(Vec3::new(0.0, 0.0, 5.0), Vec3::unit_x()).intersect_plane(ground),
    None,
  )
  // Behind the origin is not an intersection.
  assert_eq(
    Ray3::new(Vec3::new(0.0, 0.0, 5.0), Vec3::unit_z()).intersect_plane(ground),
    None,
  )

  let triangle = Triangle::new(Vec3::zero(), Vec3::unit_x(), Vec3::unit_y())
  assert_true(approx(down.intersect_triangle(triangle).unwrap(), 5.0))
  assert_true(approx(triangle.intersect_ray(down).unwrap(), 5.0))
  // Outside the triangle, behind it, and parallel to it.
  assert_eq(
    Ray3::new(Vec3::new(2.0, 2.0, 5.0), -Vec3::unit_z()).intersect_triangle(
      triangle,
    ),
    None,
  )
  assert_eq(
    Ray3::new(Vec3::new(0.2, 0.2, -5.0), -Vec3::unit_z()).intersect_triangle(
      triangle,
    ),
    None,
  )
  assert_eq(
    Ray3::new(Vec3::new(0.2, 0.2, 1.0), Vec3::unit_x()).intersect_triangle(
      triangle,
    ),
    None,
  )
}

///|
test "a plane measures distance, projects, and meets rays" {
  let ground = Plane::from_points(Vec3::zero(), Vec3::unit_x(), Vec3::unit_y()).unwrap()
  assert_true(ground.normal.approx(Vec3::unit_z()))
  assert_eq(ground.distance, 0.0)
  assert_eq(ground.signed_distance(Vec3::new(0.0, 0.0, 2.0)), 2.0)
  assert_eq(ground.signed_distance(Vec3::new(0.0, 0.0, -2.0)), -2.0)
  assert_true(
    ground.project(Vec3::new(1.0, 2.0, 3.0)).approx(Vec3::new(1.0, 2.0, 0.0)),
  )
  assert_true(ground.flip().normal.approx(-Vec3::unit_z()))
  assert_eq(ground.flip().signed_distance(Vec3::new(0.0, 0.0, 2.0)), -2.0)
  // The normal is normalized and the distance scaled with it.
  let high = Plane::new(Vec3::new(0.0, 0.0, 2.0), 4.0)
  assert_true(high.normal.approx(Vec3::unit_z()))
  assert_true(approx(high.distance, 2.0))
  assert_true(
    Plane::from_point_normal(Vec3::new(0.0, 0.0, 3.0), Vec3::zero()) == None,
  )
  // Three collinear points name no plane.
  assert_eq(
    Plane::from_points(Vec3::zero(), Vec3::unit_x(), Vec3::new(2.0, 0.0, 0.0)),
    None,
  )
}

///|
test "panic a plane needs a normal" {
  let _ = Plane::new(Vec3::zero(), 1.0)
}

///|
test "a sphere contains, meets and measures" {
  let sphere = Sphere::new(Vec3::zero(), 2.0)
  assert_true(sphere.contains_point(Vec3::new(1.0, 1.0, 0.0)))
  assert_true(sphere.contains_point(Vec3::new(0.0, 0.0, 2.0)))
  assert_false(sphere.contains_point(Vec3::new(2.0, 2.0, 0.0)))
  assert_true(approx(sphere.surface_area(), 16.0 * pi, eps=1.0e-4))
  assert_true(approx(sphere.volume(), 32.0 * pi / 3.0, eps=1.0e-4))
  assert_true(
    sphere.intersects_sphere(Sphere::new(Vec3::new(3.5, 0.0, 0.0), 2.0)),
  )
  assert_false(
    sphere.intersects_sphere(Sphere::new(Vec3::new(4.5, 0.0, 0.0), 2.0)),
  )
  // A box near the corner of the sphere: the closest point is the corner, not
  // the centre, which is the case that a centre-only test gets wrong.
  let corner = Aabb3::new(Vec3::splat(1.0), Vec3::splat(2.0))
  assert_true(sphere.intersects_aabb(corner))
  assert_false(Sphere::new(Vec3::zero(), 1.5).intersects_aabb(corner))
  assert_true(sphere.intersects_aabb(Aabb3::new(-Vec3::one(), Vec3::one())))
}

///|
test "a triangle has a normal, an area and weights" {
  let triangle = Triangle::new(Vec3::zero(), Vec3::unit_x(), Vec3::unit_y())
  assert_true(triangle.normal().approx(Vec3::unit_z()))
  assert_true(approx(triangle.area(), 0.5))
  let weights = triangle.barycentric(Vec3::new(0.25, 0.25, 0.0)).unwrap()
  assert_true(weights.approx(Vec3::new(0.5, 0.25, 0.25)))
  // A point off the plane is weighted as if it were dropped onto it.
  assert_true(
    triangle
    .barycentric(Vec3::new(0.25, 0.25, 7.0))
    .unwrap()
    .approx(Vec3::new(0.5, 0.25, 0.25)),
  )
  // The corners weigh one, one at a time.
  assert_true(
    triangle.barycentric(Vec3::zero()).unwrap().approx(Vec3::new(1.0, 0.0, 0.0)),
  )
  assert_true(
    triangle
    .barycentric(Vec3::unit_x())
    .unwrap()
    .approx(Vec3::new(0.0, 1.0, 0.0)),
  )
  // A triangle with no area has no weights.
  let flat = Triangle::new(
    Vec3::zero(),
    Vec3::unit_x(),
    Vec3::new(3.0, 0.0, 0.0),
  )
  assert_eq(flat.barycentric(Vec3::unit_x()), None)
  assert_true(flat.normal().approx(Vec3::zero()))
  // The winding decides which side the normal faces.
  let reversed = Triangle::new(Vec3::zero(), Vec3::unit_y(), Vec3::unit_x())
  assert_true(reversed.normal().approx(-Vec3::unit_z()))
}

///|
test "a frustum knows what a camera can see" {
  let projection = Mat4::perspective(half_pi, 1.0, 0.1, 100.0)
  let frustum = Frustum::from_matrix(projection).unwrap()
  assert_eq(frustum.planes().length(), 6)
  assert_true(frustum.contains_point(Vec3::new(0.0, 0.0, -1.0)))
  assert_true(frustum.contains_point(Vec3::new(0.0, 0.0, -50.0)))
  assert_false(frustum.contains_point(Vec3::new(0.0, 0.0, 1.0)))
  // At one unit of depth the view is one unit wide either side of the axis.
  assert_true(frustum.contains_point(Vec3::new(0.9, 0.0, -1.0)))
  assert_false(frustum.contains_point(Vec3::new(1.1, 0.0, -1.0)))
  // A box the near plane cuts through is partly visible.
  let straddling = Aabb3::new(
    Vec3::new(-0.2, -0.2, -2.0),
    Vec3::new(0.2, 0.2, 0.5),
  )
  assert_true(frustum.intersects_aabb(straddling))
  assert_false(frustum.contains_aabb(straddling))
  // A box inside it is wholly visible.
  let inside = Aabb3::new(
    Vec3::new(-0.2, -0.2, -2.0),
    Vec3::new(0.2, 0.2, -1.5),
  )
  assert_true(frustum.contains_aabb(inside))
  assert_true(frustum.intersects_aabb(inside))
  // A box behind the camera is invisible, and one behind it is not near enough
  // to matter.
  let behind = Aabb3::new(Vec3::zero(), Vec3::splat(1.0))
  assert_false(frustum.intersects_aabb(behind))
  assert_false(
    frustum.contains_sphere(Sphere::new(Vec3::new(0.0, 0.0, 5.0), 1.0)),
  )
  assert_false(
    frustum.intersects_sphere(Sphere::new(Vec3::new(0.0, 0.0, 5.0), 1.0)),
  )
  assert_true(
    frustum.contains_sphere(Sphere::new(Vec3::new(0.0, 0.0, -5.0), 0.5)),
  )
  assert_false(
    frustum.contains_sphere(Sphere::new(Vec3::new(0.0, 0.0, -5.0), 100.0)),
  )
  assert_true(
    frustum.intersects_sphere(Sphere::new(Vec3::new(0.0, 0.0, -5.0), 100.0)),
  )
}

///|
test "a frustum in the other depth convention" {
  let projection = Mat4::perspective_gl(half_pi, 1.0, 0.1, 100.0)
  let frustum = Frustum::from_matrix_gl(projection).unwrap()
  assert_true(frustum.contains_point(Vec3::new(0.0, 0.0, -1.0)))
  assert_false(frustum.contains_point(Vec3::new(0.0, 0.0, 1.0)))
  assert_false(frustum.contains_point(Vec3::new(0.0, 0.0, -200.0)))
  // The near plane is at the same place in both conventions.
  assert_false(frustum.contains_point(Vec3::new(0.0, 0.0, -0.05)))
  // Read with the wrong convention, the near plane is somewhere else.
  let misread = Frustum::from_matrix(projection).unwrap()
  assert_false(misread.approx(frustum))
}

///|
test "a degenerate matrix has no frustum" {
  assert_eq(Frustum::from_matrix(Mat4::zero()), None)
  assert_eq(Frustum::from_matrix_gl(Mat4::zero()), None)
  // The identity is a perfectly good, if odd, view-projection: it describes the
  // cube from -1 to 1 in every direction.
  let cube = Frustum::from_matrix(Mat4::identity()).unwrap()
  assert_true(cube.contains_point(Vec3::zero()))
  assert_true(cube.contains_point(Vec3::splat(0.9)))
  assert_false(cube.contains_point(Vec3::splat(1.5)))
}

///|
test "panic a matrix built from the wrong number of values" {
  let _ = Mat4::from_array([1.0, 2.0, 3.0])
}
