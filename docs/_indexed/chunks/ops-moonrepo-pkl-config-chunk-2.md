---
doc_id: ops/moonrepo/pkl-config
chunk_id: ops/moonrepo/pkl-config#chunk-2
heading_path: ["Pkl configuration", "Installing Pkl"]
chunk_type: prose
tokens: 80
summary: "Installing Pkl"
---

## Installing Pkl

Pkl utilizes a client-server architecture, which means that the `pkl` binary must exist in the environment for parsing and evaluating `.pkl` files. Jump over to the [official documentation for instructions on how to install Pkl](https://pkl-lang.org/main/current/pkl-cli/index.html#installation).

If you are using [proto](/proto), you can install Pkl with the following commands.

```shell
proto plugin add pkl https://raw.githubusercontent.com/milesj/proto-plugins/refs/heads/master/pkl.toml
proto install pkl --pin
```
