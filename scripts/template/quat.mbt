// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The order the three Euler angles are applied in.
///
/// The name says which axis each angle turns about, read left to right: `Xyz`
/// turns about `x`, then about the new `y`, then about the new `z`. That is the
/// intrinsic reading, the one an aircraft's roll, pitch and yaw use, and it is
/// the same as applying the three turns about the fixed axes in the opposite
/// order.
///
/// Six orders turn about three different axes and six about two — the last group
/// repeats the first axis and is what a turntable and a gyroscope do. Between
/// them they cover every way to name a rotation by three angles; the choice is
/// a convention of the file format or the editor that produced the angles, not
/// of the arithmetic.
pub(all) enum EulerOrder {
  Xyz
  Xzy
  Yxz
  Yzx
  Zxy
  Zyx
  Xyx
  Xzx
  Yxy
  Yzy
  Zxz
  Zyz
} derive(Eq, Debug)

///|
pub extend EulerOrder with Eq::{equal, not_equal}

///|
pub extend EulerOrder with Debug::{to_repr}

///|
/// The three axis indices of the order: the first two are distinct, and the
/// third repeats the first for the orders that turn about two axes only.
fn EulerOrder::axes(self : EulerOrder) -> (Int, Int, Int) {
  match self {
    Xyz => (0, 1, 2)
    Xzy => (0, 2, 1)
    Yxz => (1, 0, 2)
    Yzx => (1, 2, 0)
    Zxy => (2, 0, 1)
    Zyx => (2, 1, 0)
    Xyx => (0, 1, 0)
    Xzx => (0, 2, 0)
    Yxy => (1, 0, 1)
    Yzy => (1, 2, 1)
    Zxz => (2, 0, 2)
    Zyz => (2, 1, 2)
  }
}

///|
/// Whether the first and third turn share an axis.
fn EulerOrder::is_proper(self : EulerOrder) -> Bool {
  let (i, _, k) = self.axes()
  i == k
}

///|
/// `+1` when the three axes run cyclically (`x` to `y` to `z`), `-1` when they
/// run the other way.
///
/// A turn about the middle axis looks like the opposite turn when the axes are
/// relabelled through a mirror, so the sign is part of reading angles back out
/// of a matrix.
fn cycle_parity(first : Int, second : Int, third : Int) -> {{S}} {
  if (first + 1) % 3 == second && (second + 1) % 3 == third {
    1.0
  } else {
    -1.0
  }
}

///|
/// A rotation, as a unit quaternion.
///
/// `(x, y, z)` is the axis of the rotation scaled by the sine of half its angle,
/// and `w` the cosine of half the angle. Half angles, because a rotation acts on
/// a vector from both sides: `q v q⁻¹`.
///
/// A quaternion is four numbers where a matrix is nine, composes in fewer
/// operations, and interpolates smoothly — which is why animation and physics
/// carry rotations this way and convert to a matrix only when handing one to a
/// shader.
///
/// The rotations are the unit quaternions; the ones here do not enforce that on
/// construction, because building one by summing or lerping intermediate values
/// is legitimate and only the end result has to be normal. Anything that
/// composes an arbitrary number of them — `rotate`, `to_mat3`, `slerp` — says
/// when it assumes unit length.
pub(all) struct Quat {
  x : {{S}}
  y : {{S}}
  z : {{S}}
  w : {{S}}
} derive(Eq)

///|
pub extend Quat with Eq::{equal, not_equal}

///|
/// The quaternion from its four components, in the order `(x, y, z, w)`.
pub fn Quat::new(x : {{S}}, y : {{S}}, z : {{S}}, w : {{S}}) -> Quat {
  { x, y, z, w }
}

///|
/// The rotation that changes nothing.
pub fn Quat::identity() -> Quat {
  { x: 0.0, y: 0.0, z: 0.0, w: 1.0 }
}

///|
/// The rotation of `radians` about `axis`, by the right-hand rule.
///
/// `axis` is normalized first; a zero axis has no direction to turn about and
/// gives the identity.
///
/// ```mbt check
/// test {
///   let quarter = @{{PKG}}.Quat::from_axis_angle(
///     @{{PKG}}.Vec3::unit_z(), @{{PKG}}.half_pi,
///   )
///   assert_true(
///     quarter.rotate(@{{PKG}}.Vec3::unit_x()).approx(@{{PKG}}.Vec3::unit_y()),
///   )
/// }
/// ```
pub fn Quat::from_axis_angle(axis : Vec3, radians : {{S}}) -> Quat {
  match axis.try_normalize() {
    None => Quat::identity()
    Some(axis) => {
      let half : {{S}} = 0.5
      let half_angle = radians * half
      let s = @math.{{SIN}}(half_angle)
      { x: axis.x * s, y: axis.y * s, z: axis.z * s, w: @math.{{COS}}(half_angle) }
    }
  }
}

