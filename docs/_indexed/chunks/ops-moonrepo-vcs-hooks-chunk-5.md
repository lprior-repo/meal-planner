---
doc_id: ops/moonrepo/vcs-hooks
chunk_id: ops/moonrepo/vcs-hooks#chunk-5
heading_path: ["VCS hooks", "How it works"]
chunk_type: prose
tokens: 287
summary: "How it works"
---

## How it works

When hooks are [enabled](#enabling-hooks), the following processes will take place.

1. The configured [hooks](#defining-hooks) will be generated as individual script files in the `.moon/hooks` directory. Whether or not you commit or ignore these script files is your choice. They are written to the `.moon` directory so that they can be reviewed, audited, and easily tested, but *are required*.

2. We then sync these generated hook scripts with the current VCS. For Git, we create `.git/hooks` files that execute our generated scripts, using repository relative commands. Any existing VCS hooks *will be overwritten*.

> **Info:** The `.moon/hooks` scripts are generated as Bash scripts (use a `.sh` file extension) on Unix, and PowerShell scripts (use a `.ps1` file extension) on Windows.

### Git

On Unix based operating systems (Linux, macOS, etc), the `.moon/hooks` scripts are executed from `.git/hooks` Bash files. Because of this, `bash` should be available on the system (which is typically the case).

On Windows, things get tricky. Since Git has a requirement that `.git/hooks` files *must be* extensionless, and older versions of PowerShell require an extension, we have to use a workaround. To handle this, the `.git/hooks` files are Bash-like scripts (that should work on most machines) that execute `.moon/hooks` using the `powershell.exe` (or `pwsh.exe`) executables. Because of this, PowerShell must be available on the system.
