// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Matrices: the identities that have to hold, the cases where there is no
// inverse to give, the cameras, and the round trip through a decomposition.

///|
/// A matrix with something in every position, chosen so that it is not singular.
fn sample_mat4() -> Mat4 {
  Mat4::from_array([
    1.5, 0.2, -0.3, 0.1, -0.4, 2.0, 0.6, -0.2, 0.7, -0.5, 1.8, 0.3, 2.0, -1.0, 0.5,
    1.0,
  ])
}

///|
fn sample_mat3() -> Mat3 {
  Mat3::from_array([1.5, 0.2, -0.3, -0.4, 2.0, 0.6, 0.7, -0.5, 1.8])
}

///|
test "the identity is neutral on both sides" {
  let m = sample_mat4()
  assert_true((Mat4::identity() * m).approx(m))
  assert_true((m * Mat4::identity()).approx(m))
  let m3 = sample_mat3()
  assert_true((Mat3::identity() * m3).approx(m3))
  assert_true((m3 * Mat3::identity()).approx(m3))
  let m2 = Mat2::from_array([2.0, 0.5, -1.0, 3.0])
  assert_true((Mat2::identity() * m2).approx(m2))
  assert_true((m2 * Mat2::identity()).approx(m2))
  // And on a vector, where the identity has to leave it exactly alone.
  let v = Vec4::new(1.0, 2.0, 3.0, 4.0)
  assert_eq(Mat4::identity().mul_vec4(v), v)
}

///|
test "a matrix is its columns, and its rows are the other reading" {
  let m = sample_mat3()
  assert_eq(m.col(0), m.c0)
  assert_eq(m.col(1), m.c1)
  assert_eq(m.col(2), m.c2)
  assert_eq(m.row(0), Vec3::new(m.c0.x, m.c1.x, m.c2.x))
  assert_eq(m.get(0, 1), m.c1.x)
  assert_eq(m.get(2, 0), m.c0.z)
  // Rows in, rows out.
  let r0 = Vec3::new(1.0, 2.0, 3.0)
  let r1 = Vec3::new(4.0, 5.0, 6.0)
  let r2 = Vec3::new(7.0, 8.0, 9.0)
  let built = Mat3::from_rows(r0, r1, r2)
  assert_eq(built.row(0), r0)
  assert_eq(built.row(1), r1)
  assert_eq(built.row(2), r2)
  assert_eq(built.get(2, 2), 9.0)
}

