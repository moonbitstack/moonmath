// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A colour with three components, red, green and blue, and no alpha.
///
/// The components are plain numbers: this library does the arithmetic — adding a
/// light, blending two values, lerping a gradient — and leaves the encoding to
/// the caller, who knows whether the numbers are linear or sRGB and whether they
/// are in `0..1` or `0..255`. The HSV conversion is `rgb_to_hsv`, with the hue in
/// turns and the other two in `0..1`.
///
/// Values are immutable, and the operators work component by component.
#derive(Eq)
pub(all) struct Color3 {
  /// The red component.
  r : Double
  /// The green component.
  g : Double
  /// The blue component.
  b : Double
}

///|
pub extend Color3 with Eq::{equal, not_equal}

///|
/// The colour from its three components.
pub fn Color3::new(r : Double, g : Double, b : Double) -> Color3 {
  { r, g, b, }
}

///|
/// The colour with the same value in all three components: a grey.
pub fn Color3::splat(value : Double) -> Color3 {
  { r: value, g: value, b: value, }
}

///|
/// Black: no light at all.
pub fn Color3::zero() -> Color3 {
  { r: 0.0, g: 0.0, b: 0.0, }
}

///|
/// White: the most of every component.
pub fn Color3::one() -> Color3 {
  { r: 1.0, g: 1.0, b: 1.0, }
}

///|
/// The component-wise smaller of the two.
pub fn Color3::min(self : Color3, other : Color3) -> Color3 {
  { r: self.r.min(other.r), g: self.g.min(other.g), b: self.b.min(other.b), }
}

///|
/// The component-wise larger of the two.
pub fn Color3::max(self : Color3, other : Color3) -> Color3 {
  { r: self.r.max(other.r), g: self.g.max(other.g), b: self.b.max(other.b), }
}

///|
/// The colour with every component pinned between `low` and `high`.
pub fn Color3::clamp(self : Color3, low : Color3, high : Color3) -> Color3 {
  {
    r: self.r.clamp(min=low.r, max=high.r),
    g: self.g.clamp(min=low.g, max=high.g),
    b: self.b.clamp(min=low.b, max=high.b),
  }
}

///|
/// The colour a fraction of the way from `self` to `other`.
pub fn Color3::lerp(self : Color3, other : Color3, t : Double) -> Color3 {
  {
    r: self.r + (other.r - self.r) * t,
    g: self.g + (other.g - self.g) * t,
    b: self.b + (other.b - self.b) * t,
  }
}

///|
/// The three components in order, `[r, g, b]`, for a buffer.
pub fn Color3::to_array(self : Color3) -> FixedArray[Double] {
  [self.r, self.g, self.b]
}

///|
/// Whether every component is finite.
pub fn Color3::is_finite(self : Color3) -> Bool {
  !(self.r.is_nan() ||
  self.r.is_inf() ||
  self.g.is_nan() ||
  self.g.is_inf() ||
  self.b.is_nan() ||
  self.b.is_inf())
}

///|
/// Whether the two colours agree to within `eps` component by component.
pub fn Color3::approx(self : Color3, other : Color3, eps? : Double) -> Bool {
  approx(self.r, other.r, eps?) &&
  approx(self.g, other.g, eps?) &&
  approx(self.b, other.b, eps?)
}

///|
pub impl Add for Color3 with fn add(self, other) {
  { r: self.r + other.r, g: self.g + other.g, b: self.b + other.b, }
}

///|
pub extend Color3 with Add::{add}

///|
pub impl Sub for Color3 with fn sub(self, other) {
  { r: self.r - other.r, g: self.g - other.g, b: self.b - other.b, }
}

///|
pub extend Color3 with Sub::{sub}

///|
pub impl Mul for Color3 with fn mul(self, other) {
  { r: self.r * other.r, g: self.g * other.g, b: self.b * other.b, }
}

///|
pub extend Color3 with Mul::{mul}

///|
pub impl Div for Color3 with fn div(self, other) {
  { r: self.r / other.r, g: self.g / other.g, b: self.b / other.b, }
}

