---
doc_id: ops/guides/wasm-plugins
chunk_id: ops/guides/wasm-plugins#chunk-3
heading_path: ["WASM plugins", "Concepts"]
chunk_type: code
tokens: 1509
summary: "Concepts"
---

## Concepts

Before we begin, let's talk about a few concepts that are critical to WASM and our plugin systems.

### Plugin identifier

When implementing plugin functions, you'll need to access information about the current plugin. To get the current plugin identifier (the key the plugin was configured with), use the [`get_plugin_id`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.get_plugin_id.html) function.

```rust
let id = get_plugin_id();
```

### Virtual paths

WASM by default does not have access to the host file system, but through [WASI](https://wasi.dev/), we can provide sandboxed access to a pre-defined list of allowed directories. We call these [virtual paths](https://docs.rs/warpgate_api/latest/warpgate_api/enum.VirtualPath.html), and all paths provided via function input or context use them.

Virtual paths are implemented by mapping a real path (host machine) to a virtual path (guest runtime) using file path prefixes. The following prefixes are currently supported:

| Real path | Virtual path | Only for |
|-----------|--------------|----------|
| `~` | `/userhome` | ~ |
| `~/.proto` | `/proto` | ~ |
| `~/.moon` | `/moon` | moon |
| Working directory | `/cwd` | ~ |
| moon workspace | `/workspace` | moon |

For example, from the context of WASM, you may have a virtual path of `/proto/tools/node/1.2.3`, which simply maps back to `~/.proto/tools/node/1.2.3` on the host machine. However, this should almost always be transparent to you, the developer, and to end users.

However, there may be a few cases where you need access to the real path from WASM, for example, logging or executing commands. For this, the real path can be accessed with the [`real_path`](https://docs.rs/warpgate_api/latest/warpgate_api/enum.VirtualPath.html#method.real_path) function on the `VirtualPath` enum (this is a Rust only feature).

```rust
virtual_path.real_path();
```

#### File system caveats

When working with the file system from the context of WASM, there are a few caveats to be aware of.

- All `fs` calls must use the virtual path. Real paths will error.
- Paths not white listed (using prefixes above) will error.
- Changing file permissions is not supported (on Unix and Windows).
  - This is because WASI does not support this.
  - This also means operations like unpacking archives is not possible.

### Host environment

Since WASM executes in its own runtime, it *does not* have access to the current host operating system, architecture, so on and so forth. To bridge this gap, we provide the [`get_host_environment`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.get_host_environment.html) function. [Learn more about this type](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/struct.HostEnvironment.html).

```rust
let env = get_host_environment()?;
```

The host operating system and architecture can be accessed with `os` and `arch` fields respectively. Both fields are an enum in Rust, or a string in other languages.

```rust
if env.os == HostOS::Windows {
    // Windows only
}

if env.arch == HostArch::Arm64 {
    // aarch64 only
}
```

Furthermore, the user's home directory (`~`) can be accessed with the `home_dir` field, which is a [virtual path](#virtual-paths).

```rust
if env.home_dir.join(some_path).exists() {
    // Do something
}
```

### Host functions & macros

WASM is pretty powerful but it can't do everything since it's sandboxed. To work around this, we provide a mechanism known as host functions, which are functions that are implemented on the host (in Rust), and can be executed from WASM. The following host functions are currently available:

- [`exec_command`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.exec_command.html) - Execute a system command on the host machine, with a provided list of arguments or environment variables.
- [`from_virtual_path`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.real_path.html) - Converts a virtual path into a real path.
- [`get_env_var`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.host_env.html) - Get an environment variable value from the host environment.
- [`host_log`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.host_log.html) - Log an stdout, stderr, or tracing message to the host's terminal.
- [`send_request`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.send_request.html) - Requests a URL on the host machine using a Rust-based HTTP client (not WASM).
- [`set_env_var`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.host_env.html) - Set an environment variable to the host environment.
- [`to_virtual_path`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.virtual_path.html) - Converts a real path into a virtual path.

To use host functions, you'll need to make them available by registering them at the top of your Rust file (only add the functions you want to use) using the [extism-pdk](https://crates.io/crates/extism-pdk) crate.

```rust
use extism_pdk::*;

#[host_fn]
extern "ExtismHost" {
    fn exec_command(input: Json<ExecCommandInput>) -> Json<ExecCommandOutput>;
    fn from_virtual_path(path: String) -> String;
    fn get_env_var(key: String) -> String;
    fn host_log(input: Json<HostLogInput>);
    fn send_request(input: Json<SendRequestInput>) -> Json<SendRequestOutput>;
    fn set_env_var(key: String, value: String);
    fn to_virtual_path(path: String) -> Json<VirtualPath>;
}
```

> **Info:** To simplify development, we provide built-in functions and macros for the host functions above. Continue reading for more information on these macros.

#### Converting paths

When working with virtual paths, you may need to convert them to real paths, and vice versa. The [`into_virtual_path`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.into_virtual_path.html) and [`into_real_path`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.into_real_path.html) functions can be used for such situations, which use the `to_virtual_path` and `from_virtual_path` host functions respectively.

```rust
// Supports strings or paths
let virt = into_virtual_path("/some/real/path")?;
let real = into_real_path(PathBuf::from("/some/virtual/path"))?;
```

#### Environment variables

The [`get_host_env_var`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.get_host_env_var.html) and [`set_host_env_var`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.set_host_env_var.html) functions can be used to read and write environment variables on the host, using the `set_env_var` and `get_env_var` host functions respectively.

```rust
// Set a value
set_host_env_var("ENV_VAR", "value")?;

// Get a value (returns an `Option`)
let value = get_host_env_var("ENV_VAR")?;
```

Additionally, the [`add_host_paths`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.add_host_paths.html) function can be used to append paths to the `PATH` environment variable.

```rust
// Append to path
add_host_paths(["/userhome/some/virtual/path"])?;
```

#### Executing commands

The [`exec_command!`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.exec_command.html) macro can be used to execute a command on the host, using the `exec_command` host function. If the command does not exist on `PATH`, an error is thrown. This macros supports three modes: pipe, inherit, and raw (returns `Result`).

```rust
let result = exec_command!(raw, "which", ["node"]);
```

If you want a simpler API, the [`exec`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.exec.html), [`exec_captured`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.exec_captured.html) (pipe), and [`exec_streamed`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.exec_streamed.html) (inherit) functions can be used.

```rust
// Pipe stdout/stderr
let output = exec_captured("which", ["node"])?;

// Inherit stdout/stderr
exec_streamed("npm", ["install"])?;

// Full control
exec(ExecCommandInput {
    command: "npm".into(),
    args: vec!["install".into()],
    ..ExecCommandInput::default()
})?;
```

#### Sending requests

The [`send_request`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.send_request.html) macro can be used to request a URL on the host, instead of from WASM, allowing it to use the same HTTP client as the host CLI. This macro returns a response object, with the raw body in bytes, and the status code.

```rust
let response = send_request!("https://some.com/url/to/fetch");

if response.status == 200 {
  let json = response.json::<T>()?;
  let text = response.text()?;
} else {
  // Error!
}
```

To simplify the handling of requests -> responses, we also provide the [`fetch_bytes`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.fetch_bytes.html), [`fetch_json`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.fetch_json.html), and [`fetch_text`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/fn.fetch_text.html) functions.

```rust
let json: T = fetch_json("https://some.com/url/to/fetch.json")?;
```

> Only GET requests are supported.

#### Logging

The [`host_log!`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/macro.host_log.html) macro can be used to write stdout or stderr messages to the host's terminal, using the `host_log` host function. It supports the same argument patterns as `format!`.

If you want full control, like providing data/fields, use the input mode and provide [`HostLogInput`](https://docs.rs/warpgate_pdk/latest/warpgate_pdk/struct.HostLogInput.html).

```rust
host_log!(stdout, "Some message");
host_log!(stderr, "Some message with {}", "args");

// With data
host_log!(input, HostLogInput {
    message: "Some message with data".into(),
    data: HashMap::from_iter([
        ("data".into(), serde_json::to_value(data)?),
    ]),
    target: HostLogTarget::Stderr,
});
```

Furthermore, the [extism-pdk](https://crates.io/crates/extism-pdk) crate provides a handful of macros for writing level-based messages that'll appear in the host's terminal when `--log` is enabled in the CLI. These also support arguments.

```rust
debug!("This is a debug message");
info!("Something informational happened");
warn!("Proceed with caution");
error!("Oh no, something went wrong");
```
