// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "a shear builds the upper-triangular map" {
  let shear = Shear::new(0.5, -0.25, 2.0)
  let matrix = shear.to_mat3()
  assert_eq(matrix.get(0, 1), 0.5)
  assert_eq(matrix.get(0, 2), -0.25)
  assert_eq(matrix.get(1, 2), 2.0)
  // Below the diagonal nothing moves.
  assert_eq(matrix.get(1, 0), 0.0)
  assert_eq(matrix.get(2, 0), 0.0)
  // The 4×4 keeps the same block.
  assert_eq(shear.to_mat4().get(0, 1), 0.5)
}

///|
test "a shear slides a point along the axes" {
  // x gains the y coordinate, so (0, 2, 0) becomes (2, 2, 0).
  let along_x = Shear::new(1.0, 0.0, 0.0)
  let moved = along_x.to_mat3().mul_vec3(Vec3::new(0.0, 2.0, 0.0))
  assert_true(moved.approx(Vec3::new(2.0, 2.0, 0.0)))
}

///|
test "no shear is the identity" {
  assert_true(Shear::zero().to_mat3().approx(Mat3::identity()))
}
