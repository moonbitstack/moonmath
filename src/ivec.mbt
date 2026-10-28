// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Integer vectors: grid cells, pixel coordinates, tile indices. They are here
// for the arithmetic a layout or a tilemap does — adding an offset, clamping to
// a viewport, comparing two cells — and not for the arithmetic a renderer does,
// which wants `Vec2` and `Vec3`.
//
// `Int` is 32 bits, which is what pixel coordinates need and no more; `UInt` is
// the same width unsigned, for sizes and indices that cannot be negative.

///|
/// Two whole numbers: a grid cell or a pixel coordinate.
///
/// Division is integer division and truncates towards zero, and dividing by
/// zero aborts, as it does for `Int` itself.
pub(all) struct IVec2 {
  x : Int32
  y : Int32
} derive(Eq, Hash)

///|
pub extend IVec2 with Eq::{equal, not_equal}

///|
pub extend IVec2 with Hash::{hash, hash_combine}

///|
/// The pair `(x, y)`.
pub fn IVec2::new(x : Int32, y : Int32) -> IVec2 {
  { x, y, }
}

///|
/// The same value in both components.
pub fn IVec2::splat(value : Int32) -> IVec2 {
  { x: value, y: value, }
}

///|
/// The origin of the grid.
pub fn IVec2::zero() -> IVec2 {
  { x: 0, y: 0, }
}

///|
/// One in both components: the step between neighbouring cells.
pub fn IVec2::one() -> IVec2 {
  { x: 1, y: 1, }
}

///|
/// The dot product, in whole numbers.
pub fn IVec2::dot(self : IVec2, other : IVec2) -> Int32 {
  self.x * other.x + self.y * other.y
}

///|
/// The component-wise smaller of the two.
pub fn IVec2::min(self : IVec2, other : IVec2) -> IVec2 {
  { x: self.x.min(other.x), y: self.y.min(other.y), }
}

///|
/// The component-wise larger of the two.
pub fn IVec2::max(self : IVec2, other : IVec2) -> IVec2 {
  { x: self.x.max(other.x), y: self.y.max(other.y), }
}

///|
/// The pair with every component pinned between `low` and `high`, inclusive.
pub fn IVec2::clamp(self : IVec2, low : IVec2, high : IVec2) -> IVec2 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
  }
}

///|
/// The pair with every component replaced by its absolute value.
pub fn IVec2::abs(self : IVec2) -> IVec2 {
  { x: self.x.abs(), y: self.y.abs(), }
}

///|
/// The components in order, `[x, y]`.
pub fn IVec2::to_array(self : IVec2) -> FixedArray[Int32] {
  [self.x, self.y]
}

///|
/// The same cell as a floating-point vector, exactly.
pub fn IVec2::as_vec2(self : IVec2) -> Vec2 {
  { x: Float::from_int(self.x), y: Float::from_int(self.y), }
}

///|
/// The cell a floating-point position falls in, truncated towards zero.
///
/// Truncation rather than rounding, because a pixel coordinate of `-0.5` is in
/// cell `0` when the cell is counted from the point, and the caller that wants
/// the floor asks for `floor` first.
pub fn IVec2::from_vec2(value : Vec2) -> IVec2 {
  { x: value.x.to_int(), y: value.y.to_int(), }
}

///|
pub impl Add for IVec2 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, }
}

///|
pub extend IVec2 with Add::{add}

///|
pub impl Sub for IVec2 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, }
}

///|
pub extend IVec2 with Sub::{sub}

///|
pub impl Mul for IVec2 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, }
}

///|
pub extend IVec2 with Mul::{mul}

///|
pub impl Div for IVec2 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, }
}

///|
pub extend IVec2 with Div::{div}

///|
pub impl Neg for IVec2 with fn neg(self) {
  { x: -self.x, y: -self.y, }
}

///|
pub extend IVec2 with Neg::{neg}

///|
pub impl Show for IVec2 with fn output(self, logger) {
  logger.write_string("IVec2(\{self.x}, \{self.y})")
}

///|
pub extend IVec2 with Show::{output, to_string}

///|
pub impl Debug for IVec2 with fn to_repr(self) {
  @debug.Repr::ctor("IVec2", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
  ])
}

///|
pub extend IVec2 with Debug::{to_repr}

///|
/// Three whole numbers: a cell in a voxel grid.
pub(all) struct IVec3 {
  x : Int32
  y : Int32
  z : Int32
} derive(Eq, Hash)

///|
pub extend IVec3 with Eq::{equal, not_equal}

