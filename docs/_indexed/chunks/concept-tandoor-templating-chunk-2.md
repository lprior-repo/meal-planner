---
doc_id: concept/tandoor/templating
chunk_id: concept/tandoor/templating#chunk-2
heading_path: ["Templating", "Using Templating"]
chunk_type: prose
tokens: 172
summary: "Using Templating"
---

## Using Templating
Currently the only available variable in the Templating context is `ingredients`.

`ingredients` is an array that contains all ingredients of the current recipe step. You can access an ingredient by using
`{{ ingredients[<index in list>] }}` where the index refers to the position in the list of ingredients starting with zero.
You can also use the interaction menu of the ingredient to copy its reference.

!!! warning
    Please note that changing the order of the ingredients will break the reference (or at least make it useless).
    See the technical reasoning for more information on why it is this way.

![image](https://user-images.githubusercontent.com/6819595/103709654-5d6b8580-4fb3-11eb-9d04-36ab5a993f90.png)

You can also access only the amount, unit, note or food inside your instruction text using
```json
{{ ingredients[0].amount }}
{{ ingredients[0].unit }}
{{ ingredients[0].food }}
{{ ingredients[0].note }}
```
