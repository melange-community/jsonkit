  $ bindings() { "$1" -impl - | ocamlformat - --impl | grep -E '^  (let rec|and) (a_|b_|of_json|to_json|lst_|tree_|forest_)'; }

  $ cat <<"EOF" | bindings ../native/ppx_deriving_json_native_test.exe
  > type a = A of b
  > and b = int [@@deriving json]
  > type t = N | S of t [@@deriving json]
  > type 'a lst = Nil | Cons of 'a * 'a lst [@@deriving json]
  > type 'a tree =
  >   | Leaf of 'a
  >   | Node of 'a * 'a forest
  > and 'a forest =
  >   | Empty
  >   | Base of 'a tree * 'a forest [@@deriving json]
  > EOF
    let rec a_of_json =
    and b_of_json =
    let rec a_to_json =
    and b_to_json =
    let rec of_json =
    let rec to_json =
    let rec lst_of_json of_json__a =
    let rec lst_to_json to_json__a =
    let rec tree_of_json of_json__a =
    and forest_of_json of_json__a =
    let rec tree_to_json to_json__a =
    and forest_to_json to_json__a =

  $ cat <<"EOF" | bindings ../browser/ppx_deriving_json_js_test.exe
  > type a = A of b
  > and b = int [@@deriving json]
  > type t = N | S of t [@@deriving json]
  > type 'a lst = Nil | Cons of 'a * 'a lst [@@deriving json]
  > type 'a tree =
  >   | Leaf of 'a
  >   | Node of 'a * 'a forest
  > and 'a forest =
  >   | Empty
  >   | Base of 'a tree * 'a forest [@@deriving json]
  > EOF
    let rec a_of_json =
    and b_of_json =
    let rec a_to_json =
    and b_to_json =
    let rec of_json =
    let rec to_json =
    let rec lst_of_json of_json__a =
    let rec lst_to_json to_json__a =
    let rec tree_of_json of_json__a =
    and forest_of_json of_json__a =
    let rec tree_to_json to_json__a =
    and forest_to_json to_json__a =
