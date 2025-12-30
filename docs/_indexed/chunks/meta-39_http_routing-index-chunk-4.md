---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-4
heading_path: ["HTTP routes", "Generate routes from an OpenAPI specification"]
chunk_type: prose
tokens: 292
summary: "Generate routes from an OpenAPI specification"
---

## Generate routes from an OpenAPI specification

Windmill can generate HTTP routes directly from an OpenAPI 2.0+ specification in JSON or YAML format.

You can provide the specification in one of three ways:
- Paste raw content
- Upload a file
- Provide a public URL

### To generate routes

- Navigate to the **Custom HTTP routes** page.
- Click the **From OpenAPI spec** button.
- Pick a folder for the generated routes.
- Choose your input method and provide the OpenAPI spec.
- Click **Generate HTTP routes**.

### Behavior and limitations

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

---
