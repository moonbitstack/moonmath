// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A point or a direction in space.
///
/// Right-handed: `x` and `y` as in the plane, `z` towards the viewer in the
/// usual camera setup, so that `cross(x, y) == z`.
///
/// Values are immutable; every operation returns a new one.
///
/// The operators take two vectors of the same type. Scalar scaling is `scale`
/// and `divide`, not `*` and `/`, which belong to the component-wise product.
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
} derive(Eq)

///|
pub extend Vec3 with Eq::{equal, not_equal}

///|
/// The vector from its three components.
pub fn Vec3::new(x : Double, y : Double, z : Double) -> Vec3 {
  { x, y, z, }
}

///|
/// The same value in all three components.
pub fn Vec3::splat(value : Double) -> Vec3 {
  { x: value, y: value, z: value, }
}

///|
/// The zero vector: the origin, and the one vector with no direction.
pub fn Vec3::zero() -> Vec3 {
  { x: 0.0, y: 0.0, z: 0.0, }
}

///|
/// The vector with one in every component.
pub fn Vec3::one() -> Vec3 {
  { x: 1.0, y: 1.0, z: 1.0, }
}

///|
/// The unit vector along +x.
pub fn Vec3::unit_x() -> Vec3 {
  { x: 1.0, y: 0.0, z: 0.0, }
}

///|
/// The unit vector along +y.
pub fn Vec3::unit_y() -> Vec3 {
  { x: 0.0, y: 1.0, z: 0.0, }
}

///|
/// The unit vector along +z.
pub fn Vec3::unit_z() -> Vec3 {
  { x: 0.0, y: 0.0, z: 1.0, }
}

///|
/// The dot product: `length * other.length * cos(angle)` between them.
pub fn Vec3::dot(self : Vec3, other : Vec3) -> Double {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
/// The cross product: the vector perpendicular to both, right-handed.
///
/// Its length is the area of the parallelogram they span, so the two are
/// parallel exactly when it is zero. `cross(x, y)` is `z`.
pub fn Vec3::cross(self : Vec3, other : Vec3) -> Vec3 {
  {
    x: self.y * other.z - self.z * other.y,
    y: self.z * other.x - self.x * other.z,
    z: self.x * other.y - self.y * other.x,
  }
}

///|
/// The length of the vector: its distance from the origin.
pub fn Vec3::length(self : Vec3) -> Double {
  self.length_squared().sqrt()
}

///|
/// The square of the length, without the square root.
pub fn Vec3::length_squared(self : Vec3) -> Double {
  self.dot(self)
}

///|
/// The distance between the two points.
pub fn Vec3::distance(self : Vec3, other : Vec3) -> Double {
  (self - other).length()
}

///|
/// The square of the distance between the two points.
pub fn Vec3::distance_squared(self : Vec3, other : Vec3) -> Double {
  (self - other).length_squared()
}

///|
/// The vector scaled to length one, pointing the way it did.
///
/// The zero vector has no direction, and this returns `Vec3::zero()` rather
/// than a NaN: the named answer is "no direction", not "undefined". Use
/// `try_normalize` where the case needs telling apart.
pub fn Vec3::normalize(self : Vec3) -> Vec3 {
  let length = self.length()
  if length == 0.0 {
    Vec3::zero()
  } else {
    let scale : Double = 1.0 / length
    self.scale(scale)
  }
}

///|
/// The vector scaled to length one, or `None` if it has no direction.
pub fn Vec3::try_normalize(self : Vec3) -> Vec3? {
  let length = self.length()
  if length == 0.0 {
    None
  } else {
    Some(self.scale(1.0 / length))
  }
}

///|
/// The vector scaled to length one, or `fallback` if it has no direction.
pub fn Vec3::normalize_or(self : Vec3, fallback : Vec3) -> Vec3 {
  match self.try_normalize() {
    Some(unit) => unit
    None => fallback
  }
}

///|
/// The vector multiplied by `factor`.
pub fn Vec3::scale(self : Vec3, factor : Double) -> Vec3 {
  { x: self.x * factor, y: self.y * factor, z: self.z * factor, }
}

///|
/// The vector divided by `divisor`, component by component.
///
/// Dividing by zero gives an infinity or a NaN, as the scalar division does.
pub fn Vec3::divide(self : Vec3, divisor : Double) -> Vec3 {
  { x: self.x / divisor, y: self.y / divisor, z: self.z / divisor, }
}

///|
/// The point a fraction of the way from `self` to `other`.
pub fn Vec3::lerp(self : Vec3, other : Vec3, t : Double) -> Vec3 {
  {
    x: self.x + (other.x - self.x) * t,
    y: self.y + (other.y - self.y) * t,
    z: self.z + (other.z - self.z) * t,
  }
}

///|
/// The component-wise smaller of the two.
pub fn Vec3::min(self : Vec3, other : Vec3) -> Vec3 {
  { x: self.x.min(other.x), y: self.y.min(other.y), z: self.z.min(other.z), }
}

///|
/// The component-wise larger of the two.
pub fn Vec3::max(self : Vec3, other : Vec3) -> Vec3 {
  { x: self.x.max(other.x), y: self.y.max(other.y), z: self.z.max(other.z), }
}

///|
/// The vector with every component pinned between `low` and `high`.
pub fn Vec3::clamp(self : Vec3, low : Vec3, high : Vec3) -> Vec3 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
  }
}

