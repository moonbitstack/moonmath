// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A 2×2 matrix, stored as two column vectors.
///
/// Column-major, like every matrix here: `c0` is the first column, so the
/// matrix that maps `x` to `(a, c)` and `y` to `(b, d)` is `c0 = (a, c)`,
/// `c1 = (b, d)`, and its `x` and `y` are the first and second rows. WGSL writes
/// a `mat2x2<f32>` in the same order, so `to_array` goes straight into a buffer.
///
/// Values are immutable.
pub(all) struct Mat2 {
  /// The first column.
  c0 : Vec2
  /// The second column.
  c1 : Vec2
} derive(Eq)

///|
pub extend Mat2 with Eq::{equal, not_equal}

///|
/// The matrix with `c0` and `c1` as its columns.
pub fn Mat2::from_cols(c0 : Vec2, c1 : Vec2) -> Mat2 {
  { c0, c1 }
}

///|
/// The matrix with `r0` and `r1` as its rows.
pub fn Mat2::from_rows(r0 : Vec2, r1 : Vec2) -> Mat2 {
  { c0: { x: r0.x, y: r1.x }, c1: { x: r0.y, y: r1.y } }
}

///|
/// The matrix from four values in column-major order: `[c0.x, c0.y, c1.x, c1.y]`.
///
/// This is the order a `mat2x2<f32>` sits in a GPU buffer in, so a matrix read
/// back out of one goes in here unchanged. Aborts if the array does not hold
/// four values.
pub fn Mat2::from_array(values : FixedArray[{{S}}]) -> Mat2 {
  guard values.length() == 4 else {
    abort("Mat2::from_array wants 4 values, got \{values.length()}")
  }
  { c0: { x: values[0], y: values[1] }, c1: { x: values[2], y: values[3] } }
}

///|
/// The identity: the matrix that changes nothing.
pub fn Mat2::identity() -> Mat2 {
  { c0: { x: 1.0, y: 0.0 }, c1: { x: 0.0, y: 1.0 } }
}

///|
/// The zero matrix: the one that sends everything to the origin.
pub fn Mat2::zero() -> Mat2 {
  { c0: Vec2::zero(), c1: Vec2::zero() }
}

///|
/// The matrix that scales `x` by `s.x` and `y` by `s.y`.
pub fn Mat2::from_scale(s : Vec2) -> Mat2 {
  { c0: { x: s.x, y: 0.0 }, c1: { x: 0.0, y: s.y } }
}

///|
/// The matrix that rotates counter-clockwise by `radians`.
pub fn Mat2::from_angle(radians : {{S}}) -> Mat2 {
  let c = @math.{{COS}}(radians)
  let s = @math.{{SIN}}(radians)
  { c0: { x: c, y: s }, c1: { x: -s, y: c } }
}

///|
/// The angle, in radians, the matrix rotates `x` by.
///
/// Only meaningful for a rotation matrix — one built by `from_angle`, or a
/// linear part that happens to be one; on anything else it reads the direction
/// of the first column.
pub fn Mat2::to_angle(self : Mat2) -> {{S}} {
  @math.{{ATAN2}}(self.c0.y, self.c0.x)
}

///|
/// Column `index`, counted from zero.
pub fn Mat2::col(self : Mat2, index : Int) -> Vec2 {
  if index == 0 {
    self.c0
  } else {
    self.c1
  }
}

///|
/// Row `index`, counted from zero.
pub fn Mat2::row(self : Mat2, index : Int) -> Vec2 {
  if index == 0 {
    { x: self.c0.x, y: self.c1.x }
  } else {
    { x: self.c0.y, y: self.c1.y }
  }
}

///|
/// The element at `row` and `column`, both counted from zero.
pub fn Mat2::get(self : Mat2, row_index : Int, column_index : Int) -> {{S}} {
  let column = if column_index == 0 { self.c0 } else { self.c1 }
  if row_index == 0 {
    column.x
  } else {
    column.y
  }
}

