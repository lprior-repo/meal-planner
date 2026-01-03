---
id: concept/windmill/user
title: "Users management"
category: concept
tags: ["windmill", "concept", "users"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI User Management</title>
  <description>Manage users via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Users management" level="1"/>
    <section name="Adding a user" level="2"/>
    <section name="Removing a user" level="2"/>
    <section name="Creating a token" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>user_management</feature>
    <feature>token_creation</feature>
    <feature>authentication</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="3">
    <example>Create user with auto-generated password</example>
    <example>Create user with specified password</example>
    <example>Create superadmin user with company details</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>6</estimated_reading_time>
  <tags>windmill,cli,wmill,user,add,remove,token,authentication,superadmin</tags>
</doc_metadata>
-->

# Users management

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI User Management</title> <description>Manage users via CLI</des

## Adding a user

The `wmill user add` command is used to add a new user to the remote server.

```bash
wmill user add <email:string> [password:string] [--superadmin] [--company <company:string>] [--name <name:string>]
```text

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
```text

2. Create a new user with the email "example@example.com" and specify a password:

```bash
wmill user add example@example.com mypassword123
```text

3. Create a new superadmin user with the email "example@example.com", a specified password, and additional information:

```bash
wmill user add example@example.com mypassword123 --superadmin --company "Acme Inc." --name "John Doe"
```text

## Removing a user

The `wmill user remove` command is used to remove a user from the remote server.

```bash
wmill user remove <email:string>
```text

### Arguments

| Argument | Description                                  |
| -------- | -------------------------------------------- |
| `email`  | The email address of the user to be removed. |

### Examples

1. Remove the user with the email "example@example.com"

```bash
wmill user remove example@example.com
```text

## Creating a token

The wmill user create-token command allows you to create an authentication token for a user. This token can be used for subsequent authenticated requests to the API server.

```bash
wmill user create-token [--email <email:string> --password <password:string>]
```

There are two ways to create a token:

- Option 1: Specify email and password for authentication:
  Use the --email option to specify the email address of the user.
  Use the --password option to specify the password of the user.
  The command will exchange the provided credentials for a token with the API server and display the generated token.

- Option 2: Already logged in:
  If you are already logged in, you can run the command without providing email and password.
  The command will use your existing authentication credentials to create a token and display it.

The command will display the generated token, which can be used for subsequent authenticated requests. Note that the token is not stored locally.


## See Also

- [Documentation Index](./COMPASS.md)