///|
test "the array form is the buffer layout" {
  let values : FixedArray[Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
  let m = Mat3::from_array(values)
  assert_eq(m.to_array(), values)
  // Column-major: the first three values are the first column, not the first
  // row.
  assert_eq(m.c0, Vec3::new(1.0, 2.0, 3.0))
  assert_eq(m.row(0), Vec3::new(1.0, 4.0, 7.0))
  let four = Mat4::identity()
  assert_eq(Mat4::from_array(four.to_array()), four)
  let two = Mat2::identity()
  assert_eq(Mat2::from_array(two.to_array()), two)
}

///|
test "transposing twice is doing nothing" {
  let m = sample_mat4()
  assert_true(m.transpose().transpose().approx(m))
  assert_eq(m.transpose().get(0, 3), m.get(3, 0))
  let m3 = sample_mat3()
  assert_true(m3.transpose().transpose().approx(m3))
  // A rotation transposes into its own inverse, which is what makes undoing one
  // cheap.
  let rotation = Mat3::from_axis_angle(Vec3::new(1.0, 2.0, 3.0), 0.9)
  assert_true(
    rotation.transpose().approx(rotation.inverse().unwrap(), eps=1.0e-5),
  )
}

///|
test "the determinant measures what the matrix scales" {
  assert_eq(Mat4::identity().determinant(), 1.0)
  assert_eq(Mat3::identity().determinant(), 1.0)
  assert_eq(Mat2::identity().determinant(), 1.0)
  // Scaling by two in every direction multiplies volumes by eight.
  let doubled = Mat4::from_scale(Vec3::splat(2.0))
  assert_eq(doubled.determinant(), 8.0)
  assert_eq(Mat3::from_scale(Vec3::splat(2.0)).determinant(), 8.0)
  assert_eq(Mat2::from_scale(Vec2::splat(2.0)).determinant(), 4.0)
  // A rotation preserves volume; a reflection flips its sign.
  let rotation = Mat3::from_axis_angle(Vec3::unit_y(), 1.1)
  assert_true(approx(rotation.determinant(), 1.0))
  let mirror = Mat3::from_scale(Vec3::new(-1.0, 1.0, 1.0))
  assert_eq(mirror.determinant(), -1.0)
  // Three vectors that lie in a plane span no volume.
  let flat = Mat3::from_cols(
    Vec3::new(1.0, 0.0, 0.0),
    Vec3::new(0.0, 1.0, 0.0),
    Vec3::new(1.0, 1.0, 0.0),
  )
  assert_eq(flat.determinant(), 0.0)
}

///|
test "an inverse undoes its matrix" {
  let m = sample_mat4()
  let inverse = m.inverse().unwrap()
  assert_true((m * inverse).approx(Mat4::identity(), eps=1.0e-4))
  assert_true((inverse * m).approx(Mat4::identity(), eps=1.0e-4))
  let m3 = sample_mat3()
  let inverse3 = m3.inverse().unwrap()
  assert_true((m3 * inverse3).approx(Mat3::identity(), eps=1.0e-4))
  assert_true((inverse3 * m3).approx(Mat3::identity(), eps=1.0e-4))
  let m2 = Mat2::from_array([2.0, 0.5, -1.0, 3.0])
  assert_true((m2 * m2.inverse().unwrap()).approx(Mat2::identity(), eps=1.0e-5))
  // The determinant of the inverse is the reciprocal of the determinant.
  assert_true(approx(inverse.determinant(), 1.0 / m.determinant(), eps=1.0e-4))
}

///|
test "a singular matrix has no inverse" {
  // Two identical columns: the second direction adds nothing.
  let flat2 = Mat2::from_cols(Vec2::new(1.0, 2.0), Vec2::new(2.0, 4.0))
  assert_eq(flat2.inverse(), None)
  let flat3 = Mat3::from_cols(
    Vec3::unit_x(),
    Vec3::unit_y(),
    Vec3::new(1.0, 1.0, 0.0),
  )
  assert_eq(flat3.inverse(), None)
  let flat4 = Mat4::from_cols(
    Vec4::unit_x(),
    Vec4::unit_y(),
    Vec4::unit_z(),
    Vec4::unit_w(),
  )
  assert_true(flat4.inverse() is Some(_))
  // A projection that maps the whole of space onto a plane has no inverse.
  let squashed = Mat4::from_scale(Vec3::new(1.0, 0.0, 1.0))
  assert_eq(squashed.inverse(), None)
}

///|
test "panic matrix division is only defined against an invertible matrix" {
  let squashed = Mat4::from_scale(Vec3::new(1.0, 0.0, 1.0))
  let _ = Mat4::identity() / squashed
}

///|
test "scale, rotation and translation compose and come apart again" {
  let rotation = Quat::from_axis_angle(Vec3::new(1.0, 2.0, 3.0), 0.7)
  let trs = Trs::new(
    Vec3::new(1.0, -2.0, 3.0),
    rotation,
    Vec3::new(2.0, 3.0, 4.0),
  )
  let m = Mat4::from_trs(trs)
  let back = m.to_trs().unwrap()
  assert_true(back.translation.approx(trs.translation))
  assert_true(back.rotation.approx(trs.rotation))
  assert_true(back.scale.approx(trs.scale))
  // And the matrix rebuilt from the decomposition is the matrix again.
  assert_true(Mat4::from_trs(back).approx(m, eps=1.0e-5))
}

///|
test "a mirrored scale comes back with its sign on the first axis" {
  let trs = Trs::new(
    Vec3::new(0.5, 1.5, -1.0),
    Quat::from_axis_angle(Vec3::unit_z(), 0.4),
    Vec3::new(-2.0, 3.0, 4.0),
  )
  let m = Mat4::from_trs(trs)
  let back = m.to_trs().unwrap()
  assert_true(approx(back.scale.x, -2.0, eps=1.0e-4))
  assert_true(approx(back.scale.y, 3.0, eps=1.0e-4))
  assert_true(approx(back.scale.z, 4.0, eps=1.0e-4))
  assert_true(back.rotation.approx(trs.rotation))
  assert_true(Mat4::from_trs(back).approx(m, eps=1.0e-4))
}

///|
test "a matrix with no scale has no decomposition, and one that is not a trs has no exact one" {
  let squashed = Mat4::from_scale(Vec3::new(1.0, 0.0, 1.0))
  assert_eq(squashed.to_trs(), None)
  // A shear is a rotation's columns leaning towards each other, and there is no
  // scale and rotation that reproduces it.
  let sheared = Mat4::from_array([
    1.0, 0.0, 0.0, 0.0, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
  ])
  assert_eq(sheared.to_trs(), None)
  // A pure translation is the easy case.
  let moved = Mat4::from_translation(Vec3::new(4.0, 5.0, 6.0))
  let back = moved.to_trs().unwrap()
  assert_true(back.translation.approx(Vec3::new(4.0, 5.0, 6.0)))
  assert_true(back.rotation.approx(Quat::identity()))
  assert_true(back.scale.approx(Vec3::one()))
}

///|
test "a rotation and a scale are the same matrix whether built from a quat or a trs" {
  let rotation = Quat::from_axis_angle(Vec3::new(0.0, 1.0, 0.0), 1.2)
  assert_true(Mat3::from_quat(rotation).approx(rotation.to_mat3()))
  assert_true(Mat4::from_quat(rotation).approx(rotation.to_mat4()))
  let trs = Trs::new(Vec3::zero(), rotation, Vec3::one())
  assert_true(Mat4::from_trs(trs).approx(rotation.to_mat4()))
}

///|
test "the upper-left block of a 4x4 is the 3x3" {
  let m3 = sample_mat3()
  let m4 = Mat4::from_mat3(m3)
  assert_true(Mat3::from_mat4(m4).approx(m3))
  assert_eq(m4.c3, Vec4::new(0.0, 0.0, 0.0, 1.0))
}

///|
test "a point moves and a direction does not" {
  let m = Mat4::from_translation(Vec3::new(1.0, 2.0, 3.0))
  assert_true(m.transform_point(Vec3::zero()).approx(Vec3::new(1.0, 2.0, 3.0)))
  assert_true(m.transform_vector(Vec3::unit_x()).approx(Vec3::unit_x()))
  assert_true(m.transform_vector(Vec3::zero()).approx(Vec3::zero()))
}

///|
test "look_at puts the camera at the origin looking down its own z" {
  let eye = Vec3::new(2.0, 3.0, 5.0)
  let target = Vec3::new(-1.0, 0.0, 1.0)
  let view = Mat4::look_at(eye, target, Vec3::unit_y())
  assert_true(view.transform_point(eye).approx(Vec3::zero(), eps=1.0e-5))
  // The target lands straight ahead: on the camera's -z axis, at the distance
  // between them.
  let ahead = view.transform_point(target)
  assert_true(ahead.x.abs() < 1.0e-5 && ahead.y.abs() < 1.0e-5)
  assert_true(approx(ahead.z, -target.distance(eye), eps=1.0e-4))
  // Up stays up.
  let up = view.transform_vector(Vec3::unit_y())
  assert_true(up.y > 0.0)
  assert_true(approx(up.length(), 1.0))
}

///|
test "look_at has no answer for a degenerate camera" {
  // Looking at the point you are standing on.
  let same = Mat4::look_at(Vec3::zero(), Vec3::zero(), Vec3::unit_y())
  assert_true(same.approx(Mat4::identity()))
  // Looking straight up, with up as the up vector.
  let straight = Mat4::look_at(Vec3::zero(), Vec3::unit_y(), Vec3::unit_y())
  assert_true(straight.approx(Mat4::identity()))
}

///|
test "the perspective projection maps the near plane to zero and the far plane to one" {
  let near : Float = 0.1
  let far : Float = 100.0
  let projection = Mat4::perspective(half_pi, 1.0, near, far)
  let at_near = projection.mul_vec4(Vec4::new(0.0, 0.0, -near, 1.0))
  assert_true(approx(at_near.z / at_near.w, 0.0))
  let at_far = projection.mul_vec4(Vec4::new(0.0, 0.0, -far, 1.0))
  assert_true(approx(at_far.z / at_far.w, 1.0, eps=1.0e-4))
  // A field of view of a quarter turn makes the near plane one unit across at
  // one unit of depth, on both axes.
  let corner = projection.mul_vec4(Vec4::new(near, -near, -near, 1.0))
  assert_true(approx(corner.x / corner.w, 1.0))
  assert_true(approx(corner.y / corner.w, -1.0))
}

///|
test "the gl perspective projection spans minus one to one" {
  let near : Float = 0.1
  let far : Float = 100.0
  let projection = Mat4::perspective_gl(half_pi, 1.0, near, far)
  let at_near = projection.mul_vec4(Vec4::new(0.0, 0.0, -near, 1.0))
  assert_true(approx(at_near.z / at_near.w, -1.0))
  let at_far = projection.mul_vec4(Vec4::new(0.0, 0.0, -far, 1.0))
  assert_true(approx(at_far.z / at_far.w, 1.0, eps=1.0e-4))
}

///|
test "the infinite perspective projection still starts at zero" {
  let near : Float = 0.5
  let projection = Mat4::perspective_infinite(half_pi, 1.0, near)
  let at_near = projection.mul_vec4(Vec4::new(0.0, 0.0, -near, 1.0))
  assert_true(approx(at_near.z / at_near.w, 0.0))
  // Depth approaches one as the distance grows, and passes it nowhere.
  let far = projection.mul_vec4(Vec4::new(0.0, 0.0, -100000.0, 1.0))
  assert_true(approx(far.z / far.w, 1.0, eps=1.0e-4))
  let beyond = projection.mul_vec4(Vec4::new(0.0, 0.0, -1000000.0, 1.0))
  assert_true(beyond.z < beyond.w)
}

///|
test "the infinite gl perspective projection starts at minus one" {
  let near : Float = 0.5
  let projection = Mat4::perspective_infinite_gl(half_pi, 1.0, near)
  let at_near = projection.mul_vec4(Vec4::new(0.0, 0.0, -near, 1.0))
  assert_true(approx(at_near.z / at_near.w, -1.0))
  let far = projection.mul_vec4(Vec4::new(0.0, 0.0, -100000.0, 1.0))
  assert_true(approx(far.z / far.w, 1.0, eps=1.0e-4))
}

///|
test "the orthographic projection is a box mapped onto the unit cube" {
  let projection = Mat4::orthographic(-2.0, 2.0, -1.0, 1.0, 0.5, 50.0)
  let at_near_corner = projection.transform_point(Vec3::new(-2.0, -1.0, -0.5))
  assert_true(at_near_corner.approx(Vec3::new(-1.0, -1.0, 0.0)))
  let at_far_corner = projection.transform_point(Vec3::new(2.0, 1.0, -50.0))
  assert_true(at_far_corner.approx(Vec3::new(1.0, 1.0, 1.0), eps=1.0e-4))
  // The middle of the box is the middle of the cube.
  let center = projection.transform_point(Vec3::new(0.0, 0.0, -25.25))
  assert_true(center.x.abs() < 1.0e-6 && center.y.abs() < 1.0e-6)
  assert_true(approx(center.z, 0.5, eps=1.0e-4))
}

///|
test "the gl orthographic projection spans minus one to one in depth" {
  let projection = Mat4::orthographic_gl(-1.0, 1.0, -1.0, 1.0, 0.5, 50.0)
  let at_near = projection.transform_point(Vec3::new(0.0, 0.0, -0.5))
  assert_true(approx(at_near.z, -1.0))
  let at_far = projection.transform_point(Vec3::new(0.0, 0.0, -50.0))
  assert_true(approx(at_far.z, 1.0, eps=1.0e-4))
}

///|
test "a frustum and a perspective projection agree when the frustum is centred" {
  let near : Float = 0.5
  let far : Float = 20.0
  let fov : Float = to_radians(60.0)
  let half_height = @math.tanf(fov * 0.5) * near
  let half_width = half_height * 1.5
  let from_frustum = Mat4::frustum(
    -half_width,
    half_width,
    -half_height,
    half_height,
    near,
    far,
  )
  let from_angle = Mat4::perspective(fov, 1.5, near, far)
  assert_true(from_frustum.approx(from_angle, eps=1.0e-5))
}

///|
test "a degenerate projection is the identity rather than a matrix of NaNs" {
  assert_true(
    Mat4::orthographic(1.0, 1.0, -1.0, 1.0, 0.5, 50.0).approx(Mat4::identity()),
  )
  assert_true(
    Mat4::orthographic(-1.0, 1.0, 1.0, 1.0, 0.5, 50.0).approx(Mat4::identity()),
  )
  assert_true(
    Mat4::orthographic(-1.0, 1.0, -1.0, 1.0, 5.0, 5.0).approx(Mat4::identity()),
  )
  assert_true(
    Mat4::frustum(0.0, 0.0, -1.0, 1.0, 0.5, 50.0).approx(Mat4::identity()),
  )
  assert_true(
    Mat4::frustum(-1.0, 1.0, -1.0, 1.0, 0.0, 50.0).approx(Mat4::identity()),
  )
}

///|
test "a shear matrix keeps its inverse honest" {
  let shear = Mat4::from_array([
    1.0, 0.0, 0.0, 0.0, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
  ])
  let inverse = shear.inverse().unwrap()
  assert_true((shear * inverse).approx(Mat4::identity(), eps=1.0e-5))
  // The second column carries half of y into x; the inverse takes it back out.
  assert_true(
    shear
    .transform_point(Vec3::new(2.0, 1.0, 0.0))
    .approx(Vec3::new(2.5, 1.0, 0.0)),
  )
  assert_true(
    inverse
    .transform_point(Vec3::new(2.5, 1.0, 0.0))
    .approx(Vec3::new(2.0, 1.0, 0.0)),
  )
}
