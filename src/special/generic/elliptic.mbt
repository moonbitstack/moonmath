// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The elliptic integrals through the Carlson symmetric forms. One duplication
// algorithm per form, and every Legendre integral is then a short expression in
// them — the complete ones are two calls, the incomplete ones three. That is why
// the symmetric forms are the thing to write: a caller who needs `K`, `E`, `F` or
// `E(phi, m)` does not get four algorithms that have to be kept in step.

///|
/// The Carlson symmetric integral of the first kind,
/// `R_F(x, y, z) = 1/2 ∫_0^∞ dt / sqrt((t+x)(t+y)(t+z))`.
///
/// The duplication step replaces the three arguments by combinations that are
/// closer together, and the differences shrink by four each round, so the series
/// that finishes the job only has to be right to sixth order.
pub fn[T] elliprf(x : T, y : T, z : T, ops : Ops[T]) -> T {
  let four = (ops.from_int)(4)
  let three = (ops.from_int)(3)
  let tolerance = (ops.from_decimal)("1e-\{ops.digits / 6 + 3}")
  let mut x = x
  let mut y = y
  let mut z = z
  let mut round : Int32 = 0
  while round < 100 {
    let sx = (ops.sqrt)(x)
    let sy = (ops.sqrt)(y)
    let sz = (ops.sqrt)(z)
    let lambda = (ops.add)((ops.mul)(sx, (ops.add)(sy, sz)), (ops.mul)(sy, sz))
    x = (ops.div)((ops.add)(x, lambda), four)
    y = (ops.div)((ops.add)(y, lambda), four)
    z = (ops.div)((ops.add)(z, lambda), four)
    let average = (ops.div)((ops.add)((ops.add)(x, y), z), three)
    let dx = (ops.div)((ops.sub)(average, x), average)
    let dy = (ops.div)((ops.sub)(average, y), average)
    let dz = (ops.div)((ops.sub)(average, z), average)
    if (ops.lt)(largest(dx, dy, dz, ops), tolerance) {
      let e2 = (ops.add)(
        (ops.add)((ops.mul)(dx, dy), (ops.mul)(dy, dz)),
        (ops.mul)(dz, dx),
      )
      let e3 = (ops.mul)((ops.mul)(dx, dy), dz)
      // `1 - E2/10 + E3/14 + E2²/24 - 3 E2 E3/44`, the sixth-order finish.
      let correction = (ops.add)(
        (ops.add)(
          (ops.sub)(ops.one, (ops.div)(e2, (ops.from_int)(10))),
          (ops.div)(e3, (ops.from_int)(14)),
        ),
        (ops.sub)(
          (ops.div)((ops.mul)(e2, e2), (ops.from_int)(24)),
          (ops.div)(
            (ops.mul)((ops.from_int)(3), (ops.mul)(e2, e3)),
            (ops.from_int)(44),
          ),
        ),
      )
      return (ops.div)(correction, (ops.sqrt)(average))
    }
    round = round + 1
  }
  abort("elliprf: the duplication did not settle")
}

///|
/// The Carlson symmetric integral of the second kind,
/// `R_D(x, y, z) = 3/2 ∫_0^∞ dt / ((t+z) sqrt((t+x)(t+y)(t+z)))`.
pub fn[T] elliprd(x : T, y : T, z : T, ops : Ops[T]) -> T {
  let four = (ops.from_int)(4)
  let three = (ops.from_int)(3)
  // `R_D`'s finishing series carries one order fewer than `R_F`'s, so the
  // duplication has to run further before that series is the only error left.
  let tolerance = (ops.from_decimal)("1e-\{ops.digits / 2 + 2}")
  let mut x = x
  let mut y = y
  let mut z = z
  let mut sum = ops.zero
  let mut factor = ops.one
  let mut round : Int32 = 0
  while round < 100 {
    let sx = (ops.sqrt)(x)
    let sy = (ops.sqrt)(y)
    let sz = (ops.sqrt)(z)
    let lambda = (ops.add)((ops.mul)(sx, (ops.add)(sy, sz)), (ops.mul)(sy, sz))
    sum = (ops.add)(sum, (ops.div)(factor, (ops.mul)(sz, (ops.add)(z, lambda))))
    factor = (ops.div)(factor, four)
    x = (ops.div)((ops.add)(x, lambda), four)
    y = (ops.div)((ops.add)(y, lambda), four)
    z = (ops.div)((ops.add)(z, lambda), four)
    let average = (ops.div)((ops.add)((ops.add)(x, y), z), three)
    let dx = (ops.div)((ops.sub)(average, x), average)
    let dy = (ops.div)((ops.sub)(average, y), average)
    let dz = (ops.div)((ops.sub)(average, z), average)
    if (ops.lt)(largest(dx, dy, dz, ops), tolerance) {
      let e2 = (ops.add)(
        (ops.add)((ops.mul)(dx, dy), (ops.mul)(dy, dz)),
        (ops.mul)(dz, dx),
      )
      let e3 = (ops.mul)((ops.mul)(dx, dy), dz)
      let correction = (ops.add)(
        (ops.add)(
          ops.one,
          (ops.div)((ops.mul)((ops.from_int)(3), e2), (ops.from_int)(14)),
        ),
        (ops.add)(
          (ops.div)(e3, (ops.from_int)(6)),
          (ops.sub)(
            (ops.div)(
              (ops.mul)((ops.from_int)(3), (ops.mul)(e2, e2)),
              (ops.from_int)(104),
            ),
            (ops.div)(
              (ops.mul)((ops.from_int)(9), (ops.mul)(e3, e2)),
              (ops.from_int)(88),
            ),
          ),
        ),
      )
      let root = (ops.sqrt)(average)
      return (ops.add)(
        (ops.mul)(three, sum),
        (ops.div)((ops.mul)(factor, correction), (ops.mul)(average, root)),
      )
    }
    round = round + 1
  }
  abort("elliprd: the duplication did not settle")
}

