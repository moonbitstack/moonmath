// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A 2D affine transform: a linear map and a translation, without the row of a
/// matrix that does nothing but hold `(0, 0, 1)`.
///
/// Composition, inversion and applying are all cheaper than the 3×3 matrix that
/// would carry the same thing, and there is no way to build one of these that
/// is not affine — which is what UI layout, sprite placement and 2D physics
/// want.
///
/// Values are immutable.
pub(all) struct Affine2 {
  /// The part that turns and scales: a 2×2 matrix.
  linear : Mat2
  /// The part that moves.
  translation : Vec2
} derive(Eq)

///|
pub extend Affine2 with Eq::{equal, not_equal}

///|
/// The transform that maps `v` to `linear * v + translation`.
pub fn Affine2::new(linear : Mat2, translation : Vec2) -> Affine2 {
  { linear, translation }
}

///|
/// The transform that changes nothing.
pub fn Affine2::identity() -> Affine2 {
  { linear: Mat2::identity(), translation: Vec2::zero() }
}

///|
/// The transform that moves every point by `offset`.
pub fn Affine2::from_translation(offset : Vec2) -> Affine2 {
  { linear: Mat2::identity(), translation: offset }
}

///|
/// The transform that scales each axis by the matching component of `scale`.
pub fn Affine2::from_scale(scale : Vec2) -> Affine2 {
  { linear: Mat2::from_scale(scale), translation: Vec2::zero() }
}

///|
/// The transform that turns counter-clockwise by `radians` about the origin.
pub fn Affine2::from_angle(radians : {{S}}) -> Affine2 {
  { linear: Mat2::from_angle(radians), translation: Vec2::zero() }
}

///|
/// The transform that turns by `radians` and then moves by `offset`.
pub fn Affine2::from_angle_translation(radians : {{S}}, offset : Vec2) -> Affine2 {
  { linear: Mat2::from_angle(radians), translation: offset }
}

///|
/// The same transform as a 3×3 matrix, with `(0, 0, 1)` as its last row.
pub fn Affine2::to_mat3(self : Affine2) -> Mat3 {
  {
    c0: { x: self.linear.c0.x, y: self.linear.c0.y, z: 0.0 },
    c1: { x: self.linear.c1.x, y: self.linear.c1.y, z: 0.0 },
    c2: { x: self.translation.x, y: self.translation.y, z: 1.0 },
  }
}

///|
/// The affine transform a 3×3 matrix holds, or `None` when the matrix is not
/// affine.
///
/// A matrix whose last row is not `(0, 0, 1)` — a projection, say — carries a
/// perspective that this type cannot hold, and there is no transform to return.
pub fn Affine2::from_mat3(m : Mat3) -> Affine2? {
  if m.get(2, 0) != 0.0 || m.get(2, 1) != 0.0 || m.get(2, 2) != 1.0 {
    None
  } else {
    Some({
      linear: Mat2::from_cols(m.c0.xy(), m.c1.xy()),
      translation: { x: m.c2.x, y: m.c2.y },
    })
  }
}

///|
/// The transform that undoes this one, or `None` when the linear part is
/// singular.
///
/// A singular linear part flattens the plane onto a line or a point, and no
/// transform brings that back.
pub fn Affine2::inverse(self : Affine2) -> Affine2? {
  match self.linear.inverse() {
    None => None
    Some(inverse) => Some({
      linear: inverse,
      translation: -(inverse.mul_vec2(self.translation)),
    })
  }
}

///|
/// The point the transform takes `p` to.
pub fn Affine2::transform_point(self : Affine2, p : Vec2) -> Vec2 {
  self.linear.mul_vec2(p) + self.translation
}

///|
/// The direction the transform takes `v` to, without the translation.
///
/// A direction has no position, so moving the origin must leave it alone.
pub fn Affine2::transform_vector(self : Affine2, v : Vec2) -> Vec2 {
  self.linear.mul_vec2(v)
}

///|
/// Whether the two transforms agree to within `eps` element by element.
pub fn Affine2::approx(self : Affine2, other : Affine2, eps? : {{S}}) -> Bool {
  self.linear.approx(other.linear, eps?) &&
  self.translation.approx(other.translation, eps?)
}

///|
/// Whether every element is finite.
pub fn Affine2::is_finite(self : Affine2) -> Bool {
  self.linear.is_finite() && self.translation.is_finite()
}

///|
/// The transform that applies `other` first and then `self`.
pub impl Mul for Affine2 with mul(self, other) {
  {
    linear: self.linear * other.linear,
    translation: self.linear.mul_vec2(other.translation) + self.translation,
  }
}

///|
pub extend Affine2 with Mul::{mul}

///|
/// The composition with the inverse of the right-hand side; aborts when that
/// side is singular.
pub impl Div for Affine2 with div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Affine2 division by a singular transform")
  }
}

///|
pub extend Affine2 with Div::{div}

///|
pub impl Show for Affine2 with output(self, logger) {
  logger.write_string(
    "Affine2[\{self.linear}, \{self.translation}]",
  )
}

///|
pub extend Affine2 with Show::{output, to_string}

///|
pub impl Debug for Affine2 with to_repr(self) {
  @debug.Repr::ctor("Affine2", [
    (Some("linear"), self.linear.to_repr()),
    (Some("translation"), self.translation.to_repr()),
  ])
}

///|
pub extend Affine2 with Debug::{to_repr}

