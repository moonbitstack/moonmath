// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A shear: the three off-diagonal terms that slide one axis into another while
/// leaving the origin and the axes themselves where they are.
///
/// A shear is a linear map, so it is applied through `to_mat3` or `to_mat4`.
/// `xy` slides `y` into `x`, `xz` slides `z` into `x`, and `yz` slides `z` into
/// `y`, matching the `(row, column)` terms of the upper triangle. The three
/// together are the general upper-triangular linear map, which is what a skew, a
/// slanted view of a page, or a shear deformation of a mesh is.
///
/// Values are immutable.
#derive(Eq)
pub(all) struct Shear {
  /// How much `x` gains from `y`: the `(0, 1)` term.
  xy : {{S}}
  /// How much `x` gains from `z`: the `(0, 2)` term.
  xz : {{S}}
  /// How much `y` gains from `z`: the `(1, 2)` term.
  yz : {{S}}
}

///|
pub extend Shear with Eq::{equal, not_equal}

///|
/// The shear from its three terms.
pub fn Shear::new(xy : {{S}}, xz : {{S}}, yz : {{S}}) -> Shear {
  { xy, xz, yz, }
}

///|
/// No shear: the identity map.
pub fn Shear::zero() -> Shear {
  { xy: 0.0, xz: 0.0, yz: 0.0, }
}

///|
/// The shear as a linear map, ready to compose with a rotation or a scale.
pub fn Shear::to_mat3(self : Shear) -> Mat3 {
  Mat3::from_cols(
    { x: 1.0, y: 0.0, z: 0.0 },
    { x: self.xy, y: 1.0, z: 0.0 },
    { x: self.xz, y: self.yz, z: 1.0 },
  )
}

///|
/// The shear as a 4×4 matrix whose translation is zero.
pub fn Shear::to_mat4(self : Shear) -> Mat4 {
  Mat4::from_mat3(self.to_mat3())
}

///|
/// Whether the three terms agree with `other` to within `eps`.
pub fn Shear::approx(self : Shear, other : Shear, eps? : {{S}}) -> Bool {
  approx(self.xy, other.xy, eps?) &&
  approx(self.xz, other.xz, eps?) &&
  approx(self.yz, other.yz, eps?)
}

///|
/// Whether the three terms are finite.
pub fn Shear::is_finite(self : Shear) -> Bool {
  !(self.xy.is_nan() ||
  self.xy.is_inf() ||
  self.xz.is_nan() ||
  self.xz.is_inf() ||
  self.yz.is_nan() ||
  self.yz.is_inf())
}

///|
pub impl Show for Shear with fn output(self, logger) {
  logger.write_string("Shear(\{self.xy}, \{self.xz}, \{self.yz})")
}

///|
pub extend Shear with Show::{output, to_string}

///|
pub impl Debug for Shear with fn to_repr(self) {
  @debug.Repr::ctor("Shear", [
    (Some("xy"), @debug.Repr::{{DBG}}(self.xy)),
    (Some("xz"), @debug.Repr::{{DBG}}(self.xz)),
    (Some("yz"), @debug.Repr::{{DBG}}(self.yz)),
  ])
}

///|
pub extend Shear with Debug::{to_repr}
