<h1 align="center">moonmath</h1>

<p align="center">
  <b>Vectors, matrices, quaternions and geometry for MoonBit.</b><br />
  Column-major, right-handed, depth from zero to one, and laid out so that a
  matrix copies straight into a WGSL buffer.
</p>

<p align="center">
  <a href="https://moonbitstack.github.io/moonmath/">Home</a> &nbsp;·&nbsp;
  <a href="https://moonbitstack.github.io/moonmath/guide.html">Guide</a> &nbsp;·&nbsp;
  <a href="https://moonbitstack.github.io/moonmath/api.html">API</a> &nbsp;·&nbsp;
  <a href="https://mooncakes.io/docs/moonbitstack/moonmath">mooncakes</a>
</p>

```moonbit
let eye = @moonmath.Vec3::new(0.0, 1.6, 6.0)
let view = @moonmath.Mat4::look_at(eye, @moonmath.Vec3::zero(), @moonmath.Vec3::unit_y())
let projection = @moonmath.Mat4::perspective(@moonmath.to_radians(60.0), 16.0 / 9.0, 0.1, 100.0)
let view_projection = projection * view

let on_screen = view_projection.transform_point(@moonmath.Vec3::zero())
```

## Installing

<!-- nocheck -->

```bash
moon add moonbitstack/moonmath
```

The package is `moonbitstack/moonmath`, imported as `@moonmath`. Double precision is the same library under `moonbitstack/moonmath/f64`, imported as `@f64`.

## What it is, and what it is not

It is the arithmetic a renderer, a layout engine or a physics step needs: the vectors and matrices a shader also has, the rotations that are easier to interpolate than a matrix, the affine transforms a scene graph stores, and the geometry that says whether two things touch.

It is not a rendering library. Nothing here talks to a GPU, loads a mesh, or knows what a camera is beyond the matrix that describes one. There is no four-component SIMD trickery and nothing allocates beyond the values it returns.

## Conventions

Five decisions shape the whole surface, and all five are visible in every signature.

**Right-handed, column-major.** `x` runs east, `y` north, `z` towards the viewer, so `cross(x, y) == z`. A matrix stores its columns, `c0` first, which is the order a `mat4x4<f32>` occupies in a buffer: `to_array` gives the sixteen floats in that order and `from_array` reads them back. A matrix product `a * b` applies `b` first.

**Depth runs from zero to one.** `perspective`, `perspective_infinite`, `orthographic` and `frustum` map the near plane to depth 0 and the far plane to 1, as WebGPU clips. The `_gl` variants of the same four map them to -1 and 1 for a pipeline that clips like OpenGL.

**Angles are radians.** Every angle in the library, in a signature or out of one, is in radians; `to_radians` and `to_degrees` convert at the edge, where the number came from a file or a human.

**Operators take two values of the same type.** `a + b`, `a - b`, `a * b`, `a / b`, `-a` do what they look like on two vectors, two matrices or two quaternions. MoonBit's arithmetic traits are declared `fn mul(Self, Self) -> Self`, so the two sides of an operator are the same type by definition: there is no `Vec3 * Float` to define, and no `Mat4 * Vec4` either. Scaling is `scale` and its inverse `divide`, and a matrix times a vector is `mul_vec4`, `mul_vec3` or `mul_vec2`.

**A matrix that cannot be inverted says so.** `inverse` returns an `Option`, `None` for a singular matrix, and the caller decides whether that is an error. The operator `/` has nowhere to report it, so `a / b` aborts when `b` is singular; `inverse` is what to reach for when the case can happen.

Two more, smaller ones. The zero vector has no direction, and `normalize` returns `Vec3::zero()` for it rather than a NaN — `try_normalize` and `normalize_or` exist for callers that need to tell the case apart. And every value type implements `Eq`, `Show` and `Debug`; the integer vectors also implement `Hash`. Equality is exact — `approx` is the comparison to use on results of arithmetic, and it takes an optional epsilon.

## Using it

### Rotations

A quaternion is four numbers that interpolate; a matrix is what a shader wants. Both directions are here, and a rotation round-trips through either.

