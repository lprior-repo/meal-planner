---
doc_id: meta/9_rust_quickstart/index
chunk_id: meta/9_rust_quickstart/index#chunk-3
heading_path: ["Rust quickstart", "Code"]
chunk_type: code
tokens: 510
summary: "Code"
---

## Code

Windmill provides an online editor to work on your Scripts. The left-side is
the editor itself. The right-side [previews the UI](./meta-6_auto_generated_uis-index.md) that Windmill will
generate from the Script's signature - this will be visible to the users of the
Script. You can preview that UI, provide input values, and [test your script](#instant-preview--testing) there.

![Editor for Rust](./editor_rust.png "Editor for Rust")

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Code editor"
		description="The code editor is Windmill's integrated development environment."
		href="/docs/code_editor"
	/>
	<DocCard
		title="Auto-generated UIs"
		description="Windmill creates auto-generated user interfaces for scripts and flows based on their parameters."
		href="/docs/core_concepts/auto_generated_uis"
	/>
</div>

As we picked `rust` for this example, Windmill provided some rust
boilerplate. Let's take a look:

```rust
//! Add dependencies in the following partial Cargo.toml manifest
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! rand = "0.7.2"
//! # wmill = "^1.0"  # Windmill client SDK for API interactions
//! ```
//!
//! Note that serde is used by default with the `derive` feature.
//! You can still reimport it if you need additional features.

use anyhow::anyhow;
use rand::seq::SliceRandom;
use serde::Serialize;

#[derive(Serialize, Debug)]
struct Ret {
    msg: String,
    number: i8,
}

fn main(who_to_greet: String, numbers: Vec<i8>) -> anyhow::Result<Ret> {
    println!(
        "Person to greet: {} -  numbers to choose: {:?}",
        who_to_greet, numbers
    );
    Ok(Ret {
        msg: format!("Greetings {}!", who_to_greet),
        number: *numbers
            .choose(&mut rand::thread_rng())
            .ok_or(anyhow!("There should be some numbers to choose from"))?,
    })
}
```

In Windmill, scripts need to have a `main` function that will be the script's
entrypoint. There are a few important things to note about the `main`.

- The main arguments are used for generating
  1.  the [input spec](./meta-13_json_schema_and_parsing-index.md) of the Script
  2.  the [frontend](./meta-6_auto_generated_uis-index.md) that you see when running the Script as a standalone app.
- Type annotations are used to generate the UI form, and help pre-validate
  inputs. While not mandatory, they are highly recommended. You can customize
  the UI in later steps (but not change the input type!).

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="JSON schema and parsing"
		description="JSON Schemas are used for defining the input specification for scripts and flows, and specifying resource types."
		href="/docs/core_concepts/json_schema_and_parsing"
	/>
</div>

Packages can be installed using cargo. Just add the dependencies you need in the partial Cargo.toml manifest and Windmill will install them for you:

```rust
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! rand = "0.7.2"
//! ```
```
