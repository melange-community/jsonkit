include Jsonkit_jsonschema.Primitives

let string_of_json json = Jsonkit_json.Of_json.string json
let bool_of_json json = Jsonkit_json.Of_json.bool json
let float_of_json json = Jsonkit_json.Of_json.float json
let int_of_json json = Jsonkit_json.Of_json.int json
let int64_of_json json = Jsonkit_json.Of_json.int64 json

let option_of_json v_of_json json =
  Jsonkit_json.Of_json.option v_of_json json

let unit_of_json json = Jsonkit_json.Of_json.unit json

let result_of_json ok_of_json err_of_json json =
  Jsonkit_json.Of_json.result ok_of_json err_of_json json

let list_of_json v_of_json json = Jsonkit_json.Of_json.list v_of_json json

let array_of_json v_of_json json =
  Jsonkit_json.Of_json.array v_of_json json

let string_to_json v = Jsonkit_json.To_json.string v
let bool_to_json v = Jsonkit_json.To_json.bool v
let float_to_json v = Jsonkit_json.To_json.float v
let int_to_json v = Jsonkit_json.To_json.int v
let int64_to_json v = Jsonkit_json.To_json.int64 v
let option_to_json v_to_json v = Jsonkit_json.To_json.option v_to_json v
let unit_to_json v = Jsonkit_json.To_json.unit v

let result_to_json a_to_json b_to_json v =
  Jsonkit_json.To_json.result a_to_json b_to_json v

let list_to_json v_to_json vs = Jsonkit_json.To_json.list v_to_json vs
let array_to_json v_to_json vs = Jsonkit_json.To_json.array v_to_json vs
