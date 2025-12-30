---
doc_id: ops/install/docker
chunk_id: ops/install/docker#chunk-2
heading_path: ["Docker", "**Versions**"]
chunk_type: prose
tokens: 209
summary: "**Versions**"
---

## **Versions**

There are different versions (tags) released on [Docker Hub](https://hub.docker.com/r/vabene1111/recipes/tags).

-   **latest** Default image. The one you should use if you don't know that you need anything else.
-   **beta** Partially stable version that gets updated every now and then. Expect to have some problems.
-   **develop** If you want the most bleeding-edge version with potentially many breaking changes, feel free to use this version (not recommended!).
-   **X.Y.Z** each released version has its own image. If you need to revert to an old version or want to make sure you stay on one specific use these tags.

!!! danger "No Downgrading"
    There is currently no way to migrate back to an older version as there is no mechanism to downgrade the database.
    You could probably do it but I cannot help you with that. Choose wisely if you want to use the unstable images.
    That said **beta** should usually be working if you like frequent updates and new stuff.
