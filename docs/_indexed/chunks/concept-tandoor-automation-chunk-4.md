---
doc_id: concept/tandoor/automation
chunk_id: concept/tandoor/automation#chunk-4
heading_path: ["Automation", "Instruction Replace, Title Replace, Food Replace & Unit Replace"]
chunk_type: prose
tokens: 118
summary: "Instruction Replace, Title Replace, Food Replace & Unit Replace"
---

## Instruction Replace, Title Replace, Food Replace & Unit Replace

These work just like the Description Replace automation.
Instruction, Food and Unit Replace will run against every iteration of the object in a recipe during import.
- Instruction Replace will run for the instructions in every step.  It will also replace every occurrence, not just the first.
- Food & Unit Replace will run for every food and unit in every ingredient in every step.

Also instead of just replacing a single occurrence of the matched pattern it will replace all.
