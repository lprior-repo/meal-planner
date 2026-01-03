---
doc_id: concept/moonrepo/query-lang
chunk_id: concept/moonrepo/query-lang#chunk-2
heading_path: ["Query language", "Syntax"]
chunk_type: code
tokens: 300
summary: "Syntax"
---

## Syntax

### Comparisons

A comparison (also known as an assignment) is an expression that defines a piece of criteria, and is a building block of a query. This criteria maps a [field](#fields) to a value, with an explicit comparison operator.

#### Equals, Not equals

The equals (`=`) and not equals (`!=`) comparison operators can be used for *exact* value matching.

```
projectType=library && language!=javascript
```

You can also define a list of values using square bracket syntax, that will match against one of the values.

```
language=[javascript, typescript]
```

#### Like, Not like

The like (`~`) and not like (`!~`) comparison operators can be used for *wildcard* value matching, using [glob syntax](/docs/concepts/file-pattern#globs).

```
projectSource~packages/* && tag!~*-app
```

> Like comparisons can only be used on non-enum fields.

### Conditions

The `&&` and `||` logical operators can be used to combine multiple comparisons into a condition. The `&&` operator is used to combine comparisons into a logical AND, and the `||` operator is used for logical OR.

```
taskToolchain=system || taskToolchain=node
```

For readability concerns, you can also use `AND` or `OR`.

```
taskToolchain=system OR taskToolchain=node
```

> Mixing both operators in the same condition is not supported.

### Grouping

For advanced queries and complex conditions, you can group comparisons using parentheses to create logical groupings. Groups can also be nested within other groups.

```
language=javascript && (taskType=test || taskType=build)
```
