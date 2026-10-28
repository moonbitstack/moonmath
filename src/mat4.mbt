// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A 4×4 matrix: everything a 3×3 matrix does, plus the translation a
/// transformation of space needs.
///
/// Column-major, so `c3` is the translation column and `to_array` is exactly the
/// sixteen floats a `mat4x4<f32>` occupies in a storage or uniform buffer. A
/// point is a `Vec4` with `w = 1`, a direction one with `w = 0`, and the fourth
/// row of a projection matrix puts the perspective divide into `w`.
///
/// Values are immutable.
pub(all) struct Mat4 {
  c0 : Vec4
  c1 : Vec4
  c2 : Vec4
  c3 : Vec4
} derive(Eq)

///|
pub extend Mat4 with Eq::{equal, not_equal}

///|
/// A translation, a rotation and a scale, in that order of composition: a point
/// is scaled, then turned, then moved.
///
/// This is what `Mat4::to_trs` recovers from a matrix that was built the same
/// way, and what a scene graph stores per node — the three pieces are what an
/// animation edits, and a decomposition keeps them editable.
pub(all) struct Trs {
  translation : Vec3
  rotation : Quat
  scale : Vec3
} derive(Eq)

///|
pub extend Trs with Eq::{equal, not_equal}

///|
/// The three parts of a transformation.
pub fn Trs::new(translation : Vec3, rotation : Quat, scale : Vec3) -> Trs {
  { translation, rotation, scale, }
}

///|
pub impl Show for Trs with fn output(self, logger) {
  logger.write_string(
    "Trs(\{self.translation}, \{self.rotation}, \{self.scale})",
  )
}

///|
pub extend Trs with Show::{output, to_string}

///|
pub impl Debug for Trs with fn to_repr(self) {
  @debug.Repr::ctor("Trs", [
    (Some("translation"), self.translation.to_repr()),
    (Some("rotation"), self.rotation.to_repr()),
    (Some("scale"), self.scale.to_repr()),
  ])
}

///|
pub extend Trs with Debug::{to_repr}

///|
/// The matrix with the four vecs as its columns.
pub fn Mat4::from_cols(c0 : Vec4, c1 : Vec4, c2 : Vec4, c3 : Vec4) -> Mat4 {
  { c0, c1, c2, c3, }
}

///|
/// The matrix with the four vecs as its rows.
pub fn Mat4::from_rows(r0 : Vec4, r1 : Vec4, r2 : Vec4, r3 : Vec4) -> Mat4 {
  {
    c0: { x: r0.x, y: r1.x, z: r2.x, w: r3.x, },
    c1: { x: r0.y, y: r1.y, z: r2.y, w: r3.y, },
    c2: { x: r0.z, y: r1.z, z: r2.z, w: r3.z, },
    c3: { x: r0.w, y: r1.w, z: r2.w, w: r3.w, },
  }
}

///|
/// The matrix from sixteen values in column-major order — the order a
/// `mat4x4<f32>` sits in a buffer in.
///
/// Aborts if the array does not hold sixteen values.
pub fn Mat4::from_array(values : FixedArray[Float]) -> Mat4 {
  guard values.length() == 16 else {
    abort("Mat4::from_array wants 16 values, got \{values.length()}")
  }
  {
    c0: { x: values[0], y: values[1], z: values[2], w: values[3], },
    c1: { x: values[4], y: values[5], z: values[6], w: values[7], },
    c2: { x: values[8], y: values[9], z: values[10], w: values[11], },
    c3: { x: values[12], y: values[13], z: values[14], w: values[15], },
  }
}

///|
/// The identity: the matrix that changes nothing.
pub fn Mat4::identity() -> Mat4 {
  {
    c0: { x: 1.0, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: 1.0, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: 1.0, w: 0.0, },
    c3: { x: 0.0, y: 0.0, z: 0.0, w: 1.0, },
  }
}

