---
doc_id: ops/features/observability
chunk_id: ops/features/observability#chunk-5
heading_path: ["observability", "Visualization", "Terminal UI"]
chunk_type: prose
tokens: 543
summary: "The Dagger CLI includes a real-time visualization feature called the terminal UI (TUI)."
---
The Dagger CLI includes a real-time visualization feature called the terminal UI (TUI). It shows a full-blown DAG in a style similar to `git log --graph`, with the current state of your DAG's evaluation and a full snapshot of all output at the end.

#### Rapid iteration

The TUI is designed for rapid iteration, in the same way regular scripting works: you run a command, it shows live progress, and then leaves all the output in your terminal scrollback.

The TUI renders a tree of Dagger API calls, represented as GraphQL queries. A parent-child relationship means that the child call is being made by the parent call.

- A red X or green check indicates whether the call succeeded or failed
- A call's duration is rendered after its name

#### Errors

Error logs appear at the top, directly below the progress report. In most cases, this tells you exactly what went wrong and where without any extra sleuthing.

#### Telemetry

The TUI also provides real-time telemetry to give you a complete view of your workflow's performance. It allows you to monitor:

- **State and duration**: Get visual cues for cached and pending states, and see exactly how long each step of your workflow takes (including accounting for lazy effects installed by a Dagger Function)
- **CPU resource usage**: Identify when CPU contention occurs, such as when all threads are blocked waiting for CPU access, and diagnose performance bottlenecks related to CPU resource constraints
- **Network activity**: See how much data is sent and received and track packet drop rates to identify potential bottlenecks in your workflows
- **Memory usage**: Keep an eye on current and peak memory consumption, helping you optimize resource utilization

> **Info:** The CLI has tiered verbosity: `-v`, `-vv`, `-vvv` (just like `curl`):
> - `-v` keeps spans visible after they complete, rather than disappearing after a brief pause;
> - `-vv` reveals internal and encapsulated spans;
> - `-vvv` reveals sub-100ms spans.
>
> For additional debugging information, add the `--debug` flag to the `dagger call` command.

The TUI is driven by [OpenTelemetry](https://opentelemetry.io/) and is essentially a live-streaming OpenTelemetry trace visualizer. It represents Dagger API calls as OpenTelemetry spans with special metadata. If user code integrates with OpenTelemetry, related spans will appear in the TUI as first-class citizens.

> **Note:** Dagger automatically detects OpenTelemetry resource attributes. By utilizing the standard [`OTEL_RESOURCE_ATTRIBUTES` environment variable](https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/), operators can now set custom resource attributes to annotate Traces, providing more detailed and contextual information for monitoring and debugging.
