---
doc_id: meta/49_mqtt_triggers/index
chunk_id: meta/49_mqtt_triggers/index#chunk-3
heading_path: ["MQTT triggers", "Implementation examples"]
chunk_type: code
tokens: 672
summary: "Implementation examples"
---

## Implementation examples

Below are code examples demonstrating how to handle MQTT messages in your Windmill scripts. You can either process messages directly in a basic script or use a preprocessor for more advanced message handling and transformation before execution.

### Basic script

```typescript
export async function main(payload: string) {
  // Convert base64 encoded payload to string
  const textPayload = atob(payload);
  
  // Parse JSON if applicable
  try {
    const jsonData = JSON.parse(textPayload);
    console.log("Received JSON data:", jsonData);
    // Process JSON data
  } catch (e) {
    // Handle as plain text
    console.log("Received text data:", textPayload);
    // Process text data
  }
  
  return { processed: true, message: "MQTT message processed successfully" };
}
```

### Script with preprocessor

If you use a [preprocessor](./meta-43_preprocessors-index.md), the preprocessor function receives the message payload as base64 encoded string and an MQTT object with the following fields:

#### MQTT object

- **`topic`**: The MQTT topic on which the message was received.
- **`retain`**: Boolean indicating if the message is retained.
- **`pkid`**: Packet identifier (if QoS > 0).
- **`qos`**: Quality of Service level.
- **`v5`**: MQTT v5 properties (optional).

#### MQTT v5 properties

- **`payload_format_indicator`**: Indicates if the payload is UTF-8 encoded or binary.
- **`topic_alias`**: An alias for the topic name.
- **`response_topic`**: A topic for the recipient to send a response to.
- **`correlation_data`**: Correlation data for request/response.
- **`user_properties`**: A list of user-defined properties.
- **`subscription_identifiers`**: Subscription identifiers.
- **`content_type`**: The content type of the payload.

For more information about MQTT v5 properties, see the [MQTT v5 Properties Documentation](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901109).

```typescript
/**
 * General Trigger Preprocessor
 * 
 * ⚠️ This function runs BEFORE the main function.
 * 
 * It processes raw trigger data (e.g., MQTT, HTTP, SQS) before passing it to `main()`.
 * Common tasks:
 * - Convert binary payloads to string/JSON
 * - Extract metadata
 * - Filter messages
 * - Add timestamps/context
 * 
 * The returned object determines `main()` parameters:
 * - `{a: 1, b: 2}` → `main(a, b)`
 * - `{payload}` → `main(payload)`
 * 
 * @param event - Trigger data and metadata (e.g., MQTT, HTTP)
 * @returns Processed data for `main()`
 */
export async function preprocessor(
  event: {
    kind: "mqtt",
    payload: string, // base64 encoded payload
    topic: string,
    retain: boolean,
    pkid: number,
    qos: number,
    v5?: {
      payload_format_indicator?: number,
      topic_alias?: number,
      response_topic?: string,
      correlation_data?: Array<number>,
      user_properties?: Array<[string, string]>,
      subscription_identifiers?: Array<number>,
      content_type?: string
    }

  }
) {
  if (event.kind === 'mqtt') {
    const payloadAsString = atob(event.payload);

    return {
      contentType: event.v5?.content_type,
      payload: uint8Payload,
      payloadAsString
    };
  }
  // We assume the script is triggered by an MQTT message, which is why an error is thrown for other trigger kinds.
  // If the script is intended to support other triggers, update this logic to handle the respective trigger kind.
  throw new Error(`Expected mqtt trigger kind got: ${event.kind}`)
}

/**
 * Main Function - Handles processed trigger events
 * 
 * ⚠️ Called AFTER `preprocessor()`, with its return values.
 * 
 * @param payload - Raw binary payload
 * @param payloadAsString - Decoded string payload
 * @param contentType - MQTT v5 content type (if available)
 */
export async function main(payload: Uint8Array, payloadAsString: string, contentType?: string) {

}
```
