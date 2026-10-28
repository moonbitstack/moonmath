// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Four components: a point in homogeneous coordinates, a colour with alpha, or
/// four numbers that travel together.
///
/// A `Vec4` is what a `Mat4` multiplies, and what a shader writes into a vertex
/// buffer: `to_array` gives the four in the order the buffer wants them.
///
/// Values are immutable; every operation returns a new one.
pub(all) struct Vec4 {
  /// The x component: east.
  x : Float
  /// The y component: north.
  y : Float
  /// The z component: towards the viewer.
  z : Float
  /// The fourth component: one for a point, zero for a direction.
  w : Float
} derive(Eq)

///|
pub extend Vec4 with Eq::{equal, not_equal}

///|
/// The vector from its four components.
pub fn Vec4::new(x : Float, y : Float, z : Float, w : Float) -> Vec4 {
  { x, y, z, w, }
}

///|
/// The same value in all four components.
pub fn Vec4::splat(value : Float) -> Vec4 {
  { x: value, y: value, z: value, w: value, }
}

///|
/// The zero vector.
pub fn Vec4::zero() -> Vec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 0.0, }
}

///|
/// The vector with one in every component.
pub fn Vec4::one() -> Vec4 {
  { x: 1.0, y: 1.0, z: 1.0, w: 1.0, }
}

///|
/// The unit vector along +x.
pub fn Vec4::unit_x() -> Vec4 {
  { x: 1.0, y: 0.0, z: 0.0, w: 0.0, }
}

///|
/// The unit vector along +y.
pub fn Vec4::unit_y() -> Vec4 {
  { x: 0.0, y: 1.0, z: 0.0, w: 0.0, }
}

///|
/// The unit vector along +z.
pub fn Vec4::unit_z() -> Vec4 {
  { x: 0.0, y: 0.0, z: 1.0, w: 0.0, }
}

///|
/// The unit vector along +w.
pub fn Vec4::unit_w() -> Vec4 {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0, }
}

///|
/// The dot product, over all four components.
///
/// In homogeneous coordinates this is what a plane's `dot` does with a point,
/// and what the `w` component of a transformed vector carries.
pub fn Vec4::dot(self : Vec4, other : Vec4) -> Float {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
/// The length of the vector, in four dimensions.
pub fn Vec4::length(self : Vec4) -> Float {
  self.length_squared().sqrt()
}

///|
/// The square of the length, without the square root.
pub fn Vec4::length_squared(self : Vec4) -> Float {
  self.dot(self)
}

///|
/// The distance between the two points, in four dimensions.
pub fn Vec4::distance(self : Vec4, other : Vec4) -> Float {
  (self - other).length()
}

///|
/// The square of the distance between the two points.
pub fn Vec4::distance_squared(self : Vec4, other : Vec4) -> Float {
  (self - other).length_squared()
}

///|
/// The vector scaled to length one, or `Vec4::zero()` if it has no direction.
pub fn Vec4::normalize(self : Vec4) -> Vec4 {
  let length = self.length()
  if length == 0.0 {
    Vec4::zero()
  } else {
    let scale : Float = 1.0 / length
    self.scale(scale)
  }
}

///|
/// The vector scaled to length one, or `None` if it has no direction.
pub fn Vec4::try_normalize(self : Vec4) -> Vec4? {
  let length = self.length()
  if length == 0.0 {
    None
  } else {
    Some(self.scale(1.0 / length))
  }
}

///|
/// The vector scaled to length one, or `fallback` if it has no direction.
pub fn Vec4::normalize_or(self : Vec4, fallback : Vec4) -> Vec4 {
  match self.try_normalize() {
    Some(unit) => unit
    None => fallback
  }
}

///|
/// The vector multiplied by `factor`.
///
/// This is how a homogeneous position is taken out of projective space: divide
/// by `w` with `divide`, or scale by its reciprocal.
pub fn Vec4::scale(self : Vec4, factor : Float) -> Vec4 {
  {
    x: self.x * factor,
    y: self.y * factor,
    z: self.z * factor,
    w: self.w * factor,
  }
}

///|
/// The vector divided by `divisor`, component by component.
pub fn Vec4::divide(self : Vec4, divisor : Float) -> Vec4 {
  {
    x: self.x / divisor,
    y: self.y / divisor,
    z: self.z / divisor,
    w: self.w / divisor,
  }
}

///|
/// The point a fraction of the way from `self` to `other`, all four components.
pub fn Vec4::lerp(self : Vec4, other : Vec4, t : Float) -> Vec4 {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
    z: self.z + (other.z - self.z) * t,
    w: self.w + (other.w - self.w) * t,
  }
}

///|
/// The component-wise smaller of the two.
pub fn Vec4::min(self : Vec4, other : Vec4) -> Vec4 {
  {
    x: self.x.min(other.x),
    y: self.y.min(other.y),
    z: self.z.min(other.z),
    w: self.w.min(other.w),
  }
}

