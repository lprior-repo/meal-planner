---
doc_id: tutorial/moonrepo/remix
chunk_id: tutorial/moonrepo/remix#chunk-4
heading_path: ["Remix example", "https://github.com/moonrepo/moon-configs"]
chunk_type: code
tokens: 273
summary: "https://github.com/moonrepo/moon-configs"
---

## https://github.com/moonrepo/moon-configs
tags: ['remix']
```

### ESLint integration

Remix does not provide a built-in linting abstraction, and instead provides a simple ESLint configuration package, [`@remix-run/eslint-config`](https://www.npmjs.com/package/@remix-run/eslint-config). For the rest of this section, we're going to assume that a [global `lint` task](/docs/guides/examples/eslint) has been configured.

Begin be installing the `@remix-run/eslint-config` dependency in the application's `package.json`. We can then enable this configuration by creating an `.eslintrc.js` file in the project root. Be sure this file is listed in your `lint` task's inputs!

<project>/.eslintrc.js

```js
module.exports = {
  extends: ['@remix-run/eslint-config', '@remix-run/eslint-config/node'],
  // If using TypeScript
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: 'tsconfig.json',
    tsconfigRootDir: __dirname,
  },
};
```

### TypeScript integration

Remix ships with TypeScript support (when enabled during installation), but the `tsconfig.json` it generates is *not* setup for TypeScript project references, which we suggest using with a [global `typecheck` task](/docs/guides/examples/typescript).

When using project references, we suggest the following `tsconfig.json`, which is a mix of Remix and moon. Other compiler options, like `isolatedModules` and `esModuleInterop`, should be declared in a shared configuration found in the workspace root (`tsconfig.projectOptions.json` in the example).

<project>/tsconfig.json

```json
{
  "extends": "../../tsconfig.projectOptions.json",
  "compilerOptions": {
    "baseUrl": ".",
    "emitDeclarationOnly": false,
    "jsx": "react-jsx",
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "noEmit": true,
    "paths": {
      "~/*": ["./app/*"]
    }
  },
  "include": [".eslintrc.js", "remix.env.d.ts", "**/*"],
  "exclude": [".cache", "build", "public"]
}
```
