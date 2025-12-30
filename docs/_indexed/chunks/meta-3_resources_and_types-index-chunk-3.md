---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-3
heading_path: ["Resources and resource types", "Create a resource type"]
chunk_type: prose
tokens: 439
summary: "Create a resource type"
---

## Create a resource type

Windmill comes preloaded with some common Resource types, such as databases, apps, SMTP, etc. You can see the full list on [Windmill Hub](https://hub.windmill.dev/resources).
You can also add custom Resource types by clicking "Add a resource type" on the Resources page.

![Create resource type](./add_resource_type.png.webp)

Use the "Add Property" button to add a field to the resource type. You can
specify constraints for the field (a type, making it mandatory, specifying a
default, etc). You can also view the schema by toggling the "As JSON" option:

![Resource type schema view](./resource_type_json.png.webp)

The resources types created from the [Admins workspace](./meta-18_instance_settings-index.md#admins-workspace) are shared across all workspaces.

### Share resource type on Hub

You can contribute to the [Windmill Hub](https://hub.windmill.dev/) by sharing your Resource Type. To do so, add a Resource Type on the [Resources section](https://hub.windmill.dev/resources) of the Hub.

You will be asked to fill Name, Integration (the corresponding service it interacts with) and Schema (the JSON Schema of the Resource Type).

Verified Resource types on the Hub are directly added to the list of available Resource types on each new Windmill instance synced with the Hub.

![Share resource type](./new_resource_type_hub.png)

### Sync resource types with WindmillHub

When creating a [self-hosted](./meta-1_self_host-index.md) instance, you are offered to set a [schedule](./meta-1_scheduling-index.md) to regularly sync all resource types from [WindmillHub](https://hub.windmill.dev/). This will ensure that all the approved resource types are available in your instance. On Windmill cloud, it is done regularly by the Windmill team. Ask us if you need a specific [resource type from Hub](https://hub.windmill.dev/resources) to be added.

The [Bun](./meta-1_typescript_quickstart-index.md) script executed from the admin workspace is:

```ts
import * as wmill from 'windmill-cli@1.393.2';

export async function main() {
	await wmill.hubPull({
		workspace: 'admins',
		token: process.env['WM_TOKEN'],
		baseUrl: globalThis.process.env['BASE_URL']
	});
}
```

You can find this script on [WindmillHub](https://hub.windmill.dev/scripts/windmillhub/9069/synchronize-hub-resource-types-with-instance-windmillhub#approved).

This script is probably already on your [Admins workspace](./meta-18_instance_settings-index.md#admins-workspace), as it was suggested during Windmill [self-hosting setup](./meta-1_self_host-index.md). Having this script run on your Admins workspace will sync resources accross all workspaces of your instance.

To avoid running it manually, we recommend [scheduling](./meta-1_scheduling-index.md) this script regularly.
