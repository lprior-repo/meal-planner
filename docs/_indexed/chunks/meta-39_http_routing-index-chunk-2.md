---
doc_id: meta/39_http_routing/index
chunk_id: meta/39_http_routing/index#chunk-2
heading_path: ["HTTP routes", "How it works"]
chunk_type: prose
tokens: 180
summary: "How it works"
---

## How it works

You define a custom HTTP route with a specific method (GET, POST, PUT, PATCH, DELETE).  
When the route is called, Windmill triggers the selected script or flow.

Each route can be protected with various authentication mechanisms, ranging from simple API keys to advanced HMAC signature validation or even fully custom logic.

Among the supported authentication mechanisms, there's also **Windmill Auth**, which uses a JWT token to authenticate requests and ensure you have read access to the route and the runnable. You can generate your personal Windmill JWT token directly from your user settings and use it to securely access your HTTP routes.

You can configure the route to run:
- **Synchronously**: Wait for the script to complete and return the result.
- **Asynchronously**: Return a job ID immediately; the script runs in the background.

---
