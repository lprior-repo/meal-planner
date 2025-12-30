---
doc_id: meta/20_jobs/index
chunk_id: meta/20_jobs/index#chunk-5
heading_path: ["Jobs", "Result"]
chunk_type: code
tokens: 652
summary: "Result"
---

## Result

Jobs have as result the return of the main function serialized as a json object. We highly recommend to return small objects as they will be stored directly in the Database. For larger objects, use [Object Storage](./meta-38_object_storage_in_windmill-index.md).

### Result of jobs that failed

If the jobs fail, it will have result an error object of the following shape:

```json
{
	"error": {
		"name": "ErrorName",
		"message": "Error message",
		"stack": "full stack"
	}
}
```

In python and typescript, and similarly for all languages, this is constructed by extracting those information from the native Exception and Error objects that are raised by the code.

### Result streaming

In Python and TypeScript (bun, nativets, deno), it's possible to stream back the result as a text stream (any `AsyncGenerator<string>` or `iter` compatible object) as a result OR to stream text before the result is fully returned.
If not returning the stream directly, we introduce 2 new functions on our SDK: `wmill.streamResult(stream)` (TS) and `wmill.stream_result(stream)` (Python), to do it prior to the return.

The stream only exists while the job is in the queue. Afterwards, the full stream becomes the result (or added as the field "wm_stream" if there is already a result).

You can run a job and get an SSE stream of the result using the [SSE stream webhooks](./meta-4_webhooks-index.md#sse-stream-webhooks).

#### Returning a stream directly

<Tabs className="unique-tabs">
<TabItem value="bun" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
// can work with //native and recommended

async function* streamWeatherReport(): AsyncGenerator<string> {
	const reportLines = [
		'📍 Current Weather Report\n',
		'Location: San Francisco, CA\n\n',
		'🌤️ Conditions: Partly Cloudy\n',
		'🌡️ Temperature: 72°F (22°C)\n',
		'💨 Wind: 8 mph SW\n',
		'💧 Humidity: 65%\n',
		'👁️ Visibility: 10 miles\n\n',
		"📊 Today's Forecast:\n",
		'Morning: Sunny, 68°F\n',
		'Afternoon: Partly cloudy, 75°F\n',
		'Evening: Clear skies, 70°F\n',
		'Night: Cool and clear, 62°F\n\n',
		'🔮 Tomorrow: Sunny with highs near 78°F\n',
		'Perfect weather for outdoor activities! ☀️\n'
	];

	for (const line of reportLines) {
		yield line;
		// Sleep between 200-500ms for natural reading pace
		await new Promise((resolve) => setTimeout(resolve, 200 + Math.random() * 300));
	}
}

export async function main(x: string) {
	return streamWeatherReport();
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python

import time
from typing import AsyncGenerator

def stream_weather_report():
    report_lines = [
        "📍 Current Weather Report\n",
        "Location: San Francisco, CA\n\n",
        "🌤️ Conditions: Partly Cloudy\n",
        "🌡️ Temperature: 72°F (22°C)\n",
        "💨 Wind: 8 mph SW\n",
        "💧 Humidity: 65%\n",
        "👁️ Visibility: 10 miles\n\n",
        "📊 Today's Forecast:\n",
        "Morning: Sunny, 68°F\n",
        "Afternoon: Partly cloudy, 75°F\n",
        "Evening: Clear skies, 70°F\n",
        "Night: Cool and clear, 62°F\n\n",
        "🔮 Tomorrow: Sunny with highs near 78°F\n",
        "Perfect weather for outdoor activities! ☀️\n"
    ]

    for line in report_lines:
        yield line
        # Sleep 0.2s for reading peace
        time.sleep(0.2)

def main() -> AsyncGenerator[str, None]:
    return stream_weather_report()
```

</TabItem>
</Tabs>

#### Proxy the stream before returning the result

<Tabs className="unique-tabs">
<TabItem value="bun" label="TypeScript" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```typescript
// similar as above

export async function main(x: string) {
	await wmill.streamResult(streamWeatherReport());
	return { foo: 42 };
}
```

</TabItem>
<TabItem value="python" label="Python" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```python