///|
/// The Carlson symmetric integral of the third kind, degenerate form,
/// `R_C(x, y) = 1/2 ∫_0^∞ dt / ((t+y) sqrt(t+x))`.
///
/// It is `R_F(x, y, y)` — the third kind with two equal arguments — so it needs
/// no algorithm of its own.
pub fn[T] elliprc(x : T, y : T, ops : Ops[T]) -> T {
  elliprf(x, y, y, ops)
}

///|
/// The Carlson symmetric integral of the second kind, completely symmetric form,
/// `R_G(x, y, z) = 1/4 ∫_0^∞ dt / sqrt((t+x)(t+y)(t+z)) · (x/(t+x) + y/(t+y) + z/(t+z))`.
///
/// It follows from `R_F` and `R_D` by
/// `2 R_G = z R_F - (x - z)(y - z) R_D / 3 + sqrt(x y / z)`, which is one call to
/// each of the two forms above.
pub fn[T] elliprg(x : T, y : T, z : T, ops : Ops[T]) -> T {
  if (ops.is_zero)(z) {
    // The relation divides by `z`; the limit from the series is finite.
    abort("elliprg: z must be positive")
  }
  let two = (ops.from_int)(2)
  let three = (ops.from_int)(3)
  let first = (ops.mul)(z, elliprf(x, y, z, ops))
  let second = (ops.div)(
    (ops.mul)(
      (ops.mul)((ops.sub)(x, z), (ops.sub)(y, z)),
      elliprd(x, y, z, ops),
    ),
    three,
  )
  let third = (ops.sqrt)((ops.div)((ops.mul)(x, y), z))
  (ops.div)((ops.add)((ops.sub)(first, second), third), two)
}

///|
/// The complete elliptic integral of the first kind, `K(m)`, with `m` the
/// parameter (`m = k²`).
///
/// `K(m) = R_F(0, 1 - m, 1)`.
pub fn[T] ellipk(m : T, ops : Ops[T]) -> T {
  let one = ops.one
  elliprf(ops.zero, (ops.sub)(one, m), one, ops)
}

///|
/// The complete elliptic integral of the second kind, `E(m)`.
///
/// `E(m) = R_F(0, 1 - m, 1) - (m/3) R_D(0, 1 - m, 1)`.
pub fn[T] ellipe(m : T, ops : Ops[T]) -> T {
  let one = ops.one
  let three = (ops.from_int)(3)
  let first = elliprf(ops.zero, (ops.sub)(one, m), one, ops)
  let second = (ops.div)(
    (ops.mul)(m, elliprd(ops.zero, (ops.sub)(one, m), one, ops)),
    three,
  )
  (ops.sub)(first, second)
}

///|
/// The complete elliptic integral of the first kind from the complementary
/// parameter, `K(1 - m1)`. The form a caller reaches for when `m` is a hair below
/// one, where `K(m)` itself would be given to the subtraction as garbage.
pub fn[T] ellipkm1(m1 : T, ops : Ops[T]) -> T {
  elliprf(ops.zero, m1, ops.one, ops)
}

///|
/// The incomplete elliptic integral of the first kind,
/// `F(phi, m) = ∫_0^phi dθ / sqrt(1 - m sin²θ)`.
///
/// `F = sin(phi) R_F(cos²phi, 1 - m sin²phi, 1)`.
pub fn[T] ellipkinc(phi : T, m : T, ops : Ops[T]) -> T {
  let sine = (ops.sin)(phi)
  let cosine = (ops.cos)(phi)
  let squared = (ops.mul)(sine, sine)
  let first = (ops.mul)(cosine, cosine)
  let second = (ops.sub)(ops.one, (ops.mul)(m, squared))
  (ops.mul)(sine, elliprf(first, second, ops.one, ops))
}

///|
/// The incomplete elliptic integral of the second kind,
/// `E(phi, m) = ∫_0^phi sqrt(1 - m sin²θ) dθ`.
///
/// `E = sin(phi) R_F(cos²phi, 1 - m sin²phi, 1) - (m/3) sin³(phi) R_D(...)`.
pub fn[T] ellipeinc(phi : T, m : T, ops : Ops[T]) -> T {
  let three = (ops.from_int)(3)
  let sine = (ops.sin)(phi)
  let cosine = (ops.cos)(phi)
  let squared = (ops.mul)(sine, sine)
  let first = (ops.mul)(cosine, cosine)
  let second = (ops.sub)(ops.one, (ops.mul)(m, squared))
  let base = (ops.mul)(sine, elliprf(first, second, ops.one, ops))
  let tail = (ops.div)(
    (ops.mul)(
      (ops.mul)(m, (ops.mul)(squared, sine)),
      elliprd(first, second, ops.one, ops),
    ),
    three,
  )
  (ops.sub)(base, tail)
}

///|
/// The largest of three values, by the `lt` of the algebra.
fn[T] largest(a : T, b : T, c : T, ops : Ops[T]) -> T {
  let mut best = (ops.abs)(a)
  let magnitude_b = (ops.abs)(b)
  if (ops.lt)(best, magnitude_b) {
    best = magnitude_b
  }
  let magnitude_c = (ops.abs)(c)
  if (ops.lt)(best, magnitude_c) {
    best = magnitude_c
  }
  best
}
