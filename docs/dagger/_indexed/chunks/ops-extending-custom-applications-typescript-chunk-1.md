---
doc_id: ops/extending/custom-applications-typescript
chunk_id: ops/extending/custom-applications-typescript#chunk-1
heading_path: ["custom-applications-typescript"]
chunk_type: code
tokens: 572
summary: "> **Context**: > **Note:** The Dagger TypeScript SDK requires [TypeScript 5."
---
# TypeScript Custom Application

> **Context**: > **Note:** The Dagger TypeScript SDK requires [TypeScript 5.0 or later](https://www.typescriptlang.org/download/). This SDK currently only supports N...


> **Note:** The Dagger TypeScript SDK requires [TypeScript 5.0 or later](https://www.typescriptlang.org/download/). This SDK currently only supports Node.js (stable) and Bun (experimental). To execute the TypeScript program, you must also have an TypeScript executor like `ts-node` or `tsx`.

Install the Dagger TypeScript SDK in your project using `npm` or `yarn`:

```bash
// using npm
npm install @dagger.io/dagger@latest --save-dev

// using yarn
yarn add @dagger.io/dagger --dev
```

This example demonstrates how to test a Node.js application against multiple Node.js versions using the TypeScript SDK.

Create an example React project (or use an existing one) in TypeScript:

```bash
npx create-react-app my-app --template typescript
cd my-app
```

In the project directory, create a new file named `build.mts` and add the following code to it:

```typescript
import { dag } from '@dagger.io/dagger'
import * as dagger from '@dagger.io/dagger'

// initialize Dagger client
await dagger.connection(async () => {
    // set Node versions against which to test and build
    const nodeVersions = ["16", "18", "20"]

    // get reference to the local project
    const source = dag.host().directory(".", { exclude: ["node_modules/"] })

    // for each Node version
    for (const nodeVersion of nodeVersions) {
      // get Node image
      const node = dag.container().from(`node:${nodeVersion}`)

      // mount cloned repository into Node image
      const runner = node
        .withDirectory("/src", source)
        .withWorkdir("/src")
        .withExec(["npm", "install"])

      // run tests
      await runner.withExec(["npm", "test", "--", "--watchAll=false"]).sync()

      // build application using specified Node version
      // write the build output to the host
      await runner
        .withExec(["npm", "run", "build"])
        .directory("build/")
        .export(`./build-node-${nodeVersion}`)
    }
  },
  { LogOutput: process.stderr })
```

This TypeScript program imports the Dagger SDK and defines an asynchronous function. This function creates a Dagger client, which provides an interface to the Dagger API. It also defines the test/build matrix, consisting of Node.js versions `16`, `18` and `20`, and iterates over this matrix, downloading a Node.js container image for each specified version and testing and building the source application against that version.

Run the program with a Typescript executor like `ts-node`, as shown below:

```bash
dagger run node --loader ts-node/esm ./build.mts
```

The `dagger run` command executes the specified command in a Dagger session and displays live progress. The program tests and builds the application against each version in sequence. At the end of the process, a built application is available for each Node.js version in a `build-node-XX` folder in the project directory, as shown below:

```
tree -L 2 -d build-*
build-node-16
└── static
    ├── css
    ├── js
    └── media
build-node-18
└── static
    ├── css
    ├── js
    └── media
build-node-20
└── static
    ├── css
    ├── js
    └── media
```
