---
doc_id: meta/28_agent_workers/index
chunk_id: meta/28_agent_workers/index#chunk-3
heading_path: ["Agent workers", "Architecture"]
chunk_type: prose
tokens: 278
summary: "Architecture"
---

## Architecture

Normal workers interact with the Postgresql database directly.

Agent workers interact only via HTTP requests with the server which expose api methods specifically for it at `/api/agent_workers/` and `/api/w/<workspace>/agent_workers/`. Those methods all require the requests to be authenticated with a JWT token, and that's what the `AGENT_TOKEN` env variable is for.

The JWT token is a signed JSON Web Token that contains the following information:

- The worker's tags
- The worker's group

It make sure that the worker can only pull and run jobs that are tagged with the worker's tags. A benefit of this architecture is that it is both secure and lightweight. Only a superadmin can create an agent worker because only a superadmin can create the JWT token with the arbitrary tags. The API exposed expose methods that are needed by the worker to run the jobs and only those. All the HTTP requests are retried in case of a transient error which make them resilient.

In addition, agent workers have slightly less throughput than normal workers but you can have many more of them because the servers act as an connection pool to the Postgresql database. You can for instance have 1000 agent workers on a single server without having to worry about the database connection limit.
