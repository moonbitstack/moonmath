// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A 3×3 matrix: a linear map of space, or the upper-left block of a 4×4 one.
///
/// Column-major, as `mat3x3<f32>` is in a buffer: `c0` is the first column, and
/// the rows are read across the columns. Rotations, scalings and shears are
/// linear maps, so they need no translation column and live here rather than in
/// `Affine3`.
///
/// Values are immutable.
pub(all) struct Mat3 {
  c0 : Vec3
  c1 : Vec3
  c2 : Vec3
} derive(Eq)

///|
pub extend Mat3 with Eq::{equal, not_equal}

///|
/// The matrix with the three vecs as its columns.
pub fn Mat3::from_cols(c0 : Vec3, c1 : Vec3, c2 : Vec3) -> Mat3 {
  { c0, c1, c2, }
}

///|
/// The matrix with the three vecs as its rows.
pub fn Mat3::from_rows(r0 : Vec3, r1 : Vec3, r2 : Vec3) -> Mat3 {
  {
    c0: { x: r0.x, y: r1.x, z: r2.x, },
    c1: { x: r0.y, y: r1.y, z: r2.y, },
    c2: { x: r0.z, y: r1.z, z: r2.z, },
  }
}

///|
/// The matrix from nine values in column-major order.
///
/// Aborts if the array does not hold nine values.
pub fn Mat3::from_array(values : FixedArray[Double]) -> Mat3 {
  guard values.length() == 9 else {
    abort("Mat3::from_array wants 9 values, got \{values.length()}")
  }
  {
    c0: { x: values[0], y: values[1], z: values[2], },
    c1: { x: values[3], y: values[4], z: values[5], },
    c2: { x: values[6], y: values[7], z: values[8], },
  }
}

///|
/// The identity: the matrix that changes nothing.
pub fn Mat3::identity() -> Mat3 {
  {
    c0: { x: 1.0, y: 0.0, z: 0.0, },
    c1: { x: 0.0, y: 1.0, z: 0.0, },
    c2: { x: 0.0, y: 0.0, z: 1.0, },
  }
}

///|
/// The zero matrix: the one that sends everything to the origin.
pub fn Mat3::zero() -> Mat3 {
  { c0: Vec3::zero(), c1: Vec3::zero(), c2: Vec3::zero(), }
}

///|
/// The matrix that scales each axis by the matching component of `s`.
pub fn Mat3::from_scale(s : Vec3) -> Mat3 {
  {
    c0: { x: s.x, y: 0.0, z: 0.0, },
    c1: { x: 0.0, y: s.y, z: 0.0, },
    c2: { x: 0.0, y: 0.0, z: s.z, },
  }
}

///|
/// The rotation of `radians` about `axis`, by the right-hand rule.
///
/// `axis` is normalized first; a zero axis has no direction to turn about and
/// gives the identity.
pub fn Mat3::from_axis_angle(axis : Vec3, radians : Double) -> Mat3 {
  match axis.try_normalize() {
    None => Mat3::identity()
    Some(a) => {
      let c = @math.cos(radians)
      let s = @math.sin(radians)
      let one : Double = 1.0
      let t = one - c
      {
        c0: {
          x: t * a.x * a.x + c,
          y: t * a.x * a.y + s * a.z,
          z: t * a.x * a.z - s * a.y,
        },
        c1: {
          x: t * a.x * a.y - s * a.z,
          y: t * a.y * a.y + c,
          z: t * a.y * a.z + s * a.x,
        },
        c2: {
          x: t * a.x * a.z + s * a.y,
          y: t * a.y * a.z - s * a.x,
          z: t * a.z * a.z + c,
        },
      }
    }
  }
}

///|
/// The rotation the quaternion holds.
pub fn Mat3::from_quat(q : Quat) -> Mat3 {
  q.to_mat3()
}

///|
/// The rotation the three angles describe, taken in `order`, read by axis.
///
/// The components are the turns about `x`, `y` and `z`, in radians, wherever in
/// the order those axes turn up; see `Quat::from_euler`, which also says which
/// orders this reading cannot express. `from_euler_turns` takes the turns in the
/// order the order names them and covers all twelve.
pub fn Mat3::from_euler(order : EulerOrder, angles : Vec3) -> Mat3 {
  Quat::from_euler(order, angles).to_mat3()
}

///|
/// The rotation the three turns describe, in the order the order names them.
pub fn Mat3::from_euler_turns(order : EulerOrder, turns : Turns) -> Mat3 {
  Quat::from_euler_turns(order, turns).to_mat3()
}

///|
/// The upper-left 3×3 block of a 4×4 matrix: the linear part, without the
/// translation.
pub fn Mat3::from_mat4(m : Mat4) -> Mat3 {
  { c0: m.c0.xyz(), c1: m.c1.xyz(), c2: m.c2.xyz(), }
}

///|
/// Column `index`, counted from zero.
pub fn Mat3::col(self : Mat3, index : Int32) -> Vec3 {
  if index == 0 {
    self.c0
  } else if index == 1 {
    self.c1
  } else {
    self.c2
  }
}

///|
/// Row `index`, counted from zero.
pub fn Mat3::row(self : Mat3, index : Int32) -> Vec3 {
  if index == 0 {
    { x: self.c0.x, y: self.c1.x, z: self.c2.x, }
  } else if index == 1 {
    { x: self.c0.y, y: self.c1.y, z: self.c2.y, }
  } else {
    { x: self.c0.z, y: self.c1.z, z: self.c2.z, }
  }
}