///|
/// The zero matrix: the one that sends everything to the origin and loses `w`.
pub fn Mat4::zero() -> Mat4 {
  { c0: Vec4::zero(), c1: Vec4::zero(), c2: Vec4::zero(), c3: Vec4::zero(), }
}

///|
/// The matrix that scales each axis by the matching component of `s`.
pub fn Mat4::from_scale(s : Vec3) -> Mat4 {
  {
    c0: { x: s.x, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: s.y, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: s.z, w: 0.0, },
    c3: { x: 0.0, y: 0.0, z: 0.0, w: 1.0, },
  }
}

///|
/// The matrix that moves every point by `t`.
pub fn Mat4::from_translation(t : Vec3) -> Mat4 {
  {
    c0: { x: 1.0, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: 1.0, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: 1.0, w: 0.0, },
    c3: { x: t.x, y: t.y, z: t.z, w: 1.0, },
  }
}

///|
/// The rotation of `radians` about `axis`, by the right-hand rule.
pub fn Mat4::from_axis_angle(axis : Vec3, radians : Float) -> Mat4 {
  Mat4::from_mat3(Mat3::from_axis_angle(axis, radians))
}

///|
/// The rotation the quaternion holds.
pub fn Mat4::from_quat(q : Quat) -> Mat4 {
  q.to_mat4()
}

///|
/// The rotation the three angles describe, taken in `order`, in radians. See
/// `Quat::from_euler` for how the components are read.
pub fn Mat4::from_euler(order : EulerOrder, angles : Vec3) -> Mat4 {
  Quat::from_euler(order, angles).to_mat4()
}

///|
/// The matrix that does what the 3×3 matrix does to `x`, `y` and `z`, and
/// leaves `w` alone.
pub fn Mat4::from_mat3(m : Mat3) -> Mat4 {
  {
    c0: m.c0.to_vec4(0.0),
    c1: m.c1.to_vec4(0.0),
    c2: m.c2.to_vec4(0.0),
    c3: { x: 0.0, y: 0.0, z: 0.0, w: 1.0, },
  }
}

///|
/// The matrix that scales by `scale`, then rotates by `rotation`, then moves by
/// `translation`.
///
/// ```mbt check
/// test {
///   let scale : @moonmath.Vec3 = @moonmath.Vec3::splat(2.0)
///   let offset = @moonmath.Vec3::new(1.0, 0.0, 0.0)
///   let m = @moonmath.Mat4::from_trs(
///     @moonmath.Trs::new(offset, @moonmath.Quat::identity(), scale),
///   )
///   // One, scaled by two, then moved one along x.
///   assert_true(
///     m
///     .transform_point(@moonmath.Vec3::one())
///     .approx(@moonmath.Vec3::new(3.0, 2.0, 2.0)),
///   )
/// }
/// ```
pub fn Mat4::from_trs(trs : Trs) -> Mat4 {
  let rotation = trs.rotation.to_mat3()
  let scaled = Mat3::from_cols(
    rotation.c0.scale(trs.scale.x),
    rotation.c1.scale(trs.scale.y),
    rotation.c2.scale(trs.scale.z),
  )
  let m = Mat4::from_mat3(scaled)
  { c0: m.c0, c1: m.c1, c2: m.c2, c3: trs.translation.to_vec4(1.0), }
}

///|
/// The translation, rotation and scale the matrix was built from, or `None` when
/// it cannot be read that way.
///
/// A matrix with shear in it — the common case being a non-uniform scale applied
/// after a rotation — is not a `Trs` and has no decomposition here; neither has
/// one whose linear part is singular, whose rotation would be unrecoverable.
/// When the determinant is negative the first component of `scale` carries the
/// sign, because a mirrored basis is a rotation with one flipped axis.
pub fn Mat4::to_trs(self : Mat4) -> Trs? {
  let mut sx = self.c0.xyz().length()
  let sy = self.c1.xyz().length()
  let sz = self.c2.xyz().length()
  if sx == 0.0 || sy == 0.0 || sz == 0.0 {
    return None
  }
  let orientation = self.c0.xyz().dot(self.c1.xyz().cross(self.c2.xyz()))
  if orientation < 0.0 {
    sx = -sx
  }
  let rotation = Mat3::from_cols(
    self.c0.xyz().divide(sx),
    self.c1.xyz().divide(sy),
    self.c2.xyz().divide(sz),
  )
  let quat = Quat::from_mat3(rotation)
  Some(Trs::new(self.c3.xyz(), quat, { x: sx, y: sy, z: sz, }))
}

