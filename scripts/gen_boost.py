"""Build the Boost.Math cross-check tables the special-function tests replay.

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

Two sets come out of it. The thirty tables of Boost's general suite become
`src/special/boost_wbtest.mbt`, and the three tables of the large-parameter
`1F1` region become `src/special/boost_big_wbtest.mbt`. The latter are read from
the copies kept in `scripts/boost/`, at `boost-1.92.0`, so that a run with no
Boost checkout and no network rebuilds the file CI checks:

    python scripts/gen_boost.py                    # the three large-parameter tables
    python scripts/gen_boost.py /path/to/math      # every table, from a checkout

Every row of every table is kept, except two kinds: a parameter of zero for
`R_J`, which is outside this package's domain, and — in the thirty general
tables, where a row is one comparison and nothing else — a value below the
smallest normal `Double`, which has no literal to write and no relative error to
measure. The three large-parameter tables keep those rows as `0.0`, and the
replay reads that as "below what the type holds": the answer there must also lie
below the smallest normal double rather than be a number of the wrong size.

The tables are checked in, so a test run needs neither Boost nor Python.
"""

from __future__ import annotations

import math
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGET = ROOT / "src" / "special" / "boost_wbtest.mbt"
BIG_TARGET = ROOT / "src" / "special" / "boost_big_wbtest.mbt"
# The three large-parameter tables, kept here rather than under `src/` so that
# the generator and the data it reads sit together.
BIG_SOURCE = ROOT / "scripts" / "boost"

HEADER = """\
// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0
//
// The cross-check table: values from Boost.Math's own test data, checked in.
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

BIG_HEADER = """\
// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0
//
// The large-parameter `1F1` tables: values from Boost.Math's own test data.
//
// The reference values in this file are taken from `test/*.ipp` in
// boostorg/math at `boost-1.92.0`. That data is
//   (C) Copyright John Maddock 2019.
//   Use, modification and distribution are subject to the
//   Boost Software License, Version 1.0. (See accompanying file
//   LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
// It is redistributed here in full, under the same licence. The tables
// themselves are kept in `scripts/boost/`, and `scripts/gen_boost.py` rebuilds
// this file from them without a Boost checkout.
//
// Every row is kept. A row whose reference is below the smallest normal
// `Double` — there are twelve across the three tables — is written as
// `0.0` here, and `large_wbtest.mbt` reads that as a value the type cannot
// hold rather than as a value of zero.
"""

# name, source file, argument columns (1 based), value column, transforms applied
# to the arguments before the call.
TABLES = [
    # The error function, with its complement in the third column.
    ("erf", "erf_data.ipp", [1], 2, []),
    ("erfc", "erf_data.ipp", [1], 3, []),
    ("erfinv", "erf_inv_data.ipp", [1], 2, []),
    ("erfcinv", "erfc_inv_data.ipp", [1], 2, []),
    ("beta", "beta_med_data.ipp", [1, 2], 3, []),
    ("zeta", "zeta_data.ipp", [1], 2, []),
    ("zeta_neg", "zeta_neg_data.ipp", [1], 2, []),
    ("digamma", "digamma_data.ipp", [1], 2, []),
    ("digamma_neg", "digamma_neg_data.ipp", [1], 2, []),
    # The elliptic tables are indexed by the modulus; this package takes the
    # parameter, so the argument is squared on the way in.
    ("ellipk", "ellint_k_data.ipp", [1], 2, ["square"]),
    ("ellipe", "ellint_e_data.ipp", [1], 2, ["square"]),
    ("ellipkinc", "ellint_f_data.ipp", [1, 2], 3, ["", "square"]),
    ("elliprf", "ellint_rf_data.ipp", [1, 2, 3], 4, []),
    ("elliprd", "ellint_rd_data.ipp", [1, 2, 3], 4, []),
    ("elliprc", "ellint_rc_data.ipp", [1, 2], 3, []),
    ("elliprj", "ellint_rj_data.ipp", [1, 2, 3, 4], 5, []),
    ("bessel_j", "bessel_j_data.ipp", [1, 2], 3, []),
    ("bessel_j_int", "bessel_j_int_data.ipp", [1, 2], 3, []),
    ("bessel_j_large", "bessel_j_large_data.ipp", [1, 2], 3, []),
    ("bessel_y", "bessel_y01_data.ipp", [1, 2], 3, []),
    ("bessel_y_int", "bessel_yn_data.ipp", [1, 2], 3, []),
    ("bessel_y_real", "bessel_yv_data.ipp", [1, 2], 3, []),
    ("bessel_i", "bessel_i_data.ipp", [1, 2], 3, []),
    ("bessel_i_int", "bessel_i_int_data.ipp", [1, 2], 3, []),
    ("bessel_k", "bessel_k_data.ipp", [1, 2], 3, []),
    ("bessel_k_int", "bessel_k_int_data.ipp", [1, 2], 3, []),
    # Kummer's function, over the three of Boost's tables whose parameters this
    # package reaches without a uniform asymptotic expansion: the general one,
    # whose every row has a parameter past twenty; the small-argument random
    # one; and the negative-integer one, where a numerator of `-67228` ends the
    # series after sixty-seven thousand terms.
    ("hyper1f1", "hypergeometric_1F1.ipp", [1, 2, 3], 4, []),
    ("hyper1f1_small", "hypergeometric_1F1_small_random.ipp", [1, 2, 3], 4, []),
    ("hyper1f1_neg_int", "hypergeometric_1f1_neg_int.ipp", [1, 2, 3], 4, []),
    # Gauss's function. Every row has parameters within a hundred of zero and
    # the argument anywhere inside the unit interval, which is the region the
    # connection formula at `1 - x` exists for.
    ("hyper2f1", "hypergeometric_2F1.ipp", [1, 2, 3, 4], 5, []),
]

# The three tables of the large-parameter region: the main one, whose parameters
# run past a million; the rows that sit at the edge of what a double holds; and
# the rows Boost itself marks unsolved.
BIG_TABLES = [
    ("hyper1f1_big", "hypergeometric_1F1_big.ipp"),
    ("hyper1f1_big_double", "hypergeometric_1F1_big_double_limited.ipp"),
    ("hyper1f1_big_unsolved", "hypergeometric_1F1_big_unsolved.ipp"),
]

# One field of a row: a decimal literal at up to forty digits, or a
# `std::ldexp` of an integer, which the double-limited table uses for its
# arguments so that they are exactly representable.
FIELD = re.compile(
    r"SC_\(([-+0-9.eE]+)\)"
    r"|std::ldexp\(\(double\)\s*(-?\d+)\s*,\s*(-?\d+)\s*\)"
)
# The two shapes an array of rows is declared in.
WIDTH = re.compile(r"(?:table_type<T>::type, *|std::array<T, *)(\d+)>")


def fields_of(line: str) -> list[float]:
    """One row's values, left to right."""
    values = []
    for found in FIELD.finditer(line):
        if found.group(1) is not None:
            values.append(float(found.group(1)))
        else:
            values.append(math.ldexp(float(found.group(2)), int(found.group(3))))
    return values