///|
pub extend IVec3 with Hash::{hash, hash_combine}

///|
/// The triple `(x, y, z)`.
pub fn IVec3::new(x : Int32, y : Int32, z : Int32) -> IVec3 {
  { x, y, z, }
}

///|
/// The same value in all three components.
pub fn IVec3::splat(value : Int32) -> IVec3 {
  { x: value, y: value, z: value, }
}

///|
/// The origin of the grid.
pub fn IVec3::zero() -> IVec3 {
  { x: 0, y: 0, z: 0, }
}

///|
/// One in every component.
pub fn IVec3::one() -> IVec3 {
  { x: 1, y: 1, z: 1, }
}

///|
/// The dot product, in whole numbers.
pub fn IVec3::dot(self : IVec3, other : IVec3) -> Int32 {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
/// The component-wise smaller of the two.
pub fn IVec3::min(self : IVec3, other : IVec3) -> IVec3 {
  { x: self.x.min(other.x), y: self.y.min(other.y), z: self.z.min(other.z), }
}

///|
/// The component-wise larger of the two.
pub fn IVec3::max(self : IVec3, other : IVec3) -> IVec3 {
  { x: self.x.max(other.x), y: self.y.max(other.y), z: self.z.max(other.z), }
}

///|
/// The triple with every component pinned between `low` and `high`, inclusive.
pub fn IVec3::clamp(self : IVec3, low : IVec3, high : IVec3) -> IVec3 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
  }
}

///|
/// The triple with every component replaced by its absolute value.
pub fn IVec3::abs(self : IVec3) -> IVec3 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs(), }
}

///|
/// The components in order, `[x, y, z]`.
pub fn IVec3::to_array(self : IVec3) -> FixedArray[Int32] {
  [self.x, self.y, self.z]
}

///|
/// The same cell as a floating-point vector, exactly.
pub fn IVec3::as_vec3(self : IVec3) -> Vec3 {
  {
    x: Float::from_int(self.x),
    y: Float::from_int(self.y),
    z: Float::from_int(self.z),
  }
}

///|
/// The cell a floating-point position falls in, truncated towards zero.
pub fn IVec3::from_vec3(value : Vec3) -> IVec3 {
  { x: value.x.to_int(), y: value.y.to_int(), z: value.z.to_int(), }
}

///|
pub impl Add for IVec3 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z, }
}

///|
pub extend IVec3 with Add::{add}

///|
pub impl Sub for IVec3 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z, }
}

///|
pub extend IVec3 with Sub::{sub}

///|
pub impl Mul for IVec3 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z, }
}

///|
pub extend IVec3 with Mul::{mul}

///|
pub impl Div for IVec3 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z, }
}

///|
pub extend IVec3 with Div::{div}

///|
pub impl Neg for IVec3 with fn neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, }
}

///|
pub extend IVec3 with Neg::{neg}

///|
pub impl Show for IVec3 with fn output(self, logger) {
  logger.write_string("IVec3(\{self.x}, \{self.y}, \{self.z})")
}

///|
pub extend IVec3 with Show::{output, to_string}

///|
pub impl Debug for IVec3 with fn to_repr(self) {
  @debug.Repr::ctor("IVec3", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
    (Some("z"), @debug.Repr::integer(self.z.to_string())),
  ])
}

///|
pub extend IVec3 with Debug::{to_repr}

///|
/// Four whole numbers.
pub(all) struct IVec4 {
  x : Int32
  y : Int32
  z : Int32
  w : Int32
} derive(Eq, Hash)

///|
pub extend IVec4 with Eq::{equal, not_equal}

///|
pub extend IVec4 with Hash::{hash, hash_combine}

///|
/// The quadruple `(x, y, z, w)`.
pub fn IVec4::new(x : Int32, y : Int32, z : Int32, w : Int32) -> IVec4 {
  { x, y, z, w, }
}

///|
/// The same value in all four components.
pub fn IVec4::splat(value : Int32) -> IVec4 {
  { x: value, y: value, z: value, w: value, }
}

///|
/// The zero vector.
pub fn IVec4::zero() -> IVec4 {
  { x: 0, y: 0, z: 0, w: 0, }
}

///|
/// One in every component.
pub fn IVec4::one() -> IVec4 {
  { x: 1, y: 1, z: 1, w: 1, }
}

