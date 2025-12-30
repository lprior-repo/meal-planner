---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-9
heading_path: ["Self-host", "Self-signed certificates"]
chunk_type: prose
tokens: 224
summary: "Self-signed certificates"
---

## Self-signed certificates

Detailed guide for using Windmill with self-signed certificates [here](https://www.lfanew.com/posts/windmill-ca-trust/) ([archived version](https://web.archive.org/web/20240424144202/https://www.lfanew.com/posts/windmill-ca-trust/)).

TL;DR: below

### Mount CA certificates in Windmill

1. Ensure CA certificate is base64 encoded and has .crt extension.
2. Create a directory for CA certificates.
3. Modify docker-compose.yml to mount this directory to /usr/local/share/ca-certificates in read-only mode.
4. Use INIT_SCRIPT in the worker config to run update-ca-certificates in worker containers.

Alternatively, you can use the `RUN_UPDATE_CA_CERTIFICATE_AT_START=true` [environment variable](./meta-47_environment_variables-index.md) to automatically run CA certificate updates at startup. You can also customize the command path using `RUN_UPDATE_CA_CERTIFICATE_PATH` if needed.

### Establish Deno’s trust

Set environment variable DENO_TLS_CA_STORE=system,mozilla in docker-compose.yml for Windmill workers.

### Configure Python (requests & httpx) Trust:

Set REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt & SSL_CERT_FILE with the same value in the worker’s environment variables.

### Configure Java's Trust:

```python
keytool -import -alias "your.corp.com" -file path/to/cert.crt -keystore path/to/created/dir/with/certs/truststore.jks -storepass '12345678' -noprompt
```

:::note

By default Windmill will use 123456 password. But you can change it to something else by setting JAVA_STOREPASS.

You can alse set JAVA_TRUST_STORE_PATH to point to different java truststore.

:::
