---
doc_id: tutorial/extending/daggerverse
chunk_id: tutorial/extending/daggerverse#chunk-3
heading_path: ["daggerverse", "Examples"]
chunk_type: prose
tokens: 514
summary: "Daggerverse will automatically show basic examples for each function in a module."
---
Daggerverse will automatically show basic examples for each function in a module. If you would like to provide hand-crafted examples, the following section will describe how to set these up.

**Go:**

A Go example must be a Dagger module located at `/examples/go` within the module you're creating examples for.

If you have a module called `Foo` and a function called `Bar`, you can create the following functions in your example module:

1. A function `Foo_Baz` will create a top level example for the `Foo` module called Baz.
2. A function `FooBar` will create an example for function `Bar`.
3. Functions `FooBar_Baz` will create a Baz example for the function `Bar`.

**Python:**

A Python example must be a Dagger module located at `/examples/python` within the module you're creating examples for.

If you have a module called `foo` and a function called `bar`, you can create the following functions in your example module:

1. A function `foo__baz` will create a top level example for the `foo` module called baz.
2. A function `foo_bar` will create an example for function `bar`.
3. Functions `foo_bar__baz` will create a baz example for the function `bar`.

> **Note:** Python function names in example modules use double underscores (`__`) as separators since by convention, Python uses single underscores to represent spaces in function names (snake case).

**TypeScript:**

A TypeScript example must be a Dagger module located at `/examples/typescript` within the module you're creating examples for.

If you have a module called `foo` and a function called `bar`, you can create the following functions in your example module:

1. A function `foo_baz` will create a top level example for the `foo` module called baz.
2. A function `fooBar` will create an example for function `bar`.
3. Functions `fooBar_baz` and will create a baz example for the function `bar`.

**Shell:**

A Shell example must be a shell script located at `/examples/shell` within the module you're creating examples for.

If you have a module called `foo` and a function called `bar`, you can create the following script in your example directory:

1. A file `foo_baz.sh` will create a top level example for the `foo` module called baz.
2. A file `foo_bar.sh` will create an example for function `bar`.
3. Files `foo_bar_baz.sh` and will create a baz example for the function `bar`.

For an example of a module with hand-crafted function examples, see the [proxy module](https://daggerverse.dev/mod/github.com/kpenfound/dagger-modules/proxy)
