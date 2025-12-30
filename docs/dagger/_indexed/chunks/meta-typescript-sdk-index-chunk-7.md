---
doc_id: meta/typescript-sdk/index
chunk_id: meta/typescript-sdk/index#chunk-7
heading_path: ["index", "Init typescript project"]
chunk_type: code
tokens: 261
summary: "npx tsc --init
```



Dagger exports its SDK using type module so you will need to also update yo..."
---
npx tsc --init
```

### 2. Update project settings

Dagger exports its SDK using type module so you will need to also update your `package.json` to the same type.

Add or update the field `type` in your `package.json` from your project root directory:

```
npm pkg set type=module
```

You must also update your `tsconfig.json` to use `NodeNext` as `module`.

```
"module": "NodeNext"
```

### 3. Symlink Dagger local module

Go to the Dagger TypeScript SDK directory and do the following:

```
cd path/to/dagger/sdk/typescript # go into the package directory
npm link # creates global link
```

Go back to the root directory of your local project to link the TypeScript SDK.

```
cd path/to/my_app # go into your project directory.
npm link @dagger.io/dagger # link install the package
```

Any changes to `path/to/dagger/sdk/typescript` will be reflected in `path/to/my_app/node_modules/@dagger.io/dagger`.

### 4. Make your contribution

While making SDK code modification you should `watch` the input files:

```
cd path/to/dagger/sdk/typescript # go into the package directory
yarn watch # Recompile the code when input files are modified
```

You can now import the local Dagger TypeScript SDK as if you were using the official one.

```
import { connect } from "@dagger.io/dagger"
```