///|
/// The vector with every component replaced by its absolute value.
pub fn Vec3::abs(self : Vec3) -> Vec3 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs(), }
}

///|
/// The vector with every component rounded down to a whole number.
pub fn Vec3::floor(self : Vec3) -> Vec3 {
  { x: self.x.floor(), y: self.y.floor(), z: self.z.floor(), }
}

///|
/// The vector with every component rounded up to a whole number.
pub fn Vec3::ceil(self : Vec3) -> Vec3 {
  { x: self.x.ceil(), y: self.y.ceil(), z: self.z.ceil(), }
}

///|
/// The vector with every component rounded to the nearest whole number, a half
/// going up.
pub fn Vec3::round(self : Vec3) -> Vec3 {
  { x: self.x.round(), y: self.y.round(), z: self.z.round(), }
}

///|
/// The vector with every component replaced by its fractional part.
pub fn Vec3::fract(self : Vec3) -> Vec3 {
  {
    x: self.x - self.x.floor(),
    y: self.y - self.y.floor(),
    z: self.z - self.z.floor(),
  }
}

///|
/// The angle between the two directions, in radians, in `0..pi`.
///
/// Unsigned: in space there is no counter-clockwise, so the answer is just how
/// far apart they point. Computed from the normalized dot product, clamped so
/// that rounding cannot push it out of the arc cosine's domain. Zero when
/// either vector has no direction.
///
/// ```mbt check
/// test {
///   let x : @f64.Vec3 = @f64.Vec3::unit_x()
///   let y = @f64.Vec3::unit_y()
///   assert_true(@f64.approx(x.angle_between(y), @f64.half_pi))
///   assert_true(@f64.approx(x.angle_between(-x), @f64.pi))
/// }
/// ```
pub fn Vec3::angle_between(self : Vec3, other : Vec3) -> Double {
  let cosine = self.normalize().dot(other.normalize())
  let unit : Double = 1.0
  @math.acos(cosine.clamp(min=-unit, max=unit))
}

///|
/// The component of `self` along `onto`.
///
/// `onto` need not be a unit vector. A zero `onto` gives zero.
pub fn Vec3::project(self : Vec3, onto : Vec3) -> Vec3 {
  let length_squared = onto.length_squared()
  if length_squared == 0.0 {
    Vec3::zero()
  } else {
    onto.scale(self.dot(onto) / length_squared)
  }
}

///|
/// The component of `self` perpendicular to `onto`.
pub fn Vec3::reject(self : Vec3, onto : Vec3) -> Vec3 {
  self - self.project(onto)
}

///|
/// The direction `self` takes after bouncing off a surface with normal `normal`.
///
/// `self` is the incoming direction and `normal` points out of the surface
/// against it. Both are taken to be unit length, as they are in a shader; the
/// result has the same length as `self`.
pub fn Vec3::reflect(self : Vec3, normal : Vec3) -> Vec3 {
  let twice : Double = 2.0 * self.dot(normal)
  self - normal.scale(twice)
}

