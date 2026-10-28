// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Everything the library does, in one run: vectors, matrices, rotations,
/// affine transforms and the geometry.
///
///     moon run src/examples/01-tour

///|
/// A hit along the ray, or the fact that there was none, as text.
fn hit(value : Float?) -> String {
  match value {
    Some(t) => t.to_string()
    None => "no hit"
  }
}

///|
#coverage.skip
fn main {
  println("-- vectors")
  let up = @moonmath.Vec3::unit_y()
  let ahead = @moonmath.Vec3::unit_z()
  println("up x ahead      = \{up.cross(ahead)}")
  println("their angle     = \{up.angle_between(ahead)} rad")
  println("reflected ahead = \{ahead.reflect(up)}")
  println("normalized      = \{@moonmath.Vec3::new(3.0, 0.0, 4.0).normalize()}")

  println("\n-- matrices")
  let projection = @moonmath.Mat4::perspective(
    @moonmath.to_radians(60.0),
    16.0 / 9.0,
    0.1,
    100.0,
  )
  let camera = @moonmath.Mat4::look_at(
    @moonmath.Vec3::new(0.0, 1.0, 5.0),
    @moonmath.Vec3::zero(),
    @moonmath.Vec3::unit_y(),
  )
  let view_projection = projection * camera
  println(
    "origin on screen  = \{view_projection.transform_point(@moonmath.Vec3::zero())}",
  )
  println(
    "one unit right    = \{view_projection.transform_point(@moonmath.Vec3::new(1.0, 0.0, 0.0))}",
  )
  println("determinant       = \{camera.determinant()}")

  println("\n-- rotations")
  let turn = @moonmath.Quat::from_axis_angle(
    @moonmath.Vec3::unit_y(),
    @moonmath.quarter_pi,
  )
  println("quarter turn of x = \{turn.rotate(@moonmath.Vec3::unit_x())}")
  println("its matrix        = \{turn.to_mat3()}")
  let halfway = @moonmath.Quat::identity().slerp(turn, 0.5)
  println("half of the turn  = \{halfway.rotate(@moonmath.Vec3::unit_x())}")

  println("\n-- affine transforms")
  let trs = @moonmath.Trs::new(
    @moonmath.Vec3::new(2.0, 0.0, 0.0),
    turn,
    @moonmath.Vec3::splat(2.0),
  )
  println(
    "scaled, turned, moved = \{@moonmath.Affine3::from_trs(trs).transform_point(@moonmath.Vec3::unit_x())}",
  )
  let back = @moonmath.Mat4::from_trs(trs).to_trs().unwrap()
  println("and taken apart again = \{back}")

  println("\n-- geometry")
  let room = @moonmath.Aabb3::new(
    @moonmath.Vec3::new(-4.0, 0.0, -4.0),
    @moonmath.Vec3::new(4.0, 3.0, 4.0),
  )
  println("room centre  = \{room.center()}")
  println("room volume  = \{room.volume()}")
  let floor = @moonmath.Plane::new(@moonmath.Vec3::unit_y(), 0.0)
  println(
    "floor at y=1 = \{floor.signed_distance(@moonmath.Vec3::new(0.0, 1.0, 0.0))}",
  )
  let ray = @moonmath.Ray3::new(
    @moonmath.Vec3::new(0.0, 2.0, 0.0),
    @moonmath.Vec3::new(0.5, -1.0, 0.0).normalize(),
  )
  println("ray meets floor at   = \{hit(ray.intersect_plane(floor))}")
  println("ray meets the room   = \{hit(ray.intersect_aabb(room))}")
  let sphere = @moonmath.Sphere::new(@moonmath.Vec3::new(0.0, 0.0, -2.0), 0.5)
  println("ray meets the ball   = \{hit(ray.intersect_sphere(sphere))}")
  println("is the ball in the room? = \{room.contains_point(sphere.center)}")
}