///|
/// The rotation the three angles describe, taken in `order`, in radians.
///
/// The components of `angles` are the three turns in the order the order names
/// them, not the turns about the three axes: for `Xyz` they are the turns about
/// `x`, `y` and `z` in that order, which is the same thing, but for `Xzy` the
/// second component is the turn about `z` and the third the turn about `y`, and
/// for `Yxy` the second is about `y` and the third about `x` again. Reading them
/// by axis is impossible as soon as an order turns about the same axis twice.
///
/// ```mbt check
/// test {
///   let turn = @{{PKG}}.Quat::from_euler(
///     @{{PKG}}.EulerOrder::Zyx, @{{PKG}}.Vec3::new(@{{PKG}}.half_pi, 0.0, 0.0),
///   )
///   // Zyx turns about z first, so the first angle is the one about z.
///   assert_true(turn.rotate(@{{PKG}}.Vec3::unit_y()).approx(-@{{PKG}}.Vec3::unit_x()))
/// }
/// ```
pub fn Quat::from_euler(order : EulerOrder, angles : Vec3) -> Quat {
  let (i, j, k) = order.axes()
  let turns = angles.to_array()
  let first = Quat::from_axis_angle(axis_of(i), turns[0])
  let second = Quat::from_axis_angle(axis_of(j), turns[1])
  let third = Quat::from_axis_angle(axis_of(k), turns[2])
  first * second * third
}

///|
/// The three angles that produce this rotation in `order`, in radians.
///
/// The inverse of `from_euler`, and read the same way: the components are the
/// three turns in the order the order names them. Feeding the result back gives
/// the rotation again, except at the two angles where the first and third turns
/// collapse into one — the gimbal lock every three-angle convention has. There
/// the first turn comes back as zero and the whole of it is carried by the
/// third.
pub fn Quat::to_euler(self : Quat, order : EulerOrder) -> Vec3 {
  let m = self.to_mat3()
  let (i, j, k) = order.axes()
  let one : {{S}} = 1.0
  let zero : {{S}} = 0.0
  let angles = FixedArray::make(3, zero)
  if order.is_proper() {
    // `other` is the axis the order does not name, and the one the middle turn
    // does not use.
    let other = 3 - i - j
    let parity = cycle_parity(i, j, other)
    let cosine = m.get(i, i).clamp(min=-one, max=one)
    let beta = @math.{{ACOS}}(cosine)
    if cosine.abs() > one - default_epsilon {
      // The middle turn is at zero or at half a turn: the first and the third
      // turn about the same axis, and only their sum — or their difference —
      // is readable. Their sum when the middle turn is nothing, their
      // difference when it is a half turn.
      let direction : {{S}} = if cosine > zero { -parity } else { parity }
      angles[0] = @math.{{ATAN2}}(direction * m.get(j, other), m.get(j, j))
      angles[1] = beta
      angles[2] = zero
    } else {
      angles[0] = @math.{{ATAN2}}(m.get(j, i), -parity * m.get(other, i))
      angles[1] = beta
      angles[2] = @math.{{ATAN2}}(m.get(i, j), parity * m.get(i, other))
    }
  } else {
    let parity = cycle_parity(i, j, k)
    let sine = (parity * m.get(i, k)).clamp(min=-one, max=one)
    let beta = @math.{{ASIN}}(sine)
    if m.get(i, k).abs() > one - default_epsilon {
      // The second turn is at a quarter turn: the first and the third rotate in
      // the same plane, and the sign of the sine says which way round.
      let direction : {{S}} = if sine < zero { -one } else { one }
      angles[0] = @math.{{ATAN2}}(direction * m.get(j, i), m.get(j, j))
      angles[1] = beta
      angles[2] = zero
    } else {
      angles[0] = @math.{{ATAN2}}(-parity * m.get(j, k), m.get(k, k))
      angles[1] = beta
      angles[2] = @math.{{ATAN2}}(-parity * m.get(i, j), m.get(i, i))
    }
  }
  { x: angles[0], y: angles[1], z: angles[2] }
}

///|
/// The axis unit vector of an axis index.
fn axis_of(index : Int) -> Vec3 {
  if index == 0 {
    Vec3::unit_x()
  } else if index == 1 {
    Vec3::unit_y()
  } else {
    Vec3::unit_z()
  }
}

