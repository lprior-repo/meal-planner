---
doc_id: ops/tandoor/manual
chunk_id: ops/tandoor/manual#chunk-8
heading_path: ["Manual installation instructions", "Setup postgresql"]
chunk_type: code
tokens: 192
summary: "Setup postgresql"
---

## Setup postgresql

```shell
sudo -u postgres psql
```text

In the psql console:

```sql
CREATE DATABASE djangodb;
CREATE USER djangouser WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE djangodb TO djangouser;
ALTER DATABASE djangodb OWNER TO djangouser;

--Maybe not necessary, but should be faster:
ALTER ROLE djangouser SET client_encoding TO 'utf8';
ALTER ROLE djangouser SET default_transaction_isolation TO 'read committed';
ALTER ROLE djangouser SET timezone TO 'UTC';

--Grant superuser right to your new user, it will be removed later
ALTER USER djangouser WITH SUPERUSER;

--exit Postgres Environment
exit
```text

Download the `.env` configuration file and **edit it accordingly**.
```shell
wget https://raw.githubusercontent.com/vabene1111/recipes/develop/.env.template -O /var/www/recipes/.env
```text

Things to edit:

- `SECRET_KEY`: use something secure (generate it with `base64 /dev/urandom | head -c50` f.e.).
- `POSTGRES_HOST`: probably 127.0.0.1.
- `POSTGRES_PASSWORD`: the password we set earlier when setting up djangodb.
- `STATIC_URL`, `MEDIA_URL`: these will be in `/var/www/recipes`, under `/staticfiles/` and `/mediafiles/` respectively.
