---
doc_id: meta/48_sqs_triggers/index
chunk_id: meta/48_sqs_triggers/index#chunk-2
heading_path: ["SQS triggers", "How to use"]
chunk_type: prose
tokens: 189
summary: "How to use"
---

## How to use

- **Pick an AWS or AWS OIDC resourcee**  
  - Select an existing [AWS resource](../../integrations/aws.md#aws-resource) or [AWS OIDC resource](../../integrations/aws.md#aws-oidc-resource) or create a new one.  
  - The AWS resource must have permissions to interact with SQS.

- **Select the runnable to execute**  
  - Choose the runnable (script or flow) that should be executed when a message arrives in the queue.  

- **Provide an SQS queue URL**  
  - Enter the **Queue URL** of the SQS queue that should trigger the runnable.  
  - You can find the Queue URL in the AWS Management Console under SQS.  
  - For more details, see the [SQS Queue URL Documentation](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-queue-message-identifiers.html#sqs-queue-url).

- **Choose (optional) message attributes**  
  - Specify which message attributes should be included in the triggered event.  
  - These attributes can carry metadata, such as sender information or priority levels.  
  - For more details, see the [SQS Message Attributes Documentation](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-message-metadata.html#sqs-message-attributes).