///|
/// The shortest rotation that turns `from` towards `to`, for two directions.
///
/// The pair need not be normalized and need not be perpendicular to anything:
/// the rotation takes the direction of `from` to the direction of `to` and leaves
/// the plane they span alone. Opposed directions have no single shortest
/// rotation — every half turn about a perpendicular axis works — and one is
/// picked. A zero vector has no direction to turn and gives the identity.
///
/// ```mbt check
/// test {
///   let turn = @{{PKG}}.Quat::from_rotation_arc(
///     @{{PKG}}.Vec3::unit_x(), @{{PKG}}.Vec3::unit_y(),
///   )
///   assert_true(turn.rotate(@{{PKG}}.Vec3::unit_x()).approx(@{{PKG}}.Vec3::unit_y()))
/// }
/// ```
pub fn Quat::from_rotation_arc(from : Vec3, to : Vec3) -> Quat {
  let from = from.normalize()
  let to = to.normalize()
  let dot = from.dot(to)
  let one : {{S}} = 1.0
  if dot >= one - default_epsilon {
    Quat::identity()
  } else if dot <= -(one - default_epsilon) {
    // Opposed: any axis perpendicular to `from` turns one into the other.
    let axis = from.cross(Vec3::unit_x())
    let axis = if axis.length_squared() < default_epsilon {
      from.cross(Vec3::unit_y())
    } else {
      axis
    }
    Quat::from_axis_angle(axis, pi)
  } else {
    let axis = from.cross(to)
    Quat::new(axis.x, axis.y, axis.z, one + dot).normalize()
  }
}

///|
/// The rotation the matrix holds, for a matrix that is a rotation.
///
/// A matrix with a scale in it gives the rotation underneath only when the scale
/// is uniform; one that is not a rotation at all gives the nearest unit
/// quaternion to its columns, which is still a usable answer for a matrix that
/// drifted.
pub fn Quat::from_mat3(m : Mat3) -> Quat {
  let one : {{S}} = 1.0
  let two : {{S}} = 2.0
  let quarter : {{S}} = 0.25
  let trace = m.c0.x + m.c1.y + m.c2.z
  let q : Quat = if trace > 0.0 {
    let four = (trace + one).sqrt() * two
    {
      x: (m.c1.z - m.c2.y) / four,
      y: (m.c2.x - m.c0.z) / four,
      z: (m.c0.y - m.c1.x) / four,
      w: quarter * four,
    }
  } else if m.c0.x > m.c1.y && m.c0.x > m.c2.z {
    let four = (one + m.c0.x - m.c1.y - m.c2.z).sqrt() * two
    {
      x: quarter * four,
      y: (m.c1.x + m.c0.y) / four,
      z: (m.c2.x + m.c0.z) / four,
      w: (m.c1.z - m.c2.y) / four,
    }
  } else if m.c1.y > m.c2.z {
    let four = (one + m.c1.y - m.c0.x - m.c2.z).sqrt() * two
    {
      x: (m.c1.x + m.c0.y) / four,
      y: quarter * four,
      z: (m.c2.y + m.c1.z) / four,
      w: (m.c2.x - m.c0.z) / four,
    }
  } else {
    let four = (one + m.c2.z - m.c0.x - m.c1.y).sqrt() * two
    {
      x: (m.c2.x + m.c0.z) / four,
      y: (m.c2.y + m.c1.z) / four,
      z: quarter * four,
      w: (m.c0.y - m.c1.x) / four,
    }
  }
  q.normalize()
}

///|
/// The rotation the 4×4 matrix holds, read from its upper-left block.
pub fn Quat::from_mat4(m : Mat4) -> Quat {
  Quat::from_mat3(Mat3::from_mat4(m))
}

///|
/// The rotation as a 3×3 matrix.
///
/// Assumes unit length; a quaternion that drifted scales the matrix by the
/// square of its norm.
pub fn Quat::to_mat3(self : Quat) -> Mat3 {
  let x2 = self.x + self.x
  let y2 = self.y + self.y
  let z2 = self.z + self.z
  let xx = self.x * x2
  let xy = self.x * y2
  let xz = self.x * z2
  let yy = self.y * y2
  let yz = self.y * z2
  let zz = self.z * z2
  let wx = self.w * x2
  let wy = self.w * y2
  let wz = self.w * z2
  {
    c0: { x: 1.0 - (yy + zz), y: xy + wz, z: xz - wy },
    c1: { x: xy - wz, y: 1.0 - (xx + zz), z: yz + wx },
    c2: { x: xz + wy, y: yz - wx, z: 1.0 - (xx + yy) },
  }
}

