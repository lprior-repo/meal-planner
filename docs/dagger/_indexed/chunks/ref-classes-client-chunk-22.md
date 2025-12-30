---
doc_id: ref/classes/client
chunk_id: ref/classes/client#chunk-22
heading_path: ["client", "Methods", "git()"]
chunk_type: prose
tokens: 46
summary: "> **git**(`url`, `opts?"
---
> **git**(`url`, `opts?`): [`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

Queries a Git repository.

#### Parameters

#### url

`string`

URL of the git repository.

Can be formatted as `https://{host}/{owner}/{repo}`, `git@{host}:{owner}/{repo}`.

Suffix ".git" is optional.

#### opts?

[`ClientGitOpts`](/reference/typescript/api/client.gen/type-aliases/ClientGitOpts)

#### Returns

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

---
