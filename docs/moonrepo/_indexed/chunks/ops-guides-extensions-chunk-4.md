---
doc_id: ops/guides/extensions
chunk_id: ops/guides/extensions#chunk-4
heading_path: ["Extensions", "Creating an extension"]
chunk_type: code
tokens: 622
summary: "Creating an extension"
---

## Creating an extension

Refer to our [official WASM guide](/docs/guides/wasm-plugins) for more information on how our WASM plugins work, critical concepts to know, how to create a plugin, and more. Once you have a good understanding, you may continue this specific guide.

> **Note:** Refer to our [moonrepo/moon-extensions](https://github.com/moonrepo/moon-extensions) repository for in-depth examples.

### Registering metadata

Before we begin, we must implement the `register_extension` function, which simply provides some metadata that we can bubble up to users, or to use for deeper integrations.

```rust
use extism_pdk::*;
use moon_pdk::*;

#[plugin_fn]
pub fn register_extension(Json(input): Json<ExtensionMetadataInput>) -> FnResult<Json<ExtensionMetadataOutput>> {
   Ok(Json(ExtensionMetadataOutput {
        name: "Extension name".into(),
        description: Some("A description about what the extension does.".into()),
        plugin_version: env!("CARGO_PKG_VERSION").into(),
        ..ExtensionMetadataOutput::default()
    }))
}
```

#### Configuration schema

If you are using [configuration](#supporting-configuration), you can register the shape of the configuration using the [`schematic`](https://crates.io/crates/schematic) crate. This shape will be used to generate outputs such as JSON schemas, or TypeScript types.

```rust
#[plugin_fn]
pub fn register_extension(_: ()) -> FnResult<Json<ExtensionMetadataOutput>> {
    Ok(Json(ExtensionMetadataOutput {
        // ...
        config_schema: Some(schematic::SchemaBuilder::generate::<NodeConfig>()),
    }))
}
```

Schematic is a heavy library, so we suggest adding the dependency like so:

```toml
[dependencies]
schematic = { version = "*", default-features = false, features = ["schema"] }
```

### Implementing execution

Extensions support a single plugin function, `execute_extension`, which is called by the [`moon ext`](/docs/commands/ext) command to execute the extension. This is where all your business logic will reside.

```rust
#[host_fn]
extern "ExtismHost" {
    fn host_log(input: Json<HostLogInput>);
}

#[plugin_fn]
pub fn execute_extension(Json(input): Json<ExecuteExtensionInput>) -> FnResult<()> {
  host_log!(stdout, "Executing extension!");

  Ok(())
}
```

### Supporting arguments

Most extensions will require arguments, as it provides a mechanism for users to pass information into the WASM runtime. To parse arguments, we provide the [`Args`](https://docs.rs/clap/latest/clap/trait.Args.html) trait/macro from the [clap](https://crates.io/crates/clap) crate. Refer to their [official documentation on usage](https://docs.rs/clap/latest/clap/_derive/index.html) (we don't support everything).

```rust
use moon_pdk::*;

#[derive(Args)]
pub struct ExampleExtensionArgs {
  // --url, -u
  #[arg(long, short = 'u', required = true)]
  pub url: String,
}
```

Once your struct has been defined, you can parse the provided input arguments using the [`parse_args`](https://docs.rs/moon_pdk/latest/moon_pdk/args/fn.parse_args.html) function.

```rust
#[plugin_fn]
pub fn execute_extension(Json(input): Json<ExecuteExtensionInput>) -> FnResult<()> {
  let args = parse_args::<ExampleExtensionArgs>(&input.args)?;

  args.url; // --url

  Ok(())
}
```

### Supporting configuration

Users can configure [extensions](/docs/config/workspace#extensions) with additional settings in [`.moon/workspace.yml`](/docs/config/workspace). Do note that settings should be in camelCase for them to be parsed correctly!

.moon/workspace.yml

```yaml
extensions:
  example:
    plugin: 'file://./path/to/example.wasm'
    someSetting: 'abc'
    anotherSetting: 123
```

In the plugin, we can map these settings (excluding `plugin`) into a struct. The `Default` trait must be implemented to handle situations where settings were not configured, or some are missing.

```rust
config_struct!(
  #[derive(Default)]
  pub struct ExampleExtensionConfig {
    pub some_setting: String,
    pub another_setting: u32,
  }
);
```

Once your struct has been defined, you can access the configuration using the [`get_extension_config`](https://docs.rs/moon_pdk/latest/moon_pdk/extension/fn.get_extension_config.html) function.

```rust
#[plugin_fn]
pub fn execute_extension(Json(input): Json<ExecuteExtensionInput>) -> FnResult<()> {
  let config = get_extension_config::<ExampleExtensionConfig>()?;

  config.another_setting; // 123

  Ok(())
}
```

**Tags:**

- [extension](/docs/tags/extension)
- [wasm](/docs/tags/wasm)
- [plugin](/docs/tags/plugin)
