---
doc_id: meta/43_preprocessors/index
chunk_id: meta/43_preprocessors/index#chunk-1
heading_path: ["Preprocessors"]
chunk_type: prose
tokens: 265
summary: "import Tabs from '@theme/Tabs';"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Preprocessors

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

[Scripts](#script-preprocessor) and [flows](#flow-preprocessor) can include a preprocessor to transform incoming requests before they are passed to the runnable.
The preprocessor is only called when the runnable is triggered via a [webhook](./meta-4_webhooks-index.md), an [HTTP route](./meta-39_http_routing-index.md), an [email trigger](./meta-17_email_triggers-index.md), a [WebSocket trigger](./meta-40_websocket_triggers-index.md), a [Kafka trigger](./meta-41_kafka_triggers-index.md), a [NATS trigger](./meta-45_nats_triggers-index.md), a [Postgres trigger](./meta-46_postgres_triggers-index.md), an [SQS trigger](./meta-48_sqs_triggers-index.md) or an [MQTT trigger](./meta-49_mqtt_triggers-index.md).

This approach is useful for preprocessing arguments differently depending on the trigger before the execution of the runnable.
It also separates the handling of arguments according to whether they are called by a trigger or from the UI, which can help you keep a simple schema form in the UI for the runnable.

The preprocessor receives an `event` parameter, which contains all the main trigger data plus additional metadata.
The object always contain a `kind` field that contains the type of trigger. Other arguments are specific to the trigger type.

You can find more details about the arguments format and the structure of `event` for each trigger kind in their respective documentation pages, or below in the templates.

Preprocessors can only be written in [TypeScript](./meta-1_typescript_quickstart-index.md) (Bun/Deno) or [Python](./meta-2_python_quickstart-index.md).