///|
pub extend Color3 with Div::{div}

///|
pub impl Neg for Color3 with fn neg(self) {
  { r: -self.r, g: -self.g, b: -self.b, }
}

///|
pub extend Color3 with Neg::{neg}

///|
pub impl Show for Color3 with fn output(self, logger) {
  logger.write_string("Color3(\{self.r}, \{self.g}, \{self.b})")
}

///|
pub extend Color3 with Show::{output, to_string}

///|
pub impl Debug for Color3 with fn to_repr(self) {
  @debug.Repr::ctor("Color3", [
    (Some("r"), @debug.Repr::double(self.r)),
    (Some("g"), @debug.Repr::double(self.g)),
    (Some("b"), @debug.Repr::double(self.b)),
  ])
}

///|
pub extend Color3 with Debug::{to_repr}

///|
/// The hue, saturation and value of a colour, packed into a `Color3` as `r` the
/// hue, `g` the saturation and `b` the value.
///
/// The hue is a fraction of a turn in `0..1` — a turn rather than degrees or
/// radians, so it lines up with the rest of a graphics pipeline — and the other
/// two are in `0..1`. A grey has no hue and comes back as zero.
pub fn rgb_to_hsv(color : Color3) -> Color3 {
  let highest : Double = color.r.max(color.g).max(color.b)
  let lowest : Double = color.r.min(color.g).min(color.b)
  let span : Double = highest - lowest
  let saturation : Double = if highest == 0.0 { 0.0 } else { span / highest }
  let six : Double = 6.0
  let mut hue : Double = if span == 0.0 {
    0.0
  } else if highest == color.r {
    (color.g - color.b) / span / six
  } else if highest == color.g {
    ((color.b - color.r) / span + 2.0) / six
  } else {
    ((color.r - color.g) / span + 4.0) / six
  }
  if hue < 0.0 {
    hue = hue + 1.0
  }
  { r: hue, g: saturation, b: highest, }
}

///|
/// The colour a hue, saturation and value describe, read the way `rgb_to_hsv`
/// writes them.
pub fn hsv_to_rgb(hsv : Color3) -> Color3 {
  let hue : Double = wrap(hsv.r, 1.0)
  let saturation : Double = hsv.g
  let value : Double = hsv.b
  let six : Double = 6.0
  let scaled : Double = hue * six
  let sector : Double = scaled.floor()
  let fraction : Double = scaled - sector
  let low : Double = value * (1.0 - saturation)
  let falling : Double = value * (1.0 - saturation * fraction)
  let rising : Double = value * (1.0 - saturation * (1.0 - fraction))
  match sector.to_int() {
    0 => { r: value, g: rising, b: low, }
    1 => { r: falling, g: value, b: low, }
    2 => { r: low, g: value, b: rising, }
    3 => { r: low, g: falling, b: value, }
    4 => { r: rising, g: low, b: value, }
    _ => { r: value, g: low, b: falling, }
  }
}

///|
/// A colour with alpha: the three components of `Color3` and an opacity.
///
/// The arithmetic is the same as `Color3`, with the fourth component carried
/// along, so an alpha-premultiplied or straight-alpha pipeline can blend with the
/// operators and decide the policy itself.
///
/// Values are immutable.
#derive(Eq)
pub(all) struct Color4 {
  /// The red component.
  r : Double
  /// The green component.
  g : Double
  /// The blue component.
  b : Double
  /// The opacity: one is opaque, zero is invisible.
  a : Double
}

///|
pub extend Color4 with Eq::{equal, not_equal}

///|
/// The colour from its four components.
pub fn Color4::new(r : Double, g : Double, b : Double, a : Double) -> Color4 {
  { r, g, b, a, }
}

///|
/// The colour with the same value in every component.
pub fn Color4::splat(value : Double) -> Color4 {
  { r: value, g: value, b: value, a: value, }
}

///|
/// The colour of `rgb` at the opacity `a`.
pub fn Color4::from_color3(rgb : Color3, a : Double) -> Color4 {
  { r: rgb.r, g: rgb.g, b: rgb.b, a, }
}

