// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Integer vectors exist in single precision only: they are for grid cells and
// pixel coordinates, which have no double-precision counterpart.

///|
test "integer vectors are for grids and pixels" {
  let cell = IVec2::new(3, 2)
  assert_eq(cell + IVec2::one(), IVec2::new(4, 3))
  assert_eq(cell * IVec2::splat(2), IVec2::new(6, 4))
  assert_eq(IVec2::new(7, 9) / IVec2::new(2, 2), IVec2::new(3, 4))
  assert_eq(-cell, IVec2::new(-3, -2))
  assert_eq(IVec2::new(-3, 2).abs(), IVec2::new(3, 2))
  assert_eq(cell.min(IVec2::new(1, 9)), IVec2::new(1, 2))
  assert_eq(cell.max(IVec2::new(1, 9)), IVec2::new(3, 9))
  assert_eq(cell.clamp(IVec2::zero(), IVec2::one()), IVec2::one())
  assert_eq(cell.dot(IVec2::new(2, 5)), 16)
  assert_eq(cell.to_array(), [3, 2])
  assert_eq(cell.as_vec2(), Vec2::new(3.0, 2.0))
  assert_eq(IVec2::from_vec2(Vec2::new(3.9, -2.9)), IVec2::new(3, -2))
  assert_eq(IVec3::new(1, 2, 3).as_vec3(), Vec3::new(1.0, 2.0, 3.0))
  assert_eq(IVec4::splat(2).to_array(), [2, 2, 2, 2])
}

///|
test "unsigned vectors count things and cannot go negative" {
  let size = UVec2::new(640, 480)
  assert_eq(size + UVec2::one(), UVec2::new(641, 481))
  assert_eq(size / UVec2::splat(2), UVec2::new(320, 240))
  assert_eq(size.min(UVec2::new(100, 1000)), UVec2::new(100, 480))
  assert_eq(size.clamp(UVec2::zero(), UVec2::splat(128)), UVec2::splat(128))
  assert_eq(size.to_array(), [640, 480])
  assert_eq(size.as_vec2(), Vec2::new(640.0, 480.0))
  assert_eq(UVec3::new(1, 2, 3).as_vec3(), Vec3::new(1.0, 2.0, 3.0))
  assert_eq(UVec4::new(1, 2, 3, 4).as_vec4(), Vec4::new(1.0, 2.0, 3.0, 4.0))
  assert_eq(UVec2::splat(3).dot(UVec2::splat(2)), 12)
}

///|
test "integer vectors work as keys" {
  let heights : @hashmap.HashMap[IVec2, Int32] = @hashmap.HashMap([])
  heights.set(IVec2::new(0, 0), 3)
  heights.set(IVec2::new(1, 0), 5)
  assert_eq(heights.get(IVec2::new(0, 0)), Some(3))
  assert_eq(heights.get(IVec2::new(1, 0)), Some(5))
  assert_eq(heights.get(IVec2::new(2, 0)), None)
  // The same values hash the same way, whichever way they were built.
  assert_eq(IVec3::new(1, 2, 3), IVec3::splat(1) + IVec3::new(0, 1, 2))
  assert_eq(UVec4::new(1, 2, 3, 4), UVec4::splat(1) + UVec4::new(0, 1, 2, 3))
}

///|
test "printing an integer vector says which kind it is" {
  assert_eq(IVec2::new(1, -2).to_string(), "IVec2(1, -2)")
  assert_eq(IVec3::new(1, 2, 3).to_string(), "IVec3(1, 2, 3)")
  assert_eq(IVec4::new(1, 2, 3, 4).to_string(), "IVec4(1, 2, 3, 4)")
  assert_eq(UVec2::new(1, 2).to_string(), "UVec2(1, 2)")
  assert_eq(UVec3::new(1, 2, 3).to_string(), "UVec3(1, 2, 3)")
  assert_eq(UVec4::new(1, 2, 3, 4).to_string(), "UVec4(1, 2, 3, 4)")
}
