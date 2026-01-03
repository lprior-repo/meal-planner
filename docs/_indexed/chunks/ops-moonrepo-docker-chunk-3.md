---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-3
heading_path: ["docker", "Creating a `Dockerfile`"]
chunk_type: prose
tokens: 423
summary: "Creating a `Dockerfile`"
---

## Creating a `Dockerfile`

> **Info:** Our [`moon docker file`](/docs/commands/docker/file) command can automatically generate a `Dockerfile` based on this guide! We suggest generating the file then reading the guide below to understand what's going on.

We're very familiar with how tedious `Dockerfile`s are to write and maintain, so in an effort to reduce this headache, we've built a handful of tools to make this process much easier. With moon, we'll take advantage of Docker's layer caching and staged builds as much as possible.

With that being said, there's many approaches you can utilize, depending on your workflow (we'll document them below):

- Running `moon docker` commands *before* running `docker run|build` commands.
- Running `moon docker` commands *within* the `Dockerfile`.
- Using multi-staged or non-staged (standard) builds.
- Something else unique to your setup!

> **Warning:** This guide and our Docker approach is merely a suggestion and is not a requirement for using moon with Docker! Feel free to use this as a starting point, or not at all. Choose the approach that works best for you!

### What we're trying to avoid

Before we dive into writing a perfect `Dockerfile`, we'll briefly talk about the pain points we're trying to avoid. In the context of Node.js and monorepo's, you may be familiar with having to `COPY` each individual `package.json` in the monorepo before installing `node_modules`, to effectively use layer caching. This is very brittle, as each new application or package is created, every `Dockerfile` in the monorepo will need to be modified to account for this new `package.json`.

Furthermore, we'll have to follow a similar process for *only copying source files* necessary for the build or `CMD` to complete. This is *very tedious*, so most developers simply use `COPY . .` and forget about it. Copying the entire monorepo is costly, especially as it grows.

As an example, we'll use moon's official repository. The `Dockerfile` would look something like the following.

```dockerfile
FROM node:latest

WORKDIR /app
