---
doc_id: concept/getting-started/types-directory
chunk_id: concept/getting-started/types-directory#chunk-1
heading_path: ["types-directory"]
chunk_type: prose
tokens: 198
summary: "> **Context**: Dagger Functions do not have access to the filesystem of the host you invoke the D..."
---
# Directory

> **Context**: Dagger Functions do not have access to the filesystem of the host you invoke the Dagger Function from. Instead, host files and directories need to be...


Dagger Functions do not have access to the filesystem of the host you invoke the Dagger Function from. Instead, host files and directories need to be explicitly passed as command-line arguments to Dagger Functions.

There are two important reasons for this:

- **Reproducibility**: By providing a call-time mechanism to define and control the files available to a Dagger Function, Dagger guards against creating hidden dependencies on ambient properties of the host filesystem.
- **Security**: By forcing you to explicitly specify which host files and directories a Dagger Function "sees" on every call, Dagger ensures that you're always 100% in control.

The `Directory` type represents the state of a directory. This could be either a local directory path or a remote Git reference.
