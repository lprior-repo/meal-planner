---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-6
heading_path: ["quickstarts-basics", "Chain functions in the shell"]
chunk_type: mixed
tokens: 95
summary: "You can chain Dagger API function calls with the pipe (`|`) operator."
---
You can chain Dagger API function calls with the pipe (`|`) operator. This is one of Dagger's most powerful features, allowing you to create dynamic workflows in a single command.

Example: Creating an Alpine container, adding a text file, setting it to display that message when run, and publishing it to a temporary registry:

```
container | from alpine | with-new-file /hi.txt "Hello from Dagger!" |
  with-entrypoint cat /hi.txt | publish ttl.sh/hello
```
