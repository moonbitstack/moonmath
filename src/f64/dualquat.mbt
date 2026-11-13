// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A rigid motion — a rotation, and the translation that follows it — written as
/// a pair of quaternions.
///
/// `real` is the rotation, a unit quaternion; `dual` is half the translation,
/// turned by that rotation, so the two halves carry eight numbers between them
/// instead of the twelve a matrix needs. The point of the pair is what happens
/// between two of them: a weighted sum keeps the motion a motion, because the
/// rotation half is normalized afterwards, while the same sum of matrices pulls
/// the rotation towards zero and with it the scale. That is what a skinning loop
/// wants, and what a matrix cannot give it.
///
/// The convention is the library's: right-handed, column-major, the rotation
/// applied first and the translation second.
#derive(Eq)
pub(all) struct DualQuat {
  /// The rotation.
  real : Quat
  /// Half the translation, turned by the rotation: `0.5 * (t, 0) * real`.
  dual : Quat
}

///|
pub extend DualQuat with Eq::{equal, not_equal}

///|
/// The two halves as given, without normalizing either.
///
/// A motion is a unit pair, and a weighted sum of motions is not; `normalize`
/// is what makes one again.
pub fn DualQuat::new(real : Quat, dual : Quat) -> DualQuat {
  { real, dual, }
}

///|
/// The motion that changes nothing.
pub fn DualQuat::identity() -> DualQuat {
  { real: Quat::identity(), dual: Quat::new(0.0, 0.0, 0.0, 0.0), }
}

///|
/// The motion that turns by `rotation` and then moves by `translation`.
///
/// ```mbt check
/// test {
///   let moved : @f64.DualQuat = @f64.DualQuat::from_rotation_translation(
///     @f64.Quat::identity(),
///     @f64.Vec3::new(1.0, 2.0, 3.0),
///   )
///   assert_true(moved.translation().approx(@f64.Vec3::new(1.0, 2.0, 3.0)))
/// }
/// ```
pub fn DualQuat::from_rotation_translation(
  rotation : Quat,
  translation : Vec3,
) -> DualQuat {
  let turn = rotation.normalize()
  let half : Quat = Quat::new(
    translation.x * 0.5,
    translation.y * 0.5,
    translation.z * 0.5,
    0.0,
  )
  { real: turn, dual: half * turn, }
}

///|
/// The motion a matrix describes, or `None` when the matrix scales or shears.
///
/// A rigid motion is the only thing the pair can hold, so a matrix that stretches
/// along an axis, or reflects, has no answer here; the check is the round trip,
/// which is also what catches a matrix whose rotation cannot be read out.
pub fn DualQuat::from_mat4(m : Mat4) -> DualQuat? {
  let candidate = DualQuat::from_rotation_translation(
    Quat::from_mat4(m),
    m.col(3).xyz(),
  )
  if candidate.to_mat4().approx(m) {
    Some(candidate)
  } else {
    None
  }
}

///|
/// The rotation half, normalized.
pub fn DualQuat::rotation(self : DualQuat) -> Quat {
  self.real.normalize()
}

///|
/// The translation half, as the vector it stands for.
pub fn DualQuat::translation(self : DualQuat) -> Vec3 {
  translation_of(self.dual, self.rotation())
}

///|
/// The point moved by the motion: turned first, then moved.
pub fn DualQuat::transform_point(self : DualQuat, point : Vec3) -> Vec3 {
  let turn = self.rotation()
  turn.rotate(point) + translation_of(self.dual, turn)
}

///|
/// The direction turned by the rotation, with the translation left out.
pub fn DualQuat::transform_vector(self : DualQuat, v : Vec3) -> Vec3 {
  self.rotation().rotate(v)
}

///|
/// The motion that undoes this one, or `None` when the rotation is zero.
pub fn DualQuat::inverse(self : DualQuat) -> DualQuat? {
  if self.real.length_squared() == 0.0 {
    None
  } else {
    let conjugate = self.rotation().conjugate()
    Some({ real: conjugate, dual: -(conjugate * self.dual * conjugate), })
  }
}

///|
/// The same motion with both halves divided by the length of the rotation.
///
/// A weighted sum of motions is no longer a rotation and a translation; this is
/// what makes it one again, and it is the step that keeps a skinning blend from
/// shrinking the mesh. A sum whose rotation has cancelled out answers the
/// identity.
pub fn DualQuat::normalize(self : DualQuat) -> DualQuat {
  let length = self.real.length()
  if length == 0.0 {
    DualQuat::identity()
  } else {
    let factor : Double = 1.0 / length
    {
      real: quat_scaled(self.real, factor),
      dual: quat_scaled(self.dual, factor),
    }
  }
}

///|
/// The same motion scaled about the identity, both halves by the same factor.
///
/// This is the multiplication a weighted sum of motions is made of; the sum
/// itself is not a motion until it is normalized.
pub fn DualQuat::scale(self : DualQuat, factor : Double) -> DualQuat {
  {
    real: quat_scaled(self.real, factor),
    dual: quat_scaled(self.dual, factor),
  }
}

