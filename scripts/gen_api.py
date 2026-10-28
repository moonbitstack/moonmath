#!/usr/bin/env python3
"""Write `docs/api.html` from the packages' interfaces and their doc comments.

The interface of a MoonBit package is `pkg.generated.mbti`, which `moon info`
writes from the source; the prose is the `///` block above each declaration.
This script joins the two: every public type, field, variant, method and value,
grouped by what it is for, each with the sentences its author wrote about it.

Methods written by `derive` and by the operator implementations have no prose of
their own — there is nothing to say about `not_equal` that `Eq` has not said —
so a type names the traits it carries in one line instead of listing eight
generated functions.

It refuses to write a page with a hole in it. A public item without a doc
comment is a bug in the source, not something to render as an empty paragraph,
so the script names the item and exits non-zero. CI runs it and compares the
result with what is committed, which is what keeps the page honest:

    python scripts/gen_api.py
    git diff --exit-code docs/api.html
"""

import html
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The order the guide reads in: the values everything stands on, then the
# shapes, then the things that answer questions about them.
GROUPS = [
    (
        "moonmath",
        "Values",
        "Scalars, angles and the easing functions, which belong to no type.",
        ["__values__"],
    ),
    ("moonmath", "Vectors", "Points and directions, and the arithmetic between them.", ["Vec2", "Vec3", "Vec4"]),
    (
        "moonmath",
        "Integer vectors",
        "For grid cells, pixels and indices, where a half is not a position.",
        ["IVec2", "IVec3", "IVec4", "UVec2", "UVec3", "UVec4"],
    ),
    (
        "moonmath",
        "Matrices",
        "Linear maps, and the four cameras: look_at, perspective, orthographic, frustum.",
        ["Mat2", "Mat3", "Mat4"],
    ),
    (
        "moonmath",
        "Rotation",
        "A rotation as four numbers, and the twelve ways of writing one as three angles.",
        ["Quat", "EulerOrder", "Turns"],
    ),
    (
        "moonmath",
        "Placement",
        "The transforms a scene graph stores: a rotation, a scale and a translation.",
        ["Trs", "Affine2", "Affine3"],
    ),
    (
        "moonmath",
        "Geometry",
        "Shapes, and whether two of them meet.",
        [
            "Rect",
            "Aabb2",
            "Aabb3",
            "Ray2",
            "Ray3",
            "Plane",
            "Sphere",
            "Triangle",
            "Frustum",
        ],
    ),
]

# The second precision is the same library at `Double`; its page is an index of
# the same names rather than a second copy of the same sentences.
SECOND = ("moonmath/f64", "src/f64")

# Methods that a `derive` or an operator implementation writes.
GENERATED = {
    "add",
    "sub",
    "mul",
    "div",
    "neg",
    "equal",
    "not_equal",
    "compare",
    "hash",
    "hash_combine",
    "to_string",
    "to_repr",
    "output",
}

TRAITS = {
    "Add": "Add",
    "Sub": "Sub",
    "Mul": "Mul",
    "Div": "Div",
    "Neg": "Neg",
    "Eq": "Eq",
    "Show": "Show",
    "Debug": "Debug",
    "Hash": "Hash",
    "Compare": "Compare",
}


class Failure(Exception):
    pass


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def strip_marker(lines):
    """A doc block, without the `///|` marker that opens one."""
    out = []
    for line in lines:
        text = line[3:].lstrip()
        if text in ("|", ""):
            out.append("")
        else:
            out.append(text)
    while out and out[0] == "":
        out.pop(0)
    while out and out[-1] == "":
        out.pop()
    return out


