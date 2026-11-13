// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Vector behaviour: the answers that are exact, the edges where a definition
// was needed, and the traits that make a type usable in ordinary code.

///|
test "the zero vector has a named answer for every direction it does not have" {
  let zero = Vec3::zero()
  assert_eq(zero.normalize(), Vec3::zero())
  assert_eq(zero.try_normalize(), None)
  assert_eq(zero.normalize_or(Vec3::unit_x()), Vec3::unit_x())
  // The same for the smaller and larger shapes.
  assert_eq(Vec2::zero().normalize(), Vec2::zero())
  assert_eq(Vec4::zero().try_normalize(), None)
  // And a vector that does have a direction keeps it.
  assert_true(Vec3::new(3.0, 0.0, 0.0).normalize().approx(Vec3::unit_x()))
}

///|
test "dot and cross answer the questions they are asked" {
  assert_eq(Vec3::unit_x().dot(Vec3::unit_y()), 0.0)
  assert_eq(Vec3::unit_x().dot(Vec3::unit_x()), 1.0)
  assert_eq(Vec3::unit_x().dot(-Vec3::unit_x()), -1.0)
  assert_true(Vec3::unit_x().cross(Vec3::unit_y()).approx(Vec3::unit_z()))
  assert_true(Vec3::unit_y().cross(Vec3::unit_z()).approx(Vec3::unit_x()))
  assert_true(Vec3::unit_z().cross(Vec3::unit_x()).approx(Vec3::unit_y()))
  // Antisymmetric, and zero against itself.
  assert_true(Vec3::unit_y().cross(Vec3::unit_x()).approx(-Vec3::unit_z()))
  assert_eq(Vec3::unit_x().cross(Vec3::unit_x()), Vec3::zero())
  // Parallel vectors span no area.
  assert_eq(Vec3::new(1.0, 2.0, 3.0).cross(Vec3::new(2.0, 4.0, 6.0)).length(), 0.0)
}

///|
test "the 2D cross product is signed area" {
  assert_eq(Vec2::unit_x().cross(Vec2::unit_y()), 1.0)
  assert_eq(Vec2::unit_y().cross(Vec2::unit_x()), -1.0)
  assert_eq(Vec2::unit_x().cross(Vec2::unit_x()), 0.0)
  // The perpendicular is the cross product folded into the plane.
  assert_eq(Vec2::unit_x().perp(), Vec2::unit_y())
  assert_eq(Vec2::unit_y().perp(), -Vec2::unit_x())
}

///|
test "the angle between two directions is the arc between them" {
  assert_true(approx(Vec3::unit_x().angle_between(Vec3::unit_y()), half_pi))
  assert_true(approx(Vec3::unit_x().angle_between(-Vec3::unit_x()), pi))
  assert_eq(Vec3::unit_x().angle_between(Vec3::unit_x()), 0.0)
  // The length of either vector does not matter.
  assert_true(approx(Vec3::new(0.0, 5.0, 0.0).angle_between(Vec3::new(9.0, 0.0, 0.0)), half_pi))
  // In the plane the angle is signed, so a turn either way is readable.
  assert_true(approx(Vec2::unit_x().angle_between(Vec2::unit_y()), half_pi))
  assert_true(approx(Vec2::unit_y().angle_between(Vec2::unit_x()), -half_pi))
}

///|
test "projection and rejection split a vector in two" {
  let v = Vec3::new(2.0, 3.0, 4.0)
  let onto = Vec3::new(1.0, 1.0, 0.0)
  let along = v.project(onto)
  let across = v.reject(onto)
  assert_true((along + across).approx(v))
  assert_true(approx(along.dot(across), 0.0))
  // Onto itself, a projection changes nothing; onto a perpendicular, it gives
  // zero.
  assert_true(v.project(v).approx(v))
  assert_eq(v.project(Vec3::new(0.0, 0.0, 1.0)).dot(Vec3::new(1.0, 1.0, 0.0)), 0.0)
  assert_eq(v.project(Vec3::zero()), Vec3::zero())
}

