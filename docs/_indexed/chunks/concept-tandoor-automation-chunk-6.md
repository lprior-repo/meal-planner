---
doc_id: concept/tandoor/automation
chunk_id: concept/tandoor/automation#chunk-6
heading_path: ["Automation", "Transpose Words"]
chunk_type: prose
tokens: 253
summary: "Transpose Words"
---

## Transpose Words

Some recipes list the food before the units for some foods (garlic cloves). This automation will transpose 2 words in an
ingredient so "garlic cloves" will automatically become "cloves garlic"

-   **Parameter 1**: first word to detect
-   **Parameter 2**: second word to detect

These rules are processed whenever you are importing recipes from websites or other apps
and when using the simple ingredient input (shopping, recipe editor, ...).

# Order

> **Context**: <!-- prettier-ignore --> !!! warning Automations are currently in a beta stage. They work pretty stable but if I encounter any issues while working on

If the Automation type allows for more than one rule to be executed (for example description replace)
the rules are processed in ascending order (ordered by the _order_ property of the automation).
The default order is always 1000 to make it easier to add automations before and after other automations.

Example:

1. Rule ABC (order 1000) replaces `everything` with `abc`
2. Rule DEF (order 2000) replaces `everything` with `def`
3. Rule XYZ (order 500) replaces `everything` with `xyz`

After processing rules XYZ, then ABC and then DEF the description will have the value `def`