///|
/// Column `index`, counted from zero.
pub fn Mat4::col(self : Mat4, index : Int32) -> Vec4 {
  if index == 0 {
    self.c0
  } else if index == 1 {
    self.c1
  } else if index == 2 {
    self.c2
  } else {
    self.c3
  }
}

///|
/// Row `index`, counted from zero.
pub fn Mat4::row(self : Mat4, index : Int32) -> Vec4 {
  if index == 0 {
    { x: self.c0.x, y: self.c1.x, z: self.c2.x, w: self.c3.x, }
  } else if index == 1 {
    { x: self.c0.y, y: self.c1.y, z: self.c2.y, w: self.c3.y, }
  } else if index == 2 {
    { x: self.c0.z, y: self.c1.z, z: self.c2.z, w: self.c3.z, }
  } else {
    { x: self.c0.w, y: self.c1.w, z: self.c2.w, w: self.c3.w, }
  }
}

///|
/// The element at `row` and `column`, both counted from zero.
pub fn Mat4::get(self : Mat4, row_index : Int32, column_index : Int32) -> Float {
  let column = self.col(column_index)
  if row_index == 0 {
    column.x
  } else if row_index == 1 {
    column.y
  } else if row_index == 2 {
    column.z
  } else {
    column.w
  }
}

///|
/// The matrix with rows and columns exchanged.
pub fn Mat4::transpose(self : Mat4) -> Mat4 {
  { c0: self.row(0), c1: self.row(1), c2: self.row(2), c3: self.row(3), }
}

///|
/// The signed hypervolume the matrix scales by: zero exactly when it is
/// singular.
pub fn Mat4::determinant(self : Mat4) -> Float {
  let c0 = self.c0
  let c1 = self.c1
  let c2 = self.c2
  let c3 = self.c3
  let s0 = c0.x * c1.y - c1.x * c0.y
  let s1 = c0.x * c1.z - c1.x * c0.z
  let s2 = c0.x * c1.w - c1.x * c0.w
  let s3 = c0.y * c1.z - c1.y * c0.z
  let s4 = c0.y * c1.w - c1.y * c0.w
  let s5 = c0.z * c1.w - c1.z * c0.w
  let d5 = c2.z * c3.w - c3.z * c2.w
  let d4 = c2.y * c3.w - c3.y * c2.w
  let d3 = c2.y * c3.z - c3.y * c2.z
  let d2 = c2.x * c3.w - c3.x * c2.w
  let d1 = c2.x * c3.z - c3.x * c2.z
  let d0 = c2.x * c3.y - c3.x * c2.y
  s0 * d5 - s1 * d4 + s2 * d3 + s3 * d2 - s4 * d1 + s5 * d0
}

