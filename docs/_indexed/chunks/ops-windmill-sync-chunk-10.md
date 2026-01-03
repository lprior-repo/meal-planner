---
doc_id: ops/windmill/sync
chunk_id: ops/windmill/sync#chunk-10
heading_path: ["Sync", "Git branch validation"]
chunk_type: code
tokens: 429
summary: "Git branch validation"
---

## Git branch validation
skipBranchValidation: false  # Skip validation for feature branches
```

### Git branch-specific configuration

The CLI supports branch-specific settings through the `gitBranches` configuration:

```yaml
gitBranches:
  main:  # Branch name
    baseUrl: 'http://localhost:8000/'  # Windmill instance URL
    workspaceId: test  # Workspace ID
    overrides: {}  # Override settings for this branch
    promotionOverrides:  # Settings used when promoting TO this branch
      skipApps: true
      skipFlows: true
    specificItems:  # Branch-specific resources/variables
      resources:
        - "u/alex/prod_*"
      variables:
        - "u/alex/env_*"

  staging:
    baseUrl: 'https://staging.windmill.dev/'
    workspaceId: staging-workspace
    overrides:
      skipVariables: true
      includeSettings: true
    promotionOverrides:
      skipSecrets: true

  production:
    baseUrl: 'https://app.windmill.dev/'
    workspaceId: prod-workspace
    overrides:
      includeSettings: true
      skipSecrets: false
    promotionOverrides:
      skipApps: true      # Don't sync apps during promotion
      skipFlows: true     # Don't sync flows during promotion

  # Common items that are branch-specific across all branches
  commonSpecificItems:
    resources:
      - "u/alex/config/**"
    variables:
      - "u/alex/database_*"
```

### Configuration resolution priority

Settings are resolved in this order (highest priority first):

1. **CLI flags** (highest priority)
2. **Promotion overrides** (if `--promotion` flag is used)
3. **Branch-specific overrides** (if current branch has `overrides` defined)
4. **Top-level settings** (base configuration)

### Codebase configuration

Advanced bundling configuration for TypeScript/JavaScript projects:

```yaml
codebases:
  - relative_path: './my-lib'
    includes: ['**/*.ts']
    excludes: ['**/*.test.ts']
    assets:
      - from: 'assets/'
        to: 'static/'
    customBundler: 'esbuild'
    external: ['lodash', 'react']
    define:
      NODE_ENV: 'production'
    inject: ['./polyfills.js']
```

All sync options for your workspace can be found on this [file](https://github.com/windmill-labs/windmill/blob/main/cli/src/core/conf.ts#L16):

```ts
export interface SyncOptions {
  raw?: boolean;
  yes?: boolean;
  skipPull?: boolean;
  failConflicts?: boolean;
  plainSecrets?: boolean;
  json?: boolean;

  // File filtering options
  skipVariables?: boolean;
  skipResources?: boolean;
  skipResourceTypes?: boolean;
  skipSecrets?: boolean;
  skipScripts?: boolean;
  skipFlows?: boolean;
  skipApps?: boolean;
  skipFolders?: boolean;

  // Include options
  includeSchedules?: boolean;
  includeTriggers?: boolean;
  includeUsers?: boolean;
  includeGroups?: boolean;
  includeSettings?: boolean;
  includeKey?: boolean;
  skipBranchValidation?: boolean;

  // Path and message options
  message?: string;
  includes?: string[];
  extraIncludes?: string[];
  excludes?: string[];
  defaultTs?: 'bun' | 'deno';
  codebases?: Codebase[];

  // Git branch configuration
  gitBranches?: {
    commonSpecificItems?: {
      variables?: string[];
      resources?: string[];
    };
    [branchName: string]: SyncOptions & {
      overrides?: Partial<SyncOptions>;
      promotionOverrides?: Partial<SyncOptions>;
      baseUrl?: string;
      workspaceId?: string;
      specificItems?: {
        variables?: string[];
        resources?: string[];
      };
    }
  };
  promotion?: string;
}
```
