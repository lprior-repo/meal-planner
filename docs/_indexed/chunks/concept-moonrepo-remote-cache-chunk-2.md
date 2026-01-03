---
doc_id: concept/moonrepo/remote-cache
chunk_id: concept/moonrepo/remote-cache#chunk-2
heading_path: ["Remote caching", "Self-hosted (v1.30.0)"]
chunk_type: code
tokens: 334
summary: "Self-hosted (v1.30.0)"
---

## Self-hosted (v1.30.0)

This solution allows you to host any remote caching service that is compatible with the [Bazel Remote Execution v2 API](https://github.com/bazelbuild/remote-apis/tree/main/build/bazel/remote/execution/v2), such as [`bazel-remote`](https://github.com/buchgr/bazel-remote). When using this solution, the following RE API features must be enabled:

- Action result caching
- Content addressable storage caching
- SHA256 digest hashing
- gRPC requests

> **Warning:** This feature and its implementation is currently unstable, and its documentation is incomplete. Please report any issues on GitHub or through Discord!

### Host your service

When you have chosen (or built) a compatible service, host it and make it available through gRPC (we do not support HTTP at this time). For example, if you plan to use `bazel-remote`, you can do something like the following:

```shell
bazel-remote --dir /path/to/moon-cache --max_size 10 --storage_mode uncompressed --grpc_address 0.0.0.0:9092
```

If you've configured the [`remote.cache.compression`](/docs/config/workspace#compression) setting to "zstd", you'll need to run the binary with that storage mode as well.

```shell
bazel-remote --dir /path/to/moon-cache --max_size 10 --storage_mode zstd --grpc_address 0.0.0.0:9092
```

> **Info:** View the official [`bazel-remote`](https://github.com/buchgr/bazel-remote#usage) documentation for all the available options, like storing artifacts in S3, configuring authentication (TLS/mTLS), proxies, and more.

### Configure remote caching

Once your service is running, you can enable remote caching by configuring the [`unstable_remote`](/docs/config/workspace#unstable_remote) settings in [`.moon/workspace.yml`](/docs/config/workspace). At minimum, the only setting that is required is `host`.

.moon/workspace.yml

```yaml
unstable_remote:
  host: 'grpc://your-host.com:9092'
```

#### TLS and mTLS

We have rudimentary support for TLS and mTLS, but it's very unstable, and has not been thoroughly tested. There's also [many](https://github.com/hyperium/tonic/issues/1652) [many](https://github.com/hyperium/tonic/issues/1989) [issues](https://github.com/hyperium/tonic/issues/1033) around authentication in Tonic.

.moon/workspace.yml

```yaml
