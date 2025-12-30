---
doc_id: meta/41_kafka_triggers/index
chunk_id: meta/41_kafka_triggers/index#chunk-2
heading_path: ["Kafka triggers", "How to use"]
chunk_type: code
tokens: 338
summary: "How to use"
---

## How to use

Create a new trigger on the Kafka triggers page.
Add a Kafka resource with the broker hostnames (hostname:port) and the security settings.
Specify the topics the trigger should listen to.
The group id is automatically filled in from the current workspace and the trigger path. You can change it if necessary.
It indicates the consumer group to which the trigger belongs. This garantees that even if the trigger stops listening for a while, it will receive the messages it missed when it starts listening again.

Once the Kafka resource and settings are set, select the runnable that should be triggered by this trigger.
The received webhook base64 encoded payload will be passed to the runnable as a string argument called `payload`.

Here's an example script:

```TypeScript
export async function main(payload: string) {
  // do something with the message
}
```

And if you use a [preprocessor](./meta-43_preprocessors-index.md), the script could look like this:

```TypeScript
export async function preprocessor(
  event: {
    kind: "kafka",
    payload: string, // base64 encoded payload
    brokers: string[];
    topic: string; // the specific topic the message was received from
    group_id: string;
  }
) {
  if (event.kind !== "kafka") {
    throw new Error(`Expected a kafka event`);
  }

  // assuming the message is a JSON object
  const msg = JSON.parse(atob(event.payload)); 

  // define args for the main function
  // let's assume we want to use the message content and the topic
  return {
    message_content: msg.content,
    topic: event.topic
  };
}

export async function main(message_content: string, topic: string) {
  // do something with the message content and topic
}
```
