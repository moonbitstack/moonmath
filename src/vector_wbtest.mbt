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
  assert_eq(
    Vec3::new(1.0, 2.0, 3.0).cross(Vec3::new(2.0, 4.0, 6.0)).length(),
    0.0,
  )
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
  assert_true(
    approx(
      Vec3::new(0.0, 5.0, 0.0).angle_between(Vec3::new(9.0, 0.0, 0.0)),
      half_pi,
    ),
  )
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
  assert_eq(
    v.project(Vec3::new(0.0, 0.0, 1.0)).dot(Vec3::new(1.0, 1.0, 0.0)),
    0.0,
  )
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
  assert_true(
    bent.normalize().dot(up).abs() > slanted.normalize().dot(up).abs(),
  )
  // Out of a denser medium at a shallow angle there is no way out.
  let shallow = Vec3::new(1.0, -0.1, 0.0).normalize()
  assert_eq(shallow.refract(up, 2.0), None)
  // The same geometry in the plane.
  let flat = Vec2::new(1.0, -0.1).normalize()
  assert_eq(flat.refract(Vec2::unit_y(), 2.0), None)
  assert_true(
    Vec2::new(0.0, -1.0)
    .refract(Vec2::unit_y(), 0.5)
    .unwrap()
    .approx(Vec2::new(0.0, -1.0)),
  )
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
  assert_eq(
    Vec2::new(1.0, 2.0).to_vec4(3.0, 4.0),
    Vec4::new(1.0, 2.0, 3.0, 4.0),
  )
  assert_eq(
    Vec3::new(1.0, 2.0, 3.0).to_vec4(4.0),
    Vec4::new(1.0, 2.0, 3.0, 4.0),
  )
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
  let infinity : Float = 1.0 / 0.0
  let nan : Float = 0.0 / 0.0
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