```moonbit
let turn = @moonmath.Quat::from_axis_angle(@moonmath.Vec3::unit_y(), @moonmath.quarter_pi)
let half_way = @moonmath.Quat::identity().slerp(turn, 0.5)

let ahead = turn.rotate(@moonmath.Vec3::unit_z())
let matrix = turn.to_mat3()

// Euler angles, in one of the twelve orders, by name.
let from_yaw = @moonmath.Quat::from_euler(
  @moonmath.EulerOrder::Zyx,
  @moonmath.Vec3::new(0.0, 0.0, @moonmath.to_radians(90.0)),
)
let back = from_yaw.to_euler(@moonmath.EulerOrder::Zyx)
```

The three components of an Euler angle vector are the turns about `x`, `y` and `z` — the component says which axis, wherever that axis turns up in the order. `Zyx` above turns about `z` first, and the turn is in the third component because it is a turn about `z`.

Six of the twelve orders turn about one axis twice — `Xyx` and its siblings — and two turns about `x` cannot both live in the single component named after it. Those six have no by-axis form, so `from_euler` and `to_euler` abort on them; `from_euler_turns` and `to_euler_turns` take a `Turns` record whose fields are named after their place in the order, and cover all twelve:

```moonbit
let precessing = @moonmath.Quat::from_euler_turns(
  @moonmath.EulerOrder::Xyx,
  @moonmath.Turns::new(0.3, 1.2, -0.4),
)
let turns = precessing.to_euler_turns(@moonmath.EulerOrder::Xyx)
```

### Scene graph transforms

Position, rotation and scale are three separate pieces, and so is a matrix built from them:

```moonbit
let placement = @moonmath.Trs::new(
  @moonmath.Vec3::new(0.0, 2.0, 0.0),
  @moonmath.Quat::from_axis_angle(@moonmath.Vec3::unit_y(), @moonmath.half_pi),
  @moonmath.Vec3::splat(0.5),
)
let model = @moonmath.Mat4::from_trs(placement)

// And back out again, for an editor or an animation to edit.
let editable = model.to_trs().unwrap()
```

`Affine2` and `Affine3` are the same transform without the row that does nothing: cheaper to compose and apply, and impossible to make non-affine.

### Geometry

Boxes, rays, planes, spheres, triangles and the frustum, with the tests a broad phase and a pick need.

```moonbit
let room = @moonmath.Aabb3::new(
  @moonmath.Vec3::new(-4.0, 0.0, -4.0),
  @moonmath.Vec3::new(4.0, 3.0, 4.0),
)
let ray = @moonmath.Ray3::new(
  @moonmath.Vec3::new(0.0, 2.0, 0.0),
  @moonmath.Vec3::new(0.0, -1.0, -1.0).normalize(),
)

match ray.intersect_aabb(room) {
  Some(t) => println("the room is \{t} away along the ray, at \{ray.at(t)}")
  None => println("the ray leaves the room alone")
}

let frustum = @moonmath.Frustum::from_matrix(view_projection).unwrap()
if frustum.intersects_aabb(room) {
  println("there is something to draw")
}
```

Rectangles are separate from boxes because a layout thinks in a corner and a size, not in two opposite corners: `Rect` is `origin` plus `size`, and `Aabb2` is `min` plus `max`. They convert to each other with `to_aabb` and `to_rect`.

### Double precision

`moonbitstack/moonmath/f64` holds the same types at `Double`, generated from the same template as the single-precision package. A simulation that runs for hours, or spans a planet, converts at the boundary rather than living in `Float` throughout:

```moonbit
let far_away = @f64.Vec3::new(1.0e9, 0.0, 0.0)
let scaled = far_away.scale(2.0)
```

### Half precision

A packed vertex or a texture often carries a sixteen-bit float, and `Half` is that encoding: the bits in and out, the conversion to and from `Float` rounded to nearest with ties to even, and the special values kept.

```moonbit
let packed = @moonmath.Half::from_float(1.5)
let restored = packed.to_float()
let raw = packed.to_bits()
```

### Colour, shear, intervals and sampling

`Color3` and `Color4` are the component arithmetic a blend or a gradient needs; `rgb_to_hsv` and `hsv_to_rgb` convert between the two forms. `Shear` is the off-diagonal linear map a skew is. `Interval` is a one-dimensional range with union, intersection and growth. `Line3` is an infinite line with the closest-point and plane-intersection questions. The sampling functions turn uniform values in `[0, 1)` into points with the right distribution, and leave the random source to the caller:

