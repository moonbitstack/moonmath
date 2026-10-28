// moonmath: the small amount of behaviour the paper needs — a lamp to read by,
// a copy button, the formulae, and the mark that says where you are.

(function () {
  "use strict";

  var root = document.documentElement;

  // ---- the lamp ----

  function setTheme(theme) {
    root.setAttribute("data-theme", theme);
    try {
      localStorage.setItem("moonmath-theme", theme);
    } catch (e) {
      /* a reader who keeps no notes */
    }
    var button = document.querySelector("[data-theme-toggle]");
    if (button) {
      button.setAttribute(
        "aria-label",
        theme === "dark" ? "Read by daylight" : "Read by candlelight",
      );
    }
    document.dispatchEvent(
      new CustomEvent("moonmath:theme", { detail: { theme: theme } }),
    );
  }

  var toggle = document.querySelector("[data-theme-toggle]");
  if (toggle) {
    toggle.addEventListener("click", function () {
      setTheme(root.getAttribute("data-theme") === "dark" ? "light" : "dark");
    });
  }
  // Keep the label right on first paint.
  setTheme(root.getAttribute("data-theme") === "dark" ? "dark" : "light");

  // ---- formulae ----

  function typeset() {
    if (typeof window.renderMathInElement !== "function") return;
    window.renderMathInElement(document.body, {
      delimiters: [
        { left: "$$", right: "$$", display: true },
        { left: "\\(", right: "\\)", display: false },
      ],
      throwOnError: false,
      strict: false,
      macros: {
        "\\R": "\\mathbb{R}",
        "\\vec": "\\mathbf",
      },
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", typeset);
  } else {
    typeset();
  }

  // ---- copy a snippet ----

  document.addEventListener("click", function (event) {
    var button = event.target.closest("[data-copy]");
    if (!button) return;
    var slip = button.closest(".slip");
    var code = slip && slip.querySelector("pre code");
    if (!code) return;
    var text = code.innerText;
    var done = function () {
      var was = button.textContent;
      button.textContent = "copied";
      setTimeout(function () {
        button.textContent = was;
      }, 1400);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, function () {});
    } else {
      var area = document.createElement("textarea");
      area.value = text;
      area.setAttribute("readonly", "");
      area.style.position = "fixed";
      area.style.opacity = "0";
      document.body.appendChild(area);
      area.select();
      try {
        document.execCommand("copy");
        done();
      } catch (e) {
        /* nothing to say */
      }
      document.body.removeChild(area);
    }
  });

  // ---- the marginal index: which entry is under the eye ----

  var rail = document.querySelector(".index-rail");
  var main = document.querySelector(".lexicon-body");
  if (rail && main && "IntersectionObserver" in window) {
    var links = new Map();
    rail.querySelectorAll('a[href^="#"]').forEach(function (link) {
      links.set(link.getAttribute("href").slice(1), link);
    });
    var visible = new Map();
    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          visible.set(entry.target.id, entry.isIntersecting ? entry : null);
        });
        var best = null;
        main.querySelectorAll("[id]").forEach(function (node) {
          if (visible.get(node.id) && !best) best = node;
        });
        links.forEach(function (link) {
          link.classList.remove("here");
        });
        if (best && links.get(best.id)) links.get(best.id).classList.add("here");
      },
      { rootMargin: "-18% 0px -70% 0px", threshold: 0 },
    );
    main.querySelectorAll("article[id], section[id]").forEach(function (node) {
      observer.observe(node);
    });
  }
})();
