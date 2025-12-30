---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-6
heading_path: ["Self-host", "install chart with default values"]
chunk_type: code
tokens: 137
summary: "install chart with default values"
---

## install chart with default values
helm install windmill-chart windmill/windmill  \
      --namespace=windmill             \
      --create-namespace
```

Detailed instructions in the official [repository][helm].

:::

### Enterprise deployment with Helm

The [Enterprise edition](/pricing) of Windmill uses different base images and supports
additional features.

See the [Helm chart repository README][helm] for more details.

To unlock EE, set in your values.yaml:

```
enterprise:
	enable: true
```

You will want to disable the postgresql provided with the helm chart and set the database_url to your own managed postgresql.

For high-scale deployments (> 20 workers), we recommend using the [global S3 cache](../../misc/13_s3_cache/index.mdx). You will need an object storage compatible with the S3 protocol.
