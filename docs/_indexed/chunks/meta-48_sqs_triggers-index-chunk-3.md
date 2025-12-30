---
doc_id: meta/48_sqs_triggers/index
chunk_id: meta/48_sqs_triggers/index#chunk-3
heading_path: ["SQS triggers", "Example"]
chunk_type: code
tokens: 352
summary: "Example"
---

## Example

Below are code examples demonstrating how to handle SQS messages in your Windmill scripts. You can either process messages directly in a basic script or use a preprocessor for more advanced message handling and transformation before execution.

### Basic script example

```TypeScript
export async function main(msg: string) {
  // do something with the message
}
```

### Using a preprocessor

If you use a [preprocessor](./meta-43_preprocessors-index.md), the preprocessor function receives an SQS message with the following fields:

#### Field descriptions

- **`queue_url`**: The URL of the SQS queue that received the message.  
- **`message_id`**: A unique identifier assigned to each message by SQS.  
  - [More details](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_ReceiveMessage.html)  
- **`receipt_handle`**: A token used to delete the message after processing.  
  - [More details](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html)  
- **`attributes`**: Metadata attributes set by SQS, such as `SentTimestamp`.  
  - [Full list of system attributes](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-metadata.html#sqs-message-system-attributes)  
- **`message_attributes`**: User-defined attributes that can be attached to the message.  
  - `string_value`: The string representation of the attribute value.  
  - `data_type`: The data type of the attribute (e.g., `"String"`, `"Number"`, `"Binary"`).  
  - [More details on message attributes](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-metadata.html#sqs-message-attributes)  


```TypeScript
export async function preprocessor(
  event: {
    kind: "sqs",
    msg: string,
    queue_url: string,
    message_id?: string,
    receipt_handle?: string,
    attributes: Record<string, string>,
    message_attributes?: Record<string, {
        string_value?: string,
        data_type: string
    }>
  }
) {
  if (event.kind !== "sqs") {
    throw new Error(`Expected a SQS event`);
  }

  // assuming the message is a JSON object
  const data = JSON.parse(event.msg);
  
  return {
      content: data.content,
      metadata: {
          sentAt: event.attributes.SentTimestamp,
          messageId: event.message_id
      }
  };
}

export async function main(content: string, metadata: { sentAt: string, messageId: string }) {
  // Process transformed message data
  console.log(`Processing message ${metadata.messageId} sent at ${metadata.sentAt}`);
  console.log("Content:", content);
}
```
