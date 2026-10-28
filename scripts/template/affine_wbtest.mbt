// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The two affine types: what they do that the matrices they wrap do not, and the
// places where the two forms have to agree.

///|
test "an affine transform of the plane moves points and turns directions" {
  let turn = Affine2::from_angle(half_pi)
  assert_true(turn.transform_point(Vec2::unit_x()).approx(Vec2::unit_y()))
  assert_true(turn.transform_vector(Vec2::unit_x()).approx(Vec2::unit_y()))
  let moved = Affine2::from_translation(Vec2::new(3.0, 4.0))
  assert_true(moved.transform_point(Vec2::zero()).approx(Vec2::new(3.0, 4.0)))
  // A direction has no position, so the translation leaves it where it was.
  assert_true(moved.transform_vector(Vec2::unit_x()).approx(Vec2::unit_x()))
  assert_true(Affine2::identity().transform_point(Vec2::new(1.0, -2.0)).approx(Vec2::new(1.0, -2.0)))
}

///|
test "composition of affine transforms applies the right-hand one first" {
  let moved = Affine2::from_translation(Vec2::new(1.0, 0.0))
  let turned = Affine2::from_angle(half_pi)
  // Turn, then move: the point comes out along +y and one to the right.
  let turn_then_move = moved * turned
  assert_true(turn_then_move.transform_point(Vec2::unit_x()).approx(Vec2::new(1.0, 1.0)))
  // Move, then turn: the move is turned as well, so the point ends up two
  // along +y rather than one along each axis.
  let move_then_turn = turned * moved
  assert_true(move_then_turn.transform_point(Vec2::unit_x()).approx(Vec2::new(0.0, 2.0)))
}

///|
test "an affine transform and its inverse cancel" {
  let transform = Affine2::from_angle_translation(quarter_pi, Vec2::new(2.0, -1.0))
  let point = Vec2::new(3.0, 5.0)
  let back = transform.inverse().unwrap()
  assert_true(back.transform_point(transform.transform_point(point)).approx(point, eps=1.0e-5))
  assert_true((transform * back).approx(Affine2::identity(), eps=1.0e-5))
  // A transform that squashes the plane has no inverse.
  let squashed = Affine2::new(Mat2::from_scale(Vec2::new(1.0, 0.0)), Vec2::zero())
  assert_eq(squashed.inverse(), None)
}

///|
test "an affine transform of the plane is a 3x3 matrix with a last row of (0, 0, 1)" {
  let transform = Affine2::from_angle_translation(0.6, Vec2::new(1.0, -2.0))
  let matrix = transform.to_mat3()
  assert_eq(matrix.get(2, 0), 0.0)
  assert_eq(matrix.get(2, 1), 0.0)
  assert_eq(matrix.get(2, 2), 1.0)
  assert_true(Affine2::from_mat3(matrix).unwrap().approx(transform))
  // The matrix and the transform agree about where a point goes.
  let point = Vec2::new(2.0, 3.0)
  assert_true(
    matrix.mul_vec3(point.to_vec3(1.0)).xy().approx(transform.transform_point(point)),
  )
  // A projection is not affine, and says so.
  let projection = Mat4::perspective(half_pi, 1.0, 0.1, 100.0)
  assert_eq(Affine2::from_mat3(Mat3::from_mat4(projection)), None)
}

///|
test "an affine transform of space applies the three parts in order" {
  let trs = Trs::new(
    Vec3::new(0.0, 1.0, 0.0),
    Quat::from_axis_angle(Vec3::unit_z(), half_pi),
    Vec3::splat(2.0),
  )
  let transform = Affine3::from_trs(trs)
  // One along x is scaled to two, turned onto +y, then lifted by one.
  assert_true(
    transform.transform_point(Vec3::unit_x()).approx(Vec3::new(0.0, 3.0, 0.0), eps=1.0e-5),
  )
  assert_true(
    transform.transform_vector(Vec3::unit_x()).approx(Vec3::new(0.0, 2.0, 0.0), eps=1.0e-5),
  )
  // The matrix it converts to does the same.
  assert_true(
    transform.to_mat4().transform_point(Vec3::unit_x()).approx(
      transform.transform_point(Vec3::unit_x()),
      eps=1.0e-5,
    ),
  )
}

///|
test "an affine transform of space goes back to its three parts" {
  let trs = Trs::new(
    Vec3::new(1.0, -2.0, 3.0),
    Quat::from_axis_angle(Vec3::new(1.0, 1.0, 0.0), 0.9),
    Vec3::new(2.0, 3.0, 4.0),
  )
  let back = Affine3::from_trs(trs).to_trs().unwrap()
  assert_true(back.translation.approx(trs.translation, eps=1.0e-5))
  assert_true(back.rotation.approx(trs.rotation, eps=1.0e-5))
  assert_true(back.scale.approx(trs.scale, eps=1.0e-5))
}

///|
test "composition and inversion of affine transforms of space" {
  let transform = Affine3::from_rotation(Quat::from_axis_angle(Vec3::unit_y(), 0.7))
  let moved = Affine3::from_translation(Vec3::new(0.0, 2.0, 0.0))
  let point = Vec3::new(1.0, 0.0, 0.0)
  // `a * b` applies `b` first, as the matrices do.
  assert_true(
    (transform * moved).transform_point(point).approx(
      transform.transform_point(moved.transform_point(point)),
      eps=1.0e-5,
    ),
  )
  let back = transform.inverse().unwrap()
  assert_true(back.transform_point(transform.transform_point(point)).approx(point, eps=1.0e-5))
  assert_true(
    Affine3::from_mat4(transform.to_mat4()).unwrap().approx(transform, eps=1.0e-5),
  )
  // A projection is not affine.
  assert_eq(
    Affine3::from_mat4(Mat4::perspective(half_pi, 1.0, 0.1, 100.0)),
    None,
  )
}

///|
test "a 2x2 rotation and its angle" {
  let angles : Array[{{S}}] = [0.0, 15.0, 90.0, 180.0, -45.0]
  for degrees in angles {
    let radians = to_radians(degrees)
    let matrix = Mat2::from_angle(radians)
    // An angle that has been through a sine and a cosine comes back wrapped, so
    // a half turn may arrive as plus or minus pi.
    assert_true(approx_angle(matrix.to_angle(), radians))
    assert_true(approx(matrix.determinant(), 1.0))
    // The first column is where x goes.
    assert_true(
      matrix.mul_vec2(Vec2::unit_x()).approx(Vec2::new(@math.{{COS}}(radians), @math.{{SIN}}(radians))),
    )
  }
}

///|
test "a matrix built from Euler angles agrees with the quaternion path" {
  let angles = Vec3::new(0.3, -0.7, 1.1)
  let quat = Quat::from_euler(Xzy, angles)
  assert_true(Mat3::from_euler(Xzy, angles).approx(quat.to_mat3(), eps=1.0e-5))
  assert_true(Mat4::from_euler(Xzy, angles).approx(quat.to_mat4(), eps=1.0e-5))
}