```moonbit
let red = @moonmath.Color3::new(1.0, 0.0, 0.0)
let hue = @moonmath.rgb_to_hsv(red)

let skew = @moonmath.Shear::new(0.3, 0.0, 0.0).to_mat3()
let span = @moonmath.Interval::new(0.0, 1.0).union(
  @moonmath.Interval::new(2.0, 3.0),
)

// The two values are a uniform random source the caller owns.
let on_sphere = @moonmath.Vec3::random_on_sphere(0.25, 0.75)
```

## The interface

Every type below is a value type: immutable, and returning a new value from every operation. Unless a row says otherwise, each also carries `+ - * /`, unary `-`, `Eq`, `Show` and `Debug`.

### Scalars

| Signature | Meaning |
|:--|:--|
| `to_radians(degrees : Float) -> Float` | degrees to radians |
| `to_degrees(radians : Float) -> Float` | radians to degrees |
| `lerp(a, b, t) -> Float` | `a` at `t = 0`, `b` at `t = 1`, extrapolating outside |
| `inverse_lerp(start, end, value) -> Float` | where a value sits in a range; zero for an empty range |
| `remap(value, from_start, from_end, to_start, to_end) -> Float` | the same position in another range |
| `smoothstep(start, end, value) -> Float` | the cubic easing with zero slope at both ends |
| `wrap(value, span) -> Float` | folded into `0..span` |
| `wrap_range(value, start, end) -> Float` | folded into `start..end` |
| `approx(a, b, eps? : Float) -> Bool` | equal to within `eps`, or within `default_epsilon` |
| `approx_angle(a, b, eps? : Float) -> Bool` | the same, for angles that wrap at `tau` |
| `clamp01(value) -> Float` | pinned to `0..1` |
| `pi`, `tau`, `half_pi`, `quarter_pi`, `default_epsilon` | the constants |

`Half` is the 16-bit float of a packed vertex or a texture: `from_float`, `to_float`, `from_bits`, `to_bits`, the predicates `is_finite`, `is_nan`, `is_inf`, `is_normal`, `is_denormal`, and the constants from `zero` and `one` to `max`, `min` and `epsilon`.

### Vectors

`Vec2`, `Vec3` and `Vec4` share this much:

| Signature | Meaning |
|:--|:--|
| `Vec::new(...)`, `splat(v)`, `zero()`, `one()`, `unit_x()`, `unit_y()`, `unit_z()`, `unit_w()` | constructors; `unit_z` and `unit_w` where the type has them |
| `dot(other) -> Float` | the dot product |
| `length()`, `length_squared() -> Float` | the length, and its square |
| `distance(other)`, `distance_squared(other) -> Float` | between two points |
| `normalize() -> Vec` | to length one; the zero vector stays zero |
| `try_normalize() -> Vec?`, `normalize_or(fallback) -> Vec` | the same, reporting the case instead |
| `scale(factor)`, `divide(divisor) -> Vec` | multiplied and divided by a scalar |
| `lerp(other, t)`, `min(other)`, `max(other)`, `clamp(low, high) -> Vec` | component-wise |
| `abs()`, `floor()`, `ceil()`, `round()`, `fract() -> Vec` | component-wise rounding; a half rounds up |
| `to_array() -> FixedArray[Float]` | the components in order |
| `is_finite() -> Bool` | no NaN and no infinity |
| `approx(other, eps? : Float) -> Bool` | equal to within `eps` |

What each type adds:

| Type | Signature | Meaning |
|:--|:--|:--|
| `Vec2` | `cross(other) -> Float` | the signed area the two span |
| | `perp() -> Vec2` | a quarter turn counter-clockwise |
| | `angle_between(other) -> Float` | the signed angle from this to that, in `-pi..pi` |
| | `yx() -> Vec2` | the components swapped |
| | `to_vec3(z)`, `to_vec4(z, w)` | lifted into a higher dimension |
| `Vec3` | `cross(other) -> Vec3` | the perpendicular, right-handed |
| | `angle_between(other) -> Float` | the unsigned angle, in `0..pi` |
| | `xy()`, `xz()`, `yz() -> Vec2` | a plane's worth of components |
| | `zyx()`, `xzy()`, `yxz()`, `yzx()`, `zxy() -> Vec3` | the six orders of the three components |
| | `to_vec4(w) -> Vec4` | lifted into 4D |
| `Vec4` | `xy() -> Vec2`, `xyz() -> Vec3` | the leading components |
| | `wzyx() -> Vec4` | all four backwards |

