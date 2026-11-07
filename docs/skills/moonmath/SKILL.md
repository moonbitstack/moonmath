---
name: moonmath
description: Vectors, matrices, quaternions, rays and colours for MoonBit, column-major and right-handed, in single and double precision — plus a special-function package (gamma, error, Bessel, elliptic, hypergeometric, zeta) in double and at arbitrary precision. Reach for it when you need 3D transforms for a renderer or a simulation, or a special-function value you would otherwise hand-roll.
---

# moonmath

## Add it

```moonbit
import {
  "moonbitstack/moonmath",
  "moonbitstack/moonmath/special",
}
```

`moon add moonbitstack/moonmath` first. The root package is the single-precision shapes, `moonbitstack/moonmath/f64` the same shapes at `Double`, `special` the special functions at `Double`, and `special/generic` the same bodies written once against an `Ops` algebra so they run at any width.

## A transform

```moonbit
let placed = @moonmath.Mat4::from_trs(
  @moonmath.Trs::new(
    @moonmath.Vec3::new(1.0, 0.0, 0.0),
    @moonmath.Quat::identity(),
    @moonmath.Vec3::splat(2.0),
  ),
)
let landed = placed.transform_point(@moonmath.Vec3::one())
```

`Trs` is translation, rotation, scale, in that order; `Mat4::to_trs` reads one back and returns `None` for a matrix with shear or a singular linear part.

## A special function

```moonbit
let root_pi = @special.gamma(0.5)
let drum = @special.bessel_j(0.0, 2.4)
let confluent = @special.hyper1f1(1.0, 2.0, 0.5)
```

## The same value at fifty digits

```moonbit
let ops = @generic.bigfloat_ops(50)
let half = (ops.from_decimal)("0.5")
let wide = @generic.gamma(half, ops)
```

## The rules that catch people out

- **Matrices are column-major.** `Mat4::from_cols(c0, c1, c2, c3)` takes columns, and a translation lives in `c3`. Copy a `Mat4` straight into a GPU buffer; do not transpose it first.
- **The handedness is right, and so is the clip depth.** `Mat4::perspective` maps to a `0..1` depth range, which is what WebGPU and D3D want, not the `-1..1` of OpenGL.
- **`Float` is the default, `Double` is a separate package.** `@moonmath.Vec3` is `Float`; `@f64.Vec3` is the same API at `Double`. A position past a few kilometres loses its low bits in `Float`.
- **An inverse is an option.** `Mat4::inverse` returns `Mat4?` and answers `None` on a singular matrix rather than filling the result with infinities.
- **`special` is not free of poles.** `@special.gamma` at a non-positive integer, and `hyper1f1` at a non-positive integer `b`, are poles; the functions report them the way `Float` does rather than raising.
