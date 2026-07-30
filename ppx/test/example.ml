type user = int [@@deriving json]
type userid = int64 [@@deriving json]
type floaty = float [@@deriving json]
type 'a param = 'a [@@deriving json]
type opt = string option [@@deriving json]
type res = (int, string) result [@@deriving json]
type tuple = int * string [@@deriving json]
type record = { name : string; age : int } [@@deriving json]
type record_aliased = { name : string; [@json.key "my_name"] age : int; [@json.key "my_age"] [@json.default 100] } [@@deriving json]
type record_opt = { k : int option; [@json.option] } [@@deriving json]
type sum = A | B of int | C of { name : string } [@@deriving json]
type sum2 = S2 of int * string [@@deriving json]
type other = [ `C ] [@@deriving json]
type poly = [ `A | `B of int | other ] [@@deriving json]
type poly2 = [ `P2 of int * string ] [@@deriving json]
type poly3 = [ poly | poly2 ] [@@deriving json]
type foo = A | B [@@deriving json]
module X = struct
  type nonrec foo = foo [@@deriving json]
end
module Recursive_types = struct
  type a = A of b
  and b = int [@@deriving json]

  type t = N | S of t [@@deriving json]

  type 'a lst = Nil | Cons of 'a * 'a lst [@@deriving json]

  type 'a tree =
    | Leaf of 'a
    | Node of 'a * 'a forest

  and 'a forest =
    | Empty
    | Base of 'a tree * 'a forest [@@deriving json]
end
type 'a c = [ `C of 'a ] [@@deriving json]
type recur = A | Fix of recur [@@deriving json]
type polyrecur = [ `A | `Fix of polyrecur ] [@@deriving json]
type evar = A | B [@json.name "b_aliased"] [@@deriving json]
type epoly = [ `a [@json.name "A_aliased"] | `b ] [@@deriving json]
type ('a, 'b) p2 = A of 'a | B of 'b [@@deriving json]
type allow_extra_fields = {a: int} [@@deriving json] [@@json.allow_extra_fields]
type allow_extra_fields2 = A of {a: int} [@json.allow_extra_fields] [@@deriving json]
type disallow_extra_fields = {a: int} [@@deriving json] [@@json.disallow_extra_fields]
type disallow_extra_fields2 = A of {a: int} [@json.disallow_extra_fields] [@@deriving json]
type drop_default_option = { a: int; b_opt: int option; [@option] [@json.drop_default] } [@@deriving json]
let equal_int = Int.equal
type drop_default_int = { dd_a: int; dd_b: int [@json.default 0] [@json.drop_default] } [@@deriving json]
type drop_default_expr = { dde_a: int; dde_b: int [@json.default 0] [@json.drop_default Int.equal] } [@@deriving json]
type drop_default_if_json_eq = { ddj_a: int; ddj_b: int [@json.default 0] [@json.drop_default_if_json_equal] } [@@deriving json]
type inner_with_option_field = { foo: int option [@option] [@json.drop_default] } [@@deriving json]
let empty_inner_with_option_field : inner_with_option_field = { foo = None }
type outer_default_record_with_option = {
  inner: inner_with_option_field; [@json.default empty_inner_with_option_field]
} [@@deriving json]
type array_list = { a: int array; b: int list} [@@deriving json]
type json = Jsonkit.t
type of_json = C : string * (json -> 'a) * ('a -> json) * 'a -> of_json
type color = Red | Green | Blue [@@deriving json]
type compact_variant = Compact_variant | Compact_variant_of_int of int [@@deriving json] [@@json.compact_variants]
type compact_polyvariant = [`Compact_polyvariant | `Compact_polyvariant_of_int of int] [@@deriving json] [@@json.compact_variants]

type shape = 
  | Circle of float  (* radius *)
  | Rectangle of float * float  (* width * height *)
  | Point of { x: float; y: float } [@@deriving json]

