// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Quaternions: the rotation itself, the conversions to and from the other two
// ways of writing one, and the interpolation between two of them.

///|
/// The orders that turn about three different axes.
fn tait_bryan_orders() -> Array[EulerOrder] {
  [Xyz, Xzy, Yxz, Yzx, Zxy, Zyx]
}

///|
/// The orders that turn about two axes, the first one twice.
fn proper_orders() -> Array[EulerOrder] {
  [Xyx, Xzx, Yxy, Yzy, Zxz, Zyz]
}

///|
test "the identity rotation leaves everything where it is" {
  let identity = Quat::identity()
  assert_eq(identity, Quat::new(0.0, 0.0, 0.0, 1.0))
  assert_true(identity.rotate(Vec3::new(1.0, -2.0, 3.0)).approx(Vec3::new(1.0, -2.0, 3.0)))
  assert_true(identity.to_mat3().approx(Mat3::identity()))
  assert_true(identity.to_mat4().approx(Mat4::identity()))
  assert_true(identity.approx(Quat::identity()))
  assert_true(approx(identity.length(), 1.0))
}

///|
test "a quarter turn takes one axis to the next" {
  let about_z = Quat::from_axis_angle(Vec3::unit_z(), half_pi)
  assert_true(about_z.rotate(Vec3::unit_x()).approx(Vec3::unit_y()))
  assert_true(about_z.rotate(Vec3::unit_y()).approx(-Vec3::unit_x()))
  assert_true(about_z.rotate(Vec3::unit_z()).approx(Vec3::unit_z()))
  // The axis is normalized first, so its length is not part of the question.
  let long_axis = Quat::from_axis_angle(Vec3::new(0.0, 0.0, 7.0), half_pi)
  assert_true(long_axis.approx(about_z))
  // A zero axis has no direction to turn about.
  assert_eq(Quat::from_axis_angle(Vec3::zero(), 1.0), Quat::identity())
}

///|
test "composition reads right to left, as matrices do" {
  let first = Quat::from_axis_angle(Vec3::unit_x(), 0.6)
  let second = Quat::from_axis_angle(Vec3::unit_y(), -0.3)
  let v = Vec3::new(1.0, 2.0, 3.0)
  let together = (first * second).rotate(v)
  let in_turn = first.rotate(second.rotate(v))
  assert_true(together.approx(in_turn, eps=1.0e-5))
  // The matrices agree about the order too.
  let from_matrix = (first.to_mat3() * second.to_mat3()).mul_vec3(v)
  assert_true(from_matrix.approx(together, eps=1.0e-5))
  // And the identity commutes with everything.
  assert_true((first * Quat::identity()).approx(first))
}

///|
test "the inverse undoes the rotation" {
  let q = Quat::from_axis_angle(Vec3::new(1.0, 2.0, -1.0), 1.3)
  let back = q.inverse().unwrap()
  assert_true((q * back).approx(Quat::identity(), eps=1.0e-5))
  assert_true((back * q).approx(Quat::identity(), eps=1.0e-5))
  // For a unit quaternion the conjugate is the inverse.
  assert_true(q.conjugate().approx(back))
  // Rotating by one and then the other gets a vector home.
  let v = Vec3::new(0.5, -1.5, 2.0)
  assert_true(back.rotate(q.rotate(v)).approx(v, eps=1.0e-5))
  // The zero quaternion is no rotation at all and has no inverse.
  assert_eq(Quat::new(0.0, 0.0, 0.0, 0.0).inverse(), None)
  // Scaling a quaternion does not change the rotation it names, but it does
  // change the conjugate, which is why `inverse` divides by the length.
  let doubled = Quat::new(q.x * 2.0, q.y * 2.0, q.z * 2.0, q.w * 2.0)
  assert_true((doubled * doubled.inverse().unwrap()).approx(Quat::identity(), eps=1.0e-5))
  assert_true(doubled.normalize().approx(q))
}

///|
test "panic dividing a quaternion by the zero quaternion" {
  let zero = Quat::new(0.0, 0.0, 0.0, 0.0)
  let _ = Quat::identity() / zero
}

///|
test "rotating the axis and the angle out of a quaternion" {
  let axis = Vec3::new(1.0, -2.0, 0.5).normalize()
  let angle : {{S}} = 0.9
  let (found_axis, found_angle) = Quat::from_axis_angle(axis, angle).to_axis_angle()
  assert_true(found_axis.approx(axis, eps=1.0e-5))
  assert_true(approx(found_angle, angle, eps=1.0e-5))
  // A rotation of no angle has no axis to name; it says so with an axis and a
  // zero angle.
  let (_, nothing) = Quat::identity().to_axis_angle()
  assert_true(approx(nothing, 0.0, eps=1.0e-5))
  assert_true(Quat::identity().to_axis_angle().0.approx(Vec3::unit_x()))
}