///|
/// A 3D affine transform: a linear map and a translation, without the fourth
/// row of a matrix that does nothing but hold `(0, 0, 0, 1)`.
///
/// This is the transform a scene node carries — position, rotation and scale
/// applied to its geometry — and it is cheaper than the 4×4 matrix that would
/// also happen to work, since the wasted row would be multiplied four times per
/// vector.
///
/// Values are immutable.
pub(all) struct Affine3 {
  /// The part that turns and scales: a 3×3 matrix.
  linear : Mat3
  /// The part that moves.
  translation : Vec3
} derive(Eq)

///|
pub extend Affine3 with Eq::{equal, not_equal}

///|
/// The transform that maps `v` to `linear * v + translation`.
pub fn Affine3::new(linear : Mat3, translation : Vec3) -> Affine3 {
  { linear, translation }
}

///|
/// The transform that changes nothing.
pub fn Affine3::identity() -> Affine3 {
  { linear: Mat3::identity(), translation: Vec3::zero() }
}

///|
/// The transform that moves every point by `offset`.
pub fn Affine3::from_translation(offset : Vec3) -> Affine3 {
  { linear: Mat3::identity(), translation: offset }
}

///|
/// The transform that scales each axis by the matching component of `scale`.
pub fn Affine3::from_scale(scale : Vec3) -> Affine3 {
  { linear: Mat3::from_scale(scale), translation: Vec3::zero() }
}

///|
/// The transform that applies the rotation, about the origin.
pub fn Affine3::from_rotation(rotation : Quat) -> Affine3 {
  { linear: rotation.to_mat3(), translation: Vec3::zero() }
}

///|
/// The transform that turns by `radians` about `axis`, by the right-hand rule.
pub fn Affine3::from_axis_angle(axis : Vec3, radians : {{S}}) -> Affine3 {
  { linear: Mat3::from_axis_angle(axis, radians), translation: Vec3::zero() }
}

///|
/// The transform that scales, then rotates, then moves: the three parts of a
/// `Trs`.
pub fn Affine3::from_trs(trs : Trs) -> Affine3 {
  {
    linear: Mat3::from_mat4(Mat4::from_trs(trs)),
    translation: trs.translation,
  }
}

///|
/// The same transform as a 4×4 matrix, with `(0, 0, 0, 1)` as its last row.
pub fn Affine3::to_mat4(self : Affine3) -> Mat4 {
  {
    c0: self.linear.c0.to_vec4(0.0),
    c1: self.linear.c1.to_vec4(0.0),
    c2: self.linear.c2.to_vec4(0.0),
    c3: self.translation.to_vec4(1.0),
  }
}

///|
/// The affine transform a 4×4 matrix holds, or `None` when the matrix is not
/// affine.
pub fn Affine3::from_mat4(m : Mat4) -> Affine3? {
  if m.get(3, 0) != 0.0 || m.get(3, 1) != 0.0 || m.get(3, 2) != 0.0 ||
    m.get(3, 3) != 1.0 {
    None
  } else {
    Some({ linear: Mat3::from_mat4(m), translation: m.c3.xyz() })
  }
}

///|
/// The transform that undoes this one, or `None` when the linear part is
/// singular.
pub fn Affine3::inverse(self : Affine3) -> Affine3? {
  match self.linear.inverse() {
    None => None
    Some(inverse) => Some({
      linear: inverse,
      translation: -(inverse.mul_vec3(self.translation)),
    })
  }
}

///|
/// The point the transform takes `p` to.
pub fn Affine3::transform_point(self : Affine3, p : Vec3) -> Vec3 {
  self.linear.mul_vec3(p) + self.translation
}

///|
/// The direction the transform takes `v` to, without the translation.
pub fn Affine3::transform_vector(self : Affine3, v : Vec3) -> Vec3 {
  self.linear.mul_vec3(v)
}

///|
/// The three parts the transform was built from, or `None` when its linear part
/// is singular or has shear in it. See `Mat4::to_trs`.
pub fn Affine3::to_trs(self : Affine3) -> Trs? {
  self.to_mat4().to_trs()
}

///|
/// Whether the two transforms agree to within `eps` element by element.
pub fn Affine3::approx(self : Affine3, other : Affine3, eps? : {{S}}) -> Bool {
  self.linear.approx(other.linear, eps?) &&
  self.translation.approx(other.translation, eps?)
}

///|
/// Whether every element is finite.
pub fn Affine3::is_finite(self : Affine3) -> Bool {
  self.linear.is_finite() && self.translation.is_finite()
}

///|
/// The transform that applies `other` first and then `self`.
pub impl Mul for Affine3 with mul(self, other) {
  {
    linear: self.linear * other.linear,
    translation: self.linear.mul_vec3(other.translation) + self.translation,
  }
}

///|
pub extend Affine3 with Mul::{mul}

///|
/// The composition with the inverse of the right-hand side; aborts when that
/// side is singular.
pub impl Div for Affine3 with div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Affine3 division by a singular transform")
  }
}

///|
pub extend Affine3 with Div::{div}

///|
pub impl Show for Affine3 with output(self, logger) {
  logger.write_string(
    "Affine3[\{self.linear}, \{self.translation}]",
  )
}

///|
pub extend Affine3 with Show::{output, to_string}

///|
pub impl Debug for Affine3 with to_repr(self) {
  @debug.Repr::ctor("Affine3", [
    (Some("linear"), self.linear.to_repr()),
    (Some("translation"), self.translation.to_repr()),
  ])
}

///|
pub extend Affine3 with Debug::{to_repr}
