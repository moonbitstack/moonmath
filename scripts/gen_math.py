#!/usr/bin/env python3
"""Generate the two precisions of the library from one template.

`scripts/template/` holds the library once, written against `{{S}}` (the scalar
type) and a handful of other placeholders for the parts that differ between
single and double precision: the name of the `sin`-family functions, the debug
repr helper, the default tolerances. This script expands every template file
into `src/` (single precision) and `src/f64/` (double precision). A template
named `foo.f32.mbt` is only emitted for single precision, which is how the
integer vectors stay out of the double package.

Run `moon fmt` afterwards: the output is formatted by the formatter, not here,
which is also why the check that the two packages are still what the template
says is "regenerate, format, and see whether anything moved".

Usage: python scripts/gen_math.py
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "scripts" / "template"

# Each precision names the same things differently. `S` is the scalar type, `DBG`
# the `@debug.Repr` constructor for it, `SIN`..`HYPOT` the C-style math entry
# points the `math` package exposes for it, `EPS`/`REL_EPS` the tolerances the
# hand-written tests use, and `ULP_TOL` how far a vector result may drift from
# the numpy reference in units of the last place.
PRECISIONS = {
    "f32": {
        "S": "Float",
        "PKG": "moonmath",
        "DBG": "float",
        "SIN": "sinf",
        "COS": "cosf",
        "TAN": "tanf",
        "ASIN": "asinf",
        "ACOS": "acosf",
        "ATAN": "atanf",
        "ATAN2": "atan2f",
        "EXP": "expf",
        "LN": "lnf",
        "POW": "powf",
        "HYPOT": "hypotf",
        "EPS": "1.0e-6",
        "INF": "3.4028234663852886e38",
        "REL_EPS": "1.0e-5",
        "MAT_EPS": "1.0e-6",
        "ULP_TOL": "16",
        "REPR": "reinterpret_as_int",
        "REPR_CAST": ".to_int64()",
        "MAX_I64": "0x7FFFFFFFFFFFFFFF",
    },
    "f64": {
        "S": "Double",
        "PKG": "f64",
        "DBG": "double",
        "SIN": "sin",
        "COS": "cos",
        "TAN": "tan",
        "ASIN": "asin",
        "ACOS": "acos",
        "ATAN": "atan",
        "ATAN2": "atan2",
        "EXP": "exp",
        "LN": "ln",
        "POW": "pow",
        "HYPOT": "hypot",
        "EPS": "1.0e-12",
        "INF": "1.7976931348623157e308",
        "REL_EPS": "1.0e-11",
        "MAT_EPS": "1.0e-14",
        "ULP_TOL": "4",
        "REPR": "reinterpret_as_int64",
        "REPR_CAST": "",
        "MAX_I64": "0x7FFFFFFFFFFFFFFF",
    },
}

TARGETS = {"f32": ROOT / "src", "f64": ROOT / "src" / "f64"}


def expand(text: str, tokens: dict[str, str]) -> str:
    for key, value in tokens.items():
        text = text.replace("{{" + key + "}}", value)
    return text


def left_behind(text: str) -> list[str]:
    return sorted(
        {
            word
            for word in text.split()
            if "{{" in word or "}}" in word
        }
    )


def main() -> int:
    written = 0
    for template in sorted(TEMPLATE.glob("*.mbt")):
        name = template.name
        precisions = ["f32", "f64"]
        # A `.f32.` or `.f64.` in the middle of the name keeps that file out of
        # the other package: the integer vectors have no double-precision
        # counterpart, and the tests that use them only exist for single.
        if ".f32." in name or ".f32_" in name:
            precisions = ["f32"]
            name = name.replace(".f32.", ".").replace(".f32_", "_")
        elif ".f64." in name or ".f64_" in name:
            precisions = ["f64"]
            name = name.replace(".f64.", ".").replace(".f64_", "_")

        for which in precisions:
            text = expand(template.read_text(encoding="utf-8"), PRECISIONS[which])
            rest = left_behind(text)
            if rest:
                print(f"{template.name}: unexpanded {rest}", file=sys.stderr)
                return 1
            out = TARGETS[which] / name
            if out.exists() and out.read_text(encoding="utf-8") == text:
                continue
            out.write_text(text, encoding="utf-8", newline="\n")
            written += 1

    if written:
        print(f"generated {written} file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