def parse_interface(path):
    """The public items of a package, in the order the interface file has them.

    A type owns its fields or variants, the methods called on it, and the traits
    it implements.
    """
    items = []
    current = None
    for raw in read(path).splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        match = re.match(r"pub\s*(?:\(all\)\s*)?(suberror|enum|struct) (\w+)", line)
        if match:
            kind = {"suberror": "error", "enum": "enum", "struct": "struct"}[
                match.group(1)
            ]
            current = {
                "kind": kind,
                "name": match.group(2),
                "sig": line.rstrip(" {").rstrip(),
                "members": [],
                "methods": [],
                "traits": [],
            }
            items.append(current)
            continue
        if line.startswith("}"):
            current = None
            continue
        if current is not None and current["kind"] in ("enum", "error"):
            match = re.match(r"([A-Z]\w*)(.*)", line)
            if match:
                current["members"].append(
                    {
                        "name": match.group(1),
                        "sig": line.rstrip(","),
                        "kind": "variant",
                    }
                )
                continue
        if current is not None and current["kind"] == "struct":
            match = re.match(r"(\w+)\s*:\s*(.+)", line)
            if match:
                current["members"].append(
                    {
                        "name": match.group(1),
                        "sig": "%s : %s" % (match.group(1), match.group(2).rstrip(",")),
                        "kind": "field",
                    }
                )
                continue
        match = re.match(r"pub impl (\S+) for (\w+)", line)
        if match:
            trait = match.group(1).split(".")[-1]
            for item in items:
                if item["name"] == match.group(2):
                    item["traits"].append(TRAITS.get(trait, trait))
                    break
            continue
        match = re.match(r"pub (fn|let) (\w+)(::\w+)?(.*)", line)
        if match:
            what, name, method, rest = match.groups()
            entry = {
                "kind": what,
                "name": method[2:] if method else name,
                "owner": name if method else None,
                "sig": line,
                "members": [],
                "methods": [],
                "traits": [],
            }
            if method:
                for item in items:
                    if item["name"] == name:
                        item["methods"].append(entry)
                        break
            else:
                items.append(entry)
            continue
    return items


def parse_docs(directory):
    """What each declaration's `///` block says, by name.

    A field or a variant is named `Type.member`, a method `Type::method`, and
    everything else by its own name.
    """
    docs = {}

    def remember(key, block):
        docs.setdefault(key, strip_marker(block) if block else [])

    for name in sorted(os.listdir(directory)):
        if not name.endswith(".mbt") or name.endswith("_test.mbt"):
            continue
        block = []
        owner = None
        for raw in read(os.path.join(directory, name)).splitlines():
            line = raw.strip()
            if line.startswith("///"):
                block.append(line)
                continue
            if not line:
                continue
            if owner is not None:
                if line.startswith("}"):
                    owner = None
                else:
                    member = re.match(r"(\w+)\s*:|([A-Z]\w*)\s*(?:\(|,|$)", line)
                    if member:
                        remember(
                            "%s.%s" % (owner, member.group(1) or member.group(2)),
                            block,
                        )
                block = []
                continue
            match = re.match(
                r"pub\s*(?:\(all\)\s*)?(?:suberror|enum|struct|fn|let)\s+"
                r"(\w+(?:::\w+)?)",
                line,
            )
            if match:
                key = match.group(1)
                if key.split("::")[-1] not in GENERATED:
                    remember(key, block)
                if match.group(0).rstrip().endswith(("struct", "enum")) or re.search(
                    r"(struct|enum)\s+\w+\s*\{?$", match.group(0)
                ):
                    owner = key
                block = []
                continue
            block = []
    return docs


def package_summary(directory):
    """The sentence that says what a package is for: the first paragraph of the
    comment on its `moon.pkg` that is not a name or an address."""
    paragraphs = []
    current = []
    for line in read(os.path.join(directory, "moon.pkg")).splitlines():
        if not line.startswith("//"):
            break
        text = line[2:].strip()
        if not text:
            if current:
                paragraphs.append(" ".join(current))
                current = []
            continue
        current.append(text)
    if current:
        paragraphs.append(" ".join(current))
    for paragraph in paragraphs:
        if "http://" not in paragraph and "https://" not in paragraph:
            return paragraph
    return paragraphs[0] if paragraphs else ""


def inline(text):
    """Escape, then put back the marks the doc comments use."""
    out = html.escape(text, quote=False)
    out = re.sub(r"\[`([^`]+)`\]", r"<code>\1</code>", out)
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)
    out = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", out)
    return out


