// The workshop: four dials, one matrix, and the cube the matrix projects.
//
// The numbers are not computed here. `globalThis.moonmath.project` is this
// library compiled to JavaScript — look_at, perspective, the matrix product and
// transform_point all run in the page — and this file only turns the answers
// into ink.

(function () {
  "use strict";

  var screen = document.querySelector("[data-screen]");
  if (!screen) return;

  var canvas = screen.querySelector("canvas");
  var ctx = canvas.getContext("2d");
  var stamp = screen.querySelector(".stamp");
  var matrixBox = document.querySelector("[data-matrix]");
  var curveBox = document.querySelector("[data-curve]");
  var eyeBox = document.querySelector("[data-eye]");
  var nearBox = document.querySelector("[data-near]");
  var farBox = document.querySelector("[data-far]");

  var state = { fov: 30, distance: 6.5, near: 0.1, far: 60 };

  // The twelve edges of the cube, with the two faces each one belongs to. An
  // edge is hidden when both of its faces face away from the eye.
  var EDGES = [
    [0, 1, "ny", "nz"],
    [1, 2, "px", "nz"],
    [2, 3, "py", "nz"],
    [3, 0, "nx", "nz"],
    [4, 5, "ny", "pz"],
    [5, 6, "px", "pz"],
    [6, 7, "py", "pz"],
    [7, 4, "nx", "pz"],
    [0, 4, "nx", "ny"],
    [1, 5, "px", "ny"],
    [2, 6, "px", "py"],
    [3, 7, "nx", "py"],
  ];

  var FACES = {
    px: [1, 0, 0],
    nx: [-1, 0, 0],
    py: [0, 1, 0],
    ny: [0, -1, 0],
    pz: [0, 0, 1],
    nz: [0, 0, -1],
  };

  var CORNERS = [
    [-1, -1, -1],
    [1, -1, -1],
    [1, 1, -1],
    [-1, 1, -1],
    [-1, -1, 1],
    [1, -1, 1],
    [1, 1, 1],
    [-1, 1, 1],
  ];

  function ink() {
    var style = getComputedStyle(document.documentElement);
    return {
      line: style.getPropertyValue("--ink").trim() || "#2a1d13",
      faint: style.getPropertyValue("--ink-faint").trim() || "#7b6448",
      rubric: style.getPropertyValue("--rubric").trim() || "#8f2d18",
      paper: style.getPropertyValue("--paper-plate").trim() || "#e9dabd",
    };
  }

  function size() {
    var ratio = Math.min(window.devicePixelRatio || 1, 2);
    var width = screen.clientWidth;
    var height = screen.clientHeight;
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    return { width: width, height: height };
  }

  function visibleFace(name, eye) {
    var normal = FACES[name];
    var centre = normal; // the centre of a face of the unit cube is its normal
    var towards = [
      eye[0] - centre[0],
      eye[1] - centre[1],
      eye[2] - centre[2],
    ];
    return (
      normal[0] * towards[0] + normal[1] * towards[1] + normal[2] * towards[2] >
      0
    );
  }

  function drawScene(data, box) {
    var palette = ink();
    var width = box.width;
    var height = box.height;
    ctx.clearRect(0, 0, width, height);

    var seen = {};
    Object.keys(FACES).forEach(function (name) {
      seen[name] = visibleFace(name, data.eye);
    });

    // The canvas is the viewport, so the sheet's own proportions are the ones
    // the projection was built for: one unit of ndc per half sheet, each way.
    function place(point) {
      return [
        (0.5 + point[0] * 0.45) * width,
        (0.5 - point[1] * 0.45) * height,
      ];
    }

    function line(a, b, dashed) {
      var p = place(a);
      var q = place(b);
      ctx.beginPath();
      ctx.setLineDash(dashed ? [4, 4] : []);
      ctx.moveTo(p[0], p[1]);
      ctx.lineTo(q[0], q[1]);
      ctx.stroke();
    }

    ctx.lineCap = "round";
    ctx.lineJoin = "round";

    // The far edges first, so the near ones lie over them.
    EDGES.forEach(function (edge) {
      if (seen[edge[2]] || seen[edge[3]]) return;
      ctx.strokeStyle = palette.faint;
      ctx.lineWidth = 0.9;
      line(data.points[edge[0]], data.points[edge[1]], true);
    });

    EDGES.forEach(function (edge) {
      if (!(seen[edge[2]] || seen[edge[3]])) return;
      ctx.strokeStyle = palette.line;
      ctx.lineWidth = 1.25;
      line(data.points[edge[0]], data.points[edge[1]], false);
    });

    // A small ink dot at the nearest corner of the box, so the eye has
    // something to sit against.
    var nearest = 0;
    for (var i = 1; i < data.points.length; i++) {
      if (data.points[i][2] < data.points[nearest][2]) nearest = i;
    }
    var dot = place(data.points[nearest]);
    ctx.setLineDash([]);
    ctx.fillStyle = palette.rubric;
    ctx.beginPath();
    ctx.arc(dot[0], dot[1], 2, 0, Math.PI * 2);
    ctx.fill();
  }

  function format(value) {
    if (value === null || value === undefined) return "—";
    if (Math.abs(value) < 5e-5) return "0";
    if (Math.abs(value) >= 1000 || Math.abs(value) < 1e-3) {
      return value.toExponential(2);
    }
    return value.toFixed(4);
  }

  function drawMatrix(data) {
    if (!matrixBox) return;
    var cells = [];
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        var value = data.matrix[column * 4 + row];
        var hot = row === 2 ? ' class="hot"' : "";
        cells.push("<span" + hot + ">" + format(value) + "</span>");
      }
    }
    matrixBox.innerHTML = cells.join("");
  }

  function drawCurve(data) {
    if (!curveBox) return;
    var w = 260;
    var h = 130;
    var left = 26;
    var right = 8;
    var top = 8;
    var bottom = 24;
    var curve = data.curve || [];
    if (!curve.length) return;
    var path = [];
    curve.forEach(function (depth, index) {
      var x = left + ((w - left - right) * index) / (curve.length - 1);
      var y = top + (h - top - bottom) * (1 - Math.min(Math.max(depth, 0), 1));
      path.push((index ? "L" : "M") + x.toFixed(1) + " " + y.toFixed(1));
    });

    var svg =
      '<svg viewBox="0 0 ' +
      w +
      " " +
      h +
      '" role="img" aria-label="Depth plotted against distance from the eye; it rises to one almost at once.">' +
      '<path class="ink-faint" d="M' +
      left +
      " " +
      top +
      " V" +
      (h - bottom) +
      " H" +
      (w - right) +
      '"/>' +
      '<path class="ink-dash" d="M' +
      left +
      " " +
      top +
      " H" +
      (w - right) +
      '"/>' +
      '<path class="ink" d="' +
      path.join(" ") +
      '" style="stroke-width: 1.4"/>' +
      '<text class="ink-label" x="2" y="' +
      (top + 7) +
      '">1</text>' +
      '<text class="ink-label" x="2" y="' +
      (h - bottom + 1) +
      '">0</text>' +
      '<text class="ink-label" x="' +
      left +
      '" y="' +
      (h - 6) +
      '">near</text>' +
      '<text class="ink-label" x="' +
      (w - right - 24) +
      '" y="' +
      (h - 6) +
      '">far</text>' +
      "</svg>" +
      '<p class="cap">depth, against distance from the eye</p>';
    curveBox.innerHTML = svg;
  }

  function update() {
    var box = size();
    if (!globalThis.moonmath || !globalThis.moonmath.project) {
      if (stamp) {
        stamp.classList.add("bad");
        stamp.textContent =
          "the library is not loaded here; it is compiled when this site is built";
      }
      return;
    }
    var aspect = box.width / box.height;
    var raw = globalThis.moonmath.project(
      state.fov,
      state.distance,
      state.near,
      state.far,
      aspect,
    );
    var data;
    try {
      data = JSON.parse(raw);
    } catch (e) {
      if (stamp) {
        stamp.classList.add("bad");
        stamp.textContent = "the library returned something unreadable";
      }
      return;
    }
    if (stamp) {
      stamp.classList.remove("bad");
      stamp.textContent = "drawn from the matrix the library returned";
    }
    drawScene(data, box);
    drawMatrix(data);
    drawCurve(data);
    if (eyeBox) {
      eyeBox.textContent =
        "eye (" +
        data.eye[0].toFixed(2) +
        ", " +
        data.eye[1].toFixed(2) +
        ", " +
        data.eye[2].toFixed(2) +
        ")";
    }
    if (nearBox) nearBox.textContent = format(data.near);
    if (farBox) farBox.textContent = format(data.far);
  }

  document.querySelectorAll("[data-dial]").forEach(function (input) {
    var key = input.getAttribute("data-dial");
    var value = input.parentElement.querySelector(".value");
    function show() {
      var unit = input.getAttribute("data-unit") || "";
      value.textContent = input.value + unit;
    }
    state[key] = parseFloat(input.value);
    show();
    input.addEventListener("input", function () {
      state[key] = parseFloat(input.value);
      show();
      update();
    });
  });

  var frame = 0;
  window.addEventListener("resize", function () {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(update);
  });

  document.addEventListener("moonmath:theme", function () {
    update();
  });

  update();
})();
