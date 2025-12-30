---
doc_id: concept/flows/10-flow-trigger
chunk_id: concept/flows/10-flow-trigger#chunk-2
heading_path: ["Trigger scripts", "Scheduled polls"]
chunk_type: prose
tokens: 470
summary: "Scheduled polls"
---

## Scheduled polls

:::tip

Think of this as someone who checks the mailbox every day. If there is a new
letter, they will continue to process it - open and read it - and if there is no
new letter, they won't do anything.

The key part is that opened letters are not placed back in the mailbox. In
Windmill, **a Trigger Script has the job to keep track of what's processed and
what's not**.

:::

Flows can be scheduled through the Flow UI using a CRON expression and then
activating the schedule as seen in the image below.

Example of a trigger script watching new Slack posts with a given word in a given channel and the flow sending each of them by email in a for loop:

![Example of a schedule script with a for loop](../getting_started/8_triggers/schedule-script.png 'Example of a schedule script with a for loop')

![Schedule](../getting_started/8_triggers/schedule-flow.png 'Schedule')

> This flow can be found on [WindmillHub](https://hub.windmill.dev/flows/51/watch-slack-posts-containing-a-given-word-and-send-all-new-ones-per-email).

<br />

Examples of trigger scripts include:

- [Trigger every time a new item text on HackerNews match at least one mention](https://hub.windmill.dev/scripts/hackernews/1301/trigger-everytime-a-new-item-text-on-hackernews-match-at-least-one-mention-hackernews)
- [Notify of new GitHub repo stars](https://hub.windmill.dev/scripts/github/1208/notify-of-new-github-repo-stars-github)
- [Check new uploaded files on Google Drive](https://hub.windmill.dev/scripts/gdrive/1457/get-new-files-gdrive)

The following TypeScript code is an example of the first module of a Flow that
checks for new documents in a MongoDB collection on a regular schedule. In this
case we query documents that were created after a specific time, expressed with
a timestamp. The timestamp is stored with the help of Windmill's built-in
[state functions](./meta-3_resources_and_types-index.md#states) and is
updated in each run.

<details>
  <summary>Code below:</summary>

```ts
import { getState, type Resource, setState } from 'npm:windmill-client';
import { MongoClient, ObjectId } from 'https://deno.land/x/atlas_sdk/mod.ts';

type MongodbRest = {
	endpoint: string;
	api_key: string;
};

export async function main(
	auth: MongodbRest,
	data_source: string,
	database: string,
	collection: string
) {
	const client = new MongoClient({
		endpoint: auth.endpoint,
		dataSource: data_source,
		auth: { apiKey: auth.api_key }
	});
	const documents = client.database(database).collection(collection);
	const lastCheck = (await getState()) || 0;
	await setState(Date.now() / 1000);
	const id = ObjectId.createFromTime(lastCheck);
	return await documents.find({ _id: { $gt: id } });
}
```

</details>

:::tip

You can find this exact Trigger Script on
[Windmill Hub](https://hub.windmill.dev/scripts/mongodb/1462/get-recently-inserted-documents-mongodb),
or many more examples [here](https://hub.windmill.dev/triggers).

:::