///|
/// The direction `self` takes after entering a medium with normal `normal` and
/// index ratio `eta`, or `None` past the critical angle.
///
/// `self` and `normal` are taken to be unit length, `normal` pointing against
/// the incoming direction, and `eta` the ratio of the indices of refraction on
/// the two sides. Past the critical angle the ray is reflected whole and there
/// is no refracted direction: `None` says so, and reflecting is the caller's
/// business.
///
/// ```mbt check
/// test {
///   let down : @f64.Vec3 = @f64.Vec3::new(0.0, -1.0, 0.0)
///   let up = @f64.Vec3::new(0.0, 1.0, 0.0)
///   // Straight down onto a surface and straight on through.
///   let through = down.refract(up, 0.5).unwrap()
///   assert_true(through.approx(down))
/// }
/// ```
pub fn Vec3::refract(self : Vec3, normal : Vec3, eta : Double) -> Vec3? {
  let cos_in = -self.dot(normal)
  let sin_out_squared = eta * eta * (1.0 - cos_in * cos_in)
  if sin_out_squared > 1.0 {
    None
  } else {
    let rest : Double = 1.0 - sin_out_squared
    let cos_out = rest.sqrt()
    Some(self.scale(eta) + normal.scale(eta * cos_in - cos_out))
  }
}

///|
/// The first two components: the vector projected onto the `xy` plane.
pub fn Vec3::xy(self : Vec3) -> Vec2 {
  { x: self.x, y: self.y, }
}

///|
/// The first and third components: the projection onto the `xz` plane.
pub fn Vec3::xz(self : Vec3) -> Vec2 {
  { x: self.x, y: self.z, }
}

///|
/// The last two components: the projection onto the `yz` plane.
pub fn Vec3::yz(self : Vec3) -> Vec2 {
  { x: self.y, y: self.z, }
}

///|
/// The components backwards: `(z, y, x)`, which turns a lookup into its mirror.
pub fn Vec3::zyx(self : Vec3) -> Vec3 {
  { x: self.z, y: self.y, z: self.x, }
}

///|
/// The components in the order `(x, z, y)`, swapping the last two.
pub fn Vec3::xzy(self : Vec3) -> Vec3 {
  { x: self.x, y: self.z, z: self.y, }
}

///|
/// The components in the order `(y, x, z)`, swapping the first two.
pub fn Vec3::yxz(self : Vec3) -> Vec3 {
  { x: self.y, y: self.x, z: self.z, }
}

///|
/// The components in the order `(y, z, x)`, a third of a turn of the axes.
pub fn Vec3::yzx(self : Vec3) -> Vec3 {
  { x: self.y, y: self.z, z: self.x, }
}

///|
/// The components in the order `(z, x, y)`, the other third of a turn.
pub fn Vec3::zxy(self : Vec3) -> Vec3 {
  { x: self.z, y: self.x, z: self.y, }
}

///|
/// The same vector with `w` appended, for a point being lifted into 4D.
pub fn Vec3::to_vec4(self : Vec3, w : Double) -> Vec4 {
  { x: self.x, y: self.y, z: self.z, w, }
}

///|
/// The components in order, `[x, y, z]`, for handing to a buffer.
pub fn Vec3::to_array(self : Vec3) -> FixedArray[Double] {
  [self.x, self.y, self.z]
}

///|
/// Whether every component is finite.
pub fn Vec3::is_finite(self : Vec3) -> Bool {
  !(self.x.is_nan() ||
  self.x.is_inf() ||
  self.y.is_nan() ||
  self.y.is_inf() ||
  self.z.is_nan() ||
  self.z.is_inf())
}

///|
/// Whether the two vectors agree to within `eps` component by component.
pub fn Vec3::approx(self : Vec3, other : Vec3, eps? : Double) -> Bool {
  approx(self.x, other.x, eps?) &&
  approx(self.y, other.y, eps?) &&
  approx(self.z, other.z, eps?)
}

///|
pub impl Add for Vec3 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z, }
}

///|
pub extend Vec3 with Add::{add}

///|
pub impl Sub for Vec3 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z, }
}

///|
pub extend Vec3 with Sub::{sub}

///|
pub impl Mul for Vec3 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z, }
}

///|
pub extend Vec3 with Mul::{mul}

///|
pub impl Div for Vec3 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z, }
}

///|
pub extend Vec3 with Div::{div}

///|
pub impl Neg for Vec3 with fn neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, }
}

///|
pub extend Vec3 with Neg::{neg}

///|
pub impl Show for Vec3 with fn output(self, logger) {
  logger.write_string("Vec3(\{self.x}, \{self.y}, \{self.z})")
}

///|
pub extend Vec3 with Show::{output, to_string}

///|
pub impl Debug for Vec3 with fn to_repr(self) {
  @debug.Repr::ctor("Vec3", [
    (Some("x"), @debug.Repr::double(self.x)),
    (Some("y"), @debug.Repr::double(self.y)),
    (Some("z"), @debug.Repr::double(self.z)),
  ])
}

///|
pub extend Vec3 with Debug::{to_repr}
