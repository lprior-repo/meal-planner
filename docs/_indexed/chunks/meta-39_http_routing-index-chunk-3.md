---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-3
heading_path: ["HTTP routes", "Creating an HTTP route"]
chunk_type: code
tokens: 833
summary: "Creating an HTTP route"
---

## Creating an HTTP route

Windmill supports two ways to create HTTP routes:

- **Manual creation**, where you define a path, method, and bind it to a runnable.
- **Automatic generation** from an OpenAPI specification, enabling batch creation.

### To create a route manually:

- Navigate to the **Custom HTTP routes** page.
- Click the **New route** button.
- Fill in the route configuration fields
- Click **Save** to create the route.

### Generate routes from an OpenAPI specification

Windmill can generate HTTP routes directly from an OpenAPI 2.0+ specification in JSON or YAML format.

You can provide the specification in one of three ways:
- Paste raw content
- Upload a file
- Provide a public URL

#### To generate routes:

- Navigate to the **Custom HTTP routes** page.
- Click the **From OpenAPI spec** button.
- Pick a folder for the generated routes.
- Choose your input method and provide the OpenAPI spec.
- Click **Generate HTTP routes**.

#### Behavior and limitations:

- If a path object has a `summary` field, it will be used as suffix for the trigger path.
  - If the `summary` exceeds 255 characters, it will be **automatically truncated** to fit the maximum allowed length.
- If no `summary` is defined, Windmill generates a unique route path automatically.
- Generated routes **do not include a script or flow binding** (`script_path`) by default.
  - This means requests to the route will return an error until a runnable is attached.
- You can:
  - **Save routes immediately without modifying them**.
  - **Edit any route before or after saving**, to assign a runnable, change route path, etc.
- External `$ref` references (e.g., referencing outside the spec) are **not supported**.
  - You must resolve them beforehand.
  - Only internal references (e.g., `#/components/...`) are supported.


You can use `:param` in the route path and access these as `params` in a [preprocessor](https://docs.windmill.dev/docs/core_concepts/preprocessors).

> ℹ️ **Only workspace admins** can create routes.  
> Once created, all properties of a route **except the HTTP path** can be modified by any user with **write access** to the route.  
> Learn more about [Admins workspace](./meta-18_instance_settings-index.md#admins-workspace).

---

### Workspace prefix

On Windmill Cloud, all HTTP routes are automatically prefixed by the `workspace_id` (e.g., `{workspace_id}/{path}`).  
This ensures that different workspaces can define the same route paths independently.

On self-hosted Windmill, you can optionally enable the **workspace prefix** setting to achieve the same behavior.

When workspace prefix is enabled:
- Multiple workspaces can define the same route path without conflict.
- HTTP triggers can be deployed across different workspaces if no conflicting route exists.

When workspace prefix is disabled (on self-hosted):
- Route paths will be **globally unique** across the entire instance.
- A route path cannot be reused by another workspace unless it is first deleted.

**Example:**  
If workspace A creates the route `/webhooks/github`, then without workspace prefix, no other workspace can create `/webhooks/github`.  
With workspace prefix enabled, workspace A could have `/workspace_a/webhooks/github` and workspace B could have `/workspace_b/webhooks/github`.

---

### Select a script or flow

- Pick the runnable to be triggered when the route is called.
- Use the “Create from template” button to generate a boilerplate if needed.

Example script:
```ts
export async function main(/* args from the request body */) {
  // your code here
}
```

With a preprocessor:
```ts
export async function preprocessor(
  event: {
    kind: 'http',
    body: { // assuming the body contains name and age parameters
      name: string,
      age: number,
    },
    raw_string: string | null,
    route: string;
    path: string;
    method: string;
    params: Record<string, string>;
    query: Record<string, string>;
    headers: Record<string, string>;
  }
) {
  if (event.kind === 'http') {
    const { name, age } = event.body;
    return {
      user_id: event.params.id,
      name,
      age,
    };
  }

  throw new Error(`Expected trigger of kind 'http', but received: ${event.kind}`);
}

export async function main(user_id: string, name: string, age: number) {
  // Do something
}
```
---