///|
/// The rotation as a 4×4 matrix whose translation is zero.
pub fn Quat::to_mat4(self : Quat) -> Mat4 {
  Mat4::from_mat3(self.to_mat3())
}

///|
/// The rotation run backwards: the quaternion that undoes this one.
///
/// For a unit quaternion this is the conjugate; for any other it is the
/// conjugate divided by the squared length, so that `q * q.inverse()` is the
/// identity. `None` for the zero quaternion, which represents no rotation and
/// has no inverse.
pub fn Quat::inverse(self : Quat) -> Quat? {
  let length_squared = self.length_squared()
  if length_squared == 0.0 {
    None
  } else {
    let scale : {{S}} = 1.0 / length_squared
    Some({
      x: -self.x * scale,
      y: -self.y * scale,
      z: -self.z * scale,
      w: self.w * scale,
    })
  }
}

///|
/// The conjugate: the quaternion with its axis part negated.
///
/// The inverse rotation for a unit quaternion, and cheaper than `inverse`
/// because it divides by nothing.
pub fn Quat::conjugate(self : Quat) -> Quat {
  { x: -self.x, y: -self.y, z: -self.z, w: self.w }
}

///|
/// The dot product of the two, as four-component vectors.
///
/// Its sign says whether the two rotations take the short way round: negative
/// means the interpolations in this module would travel the long way, and
/// interpolating with the negated quaternion instead gives the short one.
pub fn Quat::dot(self : Quat, other : Quat) -> {{S}} {
  self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
}

///|
/// The length of the quaternion as a four-component vector: one for a rotation.
pub fn Quat::length(self : Quat) -> {{S}} {
  self.length_squared().sqrt()
}

///|
/// The square of the length.
pub fn Quat::length_squared(self : Quat) -> {{S}} {
  self.dot(self)
}

///|
/// The quaternion scaled to length one, or the identity if it is zero.
///
/// A rotation is always a unit quaternion; one built by summing or lerping
/// others has to be brought back before it can rotate anything, and the zero
/// quaternion — which summing can produce — falls back to the identity rather
/// than to a division by zero.
pub fn Quat::normalize(self : Quat) -> Quat {
  let length = self.length()
  if length == 0.0 {
    Quat::identity()
  } else {
    let scale : {{S}} = 1.0 / length
    {
      x: self.x * scale,
      y: self.y * scale,
      z: self.z * scale,
      w: self.w * scale,
    }
  }
}

///|
/// The vector turned by the rotation.
///
/// Assumes unit length. Two cross products rather than `q v q⁻¹`, which is the
/// same result with fewer multiplications.
pub fn Quat::rotate(self : Quat, v : Vec3) -> Vec3 {
  // `v + 2w(q×v) + 2q×(q×v)`, written out: a `Vec3` is a heap value in the
  // native backend, and the four intermediate vectors a chained version would
  // build cost more than the twelve multiplications.
  let twice : {{S}} = 2.0
  let tx = twice * (self.y * v.z - self.z * v.y)
  let ty = twice * (self.z * v.x - self.x * v.z)
  let tz = twice * (self.x * v.y - self.y * v.x)
  {
    x: v.x + self.w * tx + (self.y * tz - self.z * ty),
    y: v.y + self.w * ty + (self.z * tx - self.x * tz),
    z: v.z + self.w * tz + (self.x * ty - self.y * tx),
  }
}

///|
/// The angle and axis of the rotation, as `(axis, radians)` with the axis a unit
/// vector and the angle in `0..pi`.
///
/// A rotation of zero has no axis to name; it comes back as `(x, 0)` — the first
/// axis, with a zero angle, which rotates nothing either way.
pub fn Quat::to_axis_angle(self : Quat) -> (Vec3, {{S}}) {
  let unit = self.normalize()
  let two : {{S}} = 2.0
  let angle = @math.{{ACOS}}(unit.w.clamp(min=-1.0, max=1.0)) * two
  let axis : Vec3 = { x: unit.x, y: unit.y, z: unit.z }
  let axis = match axis.try_normalize() {
    Some(axis) => axis
    None => Vec3::unit_x()
  }
  (axis, angle)
}

