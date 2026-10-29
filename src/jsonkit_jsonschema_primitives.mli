type jsonschema = Jsonkit_jsonschema_classify.t

module Yojson : sig
  val char_jsonschema : jsonschema
  val string_jsonschema : jsonschema
  val bool_jsonschema : jsonschema
  val float_jsonschema : jsonschema
  val int_jsonschema : jsonschema
  val list_jsonschema : jsonschema -> jsonschema
  val array_jsonschema : jsonschema -> jsonschema
  val int64_jsonschema : jsonschema
end

module Jsonkit : sig
  val char_jsonschema : jsonschema
  val string_jsonschema : jsonschema
  val bool_jsonschema : jsonschema
  val float_jsonschema : jsonschema
  val int_jsonschema : jsonschema
  val option_jsonschema : jsonschema -> jsonschema
  val unit_jsonschema : jsonschema
  val list_jsonschema : jsonschema -> jsonschema
  val array_jsonschema : jsonschema -> jsonschema
  val int64_jsonschema : jsonschema
  val result_jsonschema : jsonschema -> jsonschema -> jsonschema
end
