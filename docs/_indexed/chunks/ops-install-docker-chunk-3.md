---
doc_id: ops/install/docker
chunk_id: ops/install/docker#chunk-3
heading_path: ["Docker", "**Docker**"]
chunk_type: prose
tokens: 91
summary: "**Docker**"
---

## **Docker**

The docker image (`vabene1111/recipes`) simply exposes the application on the container's port `80` through the integrated nginx webserver.

```shell
docker run -d \
    -v "$(pwd)"/staticfiles:/opt/recipes/staticfiles \
    -v "$(pwd)"/mediafiles:/opt/recipes/mediafiles \
    -p 80:80 \
    -e SECRET_KEY=YOUR_SECRET_KEY \
    -e DB_ENGINE=django.db.backends.postgresql \
    -e POSTGRES_HOST=db_recipes \
    -e POSTGRES_PORT=5432 \
    -e POSTGRES_USER=djangodb \
    -e POSTGRES_PASSWORD=YOUR_POSTGRES_SECRET_KEY \
    -e POSTGRES_DB=djangodb \
    --name recipes_1 \
    vabene1111/recipes
```

Please make sure to replace the ```SECRET_KEY``` and ```POSTGRES_PASSWORD``` placeholders!
