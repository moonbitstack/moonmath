// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Picking and collision: a ray into a small scene, the same ray narrowed down by
/// a sphere test and then a triangle test, and a ball bouncing off a wall.
///
///     moon run src/examples/04-collision
#coverage.skip
fn main {
  let floor = @moonmath.Plane::new(@moonmath.Vec3::unit_y(), 0.0)
  let wall = @moonmath.Plane::new(@moonmath.Vec3::new(0.0, 0.0, -1.0), 5.0)

  let from = @moonmath.Vec3::new(0.0, 2.0, 0.0)
  let aim = @moonmath.Vec3::new(0.3, 0.3, -1.7)
  let ray = @moonmath.Ray3::new(from, (aim - from).normalize())
  println("ray: \{ray}")
  match ray.intersect_plane(wall) {
    Some(t) => println("wall at \{ray.at(t)}")
    None => println("the ray never reaches the wall")
  }
  match ray.intersect_plane(floor) {
    Some(t) => println("floor at \{ray.at(t)}")
    None => println("the ray never reaches the floor")
  }

  println("\n-- narrowing down")
  // A bounding sphere first: cheap, and it throws out what it can.
  let ball = @moonmath.Sphere::new(@moonmath.Vec3::new(0.5, 0.5, -2.0), 1.2)
  println("sphere: \{ball}")
  match ray.intersect_sphere(ball) {
    Some(t) => println("the ray enters the sphere's box at t = \{t}")
    None => println("no sphere to look at")
  }
  // Then the triangles inside it.
  let mesh = [
    @moonmath.Triangle::new(
      @moonmath.Vec3::new(0.0, 0.0, -1.0),
      @moonmath.Vec3::new(1.0, 0.0, -2.0),
      @moonmath.Vec3::new(0.0, 1.0, -2.0),
    ),
    @moonmath.Triangle::new(
      @moonmath.Vec3::new(1.0, 0.0, -2.0),
      @moonmath.Vec3::new(1.0, 1.0, -3.0),
      @moonmath.Vec3::new(0.0, 1.0, -2.0),
    ),
  ]
  let mut nearest : Float = 1.0e9
  let mut hit_any = false
  for triangle in mesh {
    match ray.intersect_triangle(triangle) {
      Some(t) => {
        hit_any = true
        if t < nearest {
          nearest = t
        }
      }
      None => ()
    }
  }
  if hit_any {
    println("nearest triangle at \{ray.at(nearest)}")
    println("its normal faces \{mesh[0].normal()}")
  } else {
    println("the ray passes through the mesh")
  }

  println("\n-- one bounce off the wall, then one off the floor")
  let thrown = @moonmath.Vec3::new(0.0, 2.0, 0.0)
  let thrown_at = @moonmath.Vec3::new(3.0, -1.0, -4.0).normalize()
  match @moonmath.Ray3::new(thrown, thrown_at).intersect_plane(wall) {
    Some(t) => {
      let contact = thrown + thrown_at.scale(t)
      // The wall faces +z, so its normal is the plane's own.
      let away = thrown_at.reflect(wall.normal)
      println("the ball meets the wall at \{contact}")
      println("and leaves along \{away}")
      match @moonmath.Ray3::new(contact, away).intersect_plane(floor) {
        Some(t) => println("it lands at \{(contact + away.scale(t))}")
        None => println("it never comes down")
      }
    }
    None => println("it misses the wall")
  }
}
