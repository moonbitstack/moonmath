// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A point or a direction in the plane.
///
/// Two scalars side by side, in the order the plane's axes are named: `x` runs
/// east, `y` runs north. Nothing here knows whether +y points up the screen or
/// down it — that is a convention of the canvas, not of the arithmetic.
///
/// Values are immutable; every operation returns a new one.
///
/// The operators take two vectors of the same type. There is no `Vec2 * Float`,
/// because a value can only carry one `Mul` implementation here: scalar scaling
/// is `scale`, its inverse `divide`.
pub(all) struct Vec2 {
  /// The x component: east.
  x : Float
  /// The y component: north.
  y : Float
} derive(Eq)

///|
pub extend Vec2 with Eq::{equal, not_equal}

///|
/// The vector from `x` and `y`.
pub fn Vec2::new(x : Float, y : Float) -> Vec2 {
  { x, y, }
}

///|
/// The same value in both components.
pub fn Vec2::splat(value : Float) -> Vec2 {
  { x: value, y: value, }
}

///|
/// The zero vector: the origin, and the one vector with no direction.
pub fn Vec2::zero() -> Vec2 {
  { x: 0.0, y: 0.0, }
}

///|
/// The vector with one in both components.
pub fn Vec2::one() -> Vec2 {
  { x: 1.0, y: 1.0, }
}

///|
/// The unit vector along +x.
pub fn Vec2::unit_x() -> Vec2 {
  { x: 1.0, y: 0.0, }
}

///|
/// The unit vector along +y.
pub fn Vec2::unit_y() -> Vec2 {
  { x: 0.0, y: 1.0, }
}

///|
/// The dot product: `length * other.length * cos(angle)` between them.
///
/// Positive when they point the same way, negative when they oppose, zero when
/// they are perpendicular. It is also what a shader's `dot` computes, so the
/// two agree bit for bit when the operands do.
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Float {
  self.x * other.x + self.y * other.y
}

///|
/// The length of the vector: its distance from the origin.
pub fn Vec2::length(self : Vec2) -> Float {
  self.length_squared().sqrt()
}

///|
/// The square of the length.
///
/// Comparing squared lengths orders vectors the same way `length` does without
/// the square root, which is why range checks in hot loops use it.
pub fn Vec2::length_squared(self : Vec2) -> Float {
  self.dot(self)
}

///|
/// The distance between the two points.
pub fn Vec2::distance(self : Vec2, other : Vec2) -> Float {
  (self - other).length()
}

///|
/// The square of the distance between the two points.
pub fn Vec2::distance_squared(self : Vec2, other : Vec2) -> Float {
  (self - other).length_squared()
}

///|
/// The vector scaled to length one, pointing the way it did.
///
/// The zero vector has no direction, and this returns zero rather than a NaN or
/// a division by zero: `Vec2::zero()` is the named answer for "no direction".
/// Callers that need to tell the case apart use `try_normalize`.
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  let length = self.length()
  if length == 0.0 {
    Vec2::zero()
  } else {
    let scale : Float = 1.0 / length
    self.scale(scale)
  }
}

///|
/// The vector scaled to length one, or `None` if it has no direction.
pub fn Vec2::try_normalize(self : Vec2) -> Vec2? {
  let length = self.length()
  if length == 0.0 {
    None
  } else {
    Some(self.scale(1.0 / length))
  }
}

///|
/// The vector scaled to length one, or `fallback` if it has no direction.
pub fn Vec2::normalize_or(self : Vec2, fallback : Vec2) -> Vec2 {
  match self.try_normalize() {
    Some(unit) => unit
    None => fallback
  }
}

///|
/// The vector multiplied by `factor`.
///
/// This is the scalar product the `*` operator cannot express, since `*` on two
/// vectors is the component-wise one.
pub fn Vec2::scale(self : Vec2, factor : Float) -> Vec2 {
  { x: self.x * factor, y: self.y * factor, }
}

