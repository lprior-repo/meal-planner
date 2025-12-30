---
doc_id: concept/3_cli/user
chunk_id: concept/3_cli/user#chunk-2
heading_path: ["Users management", "Adding a user"]
chunk_type: code
tokens: 260
summary: "Adding a user"
---

## Adding a user

The `wmill user add` command is used to add a new user to the remote server.

```bash
wmill user add <email:string> [password:string] [--superadmin] [--company <company:string>] [--name <name:string>]
```

### Arguments

| Argument   | Description                                    |
| ---------- | ---------------------------------------------- |
| `email`    | The email address of the user to be added.     |
| `password` | The password of the user to be added. Optional |

### Options

| Option         | Parameters | Description                                 |
| -------------- | ---------- | ------------------------------------------- |
| `--superadmin` |            | Specify to make the new user superadmin.    |
| `--company`    | `company`  | Specify to set the company of the new user. |
| `--name`       | `name`     | Specify to set the company of the new user. |

### Examples

1. Create a new user with the email "example@example.com" and automatically generate a password:

```bash
wmill user add example@example.com
```

2. Create a new user with the email "example@example.com" and specify a password:

```bash
wmill user add example@example.com mypassword123
```

3. Create a new superadmin user with the email "example@example.com", a specified password, and additional information:

```bash
wmill user add example@example.com mypassword123 --superadmin --company "Acme Inc." --name "John Doe"
```
