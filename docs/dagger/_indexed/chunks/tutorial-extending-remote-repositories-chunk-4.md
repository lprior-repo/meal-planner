---
doc_id: tutorial/extending/remote-repositories
chunk_id: tutorial/extending/remote-repositories#chunk-4
heading_path: ["remote-repositories", "Best practices"]
chunk_type: prose
tokens: 130
summary: "For quick and easy referencing:

- Copy the repository ref from your preferred Git server's UI."
---
For quick and easy referencing:

- Copy the repository ref from your preferred Git server's UI.
- To specify a particular version or commit, append `#version` (for directory arguments) or `@version` (for modules).
- To target a specific directory within the repository, use the format `#version:subpath` (for directory arguments) or add a `/subpath` (for modules). Remember that the version is mandatory when specifying a subpath.
- For private repositories:
  - HTTPS: Ensure your Git credentials are properly configured using your provider's recommended method.
  - SSH: Make sure your SSH keys are properly set up and added to the SSH agent.
