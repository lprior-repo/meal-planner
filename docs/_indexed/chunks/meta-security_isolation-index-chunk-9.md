---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-9
heading_path: ["Security and process isolation", "Agent workers"]
chunk_type: prose
tokens: 124
summary: "Agent workers"
---

## Agent workers

Another approach to isolation is using [agent workers](/docs/core_concepts/agent_workers). Agent workers:

- Do not have direct database access
- Communicate with the Windmill server only via the API
- Cannot access database credentials or other workers' data
- Provide network-level isolation from sensitive infrastructure

This approach is particularly useful when:

- You want to run workers in untrusted environments
- You need workers in different network zones without database access
- You want an additional layer of security beyond process isolation

Agent workers can be combined with PID namespace isolation or NSJAIL for defense-in-depth.
