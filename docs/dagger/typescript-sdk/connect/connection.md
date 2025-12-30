# Function: connection()

> **connection**(`fct`, `cfg`): `Promise`<`void`\>

connection executes the given function using the default global Dagger client.

## Parameters

### fct

() => `Promise`<`void`\>

### cfg

`ConnectOpts` = `{}`

## Returns

`Promise`<`void`\>

## Example

```typescript
await connection(
  async () => {
    await dag
      .container()
      .from("alpine")
      .withExec(["apk", "add", "curl"])
      .withExec(["curl", "https://dagger.io/"])
      .sync()
  },
  { LogOutput: process.stderr }
)
```