///|
test "a quaternion and a matrix say the same thing" {
  let q = Quat::from_axis_angle(Vec3::new(2.0, -1.0, 0.5), 1.1)
  assert_true(q.to_mat3().approx(Mat3::from_axis_angle(Vec3::new(2.0, -1.0, 0.5), 1.1)))
  assert_true(Mat4::from_quat(q).approx(q.to_mat4()))
  // The way back, from the matrix to the quaternion.
  let back = Quat::from_mat3(q.to_mat3())
  assert_true(back.approx(q, eps=1.0e-5))
  let back4 = Quat::from_mat4(q.to_mat4())
  assert_true(back4.approx(q, eps=1.0e-5))
  // And the round trip from a quaternion that is not near the identity, where
  // the extraction takes a different branch of the algorithm.
  let edge_sets : Array[({{S}}, {{S}}, {{S}})] = [
    (0.0, 0.0, 0.0),
    (pi, 0.0, 0.0),
    (0.0, pi, 0.0),
    (0.0, 0.0, pi),
    (2.5, -1.0, 0.4),
  ]
  for angles in edge_sets {
    let (x, y, z) = angles
    let turn = Quat::from_euler(Xyz, Vec3::new(x, y, z))
    assert_true(Quat::from_mat3(turn.to_mat3()).approx(turn, eps=1.0e-4))
  }
}

///|
test "every axis order produces a rotation that carries its own angles" {
  let orders : Array[EulerOrder] = [
    Xyz, Xzy, Yxz, Yzx, Zxy, Zyx, Xyx, Xzx, Yxy, Yzy, Zxz, Zyz,
  ]
  let angle_sets : Array[({{S}}, {{S}}, {{S}})] = [
    (0.0, 0.0, 0.0),
    (0.3, -0.4, 0.5),
    (1.2, 0.9, -2.0),
    (-2.8, 0.1, 3.0),
  ]
  for order in orders {
    for angles in angle_sets {
      let (x, y, z) = angles
      let wanted = Vec3::new(x, y, z)
      let q = Quat::from_euler(order, wanted)
      let read_back = q.to_euler(order)
      let rebuilt = Quat::from_euler(order, read_back)
      assert_true(rebuilt.approx(q, eps=1.0e-4))
    }
  }
}

///|
test "the two families of axis order are both covered" {
  assert_eq(tait_bryan_orders().length(), 6)
  assert_eq(proper_orders().length(), 6)
  // Each family keeps its own rotation: a proper order cannot produce the same
  // matrix as a Tait-Bryan one for the same angles, in general.
  let angles = Vec3::new(0.4, 0.5, 0.6)
  let tait_bryan = Quat::from_euler(Xyz, angles)
  let proper = Quat::from_euler(Xyx, angles)
  assert_false(tait_bryan.approx(proper, eps=1.0e-3))
}

///|
test "one angle, one axis" {
  // Turning about a single named axis is the same as building that rotation
  // directly, whichever order names it.
  let angle : {{S}} = 0.75
  assert_true(
    Quat::from_euler(Xyz, Vec3::new(angle, 0.0, 0.0)).approx(
      Quat::from_axis_angle(Vec3::unit_x(), angle),
    ),
  )
  // The first component is the first turn, whichever axis that is.
  assert_true(
    Quat::from_euler(Zyx, Vec3::new(angle, 0.0, 0.0)).approx(
      Quat::from_axis_angle(Vec3::unit_z(), angle),
    ),
  )
  assert_true(
    Quat::from_euler(Yxy, Vec3::new(angle, 0.0, 0.0)).approx(
      Quat::from_axis_angle(Vec3::unit_y(), angle),
    ),
  )
}

///|
/// The orders whose middle turn is `y`, the one that locks a Tait-Bryan
/// family at a quarter turn.
fn lock_orders() -> Array[EulerOrder] {
  [Xyz, Zyx, Yxz]
}

///|
/// One order of each proper-Euler family, whose lock is at a half turn.
fn proper_lock_orders() -> Array[EulerOrder] {
  [Xyx, Zxz, Yzy]
}

///|
test "the gimbal lock angle still describes the same rotation" {
  // A pitch of a quarter turn: the first and third turns of an Xyz order become
  // one, and only their sum is readable.
  for order in lock_orders() {
    let lock = Vec3::new(0.0, half_pi, 0.0)
    let q = Quat::from_euler(order, lock)
    let read_back = q.to_euler(order)
    assert_true(Quat::from_euler(order, read_back).approx(q, eps=1.0e-4))
    assert_true(approx(read_back.x, 0.0, eps=1.0e-5))
  }
  // The proper orders lock at the ends of their middle turn instead.
  for order in proper_lock_orders() {
    let q = Quat::from_euler(order, Vec3::new(0.0, pi, 0.0))
    let read_back = q.to_euler(order)
    assert_true(Quat::from_euler(order, read_back).approx(q, eps=1.0e-4))
  }
}