///|
/// The component-wise larger of the two.
pub fn Vec4::max(self : Vec4, other : Vec4) -> Vec4 {
  {
    x: self.x.max(other.x),
    y: self.y.max(other.y),
    z: self.z.max(other.z),
    w: self.w.max(other.w),
  }
}

///|
/// The vector with every component pinned between `low` and `high`.
pub fn Vec4::clamp(self : Vec4, low : Vec4, high : Vec4) -> Vec4 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
    w: self.w.clamp(min=low.w, max=high.w),
  }
}

///|
/// The vector with every component replaced by its absolute value.
pub fn Vec4::abs(self : Vec4) -> Vec4 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs(), w: self.w.abs(), }
}

///|
/// The vector with every component rounded down to a whole number.
pub fn Vec4::floor(self : Vec4) -> Vec4 {
  {
    x: self.x.floor(),
    y: self.y.floor(),
    z: self.z.floor(),
    w: self.w.floor(),
  }
}

///|
/// The vector with every component rounded up to a whole number.
pub fn Vec4::ceil(self : Vec4) -> Vec4 {
  { x: self.x.ceil(), y: self.y.ceil(), z: self.z.ceil(), w: self.w.ceil(), }
}

///|
/// The vector with every component rounded to the nearest whole number, a half
/// going up.
pub fn Vec4::round(self : Vec4) -> Vec4 {
  {
    x: self.x.round(),
    y: self.y.round(),
    z: self.z.round(),
    w: self.w.round(),
  }
}

///|
/// The vector with every component replaced by its fractional part.
pub fn Vec4::fract(self : Vec4) -> Vec4 {
  {
    x: self.x - self.x.floor(),
    y: self.y - self.y.floor(),
    z: self.z - self.z.floor(),
    w: self.w - self.w.floor(),
  }
}

///|
/// The first two components.
pub fn Vec4::xy(self : Vec4) -> Vec2 {
  { x: self.x, y: self.y, }
}

///|
/// The first three components: the position a homogeneous point names, before
/// the division by `w`.
pub fn Vec4::xyz(self : Vec4) -> Vec3 {
  { x: self.x, y: self.y, z: self.z, }
}

///|
/// All four components backwards: `(w, z, y, x)`.
pub fn Vec4::wzyx(self : Vec4) -> Vec4 {
  { x: self.w, y: self.z, z: self.y, w: self.x, }
}

///|
/// The components in order, `[x, y, z, w]`, for handing to a buffer.
pub fn Vec4::to_array(self : Vec4) -> FixedArray[Float] {
  [self.x, self.y, self.z, self.w]
}

///|
/// Whether every component is finite.
pub fn Vec4::is_finite(self : Vec4) -> Bool {
  !(self.x.is_nan() ||
  self.x.is_inf() ||
  self.y.is_nan() ||
  self.y.is_inf() ||
  self.z.is_nan() ||
  self.z.is_inf() ||
  self.w.is_nan() ||
  self.w.is_inf())
}

///|
/// Whether the two vectors agree to within `eps` component by component.
pub fn Vec4::approx(self : Vec4, other : Vec4, eps? : Float) -> Bool {
  approx(self.x, other.x, eps?) &&
  approx(self.y, other.y, eps?) &&
  approx(self.z, other.z, eps?) &&
  approx(self.w, other.w, eps?)
}

///|
pub impl Add for Vec4 with fn add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub extend Vec4 with Add::{add}

///|
pub impl Sub for Vec4 with fn sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub extend Vec4 with Sub::{sub}

///|
pub impl Mul for Vec4 with fn mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub extend Vec4 with Mul::{mul}

///|
pub impl Div for Vec4 with fn div(self, other) {
  {
    x: self.x / other.x,
    y: self.y / other.y,
    z: self.z / other.z,
    w: self.w / other.w,
  }
}

///|
pub extend Vec4 with Div::{div}

///|
pub impl Neg for Vec4 with fn neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w, }
}

///|
pub extend Vec4 with Neg::{neg}

///|
pub impl Show for Vec4 with fn output(self, logger) {
  logger.write_string("Vec4(\{self.x}, \{self.y}, \{self.z}, \{self.w})")
}

///|
pub extend Vec4 with Show::{output, to_string}

///|
pub impl Debug for Vec4 with fn to_repr(self) {
  @debug.Repr::ctor("Vec4", [
    (Some("x"), @debug.Repr::float(self.x)),
    (Some("y"), @debug.Repr::float(self.y)),
    (Some("z"), @debug.Repr::float(self.z)),
    (Some("w"), @debug.Repr::float(self.w)),
  ])
}

///|
pub extend Vec4 with Debug::{to_repr}
