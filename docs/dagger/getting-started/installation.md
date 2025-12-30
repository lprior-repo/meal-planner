# Installation

To use Dagger, you must have a container runtime installed and running. This includes `docker`, as well as other Docker-like systems (see [Container runtimes](/reference/container-runtimes/) for more information).

## Stable release

Install the latest stable release of the Dagger CLI following the steps below.

### macOS

We assume that you have [Homebrew](https://brew.sh/) installed. If you do, you can install `dagger` with a single command:

```bash
brew install dagger/tap/dagger
```

This installs `dagger` in:

```bash
type dagger
# Expected output on macOS ARM:
# dagger is /opt/homebrew/bin/dagger
# Expected output on macOS Intel:
# dagger is /usr/local/bin/dagger
```

If you do not have Homebrew installed, you can use [install.sh](https://github.com/dagger/dagger/blob/main/install.sh):

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh
```

If your user account doesn't have sufficient privileges to install in `/usr/local` and `sudo` is available, you can set `BIN_DIR` and use `sudo -E`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sudo -E sh
```

If you want to set a specific version, you can set `DAGGER_VERSION`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.19.7 BIN_DIR=/usr/local/bin sh
```

To see the installed version of dagger:

```bash
./bin/dagger version
# Expected output: dagger v0.19.7 (registry.dagger.io/engine:v0.19.7) darwin/amd64
```

### Linux

The quickest way of installing the latest stable release of `dagger` on Linux is to use [install.sh](https://github.com/dagger/dagger/blob/main/install.sh):

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=$HOME/.local/bin sh
```

This installs `dagger` in `$HOME/.local/bin`:

```bash
type dagger
# Expected output: dagger is $HOME/.local/bin/dagger
```

You may need to add it to your `$PATH` environment variable.

If you want to install globally, and `sudo` is available, you can specify an alternative install location by setting `BIN_DIR` and using `sudo -E`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sudo -E sh
```

If you want to set a specific version, you can set `DAGGER_VERSION`:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.19.7 BIN_DIR=$HOME/.local/bin sh
```

To see the installed version of dagger:

```bash
./bin/dagger version
# Expected output: dagger v0.19.7 (registry.dagger.io/engine:v0.19.7) linux/amd64
```

### Windows

The simplest way to install Dagger on Windows is using the Windows Package Manager:

```powershell
winget install Dagger.Cli
```

To verify the installation:

```powershell
dagger version
```

## Development release

> **Warning:** Development releases should be considered unfinished.

### macOS/Linux

To install the latest development release, use the following command:

```bash
curl -fsSL https://dl.dagger.io/dagger/install.sh | DAGGER_COMMIT=head sh
```

This will install the development release of the Dagger CLI in `./bin/dagger`.

### Windows

To install the latest development release, use the following command in PowerShell 7.0:

```powershell
iwr -useb https://dl.dagger.io/dagger/install.ps1 | iex; Install-Dagger -DaggerCommit head
```

This will install the development release of the Dagger CLI in the `<your home folder>\dagger` directory.

> **Warning:** Running this CLI against the stable Dagger Engine will, by default, stop and remove the stable version and install a development version of the Dagger Engine instead. You may prefer to install it in an isolated environment so as to avoid conflicts.

## Update

To update the Dagger CLI, use the same method that you originally used to install it. This will overwrite your currently-installed version with the latest (or specified) version.

Homebrew users can alternatively use the following commands:

```bash
brew update
brew upgrade dagger
```

## Uninstallation

Remove the Dagger CLI using the following command:

```bash
sudo rm /usr/local/bin/dagger
```

Homebrew users can alternatively use the following command:

```bash
brew uninstall dagger
```

Next, remove the Dagger container using the following commands:

```bash
docker rm --force --volumes "$(docker ps --quiet --filter='name=^dagger-engine-')"
```

Finally, remove the `dagger` sub-directory of your local cache and configuration directories (`$XDG_CACHE_HOME` and `$XDG_CONFIG_HOME` on Linux or the equivalent for other platforms):

### macOS

```bash
rm -rf ~/Library/Caches/dagger
rm -rf ~/Library/Application\ Support/dagger
```

### Linux

```bash
rm -rf ~/.cache/dagger
rm -rf ~/.config/dagger
```

> **Note:** The paths listed above are defaults and may require adjustment for your specific environment.

## Versioning

The Dagger CLI is released in tandem with the Dagger Engine and thus shares a version number with it. Dagger SDKs automatically provision a Dagger Engine at a compatible version.

The Dagger Engine runner is distributed as a container image at `registry.dagger.io/engine`. Tags are made for the version of each release. For example, the 0.19.7 release has a corresponding image at `registry.dagger.io/engine`.

Each release notes the compatible Dagger Engine version in its release notes.