///|
/// The matrix that undoes this one, or `None` when there is none.
///
/// The usual use is the inverse of a camera's view-projection matrix, and the
/// usual singular case is a projection built with `far` equal to `near`.
pub fn Mat4::inverse(self : Mat4) -> Mat4? {
  let a = self.to_array()
  let a00 = a[0]
  let a01 = a[1]
  let a02 = a[2]
  let a03 = a[3]
  let a10 = a[4]
  let a11 = a[5]
  let a12 = a[6]
  let a13 = a[7]
  let a20 = a[8]
  let a21 = a[9]
  let a22 = a[10]
  let a23 = a[11]
  let a30 = a[12]
  let a31 = a[13]
  let a32 = a[14]
  let a33 = a[15]
  let b00 = a00 * a11 - a01 * a10
  let b01 = a00 * a12 - a02 * a10
  let b02 = a00 * a13 - a03 * a10
  let b03 = a01 * a12 - a02 * a11
  let b04 = a01 * a13 - a03 * a11
  let b05 = a02 * a13 - a03 * a12
  let b06 = a20 * a31 - a21 * a30
  let b07 = a20 * a32 - a22 * a30
  let b08 = a20 * a33 - a23 * a30
  let b09 = a21 * a32 - a22 * a31
  let b10 = a21 * a33 - a23 * a31
  let b11 = a22 * a33 - a23 * a32
  let first = b00 * b11 - b01 * b10 + b02 * b09
  let second = b03 * b08 - b04 * b07 + b05 * b06
  let det = first + second
  if det == 0.0 {
    return None
  }
  let inv_det : Float = 1.0 / det
  Some({
    c0: {
      x: (a11 * b11 - a12 * b10 + a13 * b09) * inv_det,
      y: (a02 * b10 - a01 * b11 - a03 * b09) * inv_det,
      z: (a31 * b05 - a32 * b04 + a33 * b03) * inv_det,
      w: (a22 * b04 - a21 * b05 - a23 * b03) * inv_det,
    },
    c1: {
      x: (a12 * b08 - a10 * b11 - a13 * b07) * inv_det,
      y: (a00 * b11 - a02 * b08 + a03 * b07) * inv_det,
      z: (a32 * b02 - a30 * b05 - a33 * b01) * inv_det,
      w: (a20 * b05 - a22 * b02 + a23 * b01) * inv_det,
    },
    c2: {
      x: (a10 * b10 - a11 * b08 + a13 * b06) * inv_det,
      y: (a01 * b08 - a00 * b10 - a03 * b06) * inv_det,
      z: (a30 * b04 - a31 * b02 + a33 * b00) * inv_det,
      w: (a21 * b02 - a20 * b04 - a23 * b00) * inv_det,
    },
    c3: {
      x: (a11 * b07 - a10 * b09 - a12 * b06) * inv_det,
      y: (a00 * b09 - a01 * b07 + a02 * b06) * inv_det,
      z: (a31 * b01 - a30 * b03 - a32 * b00) * inv_det,
      w: (a20 * b03 - a21 * b01 + a22 * b00) * inv_det,
    },
  })
}

///|
/// The vector the matrix takes `v` to, without any division by `w`.
///
/// This is what a shader's `matrix * vector` does: the projection divide happens
/// after clipping, not here. One expression per component, for the reason given
/// at `Mat2::mul_vec2`.
pub fn Mat4::mul_vec4(self : Mat4, v : Vec4) -> Vec4 {
  {
    x: self.c0.x * v.x + self.c1.x * v.y + self.c2.x * v.z + self.c3.x * v.w,
    y: self.c0.y * v.x + self.c1.y * v.y + self.c2.y * v.z + self.c3.y * v.w,
    z: self.c0.z * v.x + self.c1.z * v.y + self.c2.z * v.z + self.c3.z * v.w,
    w: self.c0.w * v.x + self.c1.w * v.y + self.c2.w * v.z + self.c3.w * v.w,
  }
}

///|
/// The point the matrix takes `p` to, dividing by `w` when there is one.
///
/// A projection matrix leaves the result in homogeneous coordinates; the point
/// only exists after that division, so it happens here. A `w` of zero — a point
/// on the horizon of a perspective projection — leaves the numerator as it is.
pub fn Mat4::transform_point(self : Mat4, p : Vec3) -> Vec3 {
  let w = self.c0.w * p.x + self.c1.w * p.y + self.c2.w * p.z + self.c3.w
  let x = self.c0.x * p.x + self.c1.x * p.y + self.c2.x * p.z + self.c3.x
  let y = self.c0.y * p.x + self.c1.y * p.y + self.c2.y * p.z + self.c3.y
  let z = self.c0.z * p.x + self.c1.z * p.y + self.c2.z * p.z + self.c3.z
  if w == 0.0 || w == 1.0 {
    { x, y, z, }
  } else {
    { x: x / w, y: y / w, z: z / w, }
  }
}

