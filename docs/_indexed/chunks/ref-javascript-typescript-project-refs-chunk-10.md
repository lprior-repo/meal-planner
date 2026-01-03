---
doc_id: ref/javascript/typescript-project-refs
chunk_id: ref/javascript/typescript-project-refs#chunk-10
heading_path: ["TypeScript project references", "Editor integration"]
chunk_type: prose
tokens: 226
summary: "Editor integration"
---

## Editor integration

Unfortunately, we only have experience with VS Code. If you prefer another editor and have guidance you'd like to share with the community, feel free to submit a pull request and we'll include it below!

### VS Code

[VS Code](https://code.visualstudio.com/) has first-class support for TypeScript and project references, and should "just work" without any configuration. You can verify this by restarting the TypeScript server in VS Code (with the cmd + shift + p command palette) and navigating to each project. Pay attention to the status bar at the bottom, as you'll see this:

When this status appears, it means that VS Code is *compiling a project*. It will re-appear multiple times, basically for each project, instead of once for the entire repository.

Furthermore, ensure that VS Code is using the version of TypeScript from the `typescript` package in `node_modules`. Relying on the version that ships with VS Code may result in unexpected TypeScript failures.

.vscode/settings.json

```json
{
  "typescript.tsdk": "node_modules/typescript/lib"
  // Or "Select TypeScript version" from the command palette
}
```