def prose(lines):
    """A doc block as HTML: paragraphs, lists, tables and code fences."""
    out = []
    block = []
    index = 0

    def flush():
        if not block:
            return
        out.append("<p>%s</p>" % inline(" ".join(block)))
        block.clear()

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if stripped.startswith("```"):
            flush()
            language = stripped[3:].strip() or "mbt"
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith("```"):
                code.append(lines[index])
                index += 1
            index += 1
            out.append(
                '<div class="slip"><div class="slip-head"><span class="label">%s</span>'
                '<span class="spacer"></span></div><pre><code>%s</code></pre></div>'
                % (html.escape(language), html.escape("\n".join(code)))
            )
            continue
        if not stripped:
            flush()
            index += 1
            continue
        if stripped.startswith("|"):
            flush()
            rows = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                rows.append(lines[index].strip())
                index += 1
            out.append(table(rows))
            continue
        if stripped.startswith("- "):
            flush()
            items = []
            while index < len(lines) and lines[index].strip().startswith("- "):
                items.append(lines[index].strip()[2:])
                index += 1
            out.append(
                "<ul>%s</ul>" % "".join("<li>%s</li>" % inline(item) for item in items)
            )
            continue
        block.append(stripped)
        index += 1
    flush()
    return "\n".join(out)


def table(rows):
    def cells(row):
        return [cell.strip() for cell in row.strip("|").split("|")]

    head = cells(rows[0])
    body = [row for row in rows[1:] if not re.match(r"^\|[\s:|-]+\|$", row)]
    out = ['<div class="table-wrap"><table class="ledger"><thead><tr>']
    out.extend("<th>%s</th>" % inline(cell) for cell in head)
    out.append("</tr></thead><tbody>")
    for row in body:
        out.append(
            "<tr>%s</tr>" % "".join("<td>%s</td>" % inline(cell) for cell in cells(row))
        )
    out.append("</tbody></table></div>")
    return "".join(out)


def anchor(package, name):
    if package == "moonmath":
        return name.replace("::", "-").lower()
    return "%s-%s" % (package.split("/")[-1], name.replace("::", "-").lower())


def decl(text):
    return '<div class="decl">%s</div>' % html.escape(text, quote=False)


def render_value(package, item, docs, missing):
    doc = docs.get(item["name"])
    if not doc:
        missing.append(item["name"])
        doc = []
    return (
        '<article class="entry" id="%s"><h3>%s<span class="kind">%s</span></h3>'
        "%s<div class=\"gloss\">%s</div></article>"
        % (
            anchor(package, item["name"]),
            html.escape(item["name"]),
            "value" if item["kind"] == "let" else "function",
            decl(item["sig"]),
            prose(doc),
        )
    )


def render_type(package, item, docs, missing):
    doc = docs.get(item["name"])
    if not doc:
        missing.append(item["name"])
        doc = []
    body = [decl(item["sig"]), '<div class="gloss">%s</div>' % prose(doc)]

    if item["members"]:
        label = "Fields" if item["kind"] == "struct" else "Variants"
        rows = []
        for member in item["members"]:
            key = "%s.%s" % (item["name"], member["name"])
            member_doc = docs.get(key)
            if not member_doc:
                missing.append(key)
                member_doc = []
            rows.append(
                '<div class="row"><span class="name">%s</span>'
                '<span class="doc">%s</span></div>'
                % (html.escape(member["sig"]), prose(member_doc))
            )
        body.append(
            '<div class="members"><div class="label">%s</div>%s</div>'
            % (label, "".join(rows))
        )

    if item["traits"]:
        names = sorted(set(item["traits"]))
        body.append(
            '<p class="traits"><span class="label">Carries</span>%s</p>'
            % ", ".join("<code>%s</code>" % html.escape(name) for name in names)
        )

    methods = [m for m in item["methods"] if m["name"] not in GENERATED]
    if methods:
        rendered = []
        for method in sorted(methods, key=lambda entry: entry["name"]):
            key = "%s::%s" % (item["name"], method["name"])
            method_doc = docs.get(key)
            if not method_doc:
                missing.append(key)
                method_doc = []
            rendered.append(
                '<article class="entry" id="%s"><h3>%s</h3>%s'
                '<div class="gloss">%s</div></article>'
                % (
                    anchor(package, "%s::%s" % (item["name"], method["name"])),
                    html.escape(method["name"]),
                    decl(method["sig"]),
                    prose(method_doc),
                )
            )
        body.append('<div class="methods">%s</div>' % "".join(rendered))

    return (
        '<article class="entry" id="%s"><h3>%s<span class="kind">%s</span></h3>%s</article>'
        % (
            anchor(package, item["name"]),
            html.escape(item["name"]),
            item["kind"],
            "".join(body),
        )
    )


