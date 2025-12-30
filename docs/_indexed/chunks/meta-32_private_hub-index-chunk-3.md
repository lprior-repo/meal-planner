---
doc_id: meta/32_private_hub/index
chunk_id: meta/32_private_hub/index#chunk-3
heading_path: ["Private Hub", "Local syncing and syncing with the public Hub"]
chunk_type: prose
tokens: 258
summary: "Local syncing and syncing with the public Hub"
---

## Local syncing and syncing with the public Hub

We provide a [CLI](https://www.npmjs.com/package/@windmill-labs/hub-cli) to sync your Private Hub with your local file system. To use the CLI, set the following environment variables:

1. `HUB_URL`: The URL of your Private Hub
2. `TOKEN`: A superadmin user token

Use the commands `wmill-hub pull` and `wmill-hub push` for pulling and pushing, respectively.
The CLI will create a `hub` folder on your local system with all the integration folders inside.

If you want to partially or fully sync your private hub with the public one:

1. Pull the scripts locally from the public hub using `wmill-hub wm-pull`. This will pull the scripts to a folder named `hub`.
2. Delete any integration folders you don’t want to add to your Private Hub.
3. Push the scripts to your Private Hub using `wmill-hub push`.

:::info
If for some reason you can't pull from the official hub with `wmill-hub wm-pull`, we can provide you with a zip file of the public hub scripts.
Once extracted, you will see a hub folder with all the integration folders inside. Drag and drop those folders into your `hub` folder.
You can then push as usual using `wmill-hub push`.
:::
