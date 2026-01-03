---
doc_id: ops/moonrepo/codeowners
chunk_id: ops/moonrepo/codeowners#chunk-1
heading_path: ["sync codeowners"]
chunk_type: prose
tokens: 136
summary: "Code owners"
---

# Code owners

> **Context**: Code owners enables companies to define individuals, teams, or groups that are responsible for code in a repository. This is useful in ensuring that p

v1.8.0

Code owners enables companies to define individuals, teams, or groups that are responsible for code in a repository. This is useful in ensuring that pull/merge requests are reviewed and approved by a specific set of contributors, before the branch is merged into the base branch.

With that being said, moon *does not* implement a custom code owners solution, and instead builds upon the popular `CODEOWNERS` integration in VCS providers, like GitHub, GitLab, and Bitbucket.