///|
/// The vector divided by `divisor`, component by component.
///
/// Dividing by zero gives an infinity or a NaN, as the scalar division does;
/// no check is made here.
pub fn Vec2::divide(self : Vec2, divisor : Float) -> Vec2 {
  { x: self.x / divisor, y: self.y / divisor, }
}

///|
/// The point a fraction of the way from `self` to `other`.
pub fn Vec2::lerp(self : Vec2, other : Vec2, t : Float) -> Vec2 {
  { x: self.x + (other.x - self.x) * t, y: self.y + (other.y - self.y) * t, }
}

///|
/// The component-wise smaller of the two.
pub fn Vec2::min(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x.min(other.x), y: self.y.min(other.y), }
}

///|
/// The component-wise larger of the two.
pub fn Vec2::max(self : Vec2, other : Vec2) -> Vec2 {
  { x: self.x.max(other.x), y: self.y.max(other.y), }
}

///|
/// The vector with every component pinned between `low` and `high`.
pub fn Vec2::clamp(self : Vec2, low : Vec2, high : Vec2) -> Vec2 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
  }
}

///|
/// The vector with every component replaced by its absolute value.
pub fn Vec2::abs(self : Vec2) -> Vec2 {
  { x: self.x.abs(), y: self.y.abs(), }
}

///|
/// The vector with every component rounded down to a whole number.
pub fn Vec2::floor(self : Vec2) -> Vec2 {
  { x: self.x.floor(), y: self.y.floor(), }
}

///|
/// The vector with every component rounded up to a whole number.
pub fn Vec2::ceil(self : Vec2) -> Vec2 {
  { x: self.x.ceil(), y: self.y.ceil(), }
}

///|
/// The vector with every component rounded to the nearest whole number, a half
/// going up: `2.5` becomes `3` and `-1.5` becomes `-1`. This is the rounding
/// `Float::round` does, in both units and sign.
pub fn Vec2::round(self : Vec2) -> Vec2 {
  { x: self.x.round(), y: self.y.round(), }
}

///|
/// The vector with every component replaced by its fractional part, `x - floor(x)`.
pub fn Vec2::fract(self : Vec2) -> Vec2 {
  { x: self.x - self.x.floor(), y: self.y - self.y.floor(), }
}

///|
/// The angle from `self` to `other`, in radians, positive counter-clockwise.
///
/// Signed, because in the plane there are only two ways to turn and the sign
/// says which. The result is in `-pi..pi`, and is zero when either vector has no
/// direction.
///
/// ```mbt check
/// test {
///   let x : @moonmath.Vec2 = @moonmath.Vec2::unit_x()
///   let y = @moonmath.Vec2::unit_y()
///   assert_true(@moonmath.approx(x.angle_between(y), @moonmath.half_pi))
/// }
/// ```
pub fn Vec2::angle_between(self : Vec2, other : Vec2) -> Float {
  @math.atan2f(self.cross(other), self.dot(other))
}

///|
/// The component of `self` along `onto`: the shadow it casts on that direction.
///
/// `onto` need not be a unit vector; the result lies along it either way. A
/// zero `onto` has no direction to project onto and gives zero.
pub fn Vec2::project(self : Vec2, onto : Vec2) -> Vec2 {
  let length_squared = onto.length_squared()
  if length_squared == 0.0 {
    Vec2::zero()
  } else {
    onto.scale(self.dot(onto) / length_squared)
  }
}

///|
/// The component of `self` perpendicular to `onto`: what is left after the
/// projection is taken away.
pub fn Vec2::reject(self : Vec2, onto : Vec2) -> Vec2 {
  self - self.project(onto)
}

///|
/// The direction `self` takes after bouncing off a surface with normal `normal`.
///
/// `self` is the incoming direction, and `normal` points out of the surface
/// against it — the result leaves at the mirror angle with the same length. A
/// zero normal returns `self` unchanged.
pub fn Vec2::reflect(self : Vec2, normal : Vec2) -> Vec2 {
  let twice : Float = 2.0 * self.dot(normal)
  self - normal.scale(twice)
}

