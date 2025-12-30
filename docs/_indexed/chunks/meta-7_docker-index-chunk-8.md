---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-8
heading_path: ["Run Docker containers", "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"]
chunk_type: code
tokens: 102
summary: "if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it"
---

## if using the 'docker' mode, name it with $WM_JOB_ID for windmill to monitor it
docker run --name $WM_JOB_ID -it -d $IMAGE $COMMAND
```

### Setup

#### Docker compose

On the docker-compose, it is enough to uncomment the volume mount of the Windmill worker

```dockerfile
      # mount the docker socket to allow to run docker containers from within the workers
      # - /var/run/docker.sock:/var/run/docker.sock
```

#### Helm charts

In the charts values of our [helm charts](https://github.com/windmill-labs/windmill-helm-charts), set `windmill.exposeHostDocker` to `true`.
