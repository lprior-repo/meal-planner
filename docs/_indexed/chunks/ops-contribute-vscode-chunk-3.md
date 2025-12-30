---
doc_id: ops/contribute/vscode
chunk_id: ops/contribute/vscode#chunk-3
heading_path: ["Vscode", "VSCode Tasks"]
chunk_type: prose
tokens: 344
summary: "VSCode Tasks"
---

## VSCode Tasks

<!-- prettier-ignore -->
!!! note
     In order to hot reload vue, the `yarn dev` server must be started before starting the django server.

There are a number of built in tasks that are available. Here are a few of the key ones:

- `Setup Dev Server` - Runs all the prerequisite steps so that the dev server can be run inside VSCode.
- `Setup Tests` - Runs all prerequisites so tests can be run inside VSCode.

Once these are run, there are 2 options.  If you want to run a vue3 server in a hot reload mode for quick development of the frontend, you should run a development vue server:

- `Yarn Dev` - Runs development Vue.js vite server not connected to VSCode. Useful if you want to make Vue changes and see them in realtime.

If not, you need to build and copy the frontend to the django server.  If you make changes to the frontend, you need to re-run this and restart the django server:

- `Collect Static Files` - Builds and collects the vue3 frontend so that it can be served via the django server.

Once either of those steps are done, you can start the django server:

- `Run Dev Server` - Runs a django development server not connected to VSCode.

There are also a few other tasks specified in case you have specific development needs:

- `Run all pytests` - Runs all the pytests outside of VSCode.
- `Serve Documentation` - Runs a documentation server. Useful if you want to see how changes to documentation show up.
