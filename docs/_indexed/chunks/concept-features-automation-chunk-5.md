---
doc_id: concept/features/automation
chunk_id: concept/features/automation#chunk-5
heading_path: ["Automation", "Never Unit"]
chunk_type: prose
tokens: 143
summary: "Never Unit"
---

## Never Unit

Some ingredients have a pattern of AMOUNT and FOOD, if the food has multiple words (e.g. egg yolk) this can cause Tandoor
to detect the word "egg" as a unit. This automation will detect the word 'egg' as something that should never be considered
a unit.

You can also create them manually by setting the following

-   **Parameter 1**: string to detect
-   **Parameter 2**: Optional: unit to insert into ingredient (e.g. 1 whole 'egg yolk' instead of 1 <empty> 'egg yolk')

These rules are processed whenever you are importing recipes from websites or other apps
and when using the simple ingredient input (shopping, recipe editor, ...).