///|
test "reflection mirrors the direction about the normal" {
  let incoming = Vec3::new(1.0, -1.0, 0.0)
  assert_true(incoming.reflect(Vec3::unit_y()).approx(Vec3::new(1.0, 1.0, 0.0)))
  // Straight down onto the floor comes straight back up.
  assert_true(
    Vec3::new(0.0, -1.0, 0.0).reflect(Vec3::unit_y()).approx(Vec3::unit_y()),
  )
  // The length survives the bounce, and so does the component along the
  // surface.
  let normal = Vec3::new(1.0, 1.0, 1.0).normalize()
  let bounced = incoming.reflect(normal)
  assert_true(approx(bounced.length(), incoming.length()))
  assert_true(approx(bounced.dot(normal), -incoming.dot(normal)))
}

///|
test "refraction bends the direction and gives up past the critical angle" {
  let down = Vec3::new(0.0, -1.0, 0.0)
  let up = Vec3::unit_y()
  // Straight through the surface, nothing to bend.
  assert_true(down.refract(up, 0.5).unwrap().approx(down))
  // Into a denser medium the ray bends towards the normal: still going down,
  // but closer to the axis it entered on.
  let slanted = Vec3::new(1.0, -1.0, 0.0).normalize()
  let bent = slanted.refract(up, 0.5).unwrap()
  assert_true(bent.dot(up) < 0.0)
  assert_true(bent.normalize().dot(up).abs() > slanted.normalize().dot(up).abs())
  // Out of a denser medium at a shallow angle there is no way out.
  let shallow = Vec3::new(1.0, -0.1, 0.0).normalize()
  assert_eq(shallow.refract(up, 2.0), None)
  // The same geometry in the plane.
  let flat = Vec2::new(1.0, -0.1).normalize()
  assert_eq(flat.refract(Vec2::unit_y(), 2.0), None)
  assert_true(Vec2::new(0.0, -1.0).refract(Vec2::unit_y(), 0.5).unwrap().approx(Vec2::new(0.0, -1.0)))
}

///|
test "component-wise arithmetic is the operator, scaling is the method" {
  let a = Vec3::new(1.0, 2.0, 3.0)
  let b = Vec3::new(4.0, 5.0, 6.0)
  assert_eq(a + b, Vec3::new(5.0, 7.0, 9.0))
  assert_eq(b - a, Vec3::new(3.0, 3.0, 3.0))
  assert_eq(a * b, Vec3::new(4.0, 10.0, 18.0))
  assert_eq(b / a, Vec3::new(4.0, 2.5, 2.0))
  assert_eq(-a, Vec3::new(-1.0, -2.0, -3.0))
  assert_eq(a.scale(2.0), Vec3::new(2.0, 4.0, 6.0))
  assert_eq(a.divide(2.0), Vec3::new(0.5, 1.0, 1.5))
}

///|
test "the smallest and largest components, and a clamp between them" {
  let low = Vec3::new(-1.0, 2.0, 0.0)
  let high = Vec3::new(3.0, 4.0, 5.0)
  assert_eq(low.min(high), low)
  assert_eq(low.max(high), high)
  assert_eq(
    Vec3::new(-5.0, 3.0, 99.0).clamp(low, high),
    Vec3::new(-1.0, 3.0, 5.0),
  )
}

///|
test "rounding each component" {
  let v = Vec3::new(-1.5, 2.4, -0.0)
  assert_eq(v.abs(), Vec3::new(1.5, 2.4, 0.0))
  assert_eq(v.floor(), Vec3::new(-2.0, 2.0, 0.0))
  assert_eq(v.ceil(), Vec3::new(-1.0, 3.0, 0.0))
  // A half goes up, in both directions.
  assert_eq(v.round(), Vec3::new(-1.0, 2.0, 0.0))
  assert_eq(Vec3::splat(2.5).round(), Vec3::splat(3.0))
  assert_eq(Vec3::new(-1.25, 2.25, 0.75).fract(), Vec3::new(0.75, 0.25, 0.75))
  assert_eq(Vec4::splat(1.5).fract(), Vec4::splat(0.5))
}

