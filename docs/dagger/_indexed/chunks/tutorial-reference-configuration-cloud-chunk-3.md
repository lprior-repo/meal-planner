---
doc_id: tutorial/reference/configuration-cloud
chunk_id: tutorial/reference/configuration-cloud#chunk-3
heading_path: ["configuration-cloud", "Traces"]
chunk_type: prose
tokens: 151
summary: "```bash
dagger login
```

Or set the token directly:

```bash
export DAGGER_CLOUD_TOKEN={your tok..."
---
### Connect to Dagger Cloud

#### From local development

```bash
dagger login
```

Or set the token directly:

```bash
export DAGGER_CLOUD_TOKEN={your token}
```

#### From CI environment

1. Find your token in Dagger Cloud settings under Tokens
2. Store the token as a secret in your CI environment
3. Add it as `DAGGER_CLOUD_TOKEN` environment variable
4. For GitHub Actions, install the Dagger Cloud GitHub app for GitHub Checks

### Public traces

Dagger Cloud automatically detects if traces originate from a public repository and allows public access without requiring an invitation.

### Make an individual trace public

Admin users can make individual private traces public for sharing.

### Delete a trace

Admin users can delete individual traces.
