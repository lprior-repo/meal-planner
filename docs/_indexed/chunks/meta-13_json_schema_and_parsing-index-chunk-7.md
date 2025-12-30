---
doc_id: meta/13_json_schema_and_parsing/index
chunk_id: meta/13_json_schema_and_parsing/index#chunk-7
heading_path: ["JSON schema and parsing", "Function for flow input field named \"foo\""]
chunk_type: prose
tokens: 79
summary: "Function for flow input field named \"foo\""
---

## Function for flow input field named "foo"
def foo(x: str, y: int, text):
  if text == "42":
    return [{"value": "42", "label": "The answer to the universe"}]
  if x == "bar":
    return [{"value": "barbar", "label": "barbarbar"}]
  return [
    { "value": '1', "label": 'Foo' + x + str(y) },
    { "value": '2', "label": 'Bar' },
    { "value": '3', "label": 'Foobar' }
  ]