def read_rows(path: pathlib.Path) -> list[list[float]]:
    """Every row of a table, as floats.

    A row is a line: the data files put one to a line in both of the shapes they
    come in — `{{ SC_(..), .. }},` inside a declared array, and a bare
    `{ SC_(..), .. },` for the hypergeometric tables, which declare no width. So
    the width is read where it is declared and not assumed where it is not.
    """
    text = path.read_text(encoding="utf-8")
    declared = WIDTH.search(text)
    width = int(declared.group(1)) if declared else None
    rows = []
    for line in text.splitlines():
        if "SC_(" not in line:
            continue
        # A row Boost has commented out is not part of the table. One `2F1`
        # value of `5e350` is commented out that way: past the range a double
        # holds, so there is nothing to compare.
        if line.lstrip().startswith("//"):
            continue
        values = fields_of(line)
        if not values:
            continue
        if width is not None and len(values) != width:
            continue
        rows.append(values)
    return rows


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


# A `1F1` row is `(a, b, x, value)`; the large-parameter tables are all that.
BIG_ARITY = 4
# Rows per function. A single literal of three thousand elements would be one
# initialiser holding every value at once; a few hundred to a function keeps
# each one inside what a backend will compile, and the array is one value again
# once the pieces are added.
CHUNK = 400


def render_big(name: str, rows: list[list[float]]) -> str:
    """One table, split into functions that each build a few hundred rows."""
    declared = "Double, " * (BIG_ARITY - 1) + "Double"
    blocks = []
    for start in range(0, len(rows), CHUNK):
        piece = rows[start : start + CHUNK]
        lines = [
            "///|",
            f"fn boost_{name}_rows_{start // CHUNK}() -> Array[({declared})] {{",
            "  [",
        ]
        for row in piece:
            rendered = ", ".join(repr(number) for number in row)
            lines.append(f"    ({rendered}),")
        lines.append("  ]")
        lines.append("}")
        blocks.append("\n".join(lines))
    pieces = " + ".join(
        f"boost_{name}_rows_{start // CHUNK}()" for start in range(0, len(rows), CHUNK)
    )
    joined = (
        f"///|\nlet boost_{name}_cases : Array[({declared})] =\n  {pieces}\n"
    )
    return "\n\n".join(blocks) + "\n\n" + joined


def write_big(root: pathlib.Path) -> None:
    blocks = []
    for name, filename in BIG_TABLES:
        rows = read_rows(root / filename)
        if not rows:
            raise SystemExit(f"{filename}: no rows read")
        blocks.append(render_big(name, rows))
    BIG_TARGET.write_text(
        BIG_HEADER + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8", newline="\n"
    )
    total = sum(block.count("    (") for block in blocks)
    print(f"wrote {BIG_TARGET.relative_to(ROOT)}: {len(blocks)} tables, {total} rows")


def write_general(root: pathlib.Path) -> None:
    blocks = []
    for name, filename, arguments, value, transforms in TABLES:
        rows = read_rows(root / filename)
        if not rows:
            raise SystemExit(f"{filename}: no rows read")
        # A parameter of zero is outside `R_J`'s domain in this package.
        if name == "elliprj":
            rows = [row for row in rows if row[3] > 0]
        # A value below the smallest normal `Double` has no relative accuracy to
        # check and no literal to write: `1e-323` is a denormal that the language
        # rounds to zero on the way in. Those rows are left out of these tables.
        rows = [row for row in rows if abs(row[value - 1]) >= 1.0e-300]
        blocks.append(render(name, rows, arguments, value, transforms))

    TARGET.write_text(
        HEADER + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8", newline="\n"
    )
    total = sum(block.count("  (") for block in blocks)
    print(f"wrote {TARGET.relative_to(ROOT)}: {len(blocks)} tables, {total} rows")


def main() -> None:
    source = sys.argv[1] if len(sys.argv) > 1 else None
    if source is None:
        write_big(BIG_SOURCE)
        return
    root = (pathlib.Path(source) / "test").resolve()
    if not root.is_dir():
        raise SystemExit(f"no Boost.Math checkout at {root}")
    write_general(root)
    write_big(root)


if __name__ == "__main__":
    main()
