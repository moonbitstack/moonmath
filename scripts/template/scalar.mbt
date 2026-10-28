// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The ratio of a circle's circumference to its diameter.
pub let pi : {{S}} = 3.14159265358979323846

///|
/// A full turn in radians: `2 * pi`. The period of every angle here.
pub let tau : {{S}} = 6.28318530717958647692

///|
/// Half a turn in radians: `pi / 2`. A quarter of `tau`.
pub let half_pi : {{S}} = 1.57079632679489661923

///|
/// A quarter turn in radians: `pi / 4`, the angle whose tangent is one.
pub let quarter_pi : {{S}} = 0.78539816339744830962

///|
/// The absolute tolerance `approx` falls back on when the caller gives none.
///
/// It is a compromise: large enough to cover the rounding of a handful of
/// operations at this precision, small enough that values a user would call
/// different do not compare equal.
pub let default_epsilon : {{S}} = {{EPS}}

///|
/// The smallest angle, in radians, that `approx` still calls a difference.
let angle_epsilon : {{S}} = {{EPS}}

///|
/// Degrees per radian: `180 / pi`.
let degrees_per_radian : {{S}} = 57.29577951308232087680

///|
/// Radians per degree: `pi / 180`.
let radians_per_degree : {{S}} = 0.01745329251994329577

///|
/// `degrees` converted to radians.
pub fn to_radians(degrees : {{S}}) -> {{S}} {
  degrees * radians_per_degree
}

///|
/// `radians` converted to degrees.
pub fn to_degrees(radians : {{S}}) -> {{S}} {
  radians * degrees_per_radian
}

///|
/// The point `t` of the way from `a` to `b`: `a` at zero, `b` at one.
///
/// `t` outside `0..1` extrapolates, which is what callers building animation
/// curves usually want; clamp the result if it is not.
pub fn lerp(a : {{S}}, b : {{S}}, t : {{S}}) -> {{S}} {
  a + (b - a) * t
}

///|
/// Where `value` sits between `start` and `end`, as a fraction: the inverse of
/// `lerp`.
///
/// Returns zero when the two ends are equal — there is no fraction between
/// them, and zero is the answer that keeps `lerp` from producing a NaN.
pub fn inverse_lerp(start : {{S}}, end : {{S}}, value : {{S}}) -> {{S}} {
  let span : {{S}} = end - start
  if span == 0.0 {
    0.0
  } else {
    (value - start) / span
  }
}

///|
/// `value` taken from the range `from_start..from_end` and placed in
/// `to_start..to_end`.
///
/// It is `lerp(to_start, to_end, inverse_lerp(from_start, from_end, value))`:
/// the value keeps its position within the range, and values outside the source
/// range land outside the destination range by the same proportion.
pub fn remap(
  value : {{S}},
  from_start : {{S}},
  from_end : {{S}},
  to_start : {{S}},
  to_end : {{S}},
) -> {{S}} {
  lerp(to_start, to_end, inverse_lerp(from_start, from_end, value))
}

///|
/// A smooth step from zero at `start` to one at `end`, zero slope at both ends.
///
/// The curve is `3t² - 2t³` over the normalised position, which is the cheapest
/// easing whose first derivative vanishes at both ends — no visible corner where
/// the animation starts or stops.
///
/// A zero-width range has no slope to smooth: it steps at `start`.
pub fn smoothstep(start : {{S}}, end : {{S}}, value : {{S}}) -> {{S}} {
  if start == end {
    if value < start {
      0.0
    } else {
      1.0
    }
  } else {
    let t = clamp01((value - start) / (end - start))
    t * t * (3.0 - 2.0 * t)
  }
}

///|
/// `value` folded into `0..span`.
///
/// Angles and texture coordinates repeat, and a value that has run past the end
/// of its range has to come back to the start rather than stop there. A span of
/// zero or less has nothing to fold into and gives zero.
///
/// ```mbt check
/// test {
///   assert_eq(@{{PKG}}.wrap(7.5, 5.0), 2.5)
///   assert_eq(@{{PKG}}.wrap(-1.0, 5.0), 4.0)
/// }
/// ```
pub fn wrap(value : {{S}}, span : {{S}}) -> {{S}} {
  if span <= 0.0 {
    0.0
  } else {
    let folded : {{S}} = value - span * (value / span).floor()
    // `floor` of a value already in range gives the value back unchanged, but
    // rounding can still land exactly on the span; fold that one step back so
    // the result stays half-open.
    if folded >= span {
      0.0
    } else {
      folded
    }
  }
}

///|
/// `value` folded into `start..end`.
///
/// `wrap(value - start, end - start) + start`, with the same half-open result.
pub fn wrap_range(value : {{S}}, start : {{S}}, end : {{S}}) -> {{S}} {
  start + wrap(value - start, end - start)
}

///|
/// Whether two numbers are the same to within `eps`.
///
/// Without an epsilon the comparison uses `default_epsilon`, scaled up for
/// values whose magnitude would swamp an absolute tolerance. Equality itself is
/// exact — `==` on two numbers that took different paths to the same place
/// rarely holds — so this is the test callers want for results of arithmetic.
///
/// ```mbt check
/// test {
///   let a : {{S}} = 0.1 + 0.2
///   assert_true(@{{PKG}}.approx(a, 0.3))
///   assert_false(@{{PKG}}.approx(a, 0.31))
///   assert_true(@{{PKG}}.approx(a, 0.31, eps=0.02))
/// }
/// ```
pub fn approx(a : {{S}}, b : {{S}}, eps? : {{S}}) -> Bool {
  let limit : {{S}} = match eps {
    Some(eps) => eps
    None => default_epsilon
  }
  if a == b {
    true
  } else if a.is_nan() || b.is_nan() {
    false
  } else {
    (a - b).abs() <= limit
  }
}

///|
/// Whether two angles — in radians, wrapping at `tau` — point the same way.
///
/// `0` and `tau` are the same direction, and so are `-pi` and `pi`; comparing
/// them as plain numbers says otherwise.
pub fn approx_angle(a : {{S}}, b : {{S}}, eps? : {{S}}) -> Bool {
  let limit : {{S}} = match eps {
    Some(eps) => eps
    None => angle_epsilon
  }
  let difference = (wrap(a - b + half_pi, tau) - half_pi).abs()
  difference <= limit
}

///|
/// `value` pinned to `0..1`.
pub fn clamp01(value : {{S}}) -> {{S}} {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}
