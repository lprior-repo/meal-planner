---
doc_id: ops/moonrepo/codegen
chunk_id: ops/moonrepo/codegen#chunk-3
heading_path: ["Code generation", "Generating code from a template"]
chunk_type: code
tokens: 712
summary: "Generating code from a template"
---

## Generating code from a template

Once a template has been created and configured, you can generate files based on it using the [`moon generate`](/docs/commands/generate) command! This is also know as scaffolding or code generation.

This command requires the name of a template as the 1st argument. The template name is the folder name on the file system that houses all the template files, or the [`id`](/docs/config/template#id) setting configured in [`template.yml`](/docs/config/template).

```shell
$ moon generate npm-package
```

An optional destination path, relative from the current working directory, can be provided as the 2nd argument. If not provided, the [`destination`](/docs/config/template#destination) setting configured in [`template.yml`](/docs/config/template) will be used, or you'll be prompted during generation to provide one.

```shell
$ moon generate npm-package ./packages/example
```

> This command is extremely interactive, as we'll prompt you for the destination path, variable values, whether to overwrite files, and more. If you'd prefer to avoid interactions, pass `--defaults`, or `--force`, or both.

### Configuring template locations

Templates can be located anywhere, especially when [being shared](#sharing-templates). Because of this, our generator will loop through all template paths configured in [`generator.templates`](/docs/config/workspace#templates), in order, until a match is found.

.moon/workspace.yml

```yaml
generator:
  templates:
    - './templates'
    # Or
    - 'file://other/templates'
```

When using literal file paths, all paths are relative from the workspace root.

#### Archive URLs (v1.36.0)

Template locations can reference archives (zip, tar, etc) through https URLs. These archives should contain templates and will be downloaded and unpacked. The list of [available archive formats can be found here](https://github.com/moonrepo/starbase/blob/master/crates/archive/src/lib.rs#L76).

.moon/workspace.yml

```yaml
generator:
  templates:
    - 'https://domain.com/some/path/to/archive.zip'
```

> Archives will be unpacked to `~/.moon/templates/archive/<host>`, and will be cached for future use.

#### Globs (v1.31.0)

If you'd prefer more control over literal file paths (above), you can instead use glob paths or the `glob://` protocol. Globs are relative from the workspace root, and will only match directories, or patterns that end in `template.yml`.

.moon/workspace.yml

```yaml
generator:
  templates:
    - './templates/*'
    # Or
    - 'glob://projects/*/templates/*'
```

#### Git repositories (v1.23.0)

Templates locations can also reference templates in an external Git repository using the `git://` locator protocol. This locator requires the Git host, repository path, and revision (branch, tag, commit, etc).

.moon/workspace.yml

```yaml
generator:
  templates:
    - 'git://github.com/moonrepo/templates#master'
    - 'git://gitlab.com/org/repo#v1.2.3'
```

> Git repositories will be cloned to `~/.moon/templates/git/<host>` using an HTTPS URL (not a Git URL), and will be cached for future use.

#### npm packages (v1.23.0)

Additionally, template locations can also reference npm packages using the `npm://` locator protocol. This locator requires a package name and published version.

.moon/workspace.yml

```yaml
generator:
  templates:
    - 'npm://@moonrepo/templates#1.2.3'
    - 'npm://other-templates#4.5.6'
```

> npm packages will be downloaded and unpacked to `~/.moon/templates/npm` and cached for future use.

### Declaring variables with CLI arguments

During generation, you'll be prompted in the terminal to provide a value for any configured variables. However, you can pre-fill these variable values by passing arbitrary command line arguments after `--` to [`moon generate`](/docs/commands/generate). Argument names must exactly match the variable names.

Using the package template example above, we could pre-fill the `name` variable like so:

```shell
$ moon generate npm-package ./packages/example -- --name '@company/example' --private
```

> **Info:**
> - Array variables support multiple options of the same name.
> - Boolean variables can be negated by prefixing the argument with `--no-<arg>`.
> - Object variables *can not* declare values through arguments.
