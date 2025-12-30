---
doc_id: meta/12_deploy_to_prod/index
chunk_id: meta/12_deploy_to_prod/index#chunk-1
heading_path: ["Deploy to prod"]
chunk_type: prose
tokens: 158
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Deploy to prod

> **Context**: import DocCard from '@site/src/components/DocCard';

To deploy to prod, 3 options are possible.

[Draft and deploy](#option-1-draft-and-deploy---single-workspace) is the simplest method. It is meant to be used in a single workspace.

[Git integration](#option-2-deploy-to-prod-using-a-git-workflow---multi-workspace-recommended) is clearly the superior, most powerful method but it is more complex. Usually, to deploy to prod you would want absolutely to have the normal CI flow that goes through one review which is something that is built-in with GitHub/GitLab. Also you may want to put some CI checks there.

However, in a setting where you have dev/staging/prod, you could use the [UI to deploy to staging from dev](#option-3-deploy-to-prod-using-the-ui-only---multi-workspace), and then use git between staging and prod to tighten down prod.
