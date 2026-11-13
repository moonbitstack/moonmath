// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The rigid motion: what it reads back, how two of them compose, what a
// weighted sum of them keeps, and where a matrix stops being one.

///|
fn sample_motion() -> DualQuat {
  DualQuat::from_rotation_translation(
    Quat::from_axis_angle(Vec3::new(1.0, 2.0, -0.5), 0.7),
    Vec3::new(3.0, -1.5, 2.0),
  )
}

///|
fn another_motion() -> DualQuat {
  DualQuat::from_rotation_translation(
    Quat::from_axis_angle(Vec3::new(-0.2, 1.0, 0.4), -1.9),
    Vec3::new(-4.0, 0.5, 1.0),
  )
}

///|
test "a motion reads back the rotation and the translation it was built from" {
  let turn = Quat::from_axis_angle(Vec3::new(1.0, 2.0, -0.5), 0.7)
  let offset = Vec3::new(3.0, -1.5, 2.0)
  let motion = DualQuat::from_rotation_translation(turn, offset)
  assert_true(motion.rotation().approx(turn))
  assert_true(motion.translation().approx(offset))
  // The identity is the motion that does nothing.
  assert_true(DualQuat::identity().rotation().approx(Quat::identity()))
  assert_eq(DualQuat::identity().translation(), Vec3::zero())
  // A rotation given unnormalized is normalized on the way in, so that the two
  // halves describe a motion.
  let stretched = DualQuat::from_rotation_translation(
    Quat::new(turn.x * 2.0, turn.y * 2.0, turn.z * 2.0, turn.w * 2.0),
    offset,
  )
  assert_true(stretched.rotation().approx(turn))
  assert_true(stretched.translation().approx(offset))
}

///|
test "a motion is the matrix its halves describe" {
  let motion = sample_motion()
  let expected = Mat4::from_translation(motion.translation()) *
    Mat4::from_quat(motion.rotation())
  assert_true(motion.to_mat4().approx(expected))
  // A point is turned and then moved; a direction is only turned.
  for
    point in [
      Vec3::zero(),
      Vec3::new(0.25, -3.0, 1.5),
      Vec3::new(-1.0, 2.0, 0.0),
    ] {
    assert_true(
      motion.transform_point(point).approx(expected.transform_point(point)),
    )
    assert_true(
      motion.transform_vector(point).approx(motion.rotation().rotate(point)),
    )
  }
}

///|
test "two motions compose the way their matrices do" {
  let first = sample_motion()
  let second = another_motion()
  let point = Vec3::new(0.4, 0.2, -1.0)
  // `a * b` applies `b` first, as a matrix product does.
  assert_true(
    (first * second)
    .transform_point(point)
    .approx(first.transform_point(second.transform_point(point))),
  )
  assert_true(
    (first * second).to_mat4().approx(first.to_mat4() * second.to_mat4()),
  )
  // The identity is the unit of the product.
  assert_true((first * DualQuat::identity()).approx(first))
  assert_true((DualQuat::identity() * first).approx(first))
}

///|
test "a motion has an inverse, and only a motion does" {
  let motion = sample_motion()
  let back = motion.inverse().unwrap()
  for
    point in [Vec3::zero(), Vec3::new(1.0, 2.0, 3.0), Vec3::new(-2.0, 0.5, 4.0)] {
    assert_true(
      back.transform_point(motion.transform_point(point)).approx(point),
    )
  }
  assert_true((motion * back).approx(DualQuat::identity()))
  assert_true((motion * back).to_mat4().approx(Mat4::identity()))
  // No rotation, nothing to invert.
  let nothing : DualQuat = DualQuat::new(
    Quat::new(0.0, 0.0, 0.0, 0.0),
    Quat::new(1.0, 2.0, 3.0, 0.0),
  )
  assert_eq(nothing.inverse(), None)
}