`Vec2` and `Vec3` also carry `reflect(normal)`, `refract(normal, eta)` — which returns `None` past the critical angle — `project(onto)` and `reject(onto)`. `reflect` and `refract` assume unit vectors, as a shader does.

### Integer vectors

`IVec2/3/4` are `Int`, for grid cells and pixel coordinates; `UVec2/3/4` are `UInt`, for sizes and counts. Both carry `+ - * /` component-wise (integer division, truncating), `Eq`, `Hash`, `Show` and `Debug`; the signed ones also carry unary `-` and `abs`.

| Signature | Meaning |
|:--|:--|
| `new(...)`, `splat(v)`, `zero()`, `one()` | constructors |
| `dot(other) -> Int` (or `UInt`) | the dot product |
| `min(other)`, `max(other)`, `clamp(low, high)` | component-wise, inclusive |
| `to_array()` | the components in order |
| `IVec::abs() -> IVec` | absolute value |
| `IVec::as_vec2/3/4()`, `UVec::as_vec2/3/4()` | the same values as floats, exactly |
| `IVec::from_vec2/3/4(v)` | the floats truncated towards zero |

### Matrices

`Mat2`, `Mat3` and `Mat4` store their columns: `c0`, and `c1`, `c2`, `c3` where the type has them.

| Signature | Meaning |
|:--|:--|
| `identity()`, `zero()` | the two that need no arguments |
| `from_cols(...)`, `from_rows(...)` | built one way or the other |
| `from_array(values) -> Mat` | from the column-major array a buffer holds; aborts on the wrong length |
| `col(i) -> Vec`, `row(i) -> Vec`, `get(row, column) -> Float` | reading it |
| `transpose() -> Mat` | rows and columns exchanged |
| `determinant() -> Float` | the volume it scales by |
| `inverse() -> Mat?` | `None` when it is singular |
| `mul_vec2/3/4(v) -> Vec` | applied to a vector |
| `to_array() -> FixedArray[Float]` | column-major, ready for a buffer |
| `is_finite()`, `approx(other, eps?) -> Bool` | |

| Type | Signature | Meaning |
|:--|:--|:--|
| `Mat2` | `from_scale(Vec2)`, `from_angle(radians)`, `to_angle() -> Float` | a scaling, a rotation, and the angle back out |
| `Mat3` | `from_scale(Vec3)`, `from_axis_angle(axis, radians)`, `from_quat(q)`, `from_euler(order, angles)`, `from_euler_turns(order, turns)` | |
| | `from_mat4(m)` | the upper-left block, without the translation |
| `Mat4` | `from_scale(Vec3)`, `from_translation(Vec3)`, `from_axis_angle(axis, radians)`, `from_quat(q)`, `from_euler(order, angles)`, `from_euler_turns(order, turns)` | |
| | `from_mat3(m)` | the 3×3 with `w = 1` and no translation |
| | `from_trs(trs)`, `to_trs() -> Trs?` | scale, then rotate, then move; and back |
| | `transform_point(p) -> Vec3` | a point, divided by `w` when there is one |
| | `transform_vector(v) -> Vec3` | a direction, untouched by the translation |
| | `look_at(eye, target, up) -> Mat4` | the view matrix of a camera |
| | `perspective(fov_y, aspect, near, far)` | depth 0..1 |
| | `perspective_infinite(fov_y, aspect, near)` | depth 0..1, no far plane |
| | `orthographic(left, right, bottom, top, near, far)` | depth 0..1 |
| | `frustum(left, right, bottom, top, near, far)` | depth 0..1, off-centre |
| | `perspective_gl`, `perspective_infinite_gl`, `orthographic_gl`, `frustum_gl` | the same four, depth -1..1 |
| `Shear` | `new(xy, xz, yz)`, `zero()`, `to_mat3()`, `to_mat4()` | the off-diagonal terms as a linear map |

### Rotations

