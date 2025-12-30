---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-11
heading_path: ["Run Docker containers", "In the example, 100.64.2.97 is my pod address."]
chunk_type: code
tokens: 131
summary: "In the example, 100.64.2.97 is my pod address."
---

## In the example, 100.64.2.97 is my pod address.

DOCKER="docker -H 100.64.2.97:8000"
$DOCKER run --rm alpine /bin/echo "Hello $msg"
```

output

```log
+ DOCKER='docker -H 100.64.2.97:8000'
+ docker -H 100.64.2.97:8000 run --rm alpine /bin/echo 'Hello '
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
7264a8db6415: Pulling fs layer
7264a8db6415: Verifying Checksum
7264a8db6415: Download complete
7264a8db6415: Pull complete
Digest: sha256:7144f7bab3d4c2648d7e59409f15ec52a18006a128c733fcff20d3a4a54ba44a
Status: Downloaded newer image for alpine:latest
Hello
+ exit 0
```

### As a kubernetes task (not recommended)

If you use kubernetes and would like to run your docker file directly on the kubernetes host, use the following script:

```