///|
test "the shortest rotation between two directions" {
  let turn = Quat::from_rotation_arc(Vec3::unit_x(), Vec3::unit_y())
  assert_true(turn.rotate(Vec3::unit_x()).approx(Vec3::unit_y()))
  // Neither length nor the plane between them matters.
  let across = Quat::from_rotation_arc(
    Vec3::new(4.0, 0.0, 0.0),
    Vec3::new(0.0, 0.0, 9.0),
  )
  assert_true(across.rotate(Vec3::unit_x()).approx(Vec3::unit_z()))
  // The same direction is no rotation at all.
  assert_true(Quat::from_rotation_arc(Vec3::unit_x(), Vec3::unit_x()).approx(Quat::identity()))
  // Opposed directions still have *a* rotation, a half turn about an axis
  // perpendicular to both.
  let opposite = Quat::from_rotation_arc(Vec3::unit_x(), -Vec3::unit_x())
  assert_true(opposite.rotate(Vec3::unit_x()).approx(-Vec3::unit_x(), eps=1.0e-5))
  assert_true(approx(opposite.to_axis_angle().1, pi, eps=1.0e-5))
  // A zero vector has no direction to turn.
  assert_eq(Quat::from_rotation_arc(Vec3::zero(), Vec3::unit_y()), Quat::identity())
}

///|
test "slerp turns at a steady rate" {
  let start = Quat::identity()
  let end = Quat::from_axis_angle(Vec3::unit_z(), half_pi)
  assert_true(start.slerp(end, 0.0).approx(start))
  assert_true(start.slerp(end, 1.0).approx(end))
  assert_true(
    start.slerp(end, 0.5).approx(Quat::from_axis_angle(Vec3::unit_z(), quarter_pi)),
  )
  // A quarter of the way is a quarter of the turn.
  let at_quarter = start.slerp(end, 0.25)
  assert_true(approx(at_quarter.to_axis_angle().1, quarter_pi / 2.0, eps=1.0e-5))
  // The same rotation written with the opposite sign is still the same rotation,
  // and the interpolation takes the short way round rather than the long one.
  let negated = Quat::new(-end.x, -end.y, -end.z, -end.w)
  assert_true(negated.approx(end))
  assert_true(
    start.slerp(negated, 0.5).approx(Quat::from_axis_angle(Vec3::unit_z(), quarter_pi)),
  )
  // Between a rotation and itself there is nothing to interpolate.
  assert_true(end.slerp(end, 0.5).approx(end))
}

///|
test "nlerp walks the straight line and lands on the sphere" {
  let start = Quat::identity()
  let end = Quat::from_axis_angle(Vec3::unit_z(), half_pi)
  assert_true(start.nlerp(end, 0.0).approx(start))
  assert_true(start.nlerp(end, 1.0).approx(end))
  // Close to slerp for a quarter turn, and always a rotation.
  let half_way = start.nlerp(end, 0.5)
  assert_true(approx(half_way.length(), 1.0, eps=1.0e-5))
  assert_true(
    half_way.approx(Quat::from_axis_angle(Vec3::unit_z(), quarter_pi), eps=1.0e-2),
  )
  // The zero quaternion has no direction on the sphere; normalization falls
  // back to the identity rather than to a division by zero.
  assert_eq(Quat::new(0.0, 0.0, 0.0, 0.0).normalize(), Quat::identity())
}

///|
test "equality of rotations is up to sign" {
  let q = Quat::from_axis_angle(Vec3::new(1.0, 1.0, 0.0), 0.5)
  let negated = -q
  assert_false(q == negated)
  assert_true(q.approx(negated))
  assert_true(q.approx(q, eps=0.0))
  assert_false(q.approx(Quat::identity(), eps=0.01))
}

///|
test "a quaternion is four numbers for a buffer" {
  let q = Quat::new(0.1, 0.2, 0.3, 0.4)
  assert_eq(q.to_array(), [0.1, 0.2, 0.3, 0.4])
  assert_true(approx(q.dot(q), 0.3))
  assert_eq(Quat::identity().to_string(), "Quat(0, 0, 0, 1)")
  assert_true(Quat::new(1.0, -1.0, 1.0, -1.0).is_finite())
  assert_false(Quat::new(0.0, 0.0, 0.0, 1.0 / 0.0).is_finite())
}