///|
/// The matrix with rows and columns exchanged.
pub fn Mat2::transpose(self : Mat2) -> Mat2 {
  { c0: self.row(0), c1: self.row(1) }
}

///|
/// The signed area the matrix scales by: zero exactly when it is singular.
pub fn Mat2::determinant(self : Mat2) -> {{S}} {
  self.c0.x * self.c1.y - self.c1.x * self.c0.y
}

///|
/// The matrix that undoes this one, or `None` when there is none.
///
/// A singular matrix — one with a zero determinant — flattens the plane onto a
/// line or a point, and nothing undoes that. `None` is the honest answer; the
/// caller decides whether that is an error or a case to handle.
pub fn Mat2::inverse(self : Mat2) -> Mat2? {
  let det = self.determinant()
  if det == 0.0 {
    None
  } else {
    let inv_det : {{S}} = 1.0 / det
    Some({
      c0: { x: self.c1.y * inv_det, y: -self.c0.y * inv_det },
      c1: { x: -self.c1.x * inv_det, y: self.c0.x * inv_det },
    })
  }
}

///|
/// The vector the matrix takes `v` to.
///
/// Written as one expression per component rather than as the sum of two scaled
/// columns: a `Vec2` is a heap value in the native backend, so every intermediate
/// column is an allocation, and there are two of them here for each result.
pub fn Mat2::mul_vec2(self : Mat2, v : Vec2) -> Vec2 {
  {
    x: self.c0.x * v.x + self.c1.x * v.y,
    y: self.c0.y * v.x + self.c1.y * v.y,
  }
}

///|
/// The elements in column-major order, `[c0.x, c0.y, c1.x, c1.y]`, ready for a
/// buffer.
pub fn Mat2::to_array(self : Mat2) -> FixedArray[{{S}}] {
  [self.c0.x, self.c0.y, self.c1.x, self.c1.y]
}

///|
/// Whether every element is finite.
pub fn Mat2::is_finite(self : Mat2) -> Bool {
  self.c0.is_finite() && self.c1.is_finite()
}

///|
/// Whether the two matrices agree to within `eps` element by element.
pub fn Mat2::approx(self : Mat2, other : Mat2, eps? : {{S}}) -> Bool {
  self.c0.approx(other.c0, eps?) && self.c1.approx(other.c1, eps?)
}

///|
pub impl Add for Mat2 with add(self, other) {
  { c0: self.c0 + other.c0, c1: self.c1 + other.c1 }
}

///|
pub extend Mat2 with Add::{add}

///|
pub impl Sub for Mat2 with sub(self, other) {
  { c0: self.c0 - other.c0, c1: self.c1 - other.c1 }
}

///|
pub extend Mat2 with Sub::{sub}

///|
/// The matrix product: `(self * other) * v` is `self * (other * v)`.
pub impl Mul for Mat2 with mul(self, other) {
  {
    c0: self.mul_vec2(other.c0),
    c1: self.mul_vec2(other.c1),
  }
}

///|
pub extend Mat2 with Mul::{mul}

///|
/// The product with the inverse of the right-hand side; aborts when that side is
/// singular, since `Div` has nowhere to report it.
pub impl Div for Mat2 with div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Mat2 division by a singular matrix")
  }
}

///|
pub extend Mat2 with Div::{div}

///|
pub impl Neg for Mat2 with neg(self) {
  { c0: -self.c0, c1: -self.c1 }
}

///|
pub extend Mat2 with Neg::{neg}

///|
pub impl Show for Mat2 with output(self, logger) {
  logger.write_string("Mat2[\{self.c0}, \{self.c1}]")
}

///|
pub extend Mat2 with Show::{output, to_string}

///|
pub impl Debug for Mat2 with to_repr(self) {
  @debug.Repr::ctor("Mat2", [
    (Some("c0"), self.c0.to_repr()),
    (Some("c1"), self.c1.to_repr()),
  ])
}

///|
pub extend Mat2 with Debug::{to_repr}