///|
/// The rotation a fraction of the way from `self` to `other`, at constant
/// angular speed.
///
/// Spherical interpolation: the intermediate rotations turn at a steady rate,
/// which is what an animation between two orientations wants. The two are
/// compared first, and the negated one is used when they point away from each
/// other — `q` and `-q` are the same rotation, and the negation is the one that
/// takes the short way.
pub fn Quat::slerp(self : Quat, other : Quat, t : {{S}}) -> Quat {
  let mut to = other
  let mut cosine = self.dot(other)
  if cosine < 0.0 {
    to = { x: -other.x, y: -other.y, z: -other.z, w: -other.w }
    cosine = -cosine
  }
  if cosine > 1.0 - default_epsilon {
    // The two are the same rotation: the arc between them has no length, and
    // the straight line between them is the arc.
    self.nlerp(to, t)
  } else {
    let angle = @math.{{ACOS}}(cosine)
    let sine = @math.{{SIN}}(angle)
    let one : {{S}} = 1.0
    let a = @math.{{SIN}}((one - t) * angle) / sine
    let b = @math.{{SIN}}(t * angle) / sine
    {
      x: self.x * a + to.x * b,
      y: self.y * a + to.y * b,
      z: self.z * a + to.z * b,
      w: self.w * a + to.w * b,
    }
  }
}

///|
/// The rotation a fraction of the way from `self` to `other` along the straight
/// line, normalized back onto the sphere.
///
/// Cheaper than `slerp` and close to it for small angles; the rate is not quite
/// constant, which a long animation would show.
pub fn Quat::nlerp(self : Quat, other : Quat, t : {{S}}) -> Quat {
  let one : {{S}} = 1.0
  let a = one - t
  let mixed : Quat = {
    x: self.x * a + other.x * t,
    y: self.y * a + other.y * t,
    z: self.z * a + other.z * t,
    w: self.w * a + other.w * t,
  }
  mixed.normalize()
}

///|
/// The four components in order, `[x, y, z, w]`, for handing to a buffer.
pub fn Quat::to_array(self : Quat) -> FixedArray[{{S}}] {
  [self.x, self.y, self.z, self.w]
}

///|
/// Whether the two rotations are the same to within `eps`.
///
/// `q` and `-q` are the same rotation, so the sign between them is not a
/// difference; the comparison uses the absolute dot product.
pub fn Quat::approx(self : Quat, other : Quat, eps? : {{S}}) -> Bool {
  let dot = self.normalize().dot(other.normalize()).abs()
  let one : {{S}} = 1.0
  let limit : {{S}} = match eps {
    Some(eps) => eps
    None => default_epsilon
  }
  one - dot <= limit
}

///|
/// Whether every component is finite.
pub fn Quat::is_finite(self : Quat) -> Bool {
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
/// The product: the rotation `other` followed by the rotation `self`.
///
/// The order reads backwards from matrices and forwards from function
/// composition, and the two conventions differ between libraries; here
/// `q1 * q2` applies `q2` first, as `m1 * m2` applies `m2` first.
pub impl Mul for Quat with mul(self, other) {
  let ax = self.y * other.z - self.z * other.y
  let ay = self.z * other.x - self.x * other.z
  let az = self.x * other.y - self.y * other.x
  let dot = self.x * other.x + self.y * other.y + self.z * other.z
  {
    x: self.w * other.x + other.w * self.x + ax,
    y: self.w * other.y + other.w * self.y + ay,
    z: self.w * other.z + other.w * self.z + az,
    w: self.w * other.w - dot,
  }
}

///|
pub extend Quat with Mul::{mul}

///|
/// The product with the inverse of the right-hand side; aborts when that side is
/// the zero quaternion.
pub impl Div for Quat with div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Quat division by the zero quaternion")
  }
}

///|
pub extend Quat with Div::{div}

///|
/// The conjugate, which is the inverse for a unit quaternion.
pub impl Neg for Quat with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z, w: -self.w }
}

///|
pub extend Quat with Neg::{neg}

///|
pub impl Show for Quat with output(self, logger) {
  logger.write_string(
    "Quat(\{self.x}, \{self.y}, \{self.z}, \{self.w})",
  )
}

///|
pub extend Quat with Show::{output, to_string}

///|
pub impl Debug for Quat with to_repr(self) {
  @debug.Repr::ctor("Quat", [
    (Some("x"), @debug.Repr::{{DBG}}(self.x)),
    (Some("y"), @debug.Repr::{{DBG}}(self.y)),
    (Some("z"), @debug.Repr::{{DBG}}(self.z)),
    (Some("w"), @debug.Repr::{{DBG}}(self.w)),
  ])
}

///|
pub extend Quat with Debug::{to_repr}
