---
doc_id: concept/3_cli/variable
chunk_id: concept/3_cli/variable#chunk-5
heading_path: ["Variables", "Variable specification"]
chunk_type: code
tokens: 76
summary: "Variable specification"
---

## Variable specification

### Structure

Here is an example of a variable specification:

```ts
{
  value: string,
  is_secret: boolean,
  description: string,
  extra_perms: object,
  account: number,
  is_oauth: boolean,
  is_expired: boolean
}
```text

### Example

```JSON
{
"value": "finland does not actually exist",
"is_secret": false,
"description": "This item is not secret",
"extra_perms": {},
"account": null,
"is_oauth": false,
"is_expired": false
}
```