///|
/// The dot product, in whole numbers.
pub fn IVec4::dot(self : IVec4, other : IVec4) -> Int32 {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
/// The component-wise smaller of the two.
pub fn IVec4::min(self : IVec4, other : IVec4) -> IVec4 {
  {
    x: self.x.min(other.x),
    y: self.y.min(other.y),
    z: self.z.min(other.z),
    w: self.w.min(other.w),
  }
}

///|
/// The component-wise larger of the two.
pub fn IVec4::max(self : IVec4, other : IVec4) -> IVec4 {
  {
    x: self.x.max(other.x),
    y: self.y.max(other.y),
    z: self.z.max(other.z),
    w: self.w.max(other.w),
  }
}

///|
/// The quadruple with every component pinned between `low` and `high`.
pub fn IVec4::clamp(self : IVec4, low : IVec4, high : IVec4) -> IVec4 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
    w: self.w.clamp(min=low.w, max=high.w),
  }
}

///|
/// The quadruple with every component replaced by its absolute value.
pub fn IVec4::abs(self : IVec4) -> IVec4 {
  { x: self.x.abs(), y: self.y.abs(), z: self.z.abs(), w: self.w.abs(), }
}

///|
/// The components in order, `[x, y, z, w]`.
pub fn IVec4::to_array(self : IVec4) -> FixedArray[Int32] {
  [self.x, self.y, self.z, self.w]
}

///|
/// The same values as a floating-point vector, exactly.
pub fn IVec4::as_vec4(self : IVec4) -> Vec4 {
  {
    x: Float::from_int(self.x),
    y: Float::from_int(self.y),
    z: Float::from_int(self.z),
    w: Float::from_int(self.w),
  }
}

///|
/// The values a floating-point vector carries, truncated towards zero.
pub fn IVec4::from_vec4(value : Vec4) -> IVec4 {
  {
    x: value.x.to_int(),
    y: value.y.to_int(),
    z: value.z.to_int(),
    w: value.w.to_int(),
  }
}

///|
pub impl Add for IVec4 with fn add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub extend IVec4 with Add::{add}

///|
pub impl Sub for IVec4 with fn sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub extend IVec4 with Sub::{sub}

///|
pub impl Mul for IVec4 with fn mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub extend IVec4 with Mul::{mul}

///|
pub impl Div for IVec4 with fn div(self, other) {
  {
    x: self.x / other.x,
    y: self.y / other.y,
    z: self.z / other.z,
    w: self.w / other.w,
  }
}

///|
pub extend IVec4 with Div::{div}

///|
pub impl Neg for IVec4 with fn neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w, }
}

///|
pub extend IVec4 with Neg::{neg}

///|
pub impl Show for IVec4 with fn output(self, logger) {
  logger.write_string("IVec4(\{self.x}, \{self.y}, \{self.z}, \{self.w})")
}

///|
pub extend IVec4 with Show::{output, to_string}

///|
pub impl Debug for IVec4 with fn to_repr(self) {
  @debug.Repr::ctor("IVec4", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
    (Some("z"), @debug.Repr::integer(self.z.to_string())),
    (Some("w"), @debug.Repr::integer(self.w.to_string())),
  ])
}

///|
pub extend IVec4 with Debug::{to_repr}

///|
/// Two unsigned whole numbers: a size, a count, a pixel coordinate that cannot
/// be negative.
///
/// There is no `Neg` here for the obvious reason: a negative size is not a
/// size. Subtraction is present and wraps, as `UInt` subtraction does.
pub(all) struct UVec2 {
  x : UInt32
  y : UInt32
} derive(Eq, Hash)

///|
pub extend UVec2 with Eq::{equal, not_equal}

///|
pub extend UVec2 with Hash::{hash, hash_combine}

///|
/// The pair `(x, y)`.
pub fn UVec2::new(x : UInt32, y : UInt32) -> UVec2 {
  { x, y, }
}

///|
/// The same value in both components.
pub fn UVec2::splat(value : UInt32) -> UVec2 {
  { x: value, y: value, }
}

///|
/// Zero in both components: an empty size.
pub fn UVec2::zero() -> UVec2 {
  { x: 0, y: 0, }
}

///|
/// One in both components.
pub fn UVec2::one() -> UVec2 {
  { x: 1, y: 1, }
}

///|
/// The dot product.
pub fn UVec2::dot(self : UVec2, other : UVec2) -> UInt32 {
  self.x * other.x + self.y * other.y
}

///|
/// The component-wise smaller of the two.
pub fn UVec2::min(self : UVec2, other : UVec2) -> UVec2 {
  { x: self.x.min(other.x), y: self.y.min(other.y), }
}

///|
/// The component-wise larger of the two.
pub fn UVec2::max(self : UVec2, other : UVec2) -> UVec2 {
  { x: self.x.max(other.x), y: self.y.max(other.y), }
}

