---
doc_id: meta/6_imports/index
chunk_id: meta/6_imports/index#chunk-1
heading_path: ["Dependency management & imports"]
chunk_type: prose
tokens: 215
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Dependency management & imports

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill's strength lies in its ability to run scripts without having to manage dependency manifest files directly (package.json, requirements.txt, etc.). This is achieved by automatically parsing the top-level imports and resolving the dependencies. For automatic dependency installation, Windmill will only consider these top-level imports.

When a script is deployed through its UI, Windmill generates a lockfile to ensure that the same version of a script is always executed with the same versions of its dependencies. If no version is specified, the latest version is used. Windmill's workers cache dependencies to ensure fast performance without the need to pre-package dependencies - most jobs take under 100ms end-to-end.

On the [enterprise edition](/pricing), Windmill's caches can be configured to sync their cache with a central S3 repository to distribute the cache across multiple workers as soon as a new dependency is used for the first time.

![Dependency management & imports](./dependency_management.png "Dependency management & imports")
