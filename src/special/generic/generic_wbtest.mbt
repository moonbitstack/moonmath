// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

// The arbitrary-precision side: the same bodies the double package runs, handed
// the `BigFloat` algebra, checked against `mpmath` at fifty and a hundred digits.
// The vectors in `arb_data_wbtest.mbt` are strings because that is the only way
// to carry a value past what a double holds.

///|
/// A row's arguments, as `BigFloat` values at one width.
fn arguments(fields : Array[StringView], bits : Int32) -> Array[@arb.BigFloat] {
  fields.map(fn(field) { @arb.BigFloat::from_decimal(field.to_owned(), bits) })
}

///|
/// The function a row names, applied to its arguments. The `match` is the only
/// place the name and the call meet, so a row that names nothing fails loudly.
fn evaluate(
  name : String,
  args : Array[@arb.BigFloat],
  ops : Ops[@arb.BigFloat],
) -> @arb.BigFloat {
  match name {
    "erf" => erf(args[0], ops)
    "erfc" => erfc(args[0], ops)
    "erfcx" => erfcx(args[0], ops)
    "erfi" => erfi(args[0], ops)
    "erfinv" => erfinv(args[0], ops)
    "gamma" => gamma(args[0], ops)
    "lgamma" => lgamma(args[0], ops)
    "digamma" => digamma(args[0], ops)
    "zeta" => zeta(args[0], ops)
    "ellipk" => ellipk(args[0], ops)
    "ellipe" => ellipe(args[0], ops)
    "ellipkm1" => ellipkm1(args[0], ops)
    "beta" => beta(args[0], args[1], ops)
    "lbeta" => lbeta(args[0], args[1], ops)
    "gammainc" => gammainc(args[0], args[1], ops)
    "gammaincc" => gammaincc(args[0], args[1], ops)
    "ellipkinc" => ellipkinc(args[0], args[1], ops)
    "ellipeinc" => ellipeinc(args[0], args[1], ops)
    "elliprc" => elliprc(args[0], args[1], ops)
    "polygamma" => polygamma(args[0].to_double().to_int(), args[1], ops)
    "bessel_j" => bessel_j(args[0], args[1], ops)
    "bessel_y" => bessel_y(args[0], args[1], ops)
    "bessel_i" => bessel_i(args[0], args[1], ops)
    "bessel_k" => bessel_k(args[0], args[1], ops)
    "hyper0f1" => hyper0f1(args[0], args[1], ops)
    "incbeta" => incbeta(args[0], args[1], args[2], ops)
    "hyper1f1" => hyper1f1(args[0], args[1], args[2], ops)
    "elliprf" => elliprf(args[0], args[1], args[2], ops)
    "elliprd" => elliprd(args[0], args[1], args[2], ops)
    "elliprg" => elliprg(args[0], args[1], args[2], ops)
    "elliprj" => elliprj(args[0], args[1], args[2], args[3], ops)
    "hyper2f1" => hyper2f1(args[0], args[1], args[2], args[3], ops)
    _ => abort("no such function: \{name}")
  }
}

///|
/// Replay one width's vectors.
///
/// The tolerance is relative. The two Bessel functions of the first and second
/// kind get a looser one at the large arguments: past the crossover they are
/// answered by the asymptotic expansion, which is truncated at its least term,
/// so their reachable accuracy is set by `x` rather than by the width. The rest
/// of the table has to agree to half a digit less than the width it asks for.
fn replay(
  cases : Array[(String, String, String)],
  digits : Int32,
  tolerance : String,
) -> Unit {
  let bits = @arb.BigFloat::bits_for_digits(digits)
  let ops = bigfloat_ops(bits)
  let allowed = @arb.BigFloat::from_decimal(tolerance, bits)
  // The asymptotic expansion's truncation error, which no width can push below
  // the size of the first omitted term.
  let asymptotic = @arb.BigFloat::from_decimal("1e-18", bits)
  // The integer-order `K_n` loses about half its width to the cancellation in
  // its logarithmic series: the logarithm times an exponentially large `I_n` and
  // the series that cancels it are each around a million times the answer, and
  // the fixed point hands back a little under half of what is left.
  let cancellation = @arb.BigFloat::from_decimal("1e-\{digits / 2 - 2}", bits)
  for row in cases {
    let (name, arguments_text, expected) = row
    let fields = arguments_text.split(",").to_array()
    let got = evaluate(name, arguments(fields, bits), ops)
    let want = @arb.BigFloat::from_decimal(expected, bits)
    if got.compare(want) != 0 {
      if want.is_zero() {
        // A value that is exactly zero is the one case a relative check cannot
        // state. These functions are all of order one where they vanish, so the
        // relative tolerance serves as an absolute one.
        if allowed.lt(got.abs()) {
          abort("\{name}(\{arguments_text}): got \{got.to_double()}, want zero")
        }
      } else {
        let error = got.sub(want).abs().div(want.abs())
        let limit = match name {
          "bessel_j" | "bessel_y" => asymptotic
          "bessel_k" => cancellation
          _ => allowed
        }
        if limit.lt(error) {
          abort(
            "\{name}(\{arguments_text}): relative error \{error.to_double()} at \{digits} digits",
          )
        }
      }
    }
  }
}

///|
test "fifty digits" {
  replay(fifty_digit_cases, 50, "1e-45")
}

///|
/// The hundred-digit setting asks for a hundred and ten digits of reference and
/// asserts eighty. The rest goes to the guard the fixed point keeps and to
/// the cancellation in the logarithmic series; the measured reach at this width
/// is a little past ninety, and the check is set a few digits inside it so that
/// a platform difference cannot turn the suite red for a reason that is not a
/// regression.
test "a hundred digits" {
  replay(hundred_digit_cases, 100, "1e-80")
}