///|
/// The pair with every component pinned between `low` and `high`, inclusive.
pub fn UVec2::clamp(self : UVec2, low : UVec2, high : UVec2) -> UVec2 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
  }
}

///|
/// The components in order, `[x, y]`.
pub fn UVec2::to_array(self : UVec2) -> FixedArray[UInt32] {
  [self.x, self.y]
}

///|
/// The same size as a floating-point vector, exactly.
pub fn UVec2::as_vec2(self : UVec2) -> Vec2 {
  { x: Float::from_uint(self.x), y: Float::from_uint(self.y), }
}

///|
pub impl Add for UVec2 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, }
}

///|
pub extend UVec2 with Add::{add}

///|
pub impl Sub for UVec2 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, }
}

///|
pub extend UVec2 with Sub::{sub}

///|
pub impl Mul for UVec2 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, }
}

///|
pub extend UVec2 with Mul::{mul}

///|
pub impl Div for UVec2 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, }
}

///|
pub extend UVec2 with Div::{div}

///|
pub impl Show for UVec2 with fn output(self, logger) {
  logger.write_string("UVec2(\{self.x}, \{self.y})")
}

///|
pub extend UVec2 with Show::{output, to_string}

///|
pub impl Debug for UVec2 with fn to_repr(self) {
  @debug.Repr::ctor("UVec2", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
  ])
}

///|
pub extend UVec2 with Debug::{to_repr}

///|
/// Three unsigned whole numbers.
pub(all) struct UVec3 {
  x : UInt32
  y : UInt32
  z : UInt32
} derive(Eq, Hash)

///|
pub extend UVec3 with Eq::{equal, not_equal}

///|
pub extend UVec3 with Hash::{hash, hash_combine}

///|
/// The triple `(x, y, z)`.
pub fn UVec3::new(x : UInt32, y : UInt32, z : UInt32) -> UVec3 {
  { x, y, z, }
}

///|
/// The same value in all three components.
pub fn UVec3::splat(value : UInt32) -> UVec3 {
  { x: value, y: value, z: value, }
}

///|
/// Zero in every component.
pub fn UVec3::zero() -> UVec3 {
  { x: 0, y: 0, z: 0, }
}

///|
/// One in every component.
pub fn UVec3::one() -> UVec3 {
  { x: 1, y: 1, z: 1, }
}

///|
/// The dot product.
pub fn UVec3::dot(self : UVec3, other : UVec3) -> UInt32 {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
/// The component-wise smaller of the two.
pub fn UVec3::min(self : UVec3, other : UVec3) -> UVec3 {
  { x: self.x.min(other.x), y: self.y.min(other.y), z: self.z.min(other.z), }
}

///|
/// The component-wise larger of the two.
pub fn UVec3::max(self : UVec3, other : UVec3) -> UVec3 {
  { x: self.x.max(other.x), y: self.y.max(other.y), z: self.z.max(other.z), }
}

///|
/// The triple with every component pinned between `low` and `high`, inclusive.
pub fn UVec3::clamp(self : UVec3, low : UVec3, high : UVec3) -> UVec3 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
  }
}

///|
/// The components in order, `[x, y, z]`.
pub fn UVec3::to_array(self : UVec3) -> FixedArray[UInt32] {
  [self.x, self.y, self.z]
}

///|
/// The same values as a floating-point vector, exactly.
pub fn UVec3::as_vec3(self : UVec3) -> Vec3 {
  {
    x: Float::from_uint(self.x),
    y: Float::from_uint(self.y),
    z: Float::from_uint(self.z),
  }
}

///|
pub impl Add for UVec3 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z, }
}

///|
pub extend UVec3 with Add::{add}

///|
pub impl Sub for UVec3 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z, }
}

///|
pub extend UVec3 with Sub::{sub}

///|
pub impl Mul for UVec3 with fn mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y, z: self.z * other.z, }
}

///|
pub extend UVec3 with Mul::{mul}

///|
pub impl Div for UVec3 with fn div(self, other) {
  { x: self.x / other.x, y: self.y / other.y, z: self.z / other.z, }
}

///|
pub extend UVec3 with Div::{div}

///|
pub impl Show for UVec3 with fn output(self, logger) {
  logger.write_string("UVec3(\{self.x}, \{self.y}, \{self.z})")
}

///|
pub extend UVec3 with Show::{output, to_string}

///|
pub impl Debug for UVec3 with fn to_repr(self) {
  @debug.Repr::ctor("UVec3", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
    (Some("z"), @debug.Repr::integer(self.z.to_string())),
  ])
}

