// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Laying out a window's worth of panes, and finding what the pointer is over:
/// rectangles, integer cells and a little arithmetic between them.
///
///     moon run src/examples/03-layout
#coverage.skip
fn main {
  let window = @moonmath.Rect::from_xywh(0.0, 0.0, 1024.0, 720.0)
  println("window: \{window}")

  // A sidebar on the left, its content inset by a gutter, and a grid of cells
  // inside the remaining area.
  let gutter : Float = 16.0
  let sidebar = @moonmath.Rect::from_xywh(
    window.min().x,
    window.min().y,
    240.0,
    window.height(),
  )
  let content = @moonmath.Rect::from_xywh(
    sidebar.max().x,
    window.min().y,
    window.width() - sidebar.width(),
    window.height(),
  ).inset(gutter)
  println("sidebar: \{sidebar}")
  println("content: \{content}")

  let grid = @moonmath.UVec2::new(4, 3)
  let cell = @moonmath.Vec2::new(
    content.width() / grid.as_vec2().x,
    content.height() / grid.as_vec2().y,
  )
  println("cell size: \{cell}")

  println("\n-- what the pointer is over")
  let pointer = @moonmath.Vec2::new(600.0, 300.0)
  println("pointer: \{pointer}")
  println("in the window: \{window.contains(pointer)}")
  println("in the sidebar: \{sidebar.contains(pointer)}")
  println("in the content area: \{content.contains(pointer)}")
  // Which cell of the grid, counted from the content area's corner.
  let inside = pointer - content.min()
  let index = @moonmath.IVec2::new(
    (inside.x / cell.x).to_int(),
    (inside.y / cell.y).to_int(),
  )
  println("cell index: \{index}")
  let clamped = index.clamp(@moonmath.IVec2::zero(), @moonmath.IVec2::new(3, 2))
  println("clamped to the grid: \{clamped}")

  println("\n-- two panes that overlap")
  let toast = @moonmath.Rect::from_xywh(800.0, 600.0, 200.0, 100.0)
  println("toast: \{toast}")
  println("overlaps the window: \{toast.intersects(window)}")
  match window.intersection(toast) {
    Some(shared) => println("shared area: \{shared.area()}")
    None => println("they share nothing")
  }
  // Growing a rectangle is insetting it by a negative amount.
  println("toast with a shadow: \{toast.inset(-4.0)}")

  println("\n-- a cell and its surroundings")
  let corner = @moonmath.Aabb2::from_center_half_extents(
    @moonmath.Vec2::splat(32.0),
    @moonmath.Vec2::splat(32.0),
  )
  println("cell around (32, 32): \{corner}")
  println("hit by the pointer: \{corner.contains_point(pointer)}")
  match
    @moonmath.Ray2::new(pointer, @moonmath.Vec2::unit_x()).intersect_aabb(
      corner,
    ) {
    Some(t) => println("a ray from the pointer hits it at t = \{t}")
    None => println("a ray from the pointer misses it")
  }
}
