---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-11
heading_path: ["HTTP routes", "Custom script authentication (Advanced)"]
chunk_type: prose
tokens: 332
summary: "Custom script authentication (Advanced)"
---

## Custom script authentication (Advanced)

Use a **Custom Script** for full control over authentication and validation when built-in methods are not enough.  
This gives access to:

- Raw payload
- Headers, query, and route parameters
- Secrets stored as [variables](https://docs.windmill.dev/docs/core_concepts/variables_and_secrets)

Example script for HMAC signature validation:
```ts
const SECRET_KEY_VARIABLE_PATH = "u/admin/well_backlit_variable";

export async function preprocessor(
  event: {
    kind: 'http';
    body: any;
    raw_string: string | null;
    route: string;
    path: string;
    method: string;
    params: Record<string, string>;
    query: Record<string, string>;
    headers: Record<string, string>;
  },
) {
  if (event.kind !== 'http') {
    throw new Error('Expected a http event');
  }

  if (!event.raw_string) {
    throw new Error('Missing raw_string in event');
  }

  const signature = event.headers['x-signature'] || event.headers['signature'];
  if (!signature) {
    throw new Error('Missing signature in request headers.');
  }

  const timestamp = event.headers['x-timestamp'] || event.headers['timestamp'];
  if (timestamp) {
    const timestampValue = parseInt(timestamp, 10);
    const currentTime = Math.floor(Date.now() / 1000);
    const TIME_WINDOW_SECONDS = 5 * 60;

    if (isNaN(timestampValue)) {
      throw new Error('Invalid timestamp format.');
    }

    if (Math.abs(currentTime - timestampValue) > TIME_WINDOW_SECONDS) {
      throw new Error('Request timestamp is outside the acceptable window.');
    }
  }

  const isValid = await verifySignature(signature, event.raw_string, timestamp);
  if (!isValid) {
    throw new Error('Invalid signature.');
  }

  return JSON.parse(event.raw_string);
}

async function verifySignature(signature: string, body: string, timestamp?: string): Promise<boolean> {
  const dataToVerify = timestamp ? `${body}${timestamp}` : body;
  const secretKey = await wmill.getVariable(SECRET_KEY_VARIABLE_PATH);
  const expectedSignature = crypto
    .createHmac('sha256', secretKey)
    .update(dataToVerify)
    .digest('hex');

  try {
    return crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    );
  } catch (error) {
    console.error('Signature comparison error:', error);
    return false;
  }
}
```
> ℹ️ When using **Custom Script**, the `raw_body` option is automatically enabled.
