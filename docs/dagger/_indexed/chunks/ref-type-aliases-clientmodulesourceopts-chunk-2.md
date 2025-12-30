---
doc_id: ref/type-aliases/clientmodulesourceopts
chunk_id: ref/type-aliases/clientmodulesourceopts#chunk-2
heading_path: ["clientmodulesourceopts", "Properties"]
chunk_type: prose
tokens: 131
summary: "> `optional` **allowNotExists**: `boolean`

If true, do not error out if the provided ref string ..."
---
### allowNotExists?

> `optional` **allowNotExists**: `boolean`

If true, do not error out if the provided ref string is a local path and does not exist yet. Useful when initializing new modules in directories that don't exist yet.

---

### disableFindUp?

> `optional` **disableFindUp**: `boolean`

If true, do not attempt to find dagger.json in a parent directory of the provided path. Only relevant for local module sources.

---

### refPin?

> `optional` **refPin**: `string`

The pinned version of the module source

---

### requireKind?

> `optional` **requireKind**: [`ModuleSourceKind`](/reference/typescript/api/client.gen/enumerations/ModuleSourceKind)

If set, error out if the ref string is not of the provided requireKind.