let of_json_cases = [
  C ({|"Compact_variant"|}, compact_variant_of_json, compact_variant_to_json, (Compact_variant : compact_variant));
  C ({|["Compact_variant"]|}, compact_variant_of_json, compact_variant_to_json, (Compact_variant : compact_variant));
  C ({|["Compact_variant_of_int",42]|}, compact_variant_of_json, compact_variant_to_json, (Compact_variant_of_int 42 : compact_variant));
  C ({|"Compact_polyvariant"|}, compact_polyvariant_of_json, compact_polyvariant_to_json, (`Compact_polyvariant : compact_polyvariant));
  C ({|["Compact_polyvariant"]|}, compact_polyvariant_of_json, compact_polyvariant_to_json, (`Compact_polyvariant : compact_polyvariant));
  C ({|["Compact_polyvariant_of_int",42]|}, compact_polyvariant_of_json, compact_polyvariant_to_json, (`Compact_polyvariant_of_int 42 : compact_polyvariant));
  C ({|1|}, user_of_json, user_to_json, 1);
  C ({|"9223372036854775807"|}, userid_of_json, userid_to_json, 9223372036854775807L);
  C ({|1.1|}, floaty_of_json, floaty_to_json, 1.1);
  C ({|1.0|}, floaty_of_json, floaty_to_json, 1.0);
  C ({|42|}, floaty_of_json, floaty_to_json, 42.0);
  C ({|"OK"|}, (param_of_json string_of_json), (param_to_json string_to_json), "OK");
  C ({|"some"|}, opt_of_json, opt_to_json, (Some "some"));
  C ({|["Ok", 1]|}, res_of_json, res_to_json, Ok 1);
  C ({|["Error", "oops"]|}, res_of_json, res_to_json, Error "oops");
  C ({|[42, "works"]|}, tuple_of_json, tuple_to_json, (42, "works"));
  C ({|{"name":"N","age":1,"extra":true}|}, record_of_json, record_to_json, {name="N"; age=1});
  C ({|["A"]|}, sum_of_json, sum_to_json, (A : sum));
  C ({|["B", 42]|}, sum_of_json, sum_to_json, (B 42 : sum));
  C ({|["C", {"name": "cname", "extra": true}]|}, sum_of_json, sum_to_json, (C {name="cname"} : sum));
  C ({|["A"]|}, sum_of_json, sum_to_json, (A : sum));
  C ({|["S2", 42, "hello"]|}, sum2_of_json, sum2_to_json, (S2 (42, "hello")));
  C ({|["B", 42]|}, poly_of_json, poly_to_json, (`B 42 : poly));
  C ({|["C"]|}, poly_of_json, poly_to_json, (`C : poly));
  C ({|["P2", 42, "hello"]|}, poly2_of_json, poly2_to_json, (`P2 (42, "hello") : poly2));
  C ({|["P2", 42, "hello"]|}, poly3_of_json, poly3_to_json, (`P2 (42, "hello") : poly3));
  C ({|["A"]|}, poly3_of_json, poly3_to_json, (`A : poly3));
  C ({|["A"]|}, X.foo_of_json, X.foo_to_json, (A : X.foo));
  C ({|["B"]|}, X.foo_of_json, X.foo_to_json, (B : X.foo));
  C ({|["A", 42]|}, Recursive_types.a_of_json, Recursive_types.a_to_json, (Recursive_types.A 42 : Recursive_types.a));
  C ({|["S", ["S", ["N"]]]|}, Recursive_types.of_json, Recursive_types.to_json, (Recursive_types.S (Recursive_types.S Recursive_types.N) : Recursive_types.t));
  C ({|["Cons", 1, ["Cons", 2, ["Nil"]]]|}, Recursive_types.lst_of_json int_of_json, Recursive_types.lst_to_json int_to_json, (Recursive_types.Cons (1, Recursive_types.Cons (2, Recursive_types.Nil)) : int Recursive_types.lst));
  C ({|["Node", 1, ["Base", ["Leaf", 2], ["Empty"]]]|}, Recursive_types.tree_of_json int_of_json, Recursive_types.tree_to_json int_to_json, (Recursive_types.Node (1, Recursive_types.Base (Recursive_types.Leaf 2, Recursive_types.Empty)) : int Recursive_types.tree));
  C ({|["Base", ["Leaf", 1], ["Base", ["Leaf", 2], ["Empty"]]]|}, Recursive_types.forest_of_json int_of_json, Recursive_types.forest_to_json int_to_json, (Recursive_types.Base (Recursive_types.Leaf 1, Recursive_types.Base (Recursive_types.Leaf 2, Recursive_types.Empty)) : int Recursive_types.forest));
  C ({|["Fix",["Fix",["Fix",["A"]]]]|}, recur_of_json, recur_to_json, (Fix (Fix (Fix A))));
  C ({|["Fix",["Fix",["Fix",["A"]]]]|}, polyrecur_of_json, polyrecur_to_json, (`Fix (`Fix (`Fix `A))));
  C ({|["A"]|}, evar_of_json, evar_to_json, (A : evar));
  C ({|["b_aliased"]|}, evar_of_json, evar_to_json, (B : evar)); (* variant B repr as "b_aliased" in JSON *)
  C ({|["b"]|}, epoly_of_json, epoly_to_json, (`b : epoly));
  C ({|["A_aliased"]|}, epoly_of_json, epoly_to_json, (`a : epoly)); (* polyvariant `a aliased to "A_aliased"*)
  C ({|{"my_name":"N","my_age":1}|}, record_aliased_of_json, record_aliased_to_json, {name="N"; age=1});
  C ({|{"my_name":"N"}|}, record_aliased_of_json, record_aliased_to_json, {name="N"; age=100});
  C ({|{}|}, record_opt_of_json, record_opt_to_json, {k=None});
  C ({|{"k":42}|}, record_opt_of_json, record_opt_to_json, {k=Some 42});
  C ({|["A",1]|}, p2_of_json int_of_json string_of_json, p2_to_json int_to_json string_to_json, A 1);
  C ({|["B","ok"]|}, p2_of_json int_of_json string_of_json, p2_to_json int_to_json string_to_json, B "ok");
  C ({|{"a":1,"b":2}|}, allow_extra_fields_of_json, allow_extra_fields_to_json, {a=1});
  C ({|["A",{"a":1,"b":2}]|}, allow_extra_fields2_of_json, allow_extra_fields2_to_json, A {a=1});
  C ({|{"a":3}|}, disallow_extra_fields_of_json, disallow_extra_fields_to_json, {a=3});
  C ({|["A",{"a":4}]|}, disallow_extra_fields2_of_json, disallow_extra_fields2_to_json, A {a=4});
  C ({|{"a":1}|}, drop_default_option_of_json, drop_default_option_to_json, {a=1; b_opt=None});
  C ({|{"a":1,"b_opt":2}|}, drop_default_option_of_json, drop_default_option_to_json, {a=1; b_opt=Some 2});
  C ({|{"dd_a":1}|}, drop_default_int_of_json, drop_default_int_to_json, {dd_a=1; dd_b=0});
  C ({|{"dd_a":1,"dd_b":5}|}, drop_default_int_of_json, drop_default_int_to_json, {dd_a=1; dd_b=5});
  C ({|{"dde_a":1}|}, drop_default_expr_of_json, drop_default_expr_to_json, {dde_a=1; dde_b=0});
  C ({|{"dde_a":1,"dde_b":5}|}, drop_default_expr_of_json, drop_default_expr_to_json, {dde_a=1; dde_b=5});
  C ({|{"ddj_a":1}|}, drop_default_if_json_eq_of_json, drop_default_if_json_eq_to_json, {ddj_a=1; ddj_b=0});
  C ({|{"ddj_a":1,"ddj_b":5}|}, drop_default_if_json_eq_of_json, drop_default_if_json_eq_to_json, {ddj_a=1; ddj_b=5});
  C ({|{"inner":{}}|}, outer_default_record_with_option_of_json, outer_default_record_with_option_to_json, {inner = {foo = None}});
  C ({|{"inner":{"foo":5}}|}, outer_default_record_with_option_of_json, outer_default_record_with_option_to_json, {inner = {foo = Some 5}});
  C ({|{}|}, outer_default_record_with_option_of_json, outer_default_record_with_option_to_json, {inner = empty_inner_with_option_field});
  C ({|{"a":[1],"b":[2]}|}, array_list_of_json, array_list_to_json, {a=[|1|]; b=[2]});
  C ({|["Circle", 5.0]|}, shape_of_json, shape_to_json, Circle 5.0);
  C ({|["Rectangle", 10.0, 20.0]|}, shape_of_json, shape_to_json, Rectangle (10.0, 20.0));
  C ({|["Point", {"x": 1.0, "y": 2.0}]|}, shape_of_json, shape_to_json, Point {x=1.0; y=2.0});
]
let run' (C (data, of_json, to_json, v)) =
  print_endline (Printf.sprintf "JSON    DATA: %s" data);
  let json = Jsonkit.of_string data in
  let v' = of_json json in
  assert (v' = v);
  let json' = to_json v' in
  let data' = Jsonkit.to_string json' in
  print_endline (Printf.sprintf "JSON REPRINT: %s" data')

(* Error cases for object validation *)
type must_be_object = { field: int } [@@deriving json]
type must_be_array_2 = (int * int) [@@deriving json]
type must_be_array_3 = (int * int * int) [@@deriving json]

let error_cases = [
  (* Should fail with "expected a JSON object" *)
  C ({|42|}, must_be_object_of_json, must_be_object_to_json, {field=1});
  
  (* Should fail with "expected a JSON array of length 2" *)
  C ({|[1]|}, must_be_array_2_of_json, must_be_array_2_to_json, (1, 2));
  C ({|[1,2,3]|}, must_be_array_2_of_json, must_be_array_2_to_json, (1, 2));
  
  (* Should fail with "expected a JSON array of length 3" *)
  C ({|[1,2]|}, must_be_array_3_of_json, must_be_array_3_to_json, (1, 2, 3));
  C ({|[1,2,3,4]|}, must_be_array_3_of_json, must_be_array_3_to_json, (1, 2, 3));

  (* Should fail with "expected a JSON string representing a variant" *)
  C ({|42|}, color_of_json, color_to_json, Red);
  C ({|"Yellow"|}, color_of_json, color_to_json, Red);

  (* Should fail with disallowed extra fields *)
  C ({|{"a":1,"b":2}|}, disallow_extra_fields_of_json, disallow_extra_fields_to_json, {a=1});
  C ({|["A",{"a":1,"b":2}]|}, disallow_extra_fields2_of_json, disallow_extra_fields2_to_json, A {a=1});

  (* Should fail with shape validation *)
  C ({|["Circle"]|}, shape_of_json, shape_to_json, Circle 1.0);
  C ({|["Rectangle", 10.0]|}, shape_of_json, shape_to_json, Rectangle (10.0, 20.0));
  C ({|["Point", 1.0, 2.0]|}, shape_of_json, shape_to_json, Point {x=1.0; y=2.0});
]

let run_error_case' (C (data, of_json, _to_json, _v)) =
  print_endline (Printf.sprintf "ERROR CASE DATA: %s" data);
  let json = Jsonkit.of_string data in
  try
    let _v' = of_json json in
    print_endline "Error: should have failed"
  with Jsonkit.Of_json_error (Json_error msg) ->
    print_endline (Printf.sprintf "Got expected error: %s" msg)

let test () =
  List.iter run' of_json_cases;
  print_endline "\nTesting error cases:";
  List.iter run_error_case' error_cases
