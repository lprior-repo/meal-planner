---
doc_id: concept/moonrepo/react
chunk_id: concept/moonrepo/react#chunk-1
heading_path: ["React example"]
chunk_type: prose
tokens: 167
summary: "React example"
---

# React example

> **Context**: React is an application or library concern, and not a build system one, since the bundling of React is abstracted away through another tool like webpa

React is an application or library concern, and not a build system one, since the bundling of React is abstracted away through another tool like webpack. Because of this, moon has no guidelines around utilizing React directly. You can use React however you wish!

However, with that being said, we do suggest the following:

- Add `react` and related dependencies to each project, not the root. This includes `@types/react` as well. This will ensure accurate [hashing](/docs/concepts/cache#hashing).

```
yarn workspace <project> add react
```

- Configure Babel with the `@babel/preset-react` preset.
- Configure [TypeScript](/docs/guides/examples/typescript) compiler options with `"jsx": "react-jsx"`.
