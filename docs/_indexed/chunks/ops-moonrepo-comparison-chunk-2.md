---
doc_id: ops/moonrepo/comparison
chunk_id: ops/moonrepo/comparison#chunk-2
heading_path: ["Feature comparison", "Unique features"]
chunk_type: prose
tokens: 195
summary: "Unique features"
---

## Unique features

Although moon is still in its infancy, we provide an array of powerful features that other frontend centric task runners do not, such as...

-   **Integrated toolchain** - moon manages its own version of programming languages and dependency managers behind the scenes, so that every task is executed with the *exact same version*, across *all machines*.
-   **Task inheritance** - Instead of defining the same tasks (lint, test, etc) over and over again for *every* project in the monorepo, moon supports a task inheritance model where it only needs to be defined once at the top-level. Projects can then merge with, exclude, or override if need be.
-   **Continuous integration** - By default, all moon tasks will run in CI, as we want to encourage every facet of a project or repository to be continually tested and verified. This can be turned off on a per-task basis.
