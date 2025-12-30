---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-7
heading_path: ["HTTP routes", "Body processing options"]
chunk_type: code
tokens: 158
summary: "Body processing options"
---

## Body processing options

Depending on your setup, additional arguments can be injected into your runnable:

| Option           | Argument Provided     | Description                                                                                          |
|------------------|------------------------|------------------------------------------------------------------------------------------------------|
| **Wrap body**    | `body`                 | If enabled, Windmill will wrap the incoming request body inside an object under the `body` key. Useful when the payload structure is dynamic or unknown. |
| **Raw body**   | `raw_string`           | The raw (unprocessed) request body is provided as a `raw_string` argument (type: `string`). Useful for signature verification, binary payloads, etc. |

### Example using `body`
```ts
export async function main(body: unknown) {
  console.log("Received body:", body);
  return body;
}
```

### Example using `raw_string`
```ts
export async function main(raw_string: string) {
  console.log("Raw body received:", raw_string);
  return JSON.parse(raw_string);
}
```

---