///|
/// The direction the matrix takes `v` to, ignoring the translation column.
///
/// Directions have no position, so the fourth row must not touch them: a
/// translation leaves a direction alone, as it should.
pub fn Mat4::transform_vector(self : Mat4, v : Vec3) -> Vec3 {
  {
    x: self.c0.x * v.x + self.c1.x * v.y + self.c2.x * v.z,
    y: self.c0.y * v.x + self.c1.y * v.y + self.c2.y * v.z,
    z: self.c0.z * v.x + self.c1.z * v.y + self.c2.z * v.z,
  }
}

///|
/// The view matrix of a camera at `eye` looking at `target`, with `up` telling
/// it which way is up.
///
/// Right-handed: the camera looks down its own -z, so the third column of the
/// result is `eye - target`, normalized. `up` need not be perpendicular to the
/// view direction, only not parallel to it; when it is parallel there is no
/// answer and the identity comes back rather than a matrix full of NaNs.
pub fn Mat4::look_at(eye : Vec3, target : Vec3, up : Vec3) -> Mat4 {
  let forward = match (target - eye).try_normalize() {
    Some(forward) => forward
    None => return Mat4::identity()
  }
  let side = match forward.cross(up).try_normalize() {
    Some(side) => side
    None => return Mat4::identity()
  }
  let upward = side.cross(forward)
  {
    c0: { x: side.x, y: upward.x, z: -forward.x, w: 0.0, },
    c1: { x: side.y, y: upward.y, z: -forward.y, w: 0.0, },
    c2: { x: side.z, y: upward.z, z: -forward.z, w: 0.0, },
    c3: { x: -side.dot(eye), y: -upward.dot(eye), z: forward.dot(eye), w: 1.0, },
  }
}

///|
/// A perspective projection with the depth range `0..1`: the near plane maps to
/// zero and the far plane to one, which is what WebGPU clips against.
///
/// `fov_y` is the vertical field of view in radians and `aspect` the width
/// divided by the height. Right-handed: the camera looks down -z, so `near` and
/// `far` are distances in front of it, both positive.
///
/// ```mbt check
/// test {
///   let m = @moonmath.Mat4::perspective(@moonmath.half_pi, 1.0, 0.1, 100.0)
///   // The near plane lands on depth 0 and the far plane on depth 1.
///   let near = m.mul_vec4(@moonmath.Vec4::new(0.0, 0.0, -0.1, 1.0))
///   assert_true(@moonmath.approx(near.z / near.w, 0.0))
///   let far = m.mul_vec4(@moonmath.Vec4::new(0.0, 0.0, -100.0, 1.0))
///   assert_true(@moonmath.approx(far.z / far.w, 1.0))
/// }
/// ```
pub fn Mat4::perspective(
  fov_y : Float,
  aspect : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  let f = focal_length(fov_y)
  {
    c0: { x: f / aspect, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: f, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: far / (near - far), w: -1.0, },
    c3: { x: 0.0, y: 0.0, z: far * near / (near - far), w: 0.0, },
  }
}

///|
/// A perspective projection with the depth range `0..1` and no far plane.
///
/// Precision is better spent near the eye: with no far plane to reach, the depth
/// values crowd into the region where a depth buffer can still tell them apart,
/// instead of being spread over a range whose far end nothing occupies.
pub fn Mat4::perspective_infinite(
  fov_y : Float,
  aspect : Float,
  near : Float,
) -> Mat4 {
  let f = focal_length(fov_y)
  {
    c0: { x: f / aspect, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: f, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: -1.0, w: -1.0, },
    c3: { x: 0.0, y: 0.0, z: -near, w: 0.0, },
  }
}