///|
test "reordering the components" {
  let v = Vec3::new(1.0, 2.0, 3.0)
  assert_eq(v.xy(), Vec2::new(1.0, 2.0))
  assert_eq(v.xz(), Vec2::new(1.0, 3.0))
  assert_eq(v.yz(), Vec2::new(2.0, 3.0))
  assert_eq(v.zyx(), Vec3::new(3.0, 2.0, 1.0))
  assert_eq(v.xzy(), Vec3::new(1.0, 3.0, 2.0))
  assert_eq(v.yxz(), Vec3::new(2.0, 1.0, 3.0))
  assert_eq(v.yzx(), Vec3::new(2.0, 3.0, 1.0))
  assert_eq(v.zxy(), Vec3::new(3.0, 1.0, 2.0))
  assert_eq(Vec2::new(1.0, 2.0).yx(), Vec2::new(2.0, 1.0))
  let four = Vec4::new(1.0, 2.0, 3.0, 4.0)
  assert_eq(four.xy(), Vec2::new(1.0, 2.0))
  assert_eq(four.xyz(), Vec3::new(1.0, 2.0, 3.0))
  assert_eq(four.wzyx(), Vec4::new(4.0, 3.0, 2.0, 1.0))
  // Lifting into a higher dimension fills the new components in.
  assert_eq(Vec2::new(1.0, 2.0).to_vec3(3.0), Vec3::new(1.0, 2.0, 3.0))
  assert_eq(Vec2::new(1.0, 2.0).to_vec4(3.0, 4.0), Vec4::new(1.0, 2.0, 3.0, 4.0))
  assert_eq(Vec3::new(1.0, 2.0, 3.0).to_vec4(4.0), Vec4::new(1.0, 2.0, 3.0, 4.0))
}

///|
test "a vector is its components in order, and nothing else" {
  assert_eq(Vec2::new(1.0, 2.0).to_array(), [1.0, 2.0])
  assert_eq(Vec3::new(1.0, 2.0, 3.0).to_array(), [1.0, 2.0, 3.0])
  assert_eq(Vec4::new(1.0, 2.0, 3.0, 4.0).to_array(), [1.0, 2.0, 3.0, 4.0])
  assert_eq(Vec3::new(1.0, 2.0, 3.0).length_squared(), 14.0)
  assert_eq(Vec4::new(1.0, 2.0, 2.0, 4.0).length(), 5.0)
  assert_eq(Vec2::new(1.0, 1.0).distance(Vec2::new(4.0, 5.0)), 5.0)
}

///|
test "interpolation takes the corners and goes past them" {
  let a = Vec2::new(1.0, 2.0)
  let b = Vec2::new(3.0, 6.0)
  assert_eq(a.lerp(b, 0.0), a)
  assert_eq(a.lerp(b, 1.0), b)
  assert_eq(a.lerp(b, 0.5), Vec2::new(2.0, 4.0))
  assert_eq(a.lerp(b, 2.0), Vec2::new(5.0, 10.0))
}

///|
test "finiteness is about the components" {
  let infinity : {{S}} = 1.0 / 0.0
  let nan : {{S}} = 0.0 / 0.0
  assert_true(Vec3::one().is_finite())
  assert_false(Vec3::new(infinity, 0.0, 0.0).is_finite())
  assert_false(Vec3::new(0.0, nan, 0.0).is_finite())
  assert_true(Vec4::zero().is_finite())
  assert_false(Vec2::new(nan, 0.0).is_finite())
}

///|
test "equality is exact and approximation is not" {
  let a = Vec3::new(0.1, 0.2, 0.3)
  let b = Vec3::new(0.1, 0.2, 0.3)
  assert_true(a == b)
  assert_false(a != b)
  // The same numbers reached by different arithmetic differ in the last place.
  let c = Vec3::new(0.1 + 0.0, 0.2, 0.3)
  assert_true(a.approx(c))
  assert_true(a.approx(c, eps=0.0))
  assert_false(a.approx(Vec3::new(0.1, 0.2, 0.31)))
  assert_true(a.approx(Vec3::new(0.1, 0.2, 0.31), eps=0.02))
}

///|
test "printing a vector reads like a vector" {
  assert_eq(Vec2::new(1.0, 2.0).to_string(), "Vec2(1, 2)")
  assert_eq(Vec3::new(1.0, 2.0, 3.0).to_string(), "Vec3(1, 2, 3)")
  assert_eq(Vec4::new(1.0, 2.0, 3.0, 4.0).to_string(), "Vec4(1, 2, 3, 4)")
  assert_true(Vec3::new(1.5, 2.0, 3.0).to_string().contains("1.5"))
}

