---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-10
heading_path: ["Instance settings", "Telemetry"]
chunk_type: prose
tokens: 180
summary: "Telemetry"
---

## Telemetry

Anonymous usage data is collected to help improve Windmill. Telemetry data is sent as a HTTPS request to https://stats.windmill.dev. Stats are sent once a day. Stats only contain the size of workers, their uptime and number of seats used.

![Telemetry](./telemetry.png "Telemetry")

The following information is collected:
- version of your instances
- instance base URL
- job usage (language, total duration, count)
- login type usage (login type, count)
- worker usage (worker, worker instance, vCPUs, memory)
- user usage (author count, operator count)
- superadmin email address
- vCPU usage
- memory usage
- development instance status

From the instance settings, you can manually disable telemetry or "Send usage" to send usage data to Windmill and monitor it from the [Customer portal](../../misc/7_plans_details/index.mdx#windmill-customer-portal).

Under [Enterprise Edition](/pricing) (self-hosted), telemetry is mandatory to ensure usage correctly matches the subscription.
