---
doc_id: concept/3_cli/user
chunk_id: concept/3_cli/user#chunk-3
heading_path: ["Users management", "Removing a user"]
chunk_type: code
tokens: 85
summary: "Removing a user"
---

## Removing a user

The `wmill user remove` command is used to remove a user from the remote server.

```bash
wmill user remove <email:string>
```

### Arguments

| Argument | Description                                  |
| -------- | -------------------------------------------- |
| `email`  | The email address of the user to be removed. |

### Examples

1. Remove the user with the email "example@example.com"

```bash
wmill user remove example@example.com
```
