---
doc_id: meta/33_codebases_and_bundles/index
chunk_id: meta/33_codebases_and_bundles/index#chunk-2
heading_path: ["Codebases & bundles", "Bundles"]
chunk_type: prose
tokens: 113
summary: "Bundles"
---

## Bundles

To work with large codebases, there is another mode of deployment that relies on the same mechanism as similar services like Lambda or cloud functions: a bundle is built locally by the CLI using [esbuild](https://esbuild.github.io/) and deployed to Windmill.

This bundle contains all the code and dependencies needed to run the script.

On the latest version of the Windmill CLI, it is done automatically on `wmill sync push` for any script that falls in the patterns of includes and excludes as defined by the [wmill.yaml](#wmillyaml).
