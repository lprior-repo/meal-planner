---
doc_id: concept/guides/remote-cache
chunk_id: concept/guides/remote-cache#chunk-5
heading_path: ["Remote caching", "Cloud-hosted: Depot (v1.32.0)"]
chunk_type: prose
tokens: 145
summary: "Cloud-hosted: Depot (v1.32.0)"
---

## Cloud-hosted: Depot (v1.32.0)

If you'd prefer not to host your own solution, you could use [Depot Cache](https://depot.dev/products/cache), a cloud-based caching solution. To make use of Depot, follow these steps:

- Create an account on [depot.dev](https://depot.dev)
- Create an organization
- Go to organization settings -> API tokens
- Create a new API token
- Add the token as a `DEPOT_TOKEN` environment variable to your moon pipelines

Once these steps have been completed, you can enable remote caching in moon with the following configuration. If your Depot account has more than 1 organization, you'll need to set the `X-Depot-Org` header.

.moon/workspace.yml

```yaml
unstable_remote:
  host: 'grpcs://cache.depot.dev'
  auth:
    token: 'DEPOT_TOKEN'
    headers:
      'X-Depot-Org': '<your-org-id>'
```