///|
/// The element at `row` and `column`, both counted from zero.
pub fn Mat3::get(
  self : Mat3,
  row_index : Int32,
  column_index : Int32,
) -> Double {
  let column = self.col(column_index)
  if row_index == 0 {
    column.x
  } else if row_index == 1 {
    column.y
  } else {
    column.z
  }
}

///|
/// The matrix with rows and columns exchanged.
///
/// This is also the inverse of a rotation matrix, which is the cheapest way to
/// undo one.
pub fn Mat3::transpose(self : Mat3) -> Mat3 {
  { c0: self.row(0), c1: self.row(1), c2: self.row(2), }
}

///|
/// The signed volume the matrix scales by: zero exactly when it is singular.
pub fn Mat3::determinant(self : Mat3) -> Double {
  self.c0.dot(self.c1.cross(self.c2))
}

///|
/// The matrix that undoes this one, or `None` when there is none.
pub fn Mat3::inverse(self : Mat3) -> Mat3? {
  let c0 = self.c0
  let c1 = self.c1
  let c2 = self.c2
  // The rows of the inverse are the cross products of the columns it does not
  // come from, over the determinant: the adjugate, written so that it reads as
  // the geometry it is.
  let row0 = c1.cross(c2)
  let row1 = c2.cross(c0)
  let row2 = c0.cross(c1)
  let det = c0.dot(row0)
  if det == 0.0 {
    None
  } else {
    let inv_det : Double = 1.0 / det
    Some({
      c0: { x: row0.x * inv_det, y: row1.x * inv_det, z: row2.x * inv_det, },
      c1: { x: row0.y * inv_det, y: row1.y * inv_det, z: row2.y * inv_det, },
      c2: { x: row0.z * inv_det, y: row1.z * inv_det, z: row2.z * inv_det, },
    })
  }
}

///|
/// The vector the matrix takes `v` to.
///
/// One expression per component, for the reason given at `Mat2::mul_vec2`: the
/// three scaled columns a sum would build are three allocations on the native
/// backend.
pub fn Mat3::mul_vec3(self : Mat3, v : Vec3) -> Vec3 {
  {
    x: self.c0.x * v.x + self.c1.x * v.y + self.c2.x * v.z,
    y: self.c0.y * v.x + self.c1.y * v.y + self.c2.y * v.z,
    z: self.c0.z * v.x + self.c1.z * v.y + self.c2.z * v.z,
  }
}

///|
/// The elements in column-major order, ready for a buffer.
pub fn Mat3::to_array(self : Mat3) -> FixedArray[Double] {
  [
    self.c0.x,
    self.c0.y,
    self.c0.z,
    self.c1.x,
    self.c1.y,
    self.c1.z,
    self.c2.x,
    self.c2.y,
    self.c2.z,
  ]
}

///|
/// Whether every element is finite.
pub fn Mat3::is_finite(self : Mat3) -> Bool {
  self.c0.is_finite() && self.c1.is_finite() && self.c2.is_finite()
}

///|
/// Whether the two matrices agree to within `eps` element by element.
pub fn Mat3::approx(self : Mat3, other : Mat3, eps? : Double) -> Bool {
  self.c0.approx(other.c0, eps?) &&
  self.c1.approx(other.c1, eps?) &&
  self.c2.approx(other.c2, eps?)
}

///|
pub impl Add for Mat3 with fn add(self, other) {
  { c0: self.c0 + other.c0, c1: self.c1 + other.c1, c2: self.c2 + other.c2, }
}

///|
pub extend Mat3 with Add::{add}

///|
pub impl Sub for Mat3 with fn sub(self, other) {
  { c0: self.c0 - other.c0, c1: self.c1 - other.c1, c2: self.c2 - other.c2, }
}

///|
pub extend Mat3 with Sub::{sub}

///|
/// The matrix product: `(self * other) * v` is `self * (other * v)`.
pub impl Mul for Mat3 with fn mul(self, other) {
  {
    c0: self.mul_vec3(other.c0),
    c1: self.mul_vec3(other.c1),
    c2: self.mul_vec3(other.c2),
  }
}

///|
pub extend Mat3 with Mul::{mul}

///|
/// The product with the inverse of the right-hand side; aborts when that side is
/// singular.
pub impl Div for Mat3 with fn div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Mat3 division by a singular matrix")
  }
}

///|
pub extend Mat3 with Div::{div}

///|
pub impl Neg for Mat3 with fn neg(self) {
  { c0: -self.c0, c1: -self.c1, c2: -self.c2, }
}

///|
pub extend Mat3 with Neg::{neg}

///|
pub impl Show for Mat3 with fn output(self, logger) {
  logger.write_string("Mat3[\{self.c0}, \{self.c1}, \{self.c2}]")
}

///|
pub extend Mat3 with Show::{output, to_string}

///|
pub impl Debug for Mat3 with fn to_repr(self) {
  @debug.Repr::ctor("Mat3", [
    (Some("c0"), self.c0.to_repr()),
    (Some("c1"), self.c1.to_repr()),
    (Some("c2"), self.c2.to_repr()),
  ])
}

///|
pub extend Mat3 with Debug::{to_repr}
