---
description: Run CI and deploy to Windmill
---

Run the full CI pipeline and deploy to Windmill using `moon run :deploy`.

This command:
1. Runs all CI checks (build, test, lint, format verification)
2. Pushes the Windmill scripts and flows to the remote Windmill instance

Use this when you're ready to deploy changes to production after local development and testing.
