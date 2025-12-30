---
doc_id: ref/classes/gitrepository
chunk_id: ref/classes/gitrepository#chunk-4
heading_path: ["gitrepository", "Methods"]
chunk_type: prose
tokens: 299
summary: "> **branch**(`name`): [`GitRef`](/reference/typescript/api/client."
---
### branch()

> **branch**(`name`): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details of a branch.

#### Parameters

#### name

`string`

Branch's name (e.g., "main").

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### branches()

> **branches**(`opts?`): `Promise`<`string`\[\]>

branches that match any of the given glob patterns.

#### Parameters

#### opts?

[`GitRepositoryBranchesOpts`](/reference/typescript/api/client.gen/type-aliases/GitRepositoryBranchesOpts)

#### Returns

`Promise`<`string`\[\]>

---

### commit()

> **commit**(`id`): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details of a commit.

#### Parameters

#### id

`string`

Identifier of the commit (e.g., "b6315d8f2810962c601af73f86831f6866ea798b").

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### head()

> **head**(): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details for HEAD.

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### id()

> **id**(): `Promise`<[`GitRepositoryID`](/reference/typescript/api/client.gen/type-aliases/GitRepositoryID)\>

A unique identifier for this GitRepository.

#### Returns

`Promise`<[`GitRepositoryID`](/reference/typescript/api/client.gen/type-aliases/GitRepositoryID)\>

---

### latestVersion()

> **latestVersion**(): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details for the latest semver tag.

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### ref()

> **ref**(`name`): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details of a ref.

#### Parameters

#### name

`string`

Ref's name (can be a commit identifier, a tag name, a branch name, or a fully-qualified ref).

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### tag()

> **tag**(`name`): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Returns details of a tag.

#### Parameters

#### name

`string`

Tag's name (e.g., "v0.3.9").

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### tags()

> **tags**(`opts?`): `Promise`<`string`\[\]>

tags that match any of the given glob patterns.

#### Parameters

#### opts?

[`GitRepositoryTagsOpts`](/reference/typescript/api/client.gen/type-aliases/GitRepositoryTagsOpts)

#### Returns

`Promise`<`string`\[\]>

---

### uncommitted()

> **uncommitted**(): [`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

Returns the changeset of uncommitted changes in the git repository.

#### Returns

[`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

---

### url()

> **url**(): `Promise`<`string`\>

The URL of the git repository.

#### Returns

`Promise`<`string`\>
