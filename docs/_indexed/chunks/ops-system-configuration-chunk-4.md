---
doc_id: ops/system/configuration
chunk_id: ops/system/configuration#chunk-4
heading_path: ["Configuration", "prefix used for account related emails (default \"[Tandoor Recipes] \")"]
chunk_type: code
tokens: 1407
summary: "prefix used for account related emails (default \"[Tandoor Recipes] \")"
---

## prefix used for account related emails (default "[Tandoor Recipes] ")
ACCOUNT_EMAIL_SUBJECT_PREFIX=
```

### S3 Object storage

If you want to store your users media files using an external storage provider supporting the S3 API's (Like S3,
MinIO, ...)
configure the following settings accordingly.
As long as `S3_ACCESS_KEY` is not set, all object storage related settings are disabled.

See also [Django Storages Docs](https://django-storages.readthedocs.io/en/latest/backends/amazon-S3.html) for additional
information.

!!! info
    Settings are only named S3 but apply to all compatible object storage providers.

Required settings

```
S3_ACCESS_KEY=
S3_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=
```

Alternatively you can point to a file containing the S3_SECRET_ACCESS_KEY value. If using containers make sure the file is
persistent and available inside the container.

```
S3_SECRET_ACCESS_KEY_FILE=/path/to/file.txt
```

Optional settings (only copy the ones you need)

```
S3_REGION_NAME= # default none, set your region might be required
S3_QUERYSTRING_AUTH=1 # default true, set to 0 to serve media from a public bucket without signed urls
S3_QUERYSTRING_EXPIRE=3600 # number of seconds querystring are valid for
S3_ENDPOINT_URL= # when using a custom endpoint like minio
S3_CUSTOM_DOMAIN= # when using a CDN/proxy to S3 (see https://github.com/TandoorRecipes/recipes/issues/1943)
```

#### AI Integration

Most AI features are configured trough the AI Provider settings in the Tandoor web interface. Some defaults can be set for new spaces on your instance.

Enables AI features for spaces by default
```
SPACE_AI_ENABLED=1
```

Sets the monthly default credit limit for AI usage
```
SPACE_AI_CREDITS_MONTHLY=100
```

Ratelimit for AI API
```
AI_RATELIMIT=60/hour
```

#### FDC Api

The FDC Api is used to automatically load nutrition information from
the [FDC Nutrition Database](https://fdc.nal.usda.gov/fdc-app.html#/).
The default `DEMO_KEY` is limited to 30 requests / hour or 50 requests / day.
If you want to do many requests to the FDC API you need to get a (free) API
key [here](https://fdc.nal.usda.gov/api-key-signup.html).

```
FDC_API_KEY=DEMO_KEY
```

#### Connectors

- `DISABLE_EXTERNAL_CONNECTORS` is a global switch to disable External Connectors entirely.
- `EXTERNAL_CONNECTORS_QUEUE_SIZE` is the amount of changes that are kept in memory if the worker cannot keep up.

(External) Connectors are used to sync the status from Tandoor to other services. More info can be found [here](https://docs.tandoor.dev/features/connectors/).

```env
DISABLE_EXTERNAL_CONNECTORS=0  # Default 0 (false), set to 1 (true) to disable connectors
EXTERNAL_CONNECTORS_QUEUE_SIZE=100  # Defaults to 100, set to any number >1
```

### Debugging/Development settings

!!! warning
    These settings should not be left on in production as they might provide additional attack surfaces and
    information to adversaries.

#### Debug

> default `0` - options: `0`, `1`

!!! info
    Please enable this before posting logs anywhere to ask for help.

Setting to `1` enables several django debug features and additional
logs ([see docs](https://docs.djangoproject.com/en/5.0/ref/settings/#std-setting-DEBUG)).

```
DEBUG=0
```

#### Debug Toolbar

> default `0` - options: `0`, `1`

Set to `1` to enable django debug toolbar middleware. Toolbar only shows if `DEBUG=1` is set and the requesting IP
is in `INTERNAL_IPS`.
See [Django Debug Toolbar Docs](https://django-debug-toolbar.readthedocs.io/en/latest/).

```
DEBUG_TOOLBAR=0
```

#### SQL Debug

> default `0` - options: `0`, `1`

Set to `1` to enable additional query output on the search page.

```
SQL_DEBUG=0
```

#### Application Log Level

> default `WARNING` - options: [see Django Docs](https://docs.djangoproject.com/en/5.0/topics/logging/#loggers)

Increase or decrease the logging done by application.
Please set to `DEBUG` when making a bug report.

```
 LOG_LEVEL="DEBUG"
