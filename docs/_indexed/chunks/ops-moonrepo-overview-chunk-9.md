---
doc_id: ops/moonrepo/overview
chunk_id: ops/moonrepo/overview#chunk-9
heading_path: ["Overview", "Debugging"]
chunk_type: prose
tokens: 204
summary: "Debugging"
---

## Debugging

At minimum, most debugging can be done by passing [`--log trace`](#logging) on the command line and sifting through the logs. We also provide the following environment variables to toggle output.

-   `MOON_DEBUG_PROCESS_ENV` - By default moon hides the environment variables (except for `MOON_`) passed to processes to avoid leaking sensitive information. However, knowing what environment variables are passed around is helpful in debugging. Declare this variable to reveal the entire environment.
-   `MOON_DEBUG_PROCESS_INPUT` - By default moon truncates the stdin passed to processes to avoid thrashing the console with a large input string. However, knowing what input is passed around is helpful in debugging. Declare this variable to reveal the entire input.
-   `MOON_DEBUG_PROTO_INSTALL` - Debug the proto installation process.
-   `MOON_DEBUG_REMOTE` - Debug our remote caching implementation by including additional logging output, and printing internal connection errors.
-   `MOON_DEBUG_WASM` - Debug our WASM plugins by including additional logging output, and optionally dumping memory/core profiles.
