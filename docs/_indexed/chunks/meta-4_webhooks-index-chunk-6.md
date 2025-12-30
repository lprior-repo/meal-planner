---
doc_id: meta/4_webhooks/index
chunk_id: meta/4_webhooks/index#chunk-6
heading_path: ["Webhooks", "SSE stream webhooks"]
chunk_type: code
tokens: 408
summary: "SSE stream webhooks"
---

## SSE stream webhooks

In addition to classical webhooks, runnables are associated with SSE Stream Webhooks.
These are only useful when the runnable returns a stream. [Learn more about result streaming here](./meta-20_jobs-index.md#result-streaming).
They trigger the job and then return an SSE stream.

The endpoints follow the same convention as classical webhooks, but use the base path `/api/w/workspace/jobs/run_and_stream/`.
You can find the SSE Stream Webhook URL on the Detail page of each Script and Flow, under the Details and Triggers tab.
They support both `GET` and `POST` requests.

To get the stream updates of an existing job with SSE, use `/api/w/:workspace/job_u/getupdate_sse/:id` (pass query arg `?fast=true` for a new job to get fast polling at first)

For flows, a stream will be returned if the last step is a script that returns a stream.

The SSE stream returns JSON objects with the detailed shape available [here](./meta-20_jobs-index.md#job-progress-event-response).
For the stream endpoint, you will mainly get the following events with different available fields:

```json
// update event with new result stream data
{
	"type": "update",
	"new_result_stream": "string", // string: new result stream data since last update
	"stream_offset": 456 // integer: current result stream offset
}
```

```json
// update event with result once job is complete
{
	"type": "update",
	"completed": true, // boolean: whether the job is completed
	"only_result": {...} // JSON result
}
```

The first event is sent one or more times as the stream progresses with new data.
The second event is sent when the job is complete, containing the result of the job in the `only_result` field.
The result will be a string containing the complete stream or a JSON object with the complete stream in the `wm_stream` field if there is already a result.
Always use the `only_result` field to get the complete result at the end, as the final part of the stream might not be sent separately in a new_result_stream event.
