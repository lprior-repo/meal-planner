---
doc_id: meta/4_local_development/index
chunk_id: meta/4_local_development/index#chunk-12
heading_path: ["Local development", "Mocked API files"]
chunk_type: code
tokens: 174
summary: "Mocked API files"
---

## Mocked API files

Simulate API interactions locally by using a JSON file to store and retrieve variables and resources.

The file should conform to the following interface:

```typescript
interface MockedApi {
  variables: Record<string, string>;
  resources: Record<string, any>;
}
```

Use the file by setting the `WM_MOCKED_API_FILE` [environment variable](./meta-47_environment_variables-index.md) to the path of your JSON file. For example:

```ts
import * as wmill from "windmill-client@1.450.0-beta.2"

export async function main(x: string) {
  await Bun.write("./foo.json", '{}')
  process.env["WM_MOCKED_API_FILE"] = "./foo.json"
  await wmill.setVariable("foo", "foobar")
  await wmill.setResource({ "we": 42}, "foo")
  console.log(await wmill.getResource("foo"))
  return x
}
```

If WM_MOCKED_API_FILE is present, [`getVariable`](./meta-2_variables_and_secrets-index.md#accessing-a-variable-from-a-script) / [`getResource`](./meta-3_resources_and_types-index.md#fetching-them-from-within-a-script-by-using-the-wmill-client-in-the-respective-language) will look up first in that object if the value exists. `setVariable` / `setResource` will set it there. If the environment variable is set but no file exists, it is set to an empty mocked API.