def load(package, directory):
    interface = os.path.join(ROOT, directory, "pkg.generated.mbti")
    if not os.path.exists(interface):
        raise Failure("%s has no pkg.generated.mbti" % directory)
    items = parse_interface(interface)
    docs = parse_docs(os.path.join(ROOT, directory))
    types = {item["name"]: item for item in items if item["kind"] in ("struct", "enum", "error")}
    values = [item for item in items if item["kind"] in ("fn", "let") and not item["owner"]]
    return {
        "name": package,
        "summary": package_summary(os.path.join(ROOT, directory)),
        "types": types,
        "values": values,
        "docs": docs,
    }


def render_package(package):
    """The whole tail of the lexicon: values, then one section per family."""
    data = load(package[0], package[1])
    docs = data["docs"]
    missing = []
    seen = set()
    sections = []

    for want, title, blurb, names in GROUPS:
        if want != data["name"]:
            continue
        chunks = []
        if names == ["__values__"]:
            for item in sorted(data["values"], key=lambda entry: entry["name"]):
                chunks.append(render_value(data["name"], item, docs, missing))
                seen.add(item["name"])
        else:
            for name in names:
                item = data["types"].get(name)
                if item is None:
                    continue
                chunks.append(render_type(data["name"], item, docs, missing))
                seen.add(name)
        if not chunks:
            continue
        sections.append(
            '<section id="%s"><div class="group-head"><h2>%s</h2>'
            '<span class="count">%d</span></div><p class="group-blurb">%s</p>%s</section>'
            % (
                title.lower().replace(" ", "-"),
                html.escape(title),
                len(chunks),
                inline(blurb),
                "".join(chunks),
            )
        )

    # Anything public that no group claimed still belongs on the page.
    strays = []
    for name in sorted(set(data["types"]) - seen):
        strays.append(render_type(data["name"], data["types"][name], docs, missing))
    for item in data["values"]:
        if item["name"] not in seen:
            strays.append(render_value(data["name"], item, docs, missing))
    if strays:
        sections.append(
            '<section id="unfiled"><div class="group-head"><h2>Unfiled</h2></div>%s</section>'
            % "".join(strays)
        )
    return data, sections, missing


def render_second_hand():
    """The double-precision package: every name, once, in a compact index."""
    data = load(SECOND[0], SECOND[1])
    rows = []
    for title, names in [
        ("Values", ["__values__"]),
        ("Vectors", ["Vec2", "Vec3", "Vec4"]),
        ("Matrices", ["Mat2", "Mat3", "Mat4"]),
        ("Rotation", ["Quat", "EulerOrder", "Turns"]),
        ("Placement", ["Trs", "Affine2", "Affine3"]),
        (
            "Geometry",
            ["Rect", "Aabb2", "Aabb3", "Ray2", "Ray3", "Plane", "Sphere", "Triangle", "Frustum"],
        ),
    ]:
        if names == ["__values__"]:
            entries = []
            for item in sorted(data["values"], key=lambda entry: entry["name"]):
                entries.append(
                    '<article class="entry"><h3>%s<span class="kind">value</span></h3>'
                    '<div class="names"><span>%s</span></div></article>'
                    % (html.escape(item["name"]), html.escape(item["name"]))
                )
            if entries:
                rows.append(
                    '<section><div class="group-head"><h2>%s</h2></div>%s</section>'
                    % (title, "".join(entries))
                )
            continue
        entries = []
        for name in names:
            item = data["types"].get(name)
            if item is None:
                continue
            methods = [
                method["name"]
                for method in sorted(item["methods"], key=lambda entry: entry["name"])
                if method["name"] not in GENERATED
            ]
            entries.append(
                '<article class="entry"><h3>%s<span class="kind">%s</span></h3>'
                '<div class="names">%s</div></article>'
                % (
                    html.escape(name),
                    item["kind"],
                    "".join("<span>%s</span>" % html.escape(m) for m in methods),
                )
            )
        if entries:
            rows.append(
                '<section><div class="group-head"><h2>%s</h2></div>%s</section>'
                % (title, "".join(entries))
            )
    return data, "".join(rows)


