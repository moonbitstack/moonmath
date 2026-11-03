///|
/// Hand the page one entry point. The closure becomes a JavaScript function,
/// stored on `globalThis.moonmath`.
extern "js" fn expose(
  project : (Float, Float, Float, Float, Float) -> String,
  special_curve : () -> String,
) -> Unit = "function(project, curve){ globalThis.moonmath = { project: project, specialCurve: curve }; }"

///|
/// A number as JavaScript reads it: enough digits to see the value, and no
/// exponent that JSON would reject.
fn number(value : Float) -> String {
  if value.is_nan() || value.is_inf() {
    "null"
  } else {
    value.to_string()
  }
}

///|
/// The scene the page draws: a unit cube seen from a fixed offset, `distance`
/// along +z, through a perspective camera, as the page needs it — the
/// view-projection matrix, the projected corners, the eye, the depth the near
/// and far planes came out at, and the depth sampled across the range.
///
/// `field_of_view` is in degrees, which is where the page's slider lives; the
/// library itself only speaks radians.
fn project(
  field_of_view : Float,
  distance : Float,
  near : Float,
  far : Float,
  aspect : Float,
) -> String {
  let fov = @moonmath.to_radians(field_of_view)
  let eye = @moonmath.Vec3::new(2.6, 2.2, distance)
  let view = @moonmath.Mat4::look_at(
    eye,
    @moonmath.Vec3::zero(),
    @moonmath.Vec3::unit_y(),
  )
  let projection = @moonmath.Mat4::perspective(fov, aspect, near, far)
  let view_projection = projection * view
  let corners : Array[(Float, Float, Float)] = [
    (-1.0, -1.0, -1.0),
    (1.0, -1.0, -1.0),
    (1.0, 1.0, -1.0),
    (-1.0, 1.0, -1.0),
    (-1.0, -1.0, 1.0),
    (1.0, -1.0, 1.0),
    (1.0, 1.0, 1.0),
    (-1.0, 1.0, 1.0),
  ]
  let mut points = ""
  for i in 0..<8 {
    let (x, y, z) = corners[i]
    let ndc = view_projection.transform_point(@moonmath.Vec3::new(x, y, z))
    if i > 0 {
      points = points + ","
    }
    points = points +
      "[" +
      number(ndc.x) +
      "," +
      number(ndc.y) +
      "," +
      number(ndc.z) +
      "]"
  }
  let matrix = view_projection.to_array()
  let mut cells = ""
  for i in 0..<16 {
    if i > 0 {
      cells = cells + ","
    }
    cells = cells + number(matrix[i])
  }
  // In view space the camera looks down -z, so the near plane is the point
  // (0, 0, -near) and the far plane (0, 0, -far). The projection alone takes
  // them to the two ends of the depth range.
  let depth_near = projection.transform_point(
    @moonmath.Vec3::new(0.0, 0.0, -near),
  )
  let depth_far = projection.transform_point(
    @moonmath.Vec3::new(0.0, 0.0, -far),
  )
  // One sample per step of a walk from the near plane to the far one: the shape
  // of the curve is the whole reason z is stored the way it is.
  let steps = 64
  let last = Float::from_double((steps - 1).to_double())
  let mut curve = ""
  for i in 0..<steps {
    let along = near + (far - near) * (Float::from_double(i.to_double()) / last)
    let depth = projection.transform_point(
      @moonmath.Vec3::new(0.0, 0.0, -along),
    )
    if i > 0 {
      curve = curve + ","
    }
    curve = curve + number(depth.z)
  }
  "{\"matrix\":[" +
  cells +
  "],\"points\":[" +
  points +
  "],\"near\":" +
  number(depth_near.z) +
  ",\"far\":" +
  number(depth_far.z) +
  ",\"eye\":[" +
  number(eye.x) +
  "," +
  number(eye.y) +
  "," +
  number(eye.z) +
  "],\"curve\":[" +
  curve +
  "]}"
}

///|
/// The curves the page plots, as JSON.
///
/// The page draws them; the numbers come from this library's `special` package
/// compiled to JavaScript, so the picture is the function itself and not a
/// second implementation of it.
///
/// Two panels: the error function against its complement over `-3..3`, and the
/// two lowest modes of a circular drum, `J_0` and `J_1`, over `0..20` — the
/// second one is where the Bessel series gives way to the asymptotic expansion,
/// and the curve does not know.
fn special_curve() -> String {
  let erf_steps = 121
  let erf_from : Float = -3.0
  let erf_to : Float = 3.0
  let last_erf = Float::from_double((erf_steps - 1).to_double())
  let mut xs = ""
  let mut raised = ""
  let mut lowered = ""
  for i in 0..<erf_steps {
    let t = Float::from_double(i.to_double()) / last_erf
    let x = erf_from + (erf_to - erf_from) * t
    let up = @special.erf(x.to_double())
    let down = @special.erfc(x.to_double())
    if i > 0 {
      xs = xs + ","
      raised = raised + ","
      lowered = lowered + ","
    }
    xs = xs + number(x)
    raised = raised + number(Float::from_double(up))
    lowered = lowered + number(Float::from_double(down))
  }
  let drum_steps = 241
  let drum_to : Float = 20.0
  let last_drum = Float::from_double((drum_steps - 1).to_double())
  let mut drum_xs = ""
  let mut zeroth = ""
  let mut first = ""
  for i in 0..<drum_steps {
    let x = drum_to * (Float::from_double(i.to_double()) / last_drum)
    let zero = @special.bessel_j(0.0, x.to_double())
    let one = @special.bessel_j(1.0, x.to_double())
    if i > 0 {
      drum_xs = drum_xs + ","
      zeroth = zeroth + ","
      first = first + ","
    }
    drum_xs = drum_xs + number(x)
    zeroth = zeroth + number(Float::from_double(zero))
    first = first + number(Float::from_double(one))
  }
  "{\"x\":[" +
  xs +
  "],\"erf\":[" +
  raised +
  "],\"erfc\":[" +
  lowered +
  "],\"drumX\":[" +
  drum_xs +
  "],\"j0\":[" +
  zeroth +
  "],\"j1\":[" +
  first +
  "]}"
}

///|
fn main {
  expose(project, special_curve)
}
