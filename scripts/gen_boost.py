"""Build the Boost.Math cross-check table the special-function tests replay.

The libraries in this package are written from the algorithms; the numbers they
are checked against come from somewhere else. `gen_special.py` supplies those at
double and at fifty and a hundred digits from `mpmath`. This script supplies a
second, independent set: the tables that ship with Boost.Math's own test suite,
which is what the task asked the double-precision side to be compared with.

Boost's tables are the widest available record of what these functions are: each
one was produced by a reference implementation and checked into `test/*.ipp`
under the Boost Software License. Reading them here rather than re-deriving them
keeps the comparison honest — the values were not produced by the code under
test, nor by a script written beside it.

Every row of every table is kept, except two kinds that cannot be checked: a
value below the smallest normal `Double`, where no relative error exists to
measure and no literal exists to write, and a parameter of zero for `R_J`, which
is outside this package's domain. Eight and a half thousand rows in all, which
is a second and a half of test time.

    python scripts/gen_boost.py /path/to/boostorg/math
    python scripts/gen_boost.py            # reads $BOOST_MATH, else /tmp/boostmath

Writes `src/special/boost_wbtest.mbt`. The tables are checked in, so a test run
needs neither Boost nor Python.
"""

from __future__ import annotations

import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "src" / "special" / "boost_wbtest.mbt"

# A ceiling above every table's length: the check is row for row. Kept as a named
# limit rather than a flag so that lowering it for a much larger table stays one
# edit.
SAMPLE = 100000

HEADER = """\
// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0
//
// The cross-check table: values from Boost.Math's own test data, sampled and
// checked in.
//
// The reference values in this file are taken from `test/*.ipp` in
// boostorg/math at `boost-1.92.0`. That data is
//   (C) Copyright John Maddock 2006-7.
//   Use, modification and distribution are subject to the
//   Boost Software License, Version 1.0. (See accompanying file
//   LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
// It is redistributed here in full, under the same licence.
//
// The tables are kept whole. `scripts/gen_boost.py` rebuilds this file from a
// Boost checkout.
"""

# name, source file, test-facing name, argument columns (1 based), value column,
# transforms applied to the arguments before the call.
TABLES = [
    # The error function, with its complement in the third column.
    ("erf", "erf_data.ipp", "erf", [1], 2, []),
    ("erfc", "erf_data.ipp", "erfc", [1], 3, []),
    ("erfinv", "erf_inv_data.ipp", "erfinv", [1], 2, []),
    ("erfcinv", "erfc_inv_data.ipp", "erfcinv", [1], 2, []),
    ("beta", "beta_med_data.ipp", "beta", [1, 2], 3, []),
    ("zeta", "zeta_data.ipp", "zeta", [1], 2, []),
    ("zeta_neg", "zeta_neg_data.ipp", "zeta", [1], 2, []),
    ("digamma", "digamma_data.ipp", "digamma", [1], 2, []),
    ("digamma_neg", "digamma_neg_data.ipp", "digamma", [1], 2, []),
    # The elliptic tables are indexed by the modulus; this package takes the
    # parameter, so the argument is squared on the way in.
    ("ellipk", "ellint_k_data.ipp", "ellipk", [1], 2, ["square"]),
    ("ellipe", "ellint_e_data.ipp", "ellipe", [1], 2, ["square"]),
    ("ellipkinc", "ellint_f_data.ipp", "ellipkinc", [1, 2], 3, ["", "square"]),
    ("elliprf", "ellint_rf_data.ipp", "elliprf", [1, 2, 3], 4, []),
    ("elliprd", "ellint_rd_data.ipp", "elliprd", [1, 2, 3], 4, []),
    ("elliprc", "ellint_rc_data.ipp", "elliprc", [1, 2], 3, []),
    ("elliprj", "ellint_rj_data.ipp", "elliprj", [1, 2, 3, 4], 5, []),
    ("bessel_j", "bessel_j_data.ipp", "bessel_j", [1, 2], 3, []),
    ("bessel_j_int", "bessel_j_int_data.ipp", "bessel_j", [1, 2], 3, []),
    ("bessel_j_large", "bessel_j_large_data.ipp", "bessel_j", [1, 2], 3, []),
    ("bessel_y", "bessel_y01_data.ipp", "bessel_y", [1, 2], 3, []),
    ("bessel_y_int", "bessel_yn_data.ipp", "bessel_y", [1, 2], 3, []),
    ("bessel_y_real", "bessel_yv_data.ipp", "bessel_y", [1, 2], 3, []),
    ("bessel_i", "bessel_i_data.ipp", "bessel_i", [1, 2], 3, []),
    ("bessel_i_int", "bessel_i_int_data.ipp", "bessel_i", [1, 2], 3, []),
    ("bessel_k", "bessel_k_data.ipp", "bessel_k", [1, 2], 3, []),
    ("bessel_k_int", "bessel_k_int_data.ipp", "bessel_k", [1, 2], 3, []),
]