///|
/// The three colour components, dropping the alpha.
pub fn Color4::to_color3(self : Color4) -> Color3 {
  { r: self.r, g: self.g, b: self.b, }
}

///|
/// The component-wise smaller of the two.
pub fn Color4::min(self : Color4, other : Color4) -> Color4 {
  {
    r: self.r.min(other.r),
    g: self.g.min(other.g),
    b: self.b.min(other.b),
    a: self.a.min(other.a),
  }
}

///|
/// The component-wise larger of the two.
pub fn Color4::max(self : Color4, other : Color4) -> Color4 {
  {
    r: self.r.max(other.r),
    g: self.g.max(other.g),
    b: self.b.max(other.b),
    a: self.a.max(other.a),
  }
}

///|
/// The colour a fraction of the way from `self` to `other`.
pub fn Color4::lerp(self : Color4, other : Color4, t : Double) -> Color4 {
  {
    r: self.r + (other.r - self.r) * t,
    g: self.g + (other.g - self.g) * t,
    b: self.b + (other.b - self.b) * t,
    a: self.a + (other.a - self.a) * t,
  }
}

///|
/// The four components in order, `[r, g, b, a]`, for a buffer.
pub fn Color4::to_array(self : Color4) -> FixedArray[Double] {
  [self.r, self.g, self.b, self.a]
}

///|
/// Whether every component is finite.
pub fn Color4::is_finite(self : Color4) -> Bool {
  !(self.r.is_nan() ||
  self.r.is_inf() ||
  self.g.is_nan() ||
  self.g.is_inf() ||
  self.b.is_nan() ||
  self.b.is_inf() ||
  self.a.is_nan() ||
  self.a.is_inf())
}

///|
/// Whether the two colours agree to within `eps` component by component.
pub fn Color4::approx(self : Color4, other : Color4, eps? : Double) -> Bool {
  approx(self.r, other.r, eps?) &&
  approx(self.g, other.g, eps?) &&
  approx(self.b, other.b, eps?) &&
  approx(self.a, other.a, eps?)
}

///|
pub impl Add for Color4 with fn add(self, other) {
  {
    r: self.r + other.r,
    g: self.g + other.g,
    b: self.b + other.b,
    a: self.a + other.a,
  }
}

///|
pub extend Color4 with Add::{add}

///|
pub impl Sub for Color4 with fn sub(self, other) {
  {
    r: self.r - other.r,
    g: self.g - other.g,
    b: self.b - other.b,
    a: self.a - other.a,
  }
}

///|
pub extend Color4 with Sub::{sub}

///|
pub impl Mul for Color4 with fn mul(self, other) {
  {
    r: self.r * other.r,
    g: self.g * other.g,
    b: self.b * other.b,
    a: self.a * other.a,
  }
}

///|
pub extend Color4 with Mul::{mul}

///|
pub impl Div for Color4 with fn div(self, other) {
  {
    r: self.r / other.r,
    g: self.g / other.g,
    b: self.b / other.b,
    a: self.a / other.a,
  }
}

///|
pub extend Color4 with Div::{div}

///|
pub impl Neg for Color4 with fn neg(self) {
  { r: -self.r, g: -self.g, b: -self.b, a: -self.a, }
}

///|
pub extend Color4 with Neg::{neg}

///|
pub impl Show for Color4 with fn output(self, logger) {
  logger.write_string("Color4(\{self.r}, \{self.g}, \{self.b}, \{self.a})")
}

///|
pub extend Color4 with Show::{output, to_string}

///|
pub impl Debug for Color4 with fn to_repr(self) {
  @debug.Repr::ctor("Color4", [
    (Some("r"), @debug.Repr::double(self.r)),
    (Some("g"), @debug.Repr::double(self.g)),
    (Some("b"), @debug.Repr::double(self.b)),
    (Some("a"), @debug.Repr::double(self.a)),
  ])
}

///|
pub extend Color4 with Debug::{to_repr}
