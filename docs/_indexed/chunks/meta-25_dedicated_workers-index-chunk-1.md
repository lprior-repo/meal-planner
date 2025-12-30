---
doc_id: meta/25_dedicated_workers/index
chunk_id: meta/25_dedicated_workers/index#chunk-1
heading_path: ["Dedicated workers / High throughput"]
chunk_type: prose
tokens: 569
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Dedicated workers / High throughput

> **Context**: import DocCard from '@site/src/components/DocCard';

Dedicated Workers are [workers](./meta-9_worker_groups-index.md) that are dedicated to a particular script. They are able to execute any job that target this script much faster than normal workers at the expense of being capable to only execute that one script.
They are as fast as running the same logic in a forloop, but keep the benefit of showing separate jobs per execution.

Workers serve as the backbone of Windmill. Workers are autonomous processes that run one script at a time using the full cpu and memory available to them.

To put it simply, workers are responsible for executing code in Windmill. A single normal worker in Windmill is capable of handling up to 26 million tasks a month, with each task taking roughly 100ms. You can easily scale the number of workers horizontally without incurring extra overhead.

Typically, workers fetch jobs from the job queue based on their `scheduled_for` datetime, provided it's in the past. Once a worker retrieves a job, it immediately changes its status to "running", processes it, streams its logs, and upon completion, archives it in the database as a "finished job". Both the final outcome and the logs are preserved indefinitely.

This simple process allows one to reliably count on a small number of workers for very different jobs. However, there is a latency between each task since the worker must perform a clean-up and a cold start between each execution (to be able to handle successive jobs but from completely different scripts). This latency amounts to around a dozen milliseconds, which can be crucial in the execution of certain priority jobs:

![Worker group config](./infographic.png.webp)

Dedicated workers allow you to remove completely the cold start for selected scripts. They are workers that are dedicated to a particular script. They are able to execute any job that target this script much faster than normal workers at the expense of being capable to only execute that one script. They are as fast as running the same logic in a while-loop processing requests, that is how they are implemented actually, but keep the benefit of showing separate jobs per execution.

Dedicated workers / High throughput are a [Cloud plans & Self-Hosted Enterprise](/pricing) feature.

Dedicated workers work with [TypeScript](./meta-1_typescript_quickstart-index.md) and [Python](./meta-2_python_quickstart-index.md) scripts, they have the highest cold starts. Queries to databases such as PostgreSQL, MySQL, BigQuery, or bash and go scripts do not suffer from any cold starts and hence have the same benefits already without any compexity.

The scripts can be used within flows.

Dedicated workers are faster than AWS lambda: https://www.windmill.dev/docs/misc/benchmarks/aws_lambda.