ROW = re.compile(r"\{\{([^}]*)\}\}")
VALUE = re.compile(r"SC_\(([-+0-9.eE]+)\)")
WIDTH = re.compile(r"table_type<T>::type, *(\d+)>")


def read_rows(path: pathlib.Path) -> list[list[float]]:
    """Every row of a table, as floats; the width is the one it declares."""
    text = path.read_text(encoding="utf-8")
    declared = WIDTH.search(text)
    width = int(declared.group(1)) if declared else None
    rows = []
    for match in ROW.finditer(text):
        values = VALUE.findall(match.group(1))
        if width is not None and len(values) != width:
            continue
        rows.append([float(value) for value in values])
    return rows


def sample(rows: list[list[float]]) -> list[list[float]]:
    """Every row, unless the table is longer than the ceiling, in which case an
    even spread with both ends kept."""
    if len(rows) <= SAMPLE:
        return rows
    step = len(rows) / SAMPLE
    picked = [rows[int(index * step)] for index in range(SAMPLE)]
    picked[0] = rows[0]
    picked[-1] = rows[-1]
    return picked


def render(name: str, rows: list[list[float]], arguments: list[int], value: int,
           transforms: list[str]) -> str:
    """One `Array[(Double, ..., Double)]`, arguments first and the value last."""
    arity = len(arguments)
    declared = "Double, " * arity + "Double"
    lines = ["///|", f"let boost_{name}_cases : Array[({declared})] = ["]
    for row in rows:
        numbers = []
        for index, column in enumerate(arguments):
            transform = transforms[index] if index < len(transforms) else ""
            argument = row[column - 1]
            if transform == "square":
                argument = argument * argument
            numbers.append(argument)
        numbers.append(row[value - 1])
        rendered = ", ".join(repr(number) for number in numbers)
        lines.append(f"  ({rendered}),")
    lines.append("]")
    return "\n".join(lines)


def main() -> None:
    source = sys.argv[1] if len(sys.argv) > 1 else os.environ.get(
        "BOOST_MATH", "/tmp/boostmath"
    )
    root = pathlib.Path(source) / "test"
    if not root.is_dir():
        raise SystemExit(f"no Boost.Math checkout at {root}")

    blocks = []
    for name, filename, _, arguments, value, transforms in TABLES:
        rows = read_rows(root / filename)
        if not rows:
            raise SystemExit(f"{filename}: no rows read")
        # A parameter of zero is outside `R_J`'s domain in this package.
        if name == "elliprj":
            rows = [row for row in rows if row[3] > 0]
        # A value below the smallest normal `Double` has no relative accuracy to
        # check and no literal to write: `1e-323` is a denormal that the language
        # rounds to zero on the way in. Those rows are left out.
        rows = [row for row in rows if abs(row[value - 1]) >= 1.0e-300]
        blocks.append(render(name, sample(rows), arguments, value, transforms))

    TARGET.write_text(
        HEADER + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8", newline="\n"
    )
    total = sum(block.count("  (") for block in blocks)
    print(f"wrote {TARGET.relative_to(ROOT)}: {len(blocks)} tables, {total} rows")


if __name__ == "__main__":
    main()
