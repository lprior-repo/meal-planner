---
doc_id: concept/guides/remote-cache
chunk_id: concept/guides/remote-cache#chunk-4
heading_path: ["Remote caching", "mTLS"]
chunk_type: prose
tokens: 19
summary: "mTLS"
---

## mTLS
unstable_remote:
  host: 'grpcs://your-host.com:9092'
  mtls:
    caCert: 'certs/ca.pem'
    clientCert: 'certs/client.pem'
    clientKey: 'certs/client.key'
    domain: 'your-host.com'
```
