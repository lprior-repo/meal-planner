---
doc_id: ops/install/kubernetes
chunk_id: ops/install/kubernetes#chunk-3
heading_path: ["Kubernetes", "Files"]
chunk_type: prose
tokens: 573
summary: "Files"
---

## Files

### 10-configmap.yaml

The nginx config map. This is loaded as nginx.conf in the nginx sidecar to configure nginx to deliver static content.

### 15-secrets.yaml

!!! warning "Contains secrets"
    **Replace them!**

This file is only here for a quick start. Be aware that changing secrets after installation will be messy and is not documented here. **You should set new secrets before the installation.** As you are reading this document **before** the installation ;-)

Create your own postgresql passwords and the secret key for the django app.

See also [Managing Secrets using kubectl](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/)

**Replace** `db-password`, `postgres-user-password` and `secret-key` **with something - well - secret :-)**

~~~
echo -n 'db-password' > ./db-password.txt
echo -n 'postgres-user-password' > ./postgres-password.txt
echo -n 'secret-key' | sha256sum | awk '{ printf $1 }' > ./secret-key.txt
~~~

Delete the default secrets file `15-secrets.yaml` and generate the K8s secret from your files.

~~~
kubectl create secret generic recipes \
  --from-file=postgresql-password=./db-password.txt \
  --from-file=postgresql-postgres-password=./postgres-password.txt \
  --from-file=secret-key=./secret-key.txt
~~~

### 20-service-account.yml

Creating service account `recipes` for deployment and stateful set.

###  30-pvc.yaml

The creation of the persistent volume claims for media and static content. May you want to increase the size. This expects to have a storage class installed.

### 40-sts-postgresql.yaml

The PostgreSQL stateful set, based on a bitnami image. It runs a init container as root to do the preparations. The postgres container itself runs as a lower privileged user. The recipes app uses the database super user (postgres) as the recipes app is doing some db migrations on startup, which needs super user privileges.

### 45-service-db.yaml

Creating the database service.

### 50-deployment.yaml

The deployment first fires up a init container to do the database migrations and file modifications. This init container runs as root. The init container runs part of the [boot.sh](https://github.com/TandoorRecipes/recipes/blob/develop/boot.sh) script from the `vabene1111/recipes` image. 

The deployment then runs two containers, the recipes-nginx and the recipes container which runs the gunicorn app. The nginx container gets it's nginx.conf via config map to deliver static content `/static` and `/media`. The guincorn container gets it's secret key and the database password from the secret `recipes`. `gunicorn` runs as user `nobody`.

Currently, this deployment is using the `latest` image. You may want to explicitly set the tag, e.g.

~~~
image: vabene1111/recipes:1.4.7
~~~

It is **extremely important** to use the same image in both the initialization `init-chmod-data` and the main `recipes` containers.

### 60-service.yaml

Creating the app service.

### 70-ingress.yaml

Setting up the ingress for the recipes service. Requests for static content `/static` and `/media` are send to the nginx container, everything else to gunicorn. TLS setup via cert-manager is prepared. You have to **change the host** from `recipes.local` to your specific domain.
