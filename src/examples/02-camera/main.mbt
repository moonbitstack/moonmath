// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A camera looking at a scene: what a world point lands on, in screen space,
/// what of the scene survives the frustum, and what a screen point sees when the
/// ray is traced back out into the world.
///
///     moon run src/examples/02-camera
#coverage.skip
fn main {
  let width : Float = 1280.0
  let height : Float = 720.0
  let eye = @moonmath.Vec3::new(0.0, 2.0, 6.0)
  let target = @moonmath.Vec3::new(0.0, 1.0, 0.0)
  let up = @moonmath.Vec3::unit_y()
  let projection = @moonmath.Mat4::perspective(
    @moonmath.to_radians(50.0),
    width / height,
    0.1,
    200.0,
  )
  let view = @moonmath.Mat4::look_at(eye, target, up)
  let view_projection = projection * view

  println("-- where things land on screen")
  let scene = [
    ("in front", @moonmath.Vec3::new(0.0, 1.0, 0.0)),
    ("to the right", @moonmath.Vec3::new(2.0, 1.0, 0.0)),
    ("above", @moonmath.Vec3::new(0.0, 4.0, 0.0)),
    ("behind the camera", @moonmath.Vec3::new(0.0, 1.0, 12.0)),
  ]
  for item in scene {
    let (name, point) = item
    let clip = view_projection.mul_vec4(point.to_vec4(1.0))
    if clip.w <= 0.0 {
      println("\{name}: behind the camera")
    } else {
      let ndc = clip.xyz().divide(clip.w)
      let half : Float = 0.5
      let one : Float = 1.0
      let x = (ndc.x * half + half) * width
      let y = (one - (ndc.y * half + half)) * height
      println("\{name}: pixel (\{x}, \{y}), depth \{ndc.z}")
    }
  }

  println("\n-- what the frustum keeps")
  let frustum = @moonmath.Frustum::from_matrix(view_projection).unwrap()
  let objects = [
    (
      "crate",
      @moonmath.Aabb3::new(
        @moonmath.Vec3::new(-1.0, 0.0, -1.0),
        @moonmath.Vec3::new(0.0, 1.0, 0.0),
      ),
    ),
    (
      "far tower",
      @moonmath.Aabb3::new(
        @moonmath.Vec3::new(9.0, 0.0, -40.0),
        @moonmath.Vec3::new(11.0, 30.0, -38.0),
      ),
    ),
    (
      "behind us",
      @moonmath.Aabb3::new(
        @moonmath.Vec3::new(-1.0, 0.0, 8.0),
        @moonmath.Vec3::new(1.0, 1.0, 10.0),
      ),
    ),
    (
      "sun",
      @moonmath.Aabb3::new(
        @moonmath.Vec3::new(-1.0, 0.0, -100.0),
        @moonmath.Vec3::new(1.0, 2.0, -98.0),
      ),
    ),
  ]
  for object in objects {
    let (name, box) = object
    let verdict = if frustum.contains_aabb(box) {
      "fully visible"
    } else if frustum.intersects_aabb(box) {
      "partly visible"
    } else {
      "culled"
    }
    println("\{name}: \{verdict}")
  }

  println("\n-- what a click on the screen hits")
  let inverse = view_projection.inverse().unwrap()
  let pick = @moonmath.Vec2::new(width * 0.5, height * 0.5)
  // Screen to clip space: the depth is the near plane, which is what a click
  // knows and all it needs, since the ray is what the two points define.
  let near = @moonmath.Vec4::new(
    pick.x / width * 2.0 - 1.0,
    1.0 - pick.y / height * 2.0,
    0.0,
    1.0,
  )
  let far = @moonmath.Vec4::new(near.x, near.y, 1.0, 1.0)
  let start = inverse.transform_point(near.xyz().divide(near.w))
  let end = inverse.transform_point(far.xyz().divide(far.w))
  let ray = @moonmath.Ray3::new(start, (end - start).normalize())
  println("ray from \{ray.origin} towards \{ray.direction}")
  let ground = @moonmath.Plane::new(@moonmath.Vec3::unit_y(), 0.0)
  match ray.intersect_plane(ground) {
    Some(t) => println("it meets the ground at \{ray.at(t)}")
    None => println("it never meets the ground")
  }
}
