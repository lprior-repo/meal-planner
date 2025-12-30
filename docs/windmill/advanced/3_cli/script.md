<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Script Commands</title>
  <description>Manage scripts via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Scripts" level="1"/>
    <section name="Listing scripts" level="2"/>
    <section name="Pushing a script" level="2"/>
    <section name="Creating a new script" level="2"/>
    <section name="(Re-)Generating a script metadata file" level="2"/>
    <section name="package.json & requirements.txt" level="2"/>
    <section name="Showing a script" level="2"/>
    <section name="Running a script" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>script_management</feature>
    <feature>script_push</feature>
    <feature>script_bootstrap</feature>
    <feature>metadata_generation</feature>
    <feature>script_run</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="4">
    <example>List all scripts in workspace</example>
    <example>Push local script to remote</example>
    <example>Create new Python script</example>
    <example>Generate metadata for script</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>8</estimated_reading_time>
  <tags>windmill,cli,wmill,script,push,bootstrap,run,metadata</tags>
</doc_metadata>
-->

# Scripts

## Listing scripts

The `wmill script` list command is used to list all scripts in the remote workspace.

```bash
wmill script
```

## Pushing a script

The wmill script push command is used to push a local script to the remote server, overriding any existing remote versions of the script. This command allows you to manage and synchronize your scripts across different environments.

This command support .ts, .js, .py, .go and .sh files.

```bash
wmill script push <path>
```

### Arguments

| Argument | Description                                                |
| -------- | ---------------------------------------------------------- |
| `path`   | The path to the local script file that needs to be pushed. |

### Examples

1. Push the script located at `/path/to/script.js`

```bash
wmill script push /path/to/script.js
```

## Creating a new script

The wmill script bootstrap command is used to create a new script locally in the desired language.

```bash
wmill script bootstrap [--summary <summary>] [--description <description>] <path> <language>
```

### Arguments

| Argument   | Description                                                                                                                                                                              |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `path`     | The path of the script to be created.                                                                                                                                                    |
| `language` | The language of the new script. It should be one of `deno`, `python3`, `bun`, `bash`, `go`, `nativets`, `postgresql`, `mysql`, `bigquery`, `snowflake`, `mysql`, `graphql`, `powershell` |

### Examples

1. Create a new python script `f/scripts/hallowed_script`

```bash
wmill script bootstrap f/scripts/hallowed_script python3
```

2. Create a new deno script `f/scripts/auspicious_script` with a summary and a description

```bash
wmill script bootstrap --summary 'Great script' --description 'This script does this and that' f/scripts/auspicious_script deno
```

## (Re-)Generating a script metadata file

The `wmill script generate-metadata` command is used to read all the files that have been edited and gracefully update the metadata file and lockfile accordingly, inferring the script schema from the script content and generating the locks. Only the schema and the locks part of the metadata file will be updated. If a change was made to other fields like description or summary, it will be kept.

This command can only be run at the same level of the `wmill-lock.yaml` of your workspace, so by default at top level of the repository.

```bash
wmill script generate-metadata
```

You can also generate metadata for a single script with `wmill script generate-metadata <path>`:

```bash
wmill script generate-metadata [--lock-only] [--schema-only] [<path>]
```

Note that you can explicitly exclude (or include) specific files or folders to be taken into account by this command, with a [`wmill.yaml` file](https://github.com/windmill-labs/windmill-sync-example/blob/main/wmill.yaml).

[Flows](./flow.md) inline script lockfiles can be also updated locally in the same way as `wmill script generate-metadata --lock-only` but for flows' inline scripts:

```bash
wmill flow generate-locks
```

### package.json & requirements.txt

When doing `wmill script generate-metadata`, if a `package.json` or `requirements.txt` is discovered, the closest one will be used as source-of-truth instead of being discovered from the imports in the script directly to generate the lockfile from the server.

Below is a video on how to override Windmill inferred dependencies by [providing custom package.json](../14_dependencies_in_typescript/index.mdx#lockfile-per-script-inferred-from-a-packagejson) or requirements.txt.

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
```

## Showing a script

The wmill script show command is used to show the contents of a script on the remote server.

```bash
wmill script show <path>
```

### Arguments

| Argument | Description                                                |
| -------- | ---------------------------------------------------------- |
| `path`   | The path to the remote script file that needs to be shown. |

### Examples

1. Show the script located at `f/scripts/test`

```bash
wmill script show f/scripts/test
```

## Running a script

Running a script by its path s done using the `wmill script run` command.

```bash
wmill script run <remote_path> [options]
```

### Arguments

| Argument      | Description                       |
| ------------- | --------------------------------- |
| `remote_path` | The path of the script to be run. |

### Options

| Option         | Parameters | Description                                                                                                                                                                                                                                                                                                |
| -------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-d, --data`   | `data`     | Inputs specified as a JSON string or a file using @filename or stdin using @- . Resources and variables must be passed using "$res:..." or "$var:..." For example `wmill script run u/henri/message_to_slack -d '{"slack":"$res:u/henri/henri_slack_perso","channel":"general","text":"hello dear team"}'` |
| `-s, --silent` |            | Do not ouput anything other then the final output. Useful for scripting.                                                                                                                                                                                                                                   |

![CLI arguments](../../assets/cli/cli_arguments.png 'CLI arguments')

## Remote path format

```js
<u|g|f>/<username|group|folder>/...
```