///|
/// A perspective projection with the depth range `-1..1`, for a pipeline that
/// clips like OpenGL.
///
/// The same as `perspective` in every other respect; only the third row differs.
pub fn Mat4::perspective_gl(
  fov_y : Float,
  aspect : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  let f = focal_length(fov_y)
  {
    c0: { x: f / aspect, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: f, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: (far + near) / (near - far), w: -1.0, },
    c3: { x: 0.0, y: 0.0, z: 2.0 * far * near / (near - far), w: 0.0, },
  }
}

///|
/// A perspective projection with the depth range `-1..1` and no far plane.
pub fn Mat4::perspective_infinite_gl(
  fov_y : Float,
  aspect : Float,
  near : Float,
) -> Mat4 {
  let f = focal_length(fov_y)
  let twice : Float = 2.0
  {
    c0: { x: f / aspect, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: f, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: -1.0, w: -1.0, },
    c3: { x: 0.0, y: 0.0, z: -twice * near, w: 0.0, },
  }
}

///|
/// An orthographic projection with the depth range `0..1`: the box the six
/// planes bound becomes the unit cube in clip space.
///
/// Right-handed, so the camera looks down -z and `near` and `far` are distances
/// in front of it, both positive. A box with `left == right`, `bottom == top` or
/// `near == far` has no volume to map and gives the identity.
pub fn Mat4::orthographic(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  if left == right || bottom == top || near == far {
    return Mat4::identity()
  }
  let twice : Float = 2.0
  let width = right - left
  let height = top - bottom
  let depth = near - far
  {
    c0: { x: twice / width, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: twice / height, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: 1.0 / depth, w: 0.0, },
    c3: {
      x: -(right + left) / width,
      y: -(top + bottom) / height,
      z: near / depth,
      w: 1.0,
    },
  }
}

///|
/// An orthographic projection with the depth range `-1..1`.
pub fn Mat4::orthographic_gl(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  if left == right || bottom == top || near == far {
    return Mat4::identity()
  }
  let twice : Float = 2.0
  let width = right - left
  let height = top - bottom
  let depth = far - near
  {
    c0: { x: twice / width, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: twice / height, z: 0.0, w: 0.0, },
    c2: { x: 0.0, y: 0.0, z: -twice / depth, w: 0.0, },
    c3: {
      x: -(right + left) / width,
      y: -(top + bottom) / height,
      z: -(far + near) / depth,
      w: 1.0,
    },
  }
}

///|
/// A perspective projection from an explicit frustum with the depth range `0..1`.
///
/// The rectangle on the near plane becomes the full clip volume, so the six
/// numbers are all a camera needs: `left` and `bottom` are negative, `right` and
/// `top` positive for a centred view, and offsetting them is what a lens shift
/// does.
pub fn Mat4::frustum(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  if left == right || bottom == top || near == far || near == 0.0 {
    return Mat4::identity()
  }
  let twice : Float = 2.0
  let width = right - left
  let height = top - bottom
  let depth = near - far
  {
    c0: { x: twice * near / width, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: twice * near / height, z: 0.0, w: 0.0, },
    c2: {
      x: (right + left) / width,
      y: (top + bottom) / height,
      z: far / depth,
      w: -1.0,
    },
    c3: { x: 0.0, y: 0.0, z: far * near / depth, w: 0.0, },
  }
}