///|
test "a component can be replaced without touching the rest" {
  let v = Vec3::new(1.0, 2.0, 3.0)
  assert_eq(v.with_x(4.0), Vec3::new(4.0, 2.0, 3.0))
  assert_eq(v.with_y(4.0), Vec3::new(1.0, 4.0, 3.0))
  assert_eq(v.with_z(4.0), Vec3::new(1.0, 2.0, 4.0))
  assert_eq(v, Vec3::new(1.0, 2.0, 3.0))
  assert_eq(Vec2::new(1.0, 2.0).with_y(5.0), Vec2::new(1.0, 5.0))
  assert_eq(Vec2::new(1.0, 2.0).with_x(5.0), Vec2::new(5.0, 2.0))
  let four = Vec4::new(1.0, 2.0, 3.0, 4.0)
  assert_eq(four.with_x(9.0), Vec4::new(9.0, 2.0, 3.0, 4.0))
  assert_eq(four.with_y(9.0), Vec4::new(1.0, 9.0, 3.0, 4.0))
  assert_eq(four.with_z(9.0), Vec4::new(1.0, 2.0, 9.0, 4.0))
  assert_eq(four.with_w(9.0), Vec4::new(1.0, 2.0, 3.0, 9.0))
}

///|
test "the extreme component and the point between two" {
  assert_eq(Vec2::new(3.0, -2.0).min_element(), -2.0)
  assert_eq(Vec2::new(3.0, -2.0).max_element(), 3.0)
  assert_eq(Vec3::new(3.0, -2.0, 7.0).min_element(), -2.0)
  assert_eq(Vec3::new(3.0, -2.0, 7.0).max_element(), 7.0)
  assert_eq(Vec4::new(3.0, -2.0, 7.0, 0.5).min_element(), -2.0)
  assert_eq(Vec4::new(3.0, -2.0, 7.0, 0.5).max_element(), 7.0)
  // The point half way, for a position rather than a direction.
  assert_eq(Vec3::new(0.0, 0.0, 0.0).midpoint(Vec3::new(2.0, 4.0, -6.0)), Vec3::new(1.0, 2.0, -3.0))
  assert_eq(Vec2::new(-1.0, 3.0).midpoint(Vec2::new(1.0, 1.0)), Vec2::new(0.0, 2.0))
}

///|
test "a length can be brought into a range without losing the direction" {
  let v = Vec3::new(0.0, 3.0, 4.0)
  let shorter = v.clamp_length(0.0, 2.0)
  assert_true(approx(shorter.length(), 2.0))
  assert_true(shorter.normalize().approx(v.normalize()))
  let longer = v.clamp_length(10.0, 20.0)
  assert_true(approx(longer.length(), 10.0))
  assert_true(longer.normalize().approx(v.normalize()))
  // Bounds in either order, and bounds the length already lies between.
  assert_true(approx(v.clamp_length(2.0, 1.0).length(), 2.0))
  assert_eq(v.clamp_length(1.0, 10.0), v)
  // No direction to keep.
  assert_eq(Vec3::zero().clamp_length(1.0, 2.0), Vec3::zero())
  assert_true(approx(Vec2::new(3.0, 4.0).clamp_length(0.0, 1.0).length(), 1.0))
  assert_true(approx(Vec4::new(0.0, 0.0, 0.0, 5.0).clamp_length(0.0, 2.0).length(), 2.0))
}

///|
test "a step towards a target stops on it" {
  let origin = Vec3::zero()
  let target = Vec3::new(10.0, 0.0, 0.0)
  let stepped = origin.move_towards(target, 3.0)
  assert_true(approx(stepped.length(), 3.0))
  assert_true(stepped.normalize().approx(Vec3::unit_x()))
  // Nearer than the step: the target itself, not past it.
  assert_eq(origin.move_towards(target, 30.0), target)
  assert_eq(target.move_towards(target, 1.0), target)
  assert_true(approx(Vec2::new(0.0, 0.0).move_towards(Vec2::new(0.0, 4.0), 1.0).length(), 1.0))
  assert_true(approx(Vec4::new(0.0, 0.0, 0.0, 0.0).move_towards(Vec4::new(2.0, 0.0, 0.0, 0.0), 1.0).length(), 1.0))
}

