---
doc_id: ops/guides/docker
chunk_id: ops/guides/docker#chunk-6
heading_path: ["Docker integration", "Copy all package.json's and lockfiles"]
chunk_type: prose
tokens: 62
summary: "Copy all package.json's and lockfiles"
---

## Copy all package.json's and lockfiles
COPY ./packages/cli/package.json ./packages/cli/package.json
COPY ./packages/core-linux-arm64-gnu/package.json ./packages/core-linux-arm64-gnu/package.json
COPY ./packages/core-linux-arm64-musl/package.json ./packages/core-linux-arm64-musl/package.json
COPY ./packages/core-linux-x64-gnu/package.json ./packages/core-linux-x64-gnu/package.json
COPY ./packages/core-linux-x64-musl/package.json ./packages/core-linux-x64-musl/package.json
COPY ./packages/core-macos-arm64/package.json ./packages/core-macos-arm64/package.json
COPY ./packages/core-macos-x64/package.json ./packages/core-macos-x64/package.json
COPY ./packages/core-windows-x64-msvc/package.json ./packages/core-windows-x64-msvc/package.json
COPY ./packages/runtime/package.json ./packages/runtime/package.json
COPY ./packages/types/package.json ./packages/types/package.json
COPY ./package.json ./package.json
COPY ./yarn.lock ./yarn.lock
COPY ./.yarn ./.yarn
COPY ./.yarnrc.yml ./yarnrc.yml
