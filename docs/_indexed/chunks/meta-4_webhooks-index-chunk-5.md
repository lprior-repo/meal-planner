---
doc_id: meta/4_webhooks/index
chunk_id: meta/4_webhooks/index#chunk-5
heading_path: ["Webhooks", "Request with Header\"."]
chunk_type: code
tokens: 1476
summary: "Request with Header\"."
---

## Request with Header".
curl -X GET \
    -H "Content-Type: application/json"    \
    -H "Authorization: Bearer supersecret" \
    ".../w/demo/jobs/run_wait_result/p/u/bot/hello_world_deno?payload=<URL_SAFE_BASE64_ENCODED_JSON>"
```

You can find an example using only standard Deno libraries on the
[Windmill Hub][script].

You can also verify that the job has been triggered and run (or investigate any
encountered issues), by checking the [Runs menu][runs] on the app.

![Runs page](./runs.png.webp)

### Body

The webhook endpoints accept a JSON object or url encoded form data as the body, where each key corresponds to an argument of the script/flow.

#### Non object payload / body

If the payload is not an object, it will be wrapped in an object with the key `body` and the value will be the payload/body itself. e.g:

```json
[1,2,3] => {"body": [1,2,3]}
```

and your script can process it as:

```python
def main(body: List[int]):
    print(body)
```

#### Wrapping body, handling arbitrary payload

You can also force the payload to be wrapped in an object at the key `body` by passing the query arg `wrap_body=true`. This is useful when the payload is not not known in advance and you want to handle it in your script. e.g:

Python:

```python
def main(body: Any):
	print(body)
```

Typescript:

```typescript
export async function main(body: any) {
	console.log(body);
}
```

#### Raw payload / body

Similarly to request headers, if the query args contain `raw=true`, then an additional argument will be added: `raw_string` which contains the entire json payload as a string (without any parsing). This is useful to verify the signature of the payload for example (discord require the endpoints to verify the signature for instance).

#### Handling form data (file uploads)

The webhook endpoints also accept `multipart/form-data`, useful for file uploads. The payload should be a `FormData` object, where each key corresponds to an argument of the script/flow.

For file fields, the value will be an array containing [s3 objects](./meta-38_object_storage_in_windmill-index.md#read-a-file-from-s3-or-object-storage-within-a-script) with the path to the uploaded files in the [workspace object storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage) (e.g., S3).

Here's an example script for handling form data with a file field:

<Tabs className="unique-tabs">
<TabItem value="bun" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import { S3Object } from 'windmill-client';

export async function main(mytextfield: string, myfilefield: S3Object[]) {
	return myfilefield;
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
import wmill
from typing import List

def main(mytextfield: str, myfilefield: List[wmill.S3Object]):
    return myfilefield
```

</TabItem>
</Tabs>

:::warning
A [workspace object storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage) must be configured to accept form data payloads.
:::

### Request headers

It is possible for jobs to take request headers as arguments. To do so, either specify in the query args the headers to process at `include_header`, separated with `,`. e.g:

```text
/api/w/workspace/jobs/run_wait_result/p/u/user/new_script?include_header=X-Sign,foo
```

or use the env variable: `INCLUDE_HEADERS` with the same format so that all requests to any job will include the headers.

### Query args

