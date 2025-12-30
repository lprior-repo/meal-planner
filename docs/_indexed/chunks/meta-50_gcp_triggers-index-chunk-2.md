---
doc_id: meta/50_gcp_triggers/index
chunk_id: meta/50_gcp_triggers/index#chunk-2
heading_path: ["GCP Pub/Sub triggers", "How to use"]
chunk_type: prose
tokens: 552
summary: "How to use"
---

## How to use

### Configure GCP connection

- Select an existing [GCP resource](https://hub.windmill.dev/resource_types/154/gcloud) (service account credentials) or create a new one.

> The service account used must have enough permissions for Windmill to fully manage Pub/Sub resources. Specifically:
>
> - **Pub/Sub Viewer** (`roles/pubsub.viewer`): to check if topics or subscriptions exist, list them.
> - **Pub/Sub Subscriber** (`roles/pubsub.subscriber`): to attach to subscriptions and consume messages.
> - **Pub/Sub Editor** (`roles/pubsub.editor`): needed to create or update subscriptions, and to optionally delete the subscription in the cloud when deleting the associated trigger if the user chooses to do so.
>
> If you prefer not to assign these three individually, you can simply grant the **Pub/Sub Admin** role (`roles/pubsub.admin`).
>
> Additionally, if you want to create **authenticated push delivery subscriptions**, the service account must also have **Service Account User** (`roles/iam.serviceAccountUser`) permission. See [Authenticate Push Subscriptions](https://cloud.google.com/pubsub/docs/authenticate-push-subscriptions) for more details.

### Subscription setup

#### Select topic and subscription

- **Choose a topic** from your GCP project. You can refresh the list if needed.
- Decide how to set up your subscription:
  - **Create or update a subscription**: Windmill will create a new subscription or update an existing one.
  - **Use an existing subscription**: Link an existing subscription from your GCP project.

#### When creating/updating a subscription:

- Specify a **Subscription ID**, or leave it empty to auto-generate one.
- Choose the **delivery type**:
  - **Pull**: Windmill sets the subscription as a **Pull** subscription.
  - **Push**: Windmill sets the subscription as a **Push** subscription.
    - For **push delivery**, Windmill sets the subscription's push endpoint URL to match the path of the trigger.\
      The format is:\
      `{base_endpoint}/api/gcp/w/{workspace_id}/{trigger_path}`
    - Example: if the trigger path is `u/test/fabulous_trigger`, the endpoint will be:\
      `{base_endpoint}/api/gcp/w/myworkspace/u/test/fabulous_trigger`
    - When creating or updating a **push** subscription, Windmill allows you to configure:
      - Whether **authentication** is enabled or disabled.

Refer to [Google Cloud Pub/Sub - Managing Subscriptions](https://cloud.google.com/pubsub/docs/subscriber) for more details about delivery types.

#### When using an existing subscription:

- Select an existing subscription ID **among the subscriptions fetched from the selected topic**.
- Windmill will automatically detect the subscription's **delivery type** based on the cloud configuration.
- If the subscription is of **push delivery** type:
  - The subscription's endpoint URL must match the path of the trigger that will be bound to it.
  - The expected format is:\
    `{base_endpoint}/api/gcp/w/{workspace_id}/{trigger_path}`
> **Note:** You must not have multiple subscriptions pointing to the same trigger URL (for example, two subscriptions targeting `{base_endpoint}/api/gcp/w/myworkspace/u/test/fabulous_trigger`).

### Choose the runnable

- Select the **script** or **flow** to trigger when Pub/Sub messages are received.

---
