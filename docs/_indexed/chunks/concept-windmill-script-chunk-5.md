---
doc_id: concept/windmill/script
chunk_id: concept/windmill/script#chunk-5
heading_path: ["Scripts", "(Re-)Generating a script metadata file"]
chunk_type: code
tokens: 401
summary: "(Re-)Generating a script metadata file"
---

## (Re-)Generating a script metadata file

The `wmill script generate-metadata` command is used to read all the files that have been edited and gracefully update the metadata file and lockfile accordingly, inferring the script schema from the script content and generating the locks. Only the schema and the locks part of the metadata file will be updated. If a change was made to other fields like description or summary, it will be kept.

This command can only be run at the same level of the `wmill-lock.yaml` of your workspace, so by default at top level of the repository.

```bash
wmill script generate-metadata
```text

You can also generate metadata for a single script with `wmill script generate-metadata <path>`:

```bash
wmill script generate-metadata [--lock-only] [--schema-only] [<path>]
```text

Note that you can explicitly exclude (or include) specific files or folders to be taken into account by this command, with a [`wmill.yaml` file](https://github.com/windmill-labs/windmill-sync-example/blob/main/wmill.yaml).

[Flows](./concept-windmill-flow.md) inline script lockfiles can be also updated locally in the same way as `wmill script generate-metadata --lock-only` but for flows' inline scripts:

```bash
wmill flow generate-locks
```text

### package.json & requirements.txt

When doing `wmill script generate-metadata`, if a `package.json` or `requirements.txt` is discovered, the closest one will be used as source-of-truth instead of being discovered from the imports in the script directly to generate the lockfile from the server.

Below is a video on how to override Windmill inferred dependencies by [providing custom package.json](./meta-windmill-index-5.md#lockfile-per-script-inferred-from-a-packagejson) or requirements.txt.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/T8jMjpNvC2g"
	title="Override Inferred Dependencies with Custom Dependency Files"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

### Arguments

| Argument | Description                          |
| -------- | ------------------------------------ |
| `path`   | The path of the script content file. |

### Examples

1. After update the of the script `f/scripts/hallowed_script.py`, re-generate its schema and its locks:

```bash
wmill script generate-metadata f/scripts/hallowed_script.py
```text
