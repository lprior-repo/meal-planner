---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-2
heading_path: ["Run Docker containers", "Using Windmill native docker support (recommended)"]
chunk_type: prose
tokens: 133
summary: "Using Windmill native docker support (recommended)"
---

## Using Windmill native docker support (recommended)

Windmill has a native docker support if the `# docker` annotation is used in a bash script. It will assume a a docker socket is mounted like in the example above and will take over management of the container as soon as the script ends, assuming that the container was ran with the `$WM_JOB_ID` as name.
Which is why you should use docker `-d` deamon mode so that the bash script terminates early.

It will handle memory tracking, logs streaming and the different exit code of the container properly.

The default code is as follows:

```
