---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-8
heading_path: ["Instance settings", "Open Telemetry & Prometheus"]
chunk_type: prose
tokens: 85
summary: "Open Telemetry & Prometheus"
---

## Open Telemetry & Prometheus

![Open Telemetry & Prometheus](./otel_prometheus.png)

### OpenTelemetry (OTEL)

Enable to collect telemetry data and send it to an [OpenTelemetry](https://opentelemetry.io/) collector such as [Jaeger](https://www.jaegertracing.io/) or [Tempo](https://www.tempo.io/) for tracing. OpenTelementry data sent to the collector consists of traces, logs and metrics (coming soon). Follow this [guide](../../misc/9_guides/otel/index.mdx) for an example setup.

### Prometheus
Expose [Prometheus](https://prometheus.io/) metrics for workers and servers on port 8001 at /metrics.
