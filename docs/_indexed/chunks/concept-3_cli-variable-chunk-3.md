---
doc_id: concept/3_cli/variable
chunk_id: concept/3_cli/variable#chunk-3
heading_path: ["Variables", "Adding a variable"]
chunk_type: code
tokens: 245
summary: "Adding a variable"
---

## Adding a variable

The `wmill variable add` command allows you to add a new variable to the remote workspace.

```bash
wmill add <remote_path:string> --value=<value:string> [--secret] [--description=<description:string>] [--account=<account:number>] [--oauth]
```text

### Arguments

| Argument      | Description                                       |
| ------------- | ------------------------------------------------- |
| `remote_path` | The path of the variable in the remote workspace. |

### Options

| Option            | parameter       | Description                                                              |
| ----------------- | --------------- | ------------------------------------------------------------------------ |
| `--value`         | `<value>`       | The value of the variable.                                               |
| `--plain-secrets` | None            | (Optional) Specifies whether the variable is plain and not a secret      |
| `--description`   | `<description>` | (Optional) A description of the variable.                                |
| `--account`       | `<account>`     | (Optional) The account associated with the variable.                     |
| `--oauth`         | None            | (Optional) Specifies whether the variable requires OAuth authentication. |

### Example

This command adds a new variable with the path "my_variable" to the remote workspace. The value is set to "12345", marked as a secret, and associated with account number 1. A description is also provided for the variable.

```bash
wmill add my_variable --value=12345 --secret --description="My secret variable" --account=1
```text
