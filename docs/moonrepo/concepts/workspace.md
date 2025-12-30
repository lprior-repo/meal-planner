# Workspace

A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/concepts/task), and is coupled with a VCS repository. The root of a workspace is denoted by a `.moon` folder.

By default moon has been designed for monorepos, but can also be used for polyrepos.

## Configuration

Configuration that's applied to the entire workspace is defined in [`.moon/workspace.yml`](/docs/config/workspace).