| Signature | Meaning |
|:--|:--|
| `Quat::identity()`, `Quat::new(x, y, z, w)` | no rotation, and a raw one |
| `Quat::from_axis_angle(axis, radians)` | the right-hand rule about an axis |
| `Quat::from_euler(order, angles)`, `Quat::to_euler(order) -> Vec3` | the turns about `x`, `y` and `z`, by axis; aborts for an order that turns about one axis twice |
| `Quat::from_euler_turns(order, turns)`, `Quat::to_euler_turns(order) -> Turns` | the same, with the three turns in order, for all twelve orders |
| `Quat::from_rotation_arc(from, to)` | the shortest rotation between two directions |
| `Quat::from_mat3(m)`, `Quat::from_mat4(m)` | out of a matrix |
| `Quat::to_mat3()`, `Quat::to_mat4()` | into one |
| `Quat::to_axis_angle() -> (Vec3, Float)` | the axis and the angle |
| `Quat::rotate(v) -> Vec3` | the vector turned |
| `Quat::inverse() -> Quat?`, `conjugate()`, `normalize()`, `length()`, `length_squared()`, `dot(other)` | |
| `Quat::slerp(other, t)`, `Quat::nlerp(other, t)` | at constant angular speed, and along the straight line |
| `Quat::to_array()`, `is_finite()`, `approx(other, eps?)` | |

`EulerOrder` names the twelve orders: `Xyz`, `Xzy`, `Yxz`, `Yzx`, `Zxy`, `Zyx`, `Xyx`, `Xzx`, `Yxy`, `Yzy`, `Zxz`, `Zyz`. `Turns` is the record of three turns in order — `first`, `second`, `third` — with `Turns::new` and `Turns::approx`.

### Affine transforms

| Signature | Meaning |
|:--|:--|
| `Affine2::new(linear, translation)`, `Affine3::new(linear, translation)` | |
| `identity()`, `from_translation(v)`, `from_scale(v)` | |
| `Affine2::from_angle(radians)`, `from_angle_translation(radians, offset)` | |
| `Affine3::from_rotation(q)`, `from_axis_angle(axis, radians)`, `from_trs(trs)`, `to_trs() -> Trs?` | |
| `transform_point(p)`, `transform_vector(v)` | |
| `to_mat3()` / `to_mat4()`, `from_mat3(m) -> Affine2?` / `from_mat4(m) -> Affine3?` | to a matrix and back; `None` when the matrix is not affine |
| `inverse() -> Affine?` | `None` when the linear part is singular |
| `is_finite()`, `approx(other, eps?)` | |

`Trs` is the three parts of a transform — `translation : Vec3`, `rotation : Quat`, `scale : Vec3` — built with `Trs::new`, and what `Mat4::to_trs` recovers from a matrix built the same way.

### Geometry

| Type | Signature | Meaning |
|:--|:--|:--|
| `Rect` | `new(origin, size)`, `from_xywh(x, y, w, h)`, `from_edges(left, top, right, bottom)` | a corner and an extent |
| | `min()`, `max()`, `center() -> Vec2`, `width()`, `height()`, `area() -> Float` | |
| | `contains(point)`, `intersects(other)`, `intersection(other) -> Rect?`, `union(other)` | |
| | `inset(amount)`, `translate(offset)`, `is_empty()`, `corners()`, `to_aabb() -> Aabb2` | |
| `Aabb2`, `Aabb3` | `new(min, max)`, `from_center_half_extents(center, extents)`, `from_points(points) -> Aabb?`, `empty()` | |
| | `center()`, `size()`, `extents()`, `area()` / `volume()`, `surface_area()` | |
| | `contains_point(p)`, `contains(other)`, `intersects(other)`, `intersection(other) -> Aabb?`, `union(other)`, `expand(amount)` | |
| | `corners()`, `is_empty()`, `Aabb3::transform(m : Mat4) -> Aabb3` | the box around the transformed box |
| `Ray2`, `Ray3` | `new(origin, direction)`, `at(t) -> Vec` | a start and a direction; `t` may be any distance |
| | `intersect_aabb(box) -> Float?`, `intersect_aabb_interval(box) -> (Float, Float)?` | the first crossing, and the stretch inside |
| | `Ray2::intersect_rect(rect)`, `Ray2::intersect_circle(center, radius)` | |
| | `Ray3::intersect_sphere(sphere)`, `intersect_plane(plane)`, `intersect_triangle(triangle)` | |
| `Plane` | `new(normal, distance)`, `from_point_normal(point, normal) -> Plane?`, `from_points(a, b, c) -> Plane?` | `dot(normal, p) == distance` |
| | `signed_distance(p)`, `project(p) -> Vec3`, `intersect_ray(ray) -> Float?`, `flip()` | |
| `Sphere` | `new(center, radius)`, `contains_point(p)`, `intersects_sphere(other)`, `intersects_aabb(box)`, `surface_area()`, `volume()` | |
| `Triangle` | `new(a, b, c)`, `normal() -> Vec3`, `area()`, `barycentric(p) -> Vec3?`, `intersect_ray(ray) -> Float?` | |
| `Frustum` | `from_matrix(view_projection) -> Frustum?`, `from_matrix_gl(view_projection) -> Frustum?` | six planes facing inwards |
| | `planes() -> FixedArray[Plane]`, `plane(i) -> Plane` | left, right, bottom, top, near, far |
| | `contains_point(p)`, `contains_aabb(box)`, `intersects_aabb(box)`, `contains_sphere(s)`, `intersects_sphere(s)` | |
| `Line3` | `new(point, direction)`, `at(t)`, `closest_point_to(p)`, `distance_to_point(p)`, `closest_point_to_line(line)`, `distance_to_line(line)`, `intersect_plane(plane) -> Vec3?` | an infinite line |
| `Interval` | `new(min, max)`, `empty()`, `size()`, `center()`, `contains(x)`, `intersects(other)`, `intersection(other) -> Interval?`, `union(other)`, `extend_by(x)`, `expand(amount)` | a one-dimensional range |

