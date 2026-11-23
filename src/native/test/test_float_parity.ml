let failures = ref 0

let yojson v =
  let b = Buffer.create 32 in
  Yojson.Basic.write_float b v;
  Buffer.contents b

let check v =
  let expected = yojson v in
  let actual = Jsonkit.Writer.to_string Jsonkit.Writer.float v in
  if expected <> actual then (
    incr failures;
    if !failures <= 20 then
      Printf.printf "FAIL %h (%.17g)\n  yojson: %s\n  writer: %s\n" v v
        expected actual)

let () =
  List.iter check
    [
      0.;
      -0.;
      1.;
      -1.;
      42.;
      0.1;
      0.5;
      1. /. 3.;
      3.141592653589793;
      1e15;
      -1e15;
      9999999999999998.;
      1e16;
      1e17;
      1e22;
      1e-5;
      1e-310;
      4.9e-324;
      max_float;
      -.max_float;
      min_float;
      Float.nan;
      Float.infinity;
      Float.neg_infinity;
      0.3;
      2.675;
      1.0000000000000002;
      123456789.123456789;
      5e-324;
      1.7976931348623157e308;
    ];
  let state = ref 123456789L in
  let next () =
    let x = !state in
    let x = Int64.logxor x (Int64.shift_left x 13) in
    let x = Int64.logxor x (Int64.shift_right_logical x 7) in
    let x = Int64.logxor x (Int64.shift_left x 17) in
    state := x;
    x
  in
  for _ = 1 to 3_000_000 do
    check (Int64.float_of_bits (next ()))
  done;
  for _ = 1 to 1_000_000 do
    let v = Int64.to_float (Int64.rem (next ()) 1_000_000_000L) in
    check v;
    check (v /. 8.);
    check (v /. 100.);
    check (v *. 1e-7)
  done;
  if !failures = 0 then print_endline "jsonkit float parity: ok"
  else (
    Printf.printf "jsonkit float parity: %d failure(s)\n" !failures;
    exit 1)