TEMPLATE = """<!DOCTYPE html>
<html lang="en" data-theme="light">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>The lexicon — moonmath</title>
    <meta
      name="description"
      content="Every public type, field, method and value of moonmath, with the sentences its source wrote about them."
    />
    <link rel="icon" href="assets/nib.svg" type="image/svg+xml" />
    <script>
      (function () {
        try {
          var t = localStorage.getItem("moonmath-theme");
        } catch (e) {
          t = null;
        }
        if (!t) {
          t =
            window.matchMedia &&
            window.matchMedia("(prefers-color-scheme: dark)").matches
              ? "dark"
              : "light";
        }
        document.documentElement.setAttribute("data-theme", t);
      })();
    </script>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link
      href="https://fonts.googleapis.com/css2?family=Caveat:wght@400;600&family=Courier+Prime:ital,wght@0,400;0,700;1,400&family=EB+Garamond:ital,wght@0,400;0,500;0,600;1,400;1,500&family=IM+Fell+English:ital@0;1&family=IM+Fell+English+SC&display=swap"
      rel="stylesheet"
    />
    <link rel="stylesheet" href="assets/paper.css?v=1" />
  </head>
  <body>
    <a class="skip" href="#main">Skip to the text</a>

    <header class="masthead">
      <div class="masthead-inner">
        <a class="mark" href="index.html" aria-label="moonmath, home">
          <svg class="nib" viewBox="0 0 24 24" aria-hidden="true">
            <path d="M12 2.2c1.9 3.6 3.3 7.2 3.3 10.5 0 3.4-1.5 6.5-3.3 9.1-1.8-2.6-3.3-5.7-3.3-9.1 0-3.3 1.4-6.9 3.3-10.5z" fill="none" stroke="currentColor" stroke-width="1.1" stroke-linejoin="round" />
            <path d="M12 7.4v11" fill="none" stroke="currentColor" stroke-width="1.1" stroke-linecap="round" />
            <circle cx="12" cy="9.4" r="1.15" fill="none" stroke="currentColor" stroke-width="1.1" />
          </svg>
          <span class="mark-text">
            <span class="mark-name">moonmath</span>
            <span class="mark-sub">the arithmetic of space</span>
          </span>
        </a>
        <nav class="nav" aria-label="Main">
          <a href="index.html">Frontispiece</a>
          <a href="guide.html">Guide</a>
          <a href="api.html" aria-current="page">Lexicon</a>
          <a href="showcase.html">Workshop</a>
        </nav>
        <div class="tools">
          <button class="icon-btn" type="button" data-theme-toggle aria-label="Read by candlelight">
            <svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
            </svg>
            <svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true">
              <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" />
            </svg>
          </button>
          <a class="icon-btn" href="https://github.com/moonbitstack/moonmath" aria-label="The repository on GitHub">
            <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12 .5a12 12 0 0 0-3.8 23.4c.6.1.8-.3.8-.6v-2c-3.3.7-4-1.6-4-1.6-.6-1.4-1.4-1.8-1.4-1.8-1-.7.1-.7.1-.7 1.2.1 1.8 1.2 1.8 1.2 1 1.8 2.8 1.3 3.5 1 .1-.8.4-1.3.8-1.6-2.7-.3-5.5-1.3-5.5-6 0-1.2.5-2.3 1.2-3.1-.1-.3-.5-1.5.1-3.2 0 0 1-.3 3.3 1.2a11.5 11.5 0 0 1 6 0C17.3 4.7 18.3 5 18.3 5c.6 1.7.2 2.9.1 3.2.8.8 1.2 1.9 1.2 3.1 0 4.7-2.8 5.7-5.5 6 .4.4.8 1.1.8 2.2v3.3c0 .3.2.7.8.6A12 12 0 0 0 12 .5z" />
            </svg>
          </a>
        </div>
      </div>
    </header>

    <main id="main">
      <div class="lexicon">
        <aside class="index-rail" aria-label="Contents">
          <div class="rail-title">The lexicon</div>
          {{RAIL}}
        </aside>

        <div class="lexicon-body">
          <div class="lex-intro">
            <h1>Every public name</h1>
            <p>
              One entry per type, field, variant, method and value, in the words
              the source wrote for it. Grouped by what the thing is for; the
              page is generated from the interfaces and the doc comments, so it
              cannot drift from the code without the build saying so.
            </p>
          </div>
          {{SECTIONS}}
          <section class="second-hand" id="f64">
            <div class="group-head"><h2>moonmath/f64</h2><span class="count">the same, at Double</span></div>
            <p>
              {{SECOND_SUMMARY}} Every type, method and value above appears here
              under the same name and with the same meaning, with
              <code>Float</code> replaced by <code>Double</code>; the two packages
              are expanded from one template. The integer vectors are absent,
              because they count pixels. What follows is the index of names, not
              a second copy of the sentences.
            </p>
            {{SECOND}}
          </section>
        </div>
      </div>
    </main>

    <footer class="colophon">
      <div class="colophon-inner">
        <div>
          <div class="device">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M12 2.2c1.9 3.6 3.3 7.2 3.3 10.5 0 3.4-1.5 6.5-3.3 9.1-1.8-2.6-3.3-5.7-3.3-9.1 0-3.3 1.4-6.9 3.3-10.5z" fill="none" stroke="currentColor" stroke-width="1.1" stroke-linejoin="round" />
              <path d="M12 7.4v11" fill="none" stroke="currentColor" stroke-width="1.1" stroke-linecap="round" />
              <circle cx="12" cy="9.4" r="1.15" fill="none" stroke="currentColor" stroke-width="1.1" />
            </svg>
            <span>moonmath</span>
          </div>
          <p class="fine" style="margin: 0.5rem 0 0">
            {{COUNT}} entries, generated from the interfaces and the doc
            comments.
          </p>
        </div>
        <p class="fine">
          Set in EB Garamond and IM Fell English, the marginalia in Caveat, the
          listings in Courier Prime. Apache-2.0.
        </p>
        <div>
          <div class="links">
            <a href="index.html">Frontispiece</a>
            <a href="guide.html">Guide</a>
            <a href="showcase.html">Workshop</a>
            <a href="https://github.com/moonbitstack/moonmath">GitHub</a>
          </div>
          <div class="folio" style="margin-top: 0.7rem">fol. iv</div>
        </div>
      </div>
    </footer>

    <script src="assets/site.js?v=1" defer></script>
  </body>
</html>
"""