///|
pub extend UVec3 with Debug::{to_repr}

///|
/// Four unsigned whole numbers.
pub(all) struct UVec4 {
  x : UInt32
  y : UInt32
  z : UInt32
  w : UInt32
} derive(Eq, Hash)

///|
pub extend UVec4 with Eq::{equal, not_equal}

///|
pub extend UVec4 with Hash::{hash, hash_combine}

///|
/// The quadruple `(x, y, z, w)`.
pub fn UVec4::new(x : UInt32, y : UInt32, z : UInt32, w : UInt32) -> UVec4 {
  { x, y, z, w, }
}

///|
/// The same value in all four components.
pub fn UVec4::splat(value : UInt32) -> UVec4 {
  { x: value, y: value, z: value, w: value, }
}

///|
/// Zero in every component.
pub fn UVec4::zero() -> UVec4 {
  { x: 0, y: 0, z: 0, w: 0, }
}

///|
/// One in every component.
pub fn UVec4::one() -> UVec4 {
  { x: 1, y: 1, z: 1, w: 1, }
}

///|
/// The dot product.
pub fn UVec4::dot(self : UVec4, other : UVec4) -> UInt32 {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
/// The component-wise smaller of the two.
pub fn UVec4::min(self : UVec4, other : UVec4) -> UVec4 {
  {
    x: self.x.min(other.x),
    y: self.y.min(other.y),
    z: self.z.min(other.z),
    w: self.w.min(other.w),
  }
}

///|
/// The component-wise larger of the two.
pub fn UVec4::max(self : UVec4, other : UVec4) -> UVec4 {
  {
    x: self.x.max(other.x),
    y: self.y.max(other.y),
    z: self.z.max(other.z),
    w: self.w.max(other.w),
  }
}

///|
/// The quadruple with every component pinned between `low` and `high`.
pub fn UVec4::clamp(self : UVec4, low : UVec4, high : UVec4) -> UVec4 {
  {
    x: self.x.clamp(min=low.x, max=high.x),
    y: self.y.clamp(min=low.y, max=high.y),
    z: self.z.clamp(min=low.z, max=high.z),
    w: self.w.clamp(min=low.w, max=high.w),
  }
}

///|
/// The components in order, `[x, y, z, w]`.
pub fn UVec4::to_array(self : UVec4) -> FixedArray[UInt32] {
  [self.x, self.y, self.z, self.w]
}

///|
/// The same values as a floating-point vector, exactly.
pub fn UVec4::as_vec4(self : UVec4) -> Vec4 {
  {
    x: Float::from_uint(self.x),
    y: Float::from_uint(self.y),
    z: Float::from_uint(self.z),
    w: Float::from_uint(self.w),
  }
}

///|
pub impl Add for UVec4 with fn add(self, other) {
  {
    x: self.x + other.x,
    y: self.y + other.y,
    z: self.z + other.z,
    w: self.w + other.w,
  }
}

///|
pub extend UVec4 with Add::{add}

///|
pub impl Sub for UVec4 with fn sub(self, other) {
  {
    x: self.x - other.x,
    y: self.y - other.y,
    z: self.z - other.z,
    w: self.w - other.w,
  }
}

///|
pub extend UVec4 with Sub::{sub}

///|
pub impl Mul for UVec4 with fn mul(self, other) {
  {
    x: self.x * other.x,
    y: self.y * other.y,
    z: self.z * other.z,
    w: self.w * other.w,
  }
}

///|
pub extend UVec4 with Mul::{mul}

///|
pub impl Div for UVec4 with fn div(self, other) {
  {
    x: self.x / other.x,
    y: self.y / other.y,
    z: self.z / other.z,
    w: self.w / other.w,
  }
}

///|
pub extend UVec4 with Div::{div}

///|
pub impl Show for UVec4 with fn output(self, logger) {
  logger.write_string("UVec4(\{self.x}, \{self.y}, \{self.z}, \{self.w})")
}

///|
pub extend UVec4 with Show::{output, to_string}

///|
pub impl Debug for UVec4 with fn to_repr(self) {
  @debug.Repr::ctor("UVec4", [
    (Some("x"), @debug.Repr::integer(self.x.to_string())),
    (Some("y"), @debug.Repr::integer(self.y.to_string())),
    (Some("z"), @debug.Repr::integer(self.z.to_string())),
    (Some("w"), @debug.Repr::integer(self.w.to_string())),
  ])
}

///|
pub extend UVec4 with Debug::{to_repr}
