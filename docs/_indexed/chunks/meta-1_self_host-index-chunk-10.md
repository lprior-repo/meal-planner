---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-10
heading_path: ["Self-host", "Running Windmill as non-root user"]
chunk_type: prose
tokens: 101
summary: "Running Windmill as non-root user"
---

## Running Windmill as non-root user

Certain cloud providers require containers to be run as non-root users. For these cases you can use the `windmill` user (uid/gid 1000) or run it as any other non-root user by passing the `--user windmill` argument. For the [windmill helm chart](https://github.com/windmill-labs/windmill-helm-charts/tree/main/charts/windmill), you can pass the `runAsUser` or `runAsNonRoot` in the `podSecurityContext`.

<!-- Resources -->

[caddy]: https://caddyserver.com/
[windmill-gh]: https://github.com/windmill-labs/windmill
[windmill-gh-frontend]: https://github.com/windmill-labs/windmill/tree/main/frontend
[windmill-gh-backend]: https://github.com/windmill-labs/windmill/tree/main/backend
[windmill-docker-compose]: https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml
[windmill-caddyfile]: https://github.com/windmill-labs/windmill/blob/main/Caddyfile
[windmill-env]: https://github.com/windmill-labs/windmill/blob/main/.env
[helm]: https://github.com/windmill-labs/windmill-helm-charts
[helm-readme]: https://github.com/windmill-labs/windmill-helm-charts/blob/main/README.md
