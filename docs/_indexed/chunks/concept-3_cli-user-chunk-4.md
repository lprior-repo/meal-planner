---
doc_id: concept/3_cli/user
chunk_id: concept/3_cli/user#chunk-4
heading_path: ["Users management", "Creating a token"]
chunk_type: prose
tokens: 208
summary: "Creating a token"
---

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