///|
/// A perspective projection from an explicit frustum with the depth range
/// `-1..1`.
pub fn Mat4::frustum_gl(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> Mat4 {
  if left == right || bottom == top || near == far || near == 0.0 {
    return Mat4::identity()
  }
  let twice : Float = 2.0
  let width = right - left
  let height = top - bottom
  let depth = near - far
  {
    c0: { x: twice * near / width, y: 0.0, z: 0.0, w: 0.0, },
    c1: { x: 0.0, y: twice * near / height, z: 0.0, w: 0.0, },
    c2: {
      x: (right + left) / width,
      y: (top + bottom) / height,
      z: (far + near) / depth,
      w: -1.0,
    },
    c3: { x: 0.0, y: 0.0, z: twice * far * near / depth, w: 0.0, },
  }
}

///|
/// The focal length `1 / tan(fov_y / 2)`, the scale a projection puts on `x` and
/// `y` before the aspect ratio touches it.
fn focal_length(fov_y : Float) -> Float {
  let half : Float = 0.5
  let one : Float = 1.0
  one / @math.tanf(fov_y * half)
}

///|
/// The elements in column-major order, the sixteen a buffer holds.
pub fn Mat4::to_array(self : Mat4) -> FixedArray[Float] {
  [
    self.c0.x,
    self.c0.y,
    self.c0.z,
    self.c0.w,
    self.c1.x,
    self.c1.y,
    self.c1.z,
    self.c1.w,
    self.c2.x,
    self.c2.y,
    self.c2.z,
    self.c2.w,
    self.c3.x,
    self.c3.y,
    self.c3.z,
    self.c3.w,
  ]
}

///|
/// Whether every element is finite.
pub fn Mat4::is_finite(self : Mat4) -> Bool {
  self.c0.is_finite() &&
  self.c1.is_finite() &&
  self.c2.is_finite() &&
  self.c3.is_finite()
}

///|
/// Whether the two matrices agree to within `eps` element by element.
pub fn Mat4::approx(self : Mat4, other : Mat4, eps? : Float) -> Bool {
  self.c0.approx(other.c0, eps?) &&
  self.c1.approx(other.c1, eps?) &&
  self.c2.approx(other.c2, eps?) &&
  self.c3.approx(other.c3, eps?)
}

///|
pub impl Add for Mat4 with fn add(self, other) {
  {
    c0: self.c0 + other.c0,
    c1: self.c1 + other.c1,
    c2: self.c2 + other.c2,
    c3: self.c3 + other.c3,
  }
}

///|
pub extend Mat4 with Add::{add}

///|
pub impl Sub for Mat4 with fn sub(self, other) {
  {
    c0: self.c0 - other.c0,
    c1: self.c1 - other.c1,
    c2: self.c2 - other.c2,
    c3: self.c3 - other.c3,
  }
}

///|
pub extend Mat4 with Sub::{sub}

///|
/// The matrix product: `(self * other) * v` is `self * (other * v)`.
///
/// The four columns of the result are `self` applied to the four columns of
/// `other`, which is the definition written the way the storage suggests.
pub impl Mul for Mat4 with fn mul(self, other) {
  {
    c0: self.mul_vec4(other.c0),
    c1: self.mul_vec4(other.c1),
    c2: self.mul_vec4(other.c2),
    c3: self.mul_vec4(other.c3),
  }
}

///|
pub extend Mat4 with Mul::{mul}

///|
/// The product with the inverse of the right-hand side; aborts when that side is
/// singular.
pub impl Div for Mat4 with fn div(self, other) {
  match other.inverse() {
    Some(inverse) => self * inverse
    None => abort("Mat4 division by a singular matrix")
  }
}

///|
pub extend Mat4 with Div::{div}

///|
pub impl Neg for Mat4 with fn neg(self) {
  { c0: -self.c0, c1: -self.c1, c2: -self.c2, c3: -self.c3, }
}

///|
pub extend Mat4 with Neg::{neg}

///|
pub impl Show for Mat4 with fn output(self, logger) {
  logger.write_string("Mat4[\{self.c0}, \{self.c1}, \{self.c2}, \{self.c3}]")
}

///|
pub extend Mat4 with Show::{output, to_string}

///|
pub impl Debug for Mat4 with fn to_repr(self) {
  @debug.Repr::ctor("Mat4", [
    (Some("c0"), self.c0.to_repr()),
    (Some("c1"), self.c1.to_repr()),
    (Some("c2"), self.c2.to_repr()),
    (Some("c3"), self.c3.to_repr()),
  ])
}

///|
pub extend Mat4 with Debug::{to_repr}
