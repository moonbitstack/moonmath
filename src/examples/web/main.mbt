///|
/// Hand the page one entry point. The closure becomes a JavaScript function,
/// stored on `globalThis.moonmath`.
extern "js" fn expose(
  project : (Float, Float, Float, Float, Float) -> String,
) -> Unit = "function(project){ globalThis.moonmath = { project: project }; }"

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
fn main {
  expose(project)
}