It is possible to pass query args to the job. To do so, either specify in the query args the headers to process at `include_query`, separated with `,`. e.g for a [sync](#synchronous) get request (works for all endpoints):

```text
/api/w/workspace/jobs/run_wait_result/p/u/user/new_script?include_query=a,b,c&a=foo&b=bar&c=foobar
```

to have a: "foo", b: "bar", c: "foobar", passed as args.

### Custom response code

For all sync run jobs endpoints, if the response contains a key `windmill_status_code` with a number value, that value will be used as the status code. For example, if a script or flow returns:

```json
{
	"windmill_status_code": 201,
	"result": {
		"Hello": "World"
	}
}
```

the synchronous endpoint will return:

```json
{
	"Hello": "World"
}
```

with a status code `201`.

Note that if the status code is invalid (w.r.t [RFC9110](https://httpwg.org/specs/rfc9110.html#overview.of.status.codes)), the endpoint will return an error.

### Custom response content type

Similarly to the above, for all sync run jobs endpoints, if the response contains a key `windmill_content_type`, the associated value will be used as the content type header of the response. For example, if a script or flow returns:

```json
{
	"windmill_content_type": "text/csv",
	"result": "Hello;World"
}
```

the synchronous endpoint will return:

```csv
"Hello;World"
```

with the response header: "Content-Type: text/csv".

### Custom response headers

Similar to the above, for all sync run jobs endpoints, if the response contains a key `windmill_headers`, the headers will be added to the response. For example, if a script or flow returns:

```json
{
	"windmill_headers": { "X-Custom-Header": "foo" },
	"result": {
		"Hello": "World"
	}
}
```

the synchronous endpoint with return the result with the header `X-Custom-Header: foo` (in addition to `Content-Type: application/json`).

It's better to use `windmill_content_type` to override the content type, as the output will be correctly formatted.

### Return early for flows

It is possible to define a node at which the flow will return at for sync endpoints. The rest of the flow will continue asynchronously.

Useful when some webhooks need to return extremely fast but not just the uuid (define first step as [early return](./ops-flows-19-early-return.md)) or when the expected return from the webhook doesn't need to the full flow being computed.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Return Early for Flows"
		description="Define a node at which the flow will return at for sync endpoints."
		href="/docs/flows/early_return"
	/>
</div>

### Exposing a webhook URL

Single port proxy can be leveraged to expose a webhook with a custom URL. In its docker-compose, Windmill uses Caddy but the logic can be adapted for others.

In the Caddyfile, the [`handle_path`](https://caddyserver.com/docs/caddyfile/directives/handle_path#handle-path) and [`rewrite`](https://caddyserver.com/docs/caddyfile/directives/rewrite#rewrite) directive can be used:

```bash
{$BASE_URL} {
	bind {$ADDRESS}

	handle_path /mywebhook {
		rewrite * /api/w/demo/jobs/run_wait_result/p/u/bot/hello_world_deno"
		## You can optionally inject the token in Caddy to have the endpoint exposed publicly
		## request_header Authorization "Bearer <WINDMILL_GENERATED_TOKEN>"
	}

	...
	reverse_proxy /* http://windmill_server:8000
}
```

The job can then be triggered with:

```bash
curl -X POST                               \
    --data '{}'                            \
    -H "Content-Type: application/json"    \
    ".../mywebhook?payload=<URL_SAFE_BASE64_ENCODED_JSON>"
```

### Cloud events 1.0

Windmill's webhooks aim to be compatible with the [Cloud Events 1.0](https://cloudevents.io/) specification. The envelope metadata will be parsed into a special argument `WEBHOOK__METADATA__` for scripts and flows.

![Webhook metadata argument](./webhook_metadata.png)

Nothing extra needs to be done on Windmill's side, if a request has the cloudevent content header it will automatically be handled according to the specification. When using webhook producers that allow it, you can select to use the cloud events schema. For example with Azure Event Grid:

![Event Grid Cloud Event Subscription](./event_grid_cloud_event_subscription.png)

:::caution

Windmill does not support batching cloud events yet. This means that requests with the content type set to `'application/cloudevents-batch+json'` will return an error response.

:::

Learn more about what Cloud Events are [here](https://cloudevents.io/).

### Delete after use

For a script, delete [logs](./meta-14_audit_logs-index.md), arguments and results after use.

:::warning

This settings ONLY applies to [synchronous](#synchronous) webhooks. If used individually, this script must be triggered using a synchronous endpoint to have the desired effect.

<br />
The logs, arguments and results of the job will be completely deleted from Windmill once it is complete
and the result has been returned.
<br />
The deletion is irreversible.

:::