///|
test "a turn about one axis leaves that axis alone" {
  let x = Vec3::unit_x()
  let y = Vec3::unit_y()
  let z = Vec3::unit_z()
  // Right-handed: y goes to z about x, z to x about y, x to y about z.
  assert_true(y.rotate_x(half_pi).approx(z))
  assert_true(z.rotate_x(half_pi).approx(-y))
  assert_true(z.rotate_y(half_pi).approx(x))
  assert_true(x.rotate_y(half_pi).approx(-z))
  assert_true(x.rotate_z(half_pi).approx(y))
  assert_true(y.rotate_z(half_pi).approx(-x))
  // The axis is the one thing a turn about it cannot move.
  assert_true(x.rotate_x(1.2).approx(x))
  assert_true(y.rotate_y(1.2).approx(y))
  assert_true(z.rotate_z(1.2).approx(z))
  // A turn keeps the length, and a quarter turn four times is none.
  let v = Vec3::new(1.0, 2.0, 3.0)
  assert_true(approx(v.rotate_x(0.4).length(), v.length()))
  let mut turned = v
  for _ in 0..<4 {
    turned = turned.rotate_z(half_pi)
  }
  assert_true(turned.approx(v))
}

///|
test "a turn about an arbitrary axis is the quaternion's turn" {
  let axis = Vec3::new(1.0, -2.0, 0.5)
  let v = Vec3::new(0.3, 0.4, -0.5)
  let expected = Quat::from_axis_angle(axis, 1.1).rotate(v)
  assert_true(v.rotate_axis(axis, 1.1).approx(expected))
  // Each of the three axes is the same call with that axis.
  assert_true(v.rotate_axis(Vec3::unit_x(), 0.8).approx(v.rotate_x(0.8)))
  assert_true(v.rotate_axis(Vec3::unit_y(), 0.8).approx(v.rotate_y(0.8)))
  assert_true(v.rotate_axis(Vec3::unit_z(), 0.8).approx(v.rotate_z(0.8)))
  // No axis, no turn.
  assert_eq(v.rotate_axis(Vec3::zero(), 1.0), v)
}

///|
test "a direction carries a right-handed frame" {
  for v in [
    Vec3::unit_x(),
    Vec3::unit_y(),
    Vec3::unit_z(),
    Vec3::new(0.3, -0.7, 0.2),
    Vec3::new(1.0e-4, 1.0, 0.0),
  ] {
    let normal = v.normalize()
    let u = v.any_orthonormal_vector()
    let (pair_u, pair_v) = v.any_orthonormal_pair()
    // Both are unit, perpendicular to the direction and to each other.
    assert_true(approx(u.length(), 1.0))
    assert_true(approx(u.dot(normal), 0.0))
    assert_true(approx(pair_u.length(), 1.0))
    assert_true(approx(pair_v.length(), 1.0))
    assert_true(approx(pair_u.dot(normal), 0.0))
    assert_true(approx(pair_v.dot(normal), 0.0))
    assert_true(approx(pair_u.dot(pair_v), 0.0))
    // The same input gives the same frame, and the frame is right-handed.
    assert_eq(u, v.any_orthonormal_vector())
    assert_true(pair_u.cross(pair_v).approx(normal))
  }
  // No direction: the plane the direction would be in is the one it names.
  assert_eq(Vec3::zero().any_orthonormal_vector(), Vec3::unit_x())
  let (u, v) = Vec3::zero().any_orthonormal_pair()
  assert_eq(u, Vec3::unit_x())
  assert_eq(v, Vec3::unit_y())
}

///|
test "a slerp walks the arc between two directions" {
  let x = Vec3::unit_x()
  let y = Vec3::unit_y()
  // The ends, and the middle of a quarter turn.
  assert_true(x.slerp(y, 0.0).approx(x))
  assert_true(x.slerp(y, 1.0).approx(y))
  assert_true(
    x.slerp(y, 0.5).approx(Vec3::new(1.0, 1.0, 0.0).normalize()),
  )
  // Every point on the arc is a direction, and the rate is steady: the angle
  // from the start grows with `t`.
  let steps : Array[{{S}}] = [0.1, 0.25, 0.5, 0.75, 0.9]
  for t in steps {
    let point = x.slerp(y, t)
    assert_true(approx(point.length(), 1.0))
    assert_true(approx(x.angle_between(point), t * half_pi))
  }
  // The length of the inputs does not matter, only the direction.
  assert_true(
    Vec3::new(5.0, 0.0, 0.0).slerp(Vec3::new(0.0, -2.0, 0.0), 0.5).approx(
      Vec3::new(1.0, -1.0, 0.0).normalize(),
    ),
  )
  // The same direction, an opposite one, and one with no direction at all.
  assert_true(x.slerp(x, 0.4).approx(x))
  assert_true(x.slerp(-x, 0.4).approx(x))
  assert_eq(Vec3::zero().slerp(y, 0.5), Vec3::zero().lerp(y, 0.5))
}