```


#### Gunicorn Log Level

> default `info` - options: [see Gunicorn Docs](https://docs.gunicorn.org/en/stable/settings.html#loglevel)

Increase or decrease the logging done by gunicorn (the python wsgi application).

```
 GUNICORN_LOG_LEVEL="debug"
```

### Default User Preferences

Having default user preferences is nice so that users signing up to your instance already have the settings you deem
appropriate.

#### Fractions

> default `0` - options: `0`,`1`

The default value for the user preference 'fractions' (showing amounts as decimals or fractions).

```
FRACTION_PREF_DEFAULT=0
```

#### Comments

> default `1` - options: `0`,`1`

The default value for the user preference 'comments' (enable/disable commenting system)

```
COMMENT_PREF_DEFAULT=1
```

#### Sticky Navigation

> default `1` - options: `0`,`1`

The default value for the user preference 'sticky navigation' (always show navbar on top or hide when scrolling)

```
STICKY_NAV_PREF_DEFAULT=1
```

#### Max owned spaces

> default `100` - options: `0-X`

The default for the number of spaces a user can own. By setting to 0 space creation for users will be disabled.
Superusers can always bypass this limit.

```
MAX_OWNED_SPACES_PREF_DEFAULT=100
```


### Cosmetic / Preferences

#### Timezone

> default `Europe/Berlin` - options: [see timezone DB](https://timezonedb.com/time-zones)

Default timezone to use for database
connections ([see Django docs](https://docs.djangoproject.com/en/5.0/ref/settings/#time-zone)).
Usually everything is converted to the users timezone so this setting doesn't really need to be correct.

```
TZ=Europe/Berlin
```

#### Default Theme
> default `0` - options `1-X` (space ID)

Tandoors appearance can be changed on a user and space level but unauthenticated users always see the tandoor default style.
With this setting you can specify the ID of a space of which the appearance settings should be applied if a user is not logged in.

```
UNAUTHENTICATED_THEME_FROM_SPACE=
```

#### Force Theme
> default `0` - options `1-X` (space ID)

Similar to the Default theme but forces the theme upon all users (authenticated/unauthenticated) and all spaces

```
FORCE_THEME_FROM_SPACE=
```

### Rate Limiting / Performance

#### Shopping auto sync

> default `5` - options: `1-XXX`

Users can set an amount of time after which the shopping list is automatically refreshed.
This is the minimum interval users can set. Setting this to a low value will allow users to automatically refresh very
frequently which
might cause high load on the server. (Technically they can obviously refresh as often as they want with their own
scripts)

```
SHOPPING_MIN_AUTOSYNC_INTERVAL=5
```

#### API Url Import throttle

> default `60/hour` - options: `x/hour`, `x/day`, `x/minute`, `x/second`

Limits how many recipes a user can import per hour.
A rate limit is recommended to prevent users from abusing your server for (DDoS) relay attacks and to prevent external
service
providers from blocking your server for too many request.

```
DRF_THROTTLE_RECIPE_URL_IMPORT=60/hour
```

#### Default Space Limits
You might want to limit how many resources a user might create. The following settings apply automatically to newly
created spaces. These defaults can be changed in the admin view after a space has been created.

If unset, all settings default to unlimited/enabled

```
SPACE_DEFAULT_MAX_RECIPES=0 # 0=unlimited recipes
SPACE_DEFAULT_MAX_USERS=0 # 0=unlimited users per space
SPACE_DEFAULT_MAX_FILES=0 # Maximum file storage for space in MB. 0 for unlimited, -1 to disable file upload.
SPACE_DEFAULT_ALLOW_SHARING=1 # Allow users to share recipes with public links
```

#### Export file caching
> default `600` - options `1-X`

Recipe exports are cached for a certain time (in seconds) by default, adjust time if needed
```
EXPORT_FILE_CACHE_DURATION=600
```
