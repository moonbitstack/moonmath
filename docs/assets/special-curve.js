(function () {
  "use strict";

  function token(name, fallback) {
    var value = getComputedStyle(document.documentElement)
      .getPropertyValue(name)
      .trim();
    return value || fallback;
  }

  function panel(canvas, xs, series, range, xTicks, yTicks) {
    var ratio = window.devicePixelRatio || 1;
    var rect = canvas.getBoundingClientRect();
    var width = rect.width;
    var height = rect.height;
    if (!width || !height) {
      return;
    }
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    var ctx = canvas.getContext("2d");
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);

    var ink = token("--ink", "#2a1d13");
    var faint = token("--ink-faint", "#7b6448");
    var rule = token("--rule", "#bda884");
    var pad = { left: 34, right: 14, top: 16, bottom: 28 };
    var plotWidth = width - pad.left - pad.right;
    var plotHeight = height - pad.top - pad.bottom;

    function sx(x) {
      return pad.left + ((x - range.xMin) / (range.xMax - range.xMin)) * plotWidth;
    }
    function sy(y) {
      return pad.top + ((range.yMax - y) / (range.yMax - range.yMin)) * plotHeight;
    }

    ctx.strokeStyle = rule;
    ctx.lineWidth = 1;
    ctx.strokeRect(pad.left, pad.top, plotWidth, plotHeight);

    ctx.setLineDash([3, 4]);
    ctx.beginPath();
    ctx.moveTo(pad.left, sy(0));
    ctx.lineTo(width - pad.right, sy(0));
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.fillStyle = faint;
    ctx.font = "12px 'Courier Prime', monospace";
    ctx.textAlign = "center";
    for (var t = 0; t < xTicks.length; t++) {
      ctx.fillText(xTicks[t][0], sx(xTicks[t][1]), height - 9);
    }
    ctx.textAlign = "right";
    for (var v = 0; v < yTicks.length; v++) {
      ctx.fillText(yTicks[v][0], pad.left - 6, sy(yTicks[v][1]) + 4);
    }

    for (var s = 0; s < series.length; s++) {
      var values = series[s].values;
      ctx.strokeStyle = series[s].faint ? faint : ink;
      ctx.lineWidth = series[s].faint ? 1.4 : 1.7;
      ctx.beginPath();
      for (var i = 0; i < values.length; i++) {
        if (values[i] === null) {
          continue;
        }
        var px = sx(xs[i]);
        var py = sy(values[i]);
        if (i === 0) {
          ctx.moveTo(px, py);
        } else {
          ctx.lineTo(px, py);
        }
      }
      ctx.stroke();
    }
  }

  function draw() {
    if (!window.moonmath || !window.moonmath.specialCurve) {
      return;
    }
    var data = JSON.parse(window.moonmath.specialCurve());

    var errorCanvas = document.querySelector("[data-special-curve]");
    if (errorCanvas) {
      panel(
        errorCanvas,
        data.x,
        [{ values: data.erf }, { values: data.erfc, faint: true }],
        { xMin: -3, xMax: 3, yMin: -1.2, yMax: 2.2 },
        [
          ["-3", -3],
          ["0", 0],
          ["3", 3],
        ],
        [
          ["2", 2],
          ["1", 1],
          ["0", 0],
        ]
      );
    }

    var drumCanvas = document.querySelector("[data-bessel-curve]");
    if (drumCanvas) {
      panel(
        drumCanvas,
        data.drumX,
        [{ values: data.j0 }, { values: data.j1, faint: true }],
        { xMin: 0, xMax: 20, yMin: -0.7, yMax: 1.15 },
        [
          ["0", 0],
          ["10", 10],
          ["20", 20],
        ],
        [
          ["1", 1],
          ["0", 0],
        ]
      );
    }
  }

  function ready() {
    draw();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", ready);
  } else {
    ready();
  }
  window.addEventListener("load", draw);
  window.addEventListener("resize", draw);
  var buttons = document.querySelectorAll("[data-theme-toggle]");
  for (var i = 0; i < buttons.length; i++) {
    buttons[i].addEventListener("click", function () {
      setTimeout(draw, 0);
    });
  }
})();
