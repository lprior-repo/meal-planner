---
doc_id: tutorial/extending/remote-repositories
chunk_id: tutorial/extending/remote-repositories#chunk-2
heading_path: ["remote-repositories", "Common SSH cloning patterns"]
chunk_type: mixed
tokens: 195
summary: "One approach is to pre-resolve a private Git repository into a `Directory` object at the top-leve..."
---
### Pass a remote directory as argument

One approach is to pre-resolve a private Git repository into a `Directory` object at the top-level call. This allows you to decide exactly which repository (and branch or commit) is made available to downstream modules:

```bash
dagger call clone --dir git@github.com:private/secret-repo@main
```

In this approach, the module simply receives a `Directory` object and never directly accesses your SSH agent. [Refer to the cookbook for an example](./concept-cookbook-filesystems.md#mount-or-copy-a-directory-or-remote-repository-to-a-container).

### Pass the host SSH agent socket as argument

Alternatively, you can allow a function to perform the Git clone by passing in your SSH socket:

```bash
dagger call clone-with-ssh --repository git@github.com:private/secret-repo.git \
  --ref main --sock "$SSH_AUTH_SOCK"
```

In this approach, the caller explicitly provides the SSH agent socket. This prevents hidden or unapproved use of SSH credentials because the module cannot complete the cloning operation without the user's approval. [Refer to the cookbook for an example](./concept-cookbook-filesystems.md#clone-a-remote-git-repository-into-a-container).
