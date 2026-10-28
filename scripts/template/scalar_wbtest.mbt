// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The scalar helpers: the ones with a case at the edge — a range of zero width,
// a fraction with no span, an angle that has wrapped — are the ones that get
// one here.

///|
test "degrees and radians agree at the quarter turns" {
  assert_true(approx(to_radians(180.0), pi))
  assert_true(approx(to_radians(90.0), half_pi))
  assert_true(approx(to_radians(360.0), tau))
  assert_true(approx(to_degrees(pi), 180.0))
  assert_true(approx(to_degrees(quarter_pi), 45.0))
  // The round trip lands back where it started for ordinary angles.
  let degrees_to_try : Array[{{S}}] = [-720.0, -90.0, -0.5, 0.0, 1.0, 33.0, 179.0]
  for degrees in degrees_to_try {
    assert_true(approx(to_degrees(to_radians(degrees)), degrees, eps=1.0e-3))
  }
}

///|
test "lerp walks from one end to the other and past it" {
  assert_eq(lerp(2.0, 6.0, 0.0), 2.0)
  assert_eq(lerp(2.0, 6.0, 1.0), 6.0)
  assert_eq(lerp(2.0, 6.0, 0.5), 4.0)
  // Extrapolation is deliberate: animation curves overshoot.
  assert_eq(lerp(2.0, 6.0, 1.5), 8.0)
  assert_eq(lerp(2.0, 6.0, -0.5), 0.0)
  assert_eq(lerp(3.0, 3.0, 0.7), 3.0)
}

///|
test "inverse_lerp reports where a value sits, and refuses to divide by zero" {
  assert_eq(inverse_lerp(0.0, 10.0, 5.0), 0.5)
  assert_eq(inverse_lerp(0.0, 10.0, 0.0), 0.0)
  assert_eq(inverse_lerp(0.0, 10.0, 20.0), 2.0)
  // No span, no fraction: zero, rather than a division by zero.
  assert_eq(inverse_lerp(4.0, 4.0, 4.0), 0.0)
  let values : Array[{{S}}] = [-3.0, 0.0, 2.5, 10.0, 12.0]
  for value in values {
    assert_true(approx(lerp(0.0, 10.0, inverse_lerp(0.0, 10.0, value)), value))
  }
}

///|
test "remap moves a value between ranges and keeps its place" {
  assert_eq(remap(5.0, 0.0, 10.0, 0.0, 100.0), 50.0)
  assert_eq(remap(0.0, 0.0, 10.0, 100.0, 0.0), 100.0)
  assert_eq(remap(15.0, 0.0, 10.0, 0.0, 100.0), 150.0)
  // A source range with no width has no place to keep.
  assert_eq(remap(3.0, 3.0, 3.0, 1.0, 2.0), 1.0)
}

///|
test "smoothstep eases in and out" {
  assert_eq(smoothstep(0.0, 1.0, -1.0), 0.0)
  assert_eq(smoothstep(0.0, 1.0, 0.0), 0.0)
  assert_eq(smoothstep(0.0, 1.0, 0.5), 0.5)
  assert_eq(smoothstep(0.0, 1.0, 1.0), 1.0)
  assert_eq(smoothstep(0.0, 1.0, 2.0), 1.0)
  // The curve is flat at both ends, which is the reason to use it.
  assert_true(smoothstep(0.0, 1.0, 0.01) < 0.001)
  assert_true(smoothstep(0.0, 1.0, 0.99) > 0.999)
  // A range of no width is a step at that value.
  assert_eq(smoothstep(1.0, 1.0, 0.5), 0.0)
  assert_eq(smoothstep(1.0, 1.0, 1.5), 1.0)
}

///|
test "wrap folds a value into its range" {
  assert_eq(wrap(2.5, 5.0), 2.5)
  assert_eq(wrap(7.5, 5.0), 2.5)
  assert_eq(wrap(-1.0, 5.0), 4.0)
  assert_eq(wrap(-7.0, 5.0), 3.0)
  assert_eq(wrap(0.0, 5.0), 0.0)
  // The range is half-open: the end itself comes back as the start.
  assert_eq(wrap(5.0, 5.0), 0.0)
  assert_eq(wrap(10.0, 5.0), 0.0)
  // Nothing to fold into.
  assert_eq(wrap(3.0, 0.0), 0.0)
  assert_eq(wrap(3.0, -2.0), 0.0)
}

///|
test "wrap_range folds into an arbitrary interval" {
  assert_eq(wrap_range(3.0, 0.0, 10.0), 3.0)
  assert_eq(wrap_range(13.0, 0.0, 10.0), 3.0)
  assert_eq(wrap_range(-7.0, 0.0, 10.0), 3.0)
  assert_eq(wrap_range(190.0, -180.0, 180.0), -170.0)
  assert_eq(wrap_range(-190.0, -180.0, 180.0), 170.0)
}

///|
test "approx treats rounding as agreement and a difference as a difference" {
  let third : {{S}} = 1.0 / 3.0
  assert_true(approx(0.1 + 0.2, 0.3))
  assert_true(approx(third * 3.0, 1.0))
  assert_false(approx(1.0, 1.1))
  assert_true(approx(1.0, 1.1, eps=0.2))
  // An exact match short-circuits, including the infinities.
  assert_true(approx(1.0, 1.0))
  // A NaN agrees with nothing, itself included.
  assert_false(approx(1.0, 0.0 / 0.0))
  assert_false(approx(0.0 / 0.0, 0.0 / 0.0))
}

///|
test "approx_angle sees through the wrap" {
  assert_true(approx_angle(0.0, tau))
  assert_true(approx_angle(-pi, pi))
  assert_true(approx_angle(half_pi, half_pi + tau))
  assert_false(approx_angle(0.0, half_pi))
  assert_false(approx_angle(0.0, pi))
}

///|
test "the default epsilon is small enough to be a difference" {
  assert_true(default_epsilon > 0.0)
  assert_false(approx(0.0, default_epsilon * 10.0))
  assert_true(approx(0.0, default_epsilon / 2.0))
}

///|
test "clamp01 pins a value to the unit interval" {
  assert_eq(clamp01(-0.5), 0.0)
  assert_eq(clamp01(0.5), 0.5)
  assert_eq(clamp01(1.5), 1.0)
  assert_eq(clamp01(0.0), 0.0)
  assert_eq(clamp01(1.0), 1.0)
}
