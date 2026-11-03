// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "colour arithmetic is component-wise" {
  let first = Color3::new(1.0, 2.0, 3.0)
  let second = Color3::new(0.5, 0.5, 0.5)
  assert_true((first + second).approx(Color3::new(1.5, 2.5, 3.5)))
  assert_true((first - second).approx(Color3::new(0.5, 1.5, 2.5)))
  assert_true((first * second).approx(Color3::new(0.5, 1.0, 1.5)))
  assert_true((first / second).approx(Color3::new(2.0, 4.0, 6.0)))
  assert_true(first.min(second).approx(second))
  assert_true(first.max(second).approx(first))
}

///|
test "red is hue zero, full saturation and value" {
  let red = Color3::new(1.0, 0.0, 0.0)
  let hsv = rgb_to_hsv(red)
  assert_true(approx(hsv.r, 0.0))
  assert_true(approx(hsv.g, 1.0))
  assert_true(approx(hsv.b, 1.0))
  assert_true(hsv_to_rgb(hsv).approx(red))
}

///|
test "rgb and hsv round-trip" {
  let samples : Array[Color3] = [
    Color3::new(0.2, 0.8, 0.4),
    Color3::new(0.9, 0.1, 0.3),
    Color3::new(0.0, 0.5, 0.7),
    Color3::new(0.5, 0.5, 0.5),
  ]
  for color in samples {
    assert_true(hsv_to_rgb(rgb_to_hsv(color)).approx(color))
  }
}

///|
test "a colour with alpha carries it through" {
  let color = Color4::new(1.0, 0.5, 0.0, 0.25)
  assert_eq(color.a, 0.25)
  assert_true(Color4::from_color3(color.to_color3(), 0.25).approx(color))
  assert_true((color + color).approx(Color4::new(2.0, 1.0, 0.0, 0.5)))
}