The intersection functions return the `t` of the crossing rather than the point, because the distance is usually what a caller wants and the point is `at(t)`. A ray that starts inside a shape reports the crossing on its way out.

### Colour

| Type | Signature | Meaning |
|:--|:--|:--|
| `Color3`, `Color4` | `new(...)`, `splat(v)`, `zero()`, `one()` | red, green and blue, and alpha |
| | `min(other)`, `max(other)`, `lerp(other, t)` | component-wise |
| | `to_array()`, `is_finite()`, `approx(other, eps?)` | |
| | `rgb_to_hsv(c)`, `hsv_to_rgb(c)` | between the two forms; the hue in turns |

## Special functions

`moonbitstack/moonmath/special` is a subpackage for the functions a probability, a physics or a numerical caller reaches for. Every body is written once, in `special/generic`, against an `Ops` algebra of the number type; `special` is the double-precision face of it and `moonnum`'s `Fixed` supplies the arbitrary-precision one, so the two precisions cannot drift apart.

| Function | Meaning |
|:--|:--|
| `gamma(x)`, `lgamma(x)` | the gamma function and its log; Stirling with the reflection below one half |
| `beta(a, b)`, `lbeta(a, b)` | the beta function and its log |
| `digamma(x)`, `polygamma(n, x)` | the logarithmic derivative of gamma, and its `n`-th derivative |
| `gammainc(a, x)`, `gammaincc(a, x)` | the regularised incomplete gamma, lower and upper |
| `incbeta(a, b, x)` | the regularised incomplete beta |
| `erf(x)`, `erfc(x)`, `erfcx(x)`, `erfi(x)` | the error function, its complement, the scaled complement, the imaginary one |
| `erfinv(x)`, `erfcinv(x)` | the inverses of the first two |
| `bessel_j(v, x)`, `bessel_y(v, x)` | the Bessel functions of the first and second kind, real order |
| `bessel_i(v, x)`, `bessel_k(v, x)` | the modified ones |
| `ellipk(m)`, `ellipe(m)`, `ellipkm1(m)` | the complete elliptic integrals, `m` the parameter |
| `ellipkinc(phi, m)`, `ellipeinc(phi, m)` | the incomplete ones |
| `elliprf`, `elliprd`, `elliprc`, `elliprj`, `elliprg` | the Carlson symmetric forms the others are built on |
| `hyper0f1(b, x)`, `hyper1f1(a, b, x)`, `hyper2f1(a, b, c, x)` | the hypergeometric functions |
| `zeta(s)` | the Riemann zeta, above and below one |

```moonbit
let root_pi = @special.gamma(0.5)
let tail = @special.erfc(2.0)
let drum = @special.bessel_j(0.0, 2.4)
```