///|
test "a weighted sum of motions is a motion once it is normalized" {
  let motion = sample_motion()
  // The same motion twice is that motion, not half of it.
  assert_true(
    (motion.scale(0.5) + motion.scale(0.5)).normalize().approx(motion),
  )
  // Two placements that share a rotation blend to the point between them.
  let turn = Quat::from_axis_angle(Vec3::unit_y(), 1.1)
  let left = DualQuat::from_rotation_translation(
    turn,
    Vec3::new(-2.0, 0.0, 0.0),
  )
  let right = DualQuat::from_rotation_translation(
    turn,
    Vec3::new(2.0, 0.0, 0.0),
  )
  let middle = (left.scale(0.5) + right.scale(0.5)).normalize()
  assert_true(middle.rotation().approx(turn))
  assert_eq(middle.translation(), Vec3::zero())
  // A blend of two different rotations stays a rotation.
  let other = another_motion()
  let signed = if motion.dot(other) < 0.0 { -other } else { other }
  let mixed = (motion.scale(0.25) + signed.scale(0.75)).normalize()
  assert_true(approx(mixed.rotation().length(), 1.0))
  assert_true(mixed.is_finite())
  // A sum whose rotation has cancelled answers the identity rather than a
  // division by zero.
  let cancelled = (motion.scale(1.0) + (-motion).scale(1.0)).normalize()
  assert_true(cancelled.approx(DualQuat::identity()))
}

///|
test "a blend takes the shortest arc between two placements" {
  let first = sample_motion()
  let second = another_motion()
  assert_true(first.slerp(second, 0.0).approx(first))
  assert_true(first.slerp(second, 1.0).approx(second))
  let half = first.slerp(second, 0.5)
  assert_true(
    half.rotation().approx(first.rotation().slerp(second.rotation(), 0.5)),
  )
  assert_true(
    half
    .translation()
    .approx(first.translation().lerp(second.translation(), 0.5)),
  )
  assert_true(approx(half.rotation().length(), 1.0))
  // The sign between two rotations is not a difference: the negated placement
  // is the same placement, and the blend still ends where it should.
  assert_true(first.slerp(-second, 1.0).approx(second))
}

///|
test "a matrix that scales is not a motion" {
  let placement = Trs::new(
    Vec3::new(1.0, 2.0, 3.0),
    Quat::from_axis_angle(Vec3::unit_y(), 0.6),
    Vec3::one(),
  )
  let rigid = Mat4::from_trs(placement)
  let motion = DualQuat::from_mat4(rigid).unwrap()
  assert_true(motion.to_mat4().approx(rigid))
  assert_true(motion.translation().approx(Vec3::new(1.0, 2.0, 3.0)))
  // A stretch, a mirror and a shear have no answer here.
  assert_eq(DualQuat::from_mat4(Mat4::from_scale(Vec3::splat(2.0))), None)
  assert_eq(
    DualQuat::from_mat4(Mat4::from_scale(Vec3::new(-1.0, 1.0, 1.0))),
    None,
  )
  assert_eq(DualQuat::from_mat4(Shear::new(0.3, 0.0, 0.0).to_mat4()), None)
  // A motion with no rotation is still a motion.
  let moved = DualQuat::from_mat4(
    Mat4::from_translation(Vec3::new(0.0, 5.0, 0.0)),
  )
  assert_true(moved.unwrap().translation().approx(Vec3::new(0.0, 5.0, 0.0)))
}

///|
test "the halves are eight numbers in the order a buffer wants" {
  let motion = sample_motion()
  let values = motion.to_array()
  assert_eq(values.length(), 8)
  assert_eq(values[0], motion.real.x)
  assert_eq(values[1], motion.real.y)
  assert_eq(values[2], motion.real.z)
  assert_eq(values[3], motion.real.w)
  assert_eq(values[4], motion.dual.x)
  assert_eq(values[5], motion.dual.y)
  assert_eq(values[6], motion.dual.z)
  assert_eq(values[7], motion.dual.w)
}

///|
test "the sign between two motions is not a difference, and the halves are checked" {
  let motion = sample_motion()
  assert_true((-motion).approx(motion))
  assert_false(motion.approx(DualQuat::identity()))
  assert_true(motion.approx(motion))
  assert_true(motion.is_finite())
  let nan : Double = 0.0 / 0.0
  let broken : DualQuat = DualQuat::new(
    Quat::identity(),
    Quat::new(nan, 0.0, 0.0, 0.0),
  )
  assert_false(broken.is_finite())
}

///|
test "printing a motion reads like a pair of quaternions" {
  assert_eq(
    DualQuat::identity().to_string(),
    "DualQuat(Quat(0, 0, 0, 1), Quat(0, 0, 0, 0))",
  )
  assert_true(sample_motion().to_string().has_prefix("DualQuat(Quat("))
}
