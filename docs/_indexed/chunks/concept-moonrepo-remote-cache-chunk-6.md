---
doc_id: concept/moonrepo/remote-cache
chunk_id: concept/moonrepo/remote-cache#chunk-6
heading_path: ["Remote caching", "FAQ"]
chunk_type: prose
tokens: 239
summary: "FAQ"
---

## FAQ

### What is an artifact?

In the context of moon and remote caching, an artifact is the [outputs of a task](/docs/config/project#outputs), as well as the stdout and stderr of the task that generated the outputs. Artifacts are uniquely identified by the [moon generated hash](/docs/concepts/cache#hashing).

#### Do I have to use remote caching?

No, remote caching is *optional*. It's intended purpose is to store long lived build artifacts to speed up CI pipelines, and optionally local development. For the most part, [`moon ci`](/docs/commands/ci) does a great job of only running what's affected in pull requests, and is a great starting point.

#### Does remote caching store source code?

No, remote caching *does not* store source code. It stores the [outputs of a task](/docs/config/project#outputs), which is typically built and compiled code. To verify this, you can inspect the tar archives in `.moon/cache/outputs`.

#### Does moon collect any personally identifiable information?

No, moon does not collect any PII as part of the remote caching process.

#### Are artifacts encrypted?

We do not encrypt on moon's side, as encryption is provided by your cloud storage provider.