///|
/// The dot product of the two rotations.
///
/// A negative one means the two rotations are more than a half turn apart in the
/// four-dimensional sense, and that the second should be negated before the two
/// are summed: `q` and `-q` are the same rotation, and summing without looking
/// takes the long way round.
pub fn DualQuat::dot(self : DualQuat, other : DualQuat) -> Double {
  self.real.dot(other.real)
}

///|
/// The motion a fraction `t` of the way from this one to `other`.
///
/// The rotation takes the shortest arc at constant angular speed, as `Quat::slerp`
/// does; the translation moves at constant speed along the straight line between
/// the two, as `Vec3::lerp` does. A screw motion — turning about the axis the two
/// share — is a different curve, and not the one a keyframe between two poses
/// describes.
pub fn DualQuat::slerp(
  self : DualQuat,
  other : DualQuat,
  t : Double,
) -> DualQuat {
  DualQuat::from_rotation_translation(
    self.rotation().slerp(other.rotation(), t),
    self.translation().lerp(other.translation(), t),
  )
}

///|
/// The matrix this motion is: the rotation, then the translation.
pub fn DualQuat::to_mat4(self : DualQuat) -> Mat4 {
  Mat4::from_translation(self.translation()) * Mat4::from_quat(self.rotation())
}

///|
/// The eight components in order, `[rx, ry, rz, rw, dx, dy, dz, dw]`, for
/// handing to a buffer.
pub fn DualQuat::to_array(self : DualQuat) -> FixedArray[Double] {
  [
    self.real.x,
    self.real.y,
    self.real.z,
    self.real.w,
    self.dual.x,
    self.dual.y,
    self.dual.z,
    self.dual.w,
  ]
}

///|
/// Whether every component of both halves is finite.
pub fn DualQuat::is_finite(self : DualQuat) -> Bool {
  self.real.is_finite() && self.dual.is_finite()
}

///|
/// Whether the two motions agree to within `eps`.
///
/// The halves are compared component by component, after negating the other one
/// when the two rotations lie on opposite sides of the four-dimensional sphere:
/// the sign between them is not a difference, but the dual half has to follow
/// the same negation for the two to describe the same motion.
pub fn DualQuat::approx(
  self : DualQuat,
  other : DualQuat,
  eps? : Double,
) -> Bool {
  let negated = if self.real.dot(other.real) < 0.0 { -other } else { other }
  approx(self.real.x, negated.real.x, eps?) &&
  approx(self.real.y, negated.real.y, eps?) &&
  approx(self.real.z, negated.real.z, eps?) &&
  approx(self.real.w, negated.real.w, eps?) &&
  approx(self.dual.x, negated.dual.x, eps?) &&
  approx(self.dual.y, negated.dual.y, eps?) &&
  approx(self.dual.z, negated.dual.z, eps?) &&
  approx(self.dual.w, negated.dual.w, eps?)
}

///|
fn quat_scaled(q : Quat, factor : Double) -> Quat {
  { x: q.x * factor, y: q.y * factor, z: q.z * factor, w: q.w * factor, }
}

///|
fn quat_sum(a : Quat, b : Quat) -> Quat {
  { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, w: a.w + b.w, }
}

///|
/// The translation a dual half stands for, given the rotation it was turned by:
/// `2 * dual * conjugate(rotation)`, taken as a vector.
fn translation_of(dual : Quat, turn : Quat) -> Vec3 {
  let moved = dual * turn.conjugate()
  { x: moved.x * 2.0, y: moved.y * 2.0, z: moved.z * 2.0, }
}

///|
/// The product: `other` first, then `self` — the order a matrix product reads in,
/// so that `a * b` moves a point the way `a.to_mat4() * b.to_mat4()` does.
pub impl Mul for DualQuat with fn mul(self, other) {
  {
    real: self.real * other.real,
    dual: quat_sum(self.real * other.dual, self.dual * other.real),
  }
}

///|
pub extend DualQuat with Mul::{mul}

///|
/// The sum of the two, half by half: the blend a weighted sum of skins is built
/// from, and not a motion until it is normalized.
pub impl Add for DualQuat with fn add(self, other) {
  {
    real: quat_sum(self.real, other.real),
    dual: quat_sum(self.dual, other.dual),
  }
}

///|
pub extend DualQuat with Add::{add}

///|
pub impl Neg for DualQuat with fn neg(self) {
  { real: -self.real, dual: -self.dual, }
}

///|
pub extend DualQuat with Neg::{neg}

///|
pub impl Show for DualQuat with fn output(self, logger) {
  logger.write_string("DualQuat(\{self.real}, \{self.dual})")
}

///|
pub extend DualQuat with Show::{output, to_string}

///|
pub impl Debug for DualQuat with fn to_repr(self) {
  @debug.Repr::ctor("DualQuat", [
    (Some("real"), self.real.to_repr()),
    (Some("dual"), self.dual.to_repr()),
  ])
}

///|
pub extend DualQuat with Debug::{to_repr}
