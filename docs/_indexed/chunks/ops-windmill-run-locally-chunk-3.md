---
doc_id: ops/windmill/run-locally
chunk_id: ops/windmill/run-locally#chunk-3
heading_path: ["Run locally", "Interacting with Windmill locally"]
chunk_type: code
tokens: 660
summary: "Interacting with Windmill locally"
---

## Interacting with Windmill locally

To interact with Windmill locally, you will need to fill out the context variables that would otherwise be filled out by the Windmill runtime for you.

The most important ones are
`WM_TOKEN`, `WM_WORKSPACE` and `BASE_INTERNAL_URL`.

Set `BASE_INTERNAL_URL` to the URL of you Windmill instance,
for example `https://app.windmill.dev`, note that you can never include a
trailing `/`, or the client will fail to connect. Then set `WM_TOKEN` to a
token, either create this in the UI, or use [wmill, the CLI](./meta-windmill-index-14.md)
using `wmill user create-token`. And then `WM_WORKSPACE` corresponds to your workspace id.
Below are some examples on how to do this in various environments.

### State

To use the `getState` and `setState` functions, you will have to set `WM_STATE_PATH`. We recommend using your script path name as the state path, for example:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
let fullUrl = import.meta.url;
let pathS = fullUrl.substring(8, fullUrl.length - 3).split('/');
const path = pathS.slice(pathS.length - 3, pathS.length).join('/');
Deno.env.set('WM_STATE_PATH', path);
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
let fullUrl = import.meta.url;
let pathS = fullUrl.substring(8, fullUrl.length - 3).split('/');
const path = pathS.slice(pathS.length - 3, pathS.length).join('/');
Bun.env.set('WM_STATE_PATH', path);
```

</TabItem>
</Tabs>

### Terminal

On UNIX platforms you can simply do
`BASE_INTERNAL_URL=https://app.windmill.dev WM_TOKEN=ThisIsAToken deno run -A my_script.ts`
with the relevant info provided, the same will work for Python.

On Windows this is not possible, you will have to use
[set](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/set_1).
For example:

```cmd
set "BASE_INTERNAL_URL=https://app.windmill.dev"
set "WM_TOKEN=ThisIsAToken"
set "WM_WORKSPACE=workspace_id"
```

then simply run the relevant command for your language.

### VS Code

:::info VS Code extension

Windmill has its own extension on VS Code for local development & testing, see [VS Code extension](./meta-windmill-index-22.md).

:::

To interact with you Windmill instance from VS Code, use a launch.json. See how to create one for
[Python](https://code.visualstudio.com/docs/python/debugging) and
[Deno](https://deno.land/manual@v1.9.2/getting_started/debugging_your_code#vscode).

Then add environment files using the "env" section in your configuration.

:::caution

Make sure you are not checking your Token into git.

To manage your secrets it may be easier to use a .env file, and add it to
.gitignore, this is also done below.

:::

For example, for TypeScript:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Deno",
      "type": "pwa-node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "deno",
      "runtimeArgs": ["run", "--inspect-brk", "-A", "${file}"],
      "env" {
        "BASE_INTERNAL_URL": "https://app.windmill.dev",
        "WM_TOKEN": "ThisIsAToken",
        "WM_WORKSPACE": "workspace_id"
      },
      "envFile": ".env"
    }
  ]
}
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Bun",
      "type": "pwa-node",
      "request": "launch",
      "cwd": "${workspaceFolder}",
      "runtimeExecutable": "bun",
      "runtimeArgs": ["run", "${file}"],
      "env" {
        "BASE_INTERNAL_URL": "https://app.windmill.dev",
        "WM_TOKEN": "ThisIsAToken",
        "WM_WORKSPACE": "workspace_id"
      },
      "envFile": ".env"
    }
  ]
}
```

</TabItem>
</Tabs>

The same `env` & `envFile` options are also supported by Python.

### JetBrains IDEs

Especially for Python you may prefer using a JetBrains IDE. Simply navigate to
your
[run config](https://www.jetbrains.com/help/idea/run-debug-configuration-python.html#1)
and add two lines:

```bash
BASE_INTERNAL_URL = https://app.windmill.dev
WM_TOKEN = ThisIsAToken
WM_WORKSPACE= workspace_id
```

:::caution

Make sure you are not checking your Token into git.

:::
