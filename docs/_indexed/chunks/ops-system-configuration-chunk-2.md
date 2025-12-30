---
doc_id: ops/system/configuration
chunk_id: ops/system/configuration#chunk-2
heading_path: ["Configuration", "Required Settings"]
chunk_type: code
tokens: 460
summary: "Required Settings"
---

## Required Settings

The following settings need to be set appropriately for your installation.
They are included in the default `env.template`.

### Secret Key

Random secret key (at least 50 characters), use for example `base64 /dev/urandom | head -c50` to generate one.
It is used internally by django for various signing/cryptographic operations and **should be kept secret**.
See [Django Docs](https://docs.djangoproject.com/en/5.0/ref/settings/#std-setting-SECRET_KEY)

```bash
SECRET_KEY=#$tp%v6*(*ba01wcz(ip(i5vfz8z$f%qdio&q@anr1#$=%(m4c
```

Alternatively you can point to a file containing just the secret key value. If using containers make sure the file is
persistent and available inside the container.

```bash
SECRET_KEY_FILE=/path/to/file.txt

// contents of file
#$tp%v6*(*ba01wcz(ip(i5vfz8z$f%qdio&q@anr1#$=%(m4c
```

#### Allowed Hosts

> default `*` - options: `recipes.mydomain.com,cooking.mydomain.com,...` (comma seperated domain/ip list)

Security setting to prevent HTTP Host Header Attacks,
see [Django docs](https://docs.djangoproject.com/en/5.0/ref/settings/#allowed-hosts).
Some proxies require `*` (default) but it should be set to the actual host(s).

```bash
ALLOWED_HOSTS=recipes.mydomain.com
```

### Database

Multiple parameters are required to configure the database.
*Note: You can setup parameters for a test database by defining all of the parameters preceded by `TEST_` e.g. TEST_DB_ENGINE=*

| Var               | Options                                                            | Description                                                             |
|-------------------|--------------------------------------------------------------------|-------------------------------------------------------------------------|
| DB_ENGINE         | django.db.backends.postgresql (default) django.db.backends.sqlite3 | Type of database connection. Production should always use postgresql.   |
| POSTGRES_HOST     | any                                                                | Used to connect to database server. Use container name in docker setup. |
| POSTGRES_DB       | any                                                                | Name of database.                                                       |
| POSTGRES_PORT     | 1-65535                                                            | Port of database, Postgresql default `5432`                             |
| POSTGRES_USER     | any                                                                | Username for database connection.                                       |
| POSTGRES_PASSWORD | any                                                                | Password for database connection.                                       |

#### Password file

> default `None` - options: file path

Path to file containing the database password. Overrides `POSTGRES_PASSWORD`. Only applied when using Docker (or other
setups running `boot.sh`)

```bash
POSTGRES_PASSWORD_FILE=
```

#### Connection String

> default `None` - options: according to database specifications

Instead of configuring the connection using multiple individual environment parameters, you can use a connection string.
The connection string will override all other database settings.

```bash
DATABASE_URL = engine://username:password@host:port/dbname
```

#### Connection Options

> default `{}` - options: according to database specifications

Additional connection options can be set as shown in the example below.

```bash
DB_OPTIONS={"sslmode":"require"}
```
