(function () {
  "use strict";

  function token(name, fallback) {
    var value = getComputedStyle(document.documentElement)
      .getPropertyValue(name)
      .trim();
    return value || fallback;
  }

  function draw() {
    var canvas = document.querySelector("[data-special-curve]");
    if (!canvas || !window.moonmath || !window.moonmath.specialCurve) {
      return;
    }
    var data = JSON.parse(window.moonmath.specialCurve());
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
    var xMin = -3;
    var xMax = 3;
    var yMin = -1.2;
    var yMax = 2.2;

    function sx(x) {
      return pad.left + ((x - xMin) / (xMax - xMin)) * plotWidth;
    }
    function sy(y) {
      return pad.top + ((yMax - y) / (yMax - yMin)) * plotHeight;
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
    ctx.fillText("-3", sx(-3), height - 9);
    ctx.fillText("0", sx(0), height - 9);
    ctx.fillText("3", sx(3), height - 9);
    ctx.textAlign = "right";
    ctx.fillText("1", pad.left - 6, sy(1) + 4);
    ctx.fillText("0", pad.left - 6, sy(0) + 4);

    function line(values, color, weight) {
      ctx.strokeStyle = color;
      ctx.lineWidth = weight;
      ctx.beginPath();
      for (var i = 0; i < values.length; i++) {
        var px = sx(data.x[i]);
        var py = sy(values[i]);
        if (i === 0) {
          ctx.moveTo(px, py);
        } else {
          ctx.lineTo(px, py);
        }
      }
      ctx.stroke();
    }

    line(data.erf, ink, 1.7);
    line(data.erfc, faint, 1.4);
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
