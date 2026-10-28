// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// Throughput of the operations a frame loop calls most, on the native backend.
//
// Run with `moon bench --target native --release`; the numbers in the README
// came from this file. Two things are deliberate about the shape of these cases.
// The operands are built outside the closure, so the measurement is the
// operation and not the construction of its inputs. And each closure runs
// `batch` operations rather than one: the harness times a closure call, which on
// this backend costs more than everything below, and a single operation per call
// would measure mostly that.
//
// The reported time is for the whole batch; divide by `batch` for one operation.

///|
/// How many operations each timed closure runs.
let batch : Int32 = 64

///|
test "bench Vec3::dot" (b : @bench.T) {
  let a = @f64.Vec3::new(1.0, 2.0, 3.0)
  let c = @f64.Vec3::new(4.0, 5.0, 6.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.dot(c)
    }
    b.keep(total)
  })
}

///|
test "bench Vec3::cross" (b : @bench.T) {
  let a = @f64.Vec3::new(1.0, 2.0, 3.0)
  let c = @f64.Vec3::new(4.0, 5.0, 6.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.cross(c).x
    }
    b.keep(total)
  })
}

///|
test "bench Vec3::normalize" (b : @bench.T) {
  let a = @f64.Vec3::new(1.0, 2.0, 3.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.normalize().x
    }
    b.keep(total)
  })
}

///|
test "bench Vec4::dot" (b : @bench.T) {
  let a = @f64.Vec4::new(1.0, 2.0, 3.0, 4.0)
  let c = @f64.Vec4::new(5.0, 6.0, 7.0, 8.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.dot(c)
    }
    b.keep(total)
  })
}

///|
/// A matrix with a little of everything in it, so that no branch of the inverse
/// is the only one measured.
fn sample_matrix() -> @f64.Mat4 {
  @f64.Mat4::from_trs(
    @f64.Trs::new(
      @f64.Vec3::new(1.0, 2.0, 3.0),
      @f64.Quat::from_axis_angle(@f64.Vec3::new(1.0, 2.0, 3.0), 0.5),
      @f64.Vec3::new(2.0, 2.0, 2.0),
    ),
  )
}

///|
test "bench Mat4 multiplication" (b : @bench.T) {
  let a = sample_matrix()
  let c = @f64.Mat4::look_at(
    @f64.Vec3::new(4.0, 5.0, 6.0),
    @f64.Vec3::zero(),
    @f64.Vec3::unit_y(),
  )
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + (a * c).c0.x
    }
    b.keep(total)
  })
}

///|
test "bench Mat4::inverse" (b : @bench.T) {
  let a = sample_matrix()
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      match a.inverse() {
        Some(inverse) => total = total + inverse.c0.x
        None => ()
      }
    }
    b.keep(total)
  })
}

///|
test "bench Mat4::transform_point" (b : @bench.T) {
  let a = sample_matrix()
  let point = @f64.Vec3::new(0.5, -1.5, 2.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.transform_point(point).x
    }
    b.keep(total)
  })
}

///|
test "bench Quat::rotate" (b : @bench.T) {
  let q = @f64.Quat::from_axis_angle(@f64.Vec3::new(1.0, 2.0, 3.0), 0.5)
  let v = @f64.Vec3::new(0.5, -1.5, 2.0)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + q.rotate(v).x
    }
    b.keep(total)
  })
}

///|
test "bench Quat::slerp" (b : @bench.T) {
  let a = @f64.Quat::from_axis_angle(@f64.Vec3::unit_x(), 0.2)
  let c = @f64.Quat::from_axis_angle(@f64.Vec3::unit_y(), 1.1)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + a.slerp(c, 0.3).w
    }
    b.keep(total)
  })
}

///|
test "bench Quat::to_mat3" (b : @bench.T) {
  let q = @f64.Quat::from_axis_angle(@f64.Vec3::new(1.0, 2.0, 3.0), 0.5)
  b.bench(fn() {
    let mut total : Double = 0.0
    for _ in 0..<batch {
      total = total + q.to_mat3().c0.x
    }
    b.keep(total)
  })
}

///|
test "bench Ray3 against a sphere" (b : @bench.T) {
  let ray = @f64.Ray3::new(@f64.Vec3::new(0.0, 0.0, 5.0), -@f64.Vec3::unit_z())
  let sphere = @f64.Sphere::new(@f64.Vec3::zero(), 1.0)
  b.bench(fn() {
    let mut hits = 0
    for _ in 0..<batch {
      if ray.intersect_sphere(sphere) is Some(_) {
        hits = hits + 1
      }
    }
    b.keep(hits)
  })
}

///|
test "bench Ray3 against a box" (b : @bench.T) {
  let ray = @f64.Ray3::new(@f64.Vec3::new(0.0, 0.0, 5.0), -@f64.Vec3::unit_z())
  let box = @f64.Aabb3::new(-@f64.Vec3::one(), @f64.Vec3::one())
  b.bench(fn() {
    let mut hits = 0
    for _ in 0..<batch {
      if ray.intersect_aabb(box) is Some(_) {
        hits = hits + 1
      }
    }
    b.keep(hits)
  })
}

///|
test "bench Frustum::intersects_aabb" (b : @bench.T) {
  let projection = @f64.Mat4::perspective(@f64.half_pi, 1.5, 0.1, 100.0)
  let view = @f64.Mat4::look_at(
    @f64.Vec3::new(0.0, 0.0, 10.0),
    @f64.Vec3::zero(),
    @f64.Vec3::unit_y(),
  )
  let frustum = @f64.Frustum::from_matrix(projection * view).unwrap()
  let box = @f64.Aabb3::new(@f64.Vec3::new(-1.0, -1.0, -1.0), @f64.Vec3::one())
  b.bench(fn() {
    let mut hits = 0
    for _ in 0..<batch {
      if frustum.intersects_aabb(box) {
        hits = hits + 1
      }
    }
    b.keep(hits)
  })
}
