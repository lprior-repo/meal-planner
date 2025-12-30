---
doc_id: concept/extending/arguments
chunk_id: concept/extending/arguments#chunk-6
heading_path: ["arguments", "Container arguments"]
chunk_type: prose
tokens: 64
summary: "Just like directories, you can pass a container to a Dagger Function from the command-line."
---
Just like directories, you can pass a container to a Dagger Function from the command-line. To do so, add the corresponding flag, followed by the address of an OCI image. The CLI will dynamically pull the image, and pass the resulting `Container` object as argument to the Dagger Function.