///|
/// The direction `self` takes after entering a medium with normal `normal` and
/// index ratio `eta`, or `None` when it does not enter at all.
///
/// `self` and `normal` are taken to be unit length, `normal` pointing against
/// the incoming direction, and `eta` the ratio of the indices of refraction on
/// the two sides. Past the critical angle the ray is reflected instead of
/// refracted, and there is no refracted direction to return — that is the
/// `None`, and it is the caller's job to reflect.
pub fn Vec2::refract(self : Vec2, normal : Vec2, eta : Float) -> Vec2? {
  let cos_in = -self.dot(normal)
  let sin_out_squared = eta * eta * (1.0 - cos_in * cos_in)
  if sin_out_squared > 1.0 {
    None
  } else {
    let rest : Float = 1.0 - sin_out_squared
    let cos_out = rest.sqrt()
    Some(self.scale(eta) + normal.scale(eta * cos_in - cos_out))
  }
}

///|
/// The vector turned a quarter turn counter-clockwise: `(-y, x)`.
pub fn Vec2::perp(self : Vec2) -> Vec2 {
  { x: -self.y, y: self.x, }
}

///|
/// The 2D cross product: the signed area of the parallelogram the two span.
///
/// Positive when `other` lies counter-clockwise of `self`, which is the sign a
/// winding test reads.
pub fn Vec2::cross(self : Vec2, other : Vec2) -> Float {
  self.x * other.y - self.y * other.x
}

///|
/// The components the other way round: `(y, x)`.
pub fn Vec2::yx(self : Vec2) -> Vec2 {
  { x: self.y, y: self.x, }
}

///|
/// The same vector with `z` appended, for a point being lifted into 3D.
pub fn Vec2::to_vec3(self : Vec2, z : Float) -> Vec3 {
  { x: self.x, y: self.y, z, }
}

///|
/// The same vector with `z` and `w` appended.
pub fn Vec2::to_vec4(self : Vec2, z : Float, w : Float) -> Vec4 {
  { x: self.x, y: self.y, z, w, }
}

///|
/// The components in order, `[x, y]`, for handing to a buffer.
pub fn Vec2::to_array(self : Vec2) -> FixedArray[Float] {
  [self.x, self.y]
}

///|
/// Whether both components are finite — neither an infinity nor a NaN.
pub fn Vec2::is_finite(self : Vec2) -> Bool {
  !(self.x.is_nan() || self.x.is_inf() || self.y.is_nan() || self.y.is_inf())
}

///|
/// Whether the two vectors agree to within `eps` component by component.
///
/// Without an epsilon this uses `default_epsilon`.
pub fn Vec2::approx(self : Vec2, other : Vec2, eps? : Float) -> Bool {
  approx(self.x, other.x, eps?) && approx(self.y, other.y, eps?)
}

///|
pub impl Add for Vec2 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, }
}

///|
pub extend Vec2 with Add::{add}

///|
pub impl Sub for Vec2 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, }
}

///|
pub extend Vec2 with Sub::{sub}

///|
pub impl Mul for Vec2 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, }
}

///|
pub extend Vec2 with Mul::{mul}

///|
pub impl Div for Vec2 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, }
}

///|
pub extend Vec2 with Div::{div}

///|
pub impl Neg for Vec2 with fn neg(self) {
  { x: -self.x, y: -self.y, }
}

///|
pub extend Vec2 with Neg::{neg}

///|
pub impl Show for Vec2 with fn output(self, logger) {
  logger.write_string("Vec2(\{self.x}, \{self.y})")
}

///|
pub extend Vec2 with Show::{output, to_string}

///|
pub impl Debug for Vec2 with fn to_repr(self) {
  @debug.Repr::ctor("Vec2", [
    (Some("x"), @debug.Repr::float(self.x)),
    (Some("y"), @debug.Repr::float(self.y)),
  ])
}

///|
pub extend Vec2 with Debug::{to_repr}
