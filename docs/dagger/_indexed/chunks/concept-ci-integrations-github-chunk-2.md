---
doc_id: concept/ci-integrations/github
chunk_id: concept/ci-integrations/github#chunk-2
heading_path: ["github", "How it works"]
chunk_type: prose
tokens: 124
summary: "GitHub contains a shorthand redirect at the `/merge` endpoint that allows you to reference the co..."
---
GitHub contains a shorthand redirect at the `/merge` endpoint that allows you to reference the correct branch of a repository from a pull request (PR), without needing to know anything about the fork or branch where the PR came from.

By default, the Dagger `Directory` type works with both local directories and [remote Git repositories](./tutorial-extending-remote-repositories.md). This makes it possible to work with the directory tree at the root of a Git repository or a given branch.

By combining these two features, Dagger users can write Dagger Functions that directly use GitHub pull requests as arguments.
