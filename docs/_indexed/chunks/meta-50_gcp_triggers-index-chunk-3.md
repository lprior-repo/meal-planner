---
doc_id: meta/50_gcp_triggers/index
chunk_id: meta/50_gcp_triggers/index#chunk-3
heading_path: ["GCP Pub/Sub triggers", "Implementation examples"]
chunk_type: code
tokens: 426
summary: "Implementation examples"
---

## Implementation examples

Below are examples for handling GCP Pub/Sub messages in Windmill.

> Windmill provides the Pub/Sub message as the argument `payload` (a base64-encoded string) to your runnable.

### Basic script

```typescript
export async function main(payload: string) {
  const decoded = new TextDecoder().decode(Uint8Array.from(atob(payload), c => c.charCodeAt(0)));

  try {
    const jsonData = JSON.parse(decoded);
    console.log("Received JSON data:", jsonData);
    // Process structured data
  } catch (e) {
    console.log("Received plain text:", decoded);
    // Process raw text
  }

  return { processed: true };
}
```

---

### Using a preprocessor

If you configure a [preprocessor](./meta-43_preprocessors-index.md), you can extract fields before they reach the main function.

> Windmill provides the Pub/Sub message as the argument `payload` (a base64-encoded string) to the preprocessor.

#### GCP Pub/Sub trigger object

- `subscription`: Subscription ID
- `topic`: Topic ID
- `message_id`: Unique message ID
- `publish_time`: Publish timestamp (RFC 3339 format with `Z`, e.g., `"2024-04-07T12:34:56Z"`)
- `attributes`: Key-value metadata
- `delivery_type`: `"push"` or `"pull"` (the type of delivery)
- `ordering_key`: Ordering key (optional, if message ordering is enabled)
- `headers`: HTTP headers for push delivery (only present for push)

Example preprocessor:

```typescript
export async function preprocessor(
  event: {
    kind: 'gcp',
    payload: string, // base64 encoded payload
    message_id: string,
    subscription: string,
    ordering_key?: string,
    attributes?: Record<string, string>,
    delivery_type: "push" | "pull",
    headers?: Record<string, string>,
    publish_time?: string,
  }
) {
  if (event.kind === 'gcp') {
    const decodedString = atob(event.payload);

    const attributes = event.attributes || {};
    const contentType = attributes['content-type'] || attributes['Content-Type'];
    const isJson = contentType === 'application/json';

    let parsedMessage: any = decodedString;
    if (isJson) {
      try {
        parsedMessage = JSON.parse(decodedString);
      } catch (err) {
        throw new Error(`Invalid JSON payload: ${err}`);
      }
    }

    return {
      messageAsDecodedString: decodedString,
      contentType,
      parsedMessage,
      attributes
    };
  }

  throw new Error(`Expected gcp trigger kind got: ${event.kind}`);
}
```

Then your `main` function can simply receive the extracted arguments:

```typescript
export async function main(
  messageAsDecodedString: string,
  contentType?: string,
  parsedMessage?: any,
  attributes?: Record<string, string>,
) {
  console.log("Decoded String:", messageAsDecodedString);
  console.log("Content-Type:", contentType);
  console.log("Parsed Message:", parsedMessage);
  console.log("Attributes:", attributes);
}
```

---
