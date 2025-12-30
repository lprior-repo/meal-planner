---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-4
heading_path: ["arguments", "Directory arguments"]
chunk_type: prose
tokens: 81
summary: "You can also pass a directory argument from the command-line."
---
You can also pass a directory argument from the command-line. To do so, add the corresponding flag, followed by a local filesystem path or a [remote Git reference](./tutorial-extending-remote-repositories.md). In both cases, the CLI will convert it to an object referencing the contents of that filesystem path or Git repository location, and pass the resulting `Directory` object as argument to the Dagger Function.