The arbitrary-precision side runs the same functions on `moonnum`'s `Fixed` — a fixed-point real carried as `mantissa / 2^bits` — at whatever width the caller asks for:

```moonbit
let bits = @moonnum.Fixed::bits_for_digits(50)
let ops = @generic.fixed_ops(bits)
let x = @moonnum.Fixed::of_decimal("0.5", bits)
let value = @generic.gamma(x, ops)
```

`Fixed` lives in `moonbitstack/moonnum`, which is where a number belongs, and `moonmath` depends on it. Its release predates the type, so until `moonnum` cuts a version with it the dependency is resolved from a sibling checkout through `moon.work`:

```
members = [
  ".",
  "../moonnum",
]
```

A checkout of `moonbitstack/moonnum` at branch `feat/bigfloat` alongside this one is therefore required to build. Once the release lands, deleting `moon.work` is the whole of the change; `moon.mod` already names the module.

The precision a caller should expect is not the same for every function, and the tests say so rather than averaging it away. In double the gamma, error, zeta and elliptic families agree with the references to about `1e-15`; the Bessel functions to about `1e-12`, the widest case being a nearly integer order, where the reflection divides by the sine of a small angle; and at fifty and a hundred digits the same table is replayed at `1e-45` and `1e-80`.

`hyper1f1` is the one function here that calls the wider type as a working tool rather than as a check: the body reports the largest term its series formed, and the double-precision face re-runs the sum at forty-five digits and rounds once when that term ran far past the answer. That is what carries the large-parameter region, where the direct sum cancels — against Boost's table, which lives entirely in that region, the worst row goes from `4e-4` to `1.1e-12`.

`hyper2f1` has no such rescue and says so in its doc comment: with parameters of order a hundred and the argument near one, its transformation needs six hundred digits of dynamic range, which no fixed point supplies. It claims the moderate region, as does `hyper0f1`, and a caller outside it should not believe a double from it.

Two independent reference sets back that up. `scripts/gen_special.py` reads `mpmath` at a hundred and thirty working digits and fills both the double and the arbitrary-precision tables. `scripts/gen_boost.py` takes the tables that ship with Boost.Math's own test suite — twenty-seven of them, nine thousand rows — and `boost_check_wbtest.mbt` replays them, every row except a documented sample of the `1F1` table, whose escalated rows are the one place the suite spends real time. The tables are checked in, so a test run needs neither Python, `mpmath` nor a Boost checkout.

## Examples

Four runnable programs, each `moon run`-able on its own:

| Example | What it shows |
|:--|:--|
| `src/examples/01-tour` | the whole surface in one run |
| `src/examples/02-camera` | a camera, what lands on screen, frustum culling, and a pick |
| `src/examples/03-layout` | rectangles, insets and hit testing for a window of panes |
| `src/examples/04-collision` | a ray narrowed from a sphere to a triangle, and a bounce |

## Performance

Throughput on the native backend, `moon bench --target native --release`, single precision, on an x86-64 machine with the 2026-10-23 toolchain. Each row is one operation, measured 64 at a time inside a timed closure; the numbers are the best of three runs.

| Operation | ns | per second |
|:--|--:|--:|
| `Vec3::dot` | 1.9 | 540,000,000 |
| `Vec4::dot` | 1.7 | 600,000,000 |
| `Frustum::intersects_aabb` | 21 | 47,000,000 |
| `Vec3::normalize` | 56 | 18,000,000 |
| `Mat4::transform_point` | 56 | 18,000,000 |
| `Vec3::cross` | 61 | 16,000,000 |
| `Quat::rotate` | 64 | 16,000,000 |
| `Quat::slerp` | 96 | 10,000,000 |
| `Ray3::intersect_aabb` | 97 | 10,000,000 |
| `Ray3::intersect_sphere` | 111 | 9,000,000 |
| `Quat::to_mat3` | 220 | 4,500,000 |
| `Mat4 * Mat4` | 282 | 3,500,000 |
| `Mat4::inverse` | 330 | 3,000,000 |

The first two rows are arithmetic with nothing to build; the rest return a value type, and on this backend a struct is a heap value, so part of every row above them is the allocation of the result. What that means in practice is that an operation returning a `Vec3` costs about the same whether it is a cross product or a normalisation, and that a loop over ten thousand vectors spends much of its time in the allocator rather than in the arithmetic.

## Licence

Apache-2.0.