def main():
    data, sections, missing = render_package(("moonmath", "src"))
    second, second_body = render_second_hand()

    if missing:
        for item in sorted(set(missing)):
            print("no doc comment for", item, file=sys.stderr)
        print("%d public items have no description" % len(set(missing)), file=sys.stderr)
        return 1

    rail = []
    for name, title, _blurb, names in GROUPS:
        links = "" if names == ["__values__"] else "".join(
            '<a href="#%s">%s</a>' % (anchor("moonmath", n), html.escape(n))
            for n in names
        )
        rail.append(
            '<div class="group"><a href="#%s">%s</a>'
            '<div class="sub">%s</div></div>'
            % (title.lower().replace(" ", "-"), html.escape(title), links)
        )
    rail.append('<div class="group"><a href="#f64">moonmath/f64</a></div>')

    count = sum(section.count('<article class="entry"') for section in sections)
    page = (
        TEMPLATE.replace("{{RAIL}}", "".join(rail))
        .replace("{{SECTIONS}}", "".join(sections))
        .replace("{{SECOND}}", second_body)
        .replace("{{SECOND_SUMMARY}}", inline(second["summary"]))
        .replace("{{COUNT}}", str(count))
    )
    target = os.path.join(ROOT, "docs", "api.html")
    with open(target, "w", encoding="utf-8", newline="") as handle:
        handle.write(page)
    print("api: %d entries, %d missing" % (count, len(missing)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
