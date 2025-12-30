---
doc_id: ops/system/configuration
chunk_id: ops/system/configuration#chunk-3
heading_path: ["Configuration", "Optional Settings"]
chunk_type: code
tokens: 1916
summary: "Optional Settings"
---

## Optional Settings

All optional settings are, as their name says, optional and can be ignored safely. If you want to know more about what
you can do with them take a look through this page. I recommend using the categories to guide yourself.

### Server configuration

Configuration options for serving related services.

#### Port

> default `80` - options: `1-65535`

!!! warning
    Changed in version 2.3 to no longer configure the port of gunicorn but the port of the internal nginx

Port where Tandoor exposes its internal web server.

```bash
TANDOOR_PORT=80
```text


#### URL Path

> default `None` - options: `/custom/url/base/path`

If base URL is something other than just / (you are serving a subfolder in your proxy for
instance http://recipe_app/recipes/)
Be sure to not have a trailing slash: e.g. '/recipes' instead of '/recipes/'

```bash
SCRIPT_NAME=/recipes
```

#### Static URL

> default `/static/` - options: `/any/url/path/`, `https://any.domain.name/and/url/path`

If staticfiles are stored or served from a different location uncomment and change accordingly.
This can either be a relative path from the applications base path or the url of an external host.

!!! info
    - MUST END IN `/`
    - This is not required if you are just using a subfolder

```bash
STATIC_URL=/static/
```nginx

#### Static root

> default `<basedir>/staticfiles` - options `/some/other/media/path`.

Where staticfiles should be stored on disk. The default location is a
`staticfiles` subfolder at the root of the application directory.

#### Media URL

> default `/static/` - options: `/any/url/path/`, `https://any.domain.name/and/url/path`

If mediafiles are stored at a different location uncomment and change accordingly.
This can either be a relative path from the applications base path or the url of an external host

!!! info
    - MUST END IN `/`
    - This is **not required** if you are just using a subfolder
    - This is **not required** if using S3/object storage

```bash
MEDIA_URL=/media/
```

#### Media root

> default `<basedir>/mediafiles` - options `/some/other/media/path`.

Where mediafiles should be stored on disk. The default location is a
`mediafiles` subfolder at the root of the application directory.

#### Gunicorn Workers

> default `3` - options `1-X`

Set the number of gunicorn workers to start when starting using `boot.sh` (all container installations).
The default is likely appropriate for most installations.
See [Gunicorn docs](https://docs.gunicorn.org/en/stable/design.html#how-many-workers) for recommended settings.

```bash
GUNICORN_WORKERS=3
```text

#### Gunicorn Threads

> default `2` - options `1-X`

Set the number of gunicorn threads to start when starting using `boot.sh` (all container installations).
The default is likely appropriate for most installations.
See [Gunicorn docs](https://docs.gunicorn.org/en/stable/design.html#how-many-workers) for recommended settings.

```bash
GUNICORN_THREADS=2
```


#### Gunicorn Timeout

> default `30` - options `1-X`

Set the timeout in seconds of gunicorn when starting using `boot.sh` (all container installations).
The default is likely appropriate for most installations. However, if you are using a LLM which high response times gunicornmight time out during the wait until the LLM finished, in such cases you might want to increase the timeout.
See [Gunicorn docs]([https://docs.gunicorn.org/en/stable/design.html#how-many-workers](https://docs.gunicorn.org/en/stable/settings.html#timeout)) for default settings.

```bash
GUNICORN_TIMEOUT=30
```text

#### Gunicorn Media

> default `0` - options `0`, `1`

Serve media files directly using gunicorn. Basically everyone recommends not doing this. Please use any of the examples
provided that include an additional nxginx container to handle media file serving.
If you know what you are doing turn this on (`1`) to serve media files using djangos serve() method.

```bash
GUNICORN_MEDIA=0
```

#### CSRF Trusted Origins

> default `[]` - options: [list,of,trusted,origins]

Allows setting origins to allow for unsafe requests.
See [Django docs](https://docs.djangoproject.com/en/5.0/ref/settings/#csrf-trusted-origins)

```bash
CSRF_TRUSTED_ORIGINS = []
```text

#### Cors origins

> default `False` - options: `False`, `True`

By default, cross-origin resource sharing is disabled. Enabling this will allow access to your resources from other
domains.
Please read [the docs](https://github.com/adamchainz/django-cors-headers) carefully before enabling this.

```bash
CORS_ALLOW_ALL_ORIGINS = True
```

#### Session Cookies

Django session cookie settings. Can be changed to allow a single django application to authenticate several applications
when running under the same database.

```bash
SESSION_COOKIE_DOMAIN=.example.com
SESSION_COOKIE_NAME=sessionid # use this only to not interfere with non unified django applications under the same top level domain
```text

### Features

Some features can be enabled/disabled on a server level because they might change the user experience significantly,
they might be unstable/beta or they have performance/security implications.

#### Captcha

If you allow signing up to your instance you might want to use a captcha to prevent spam.
Tandoor supports HCAPTCHA which is supposed to be a privacy-friendly captcha provider.
See [HCAPTCHA website](https://www.hcaptcha.com/) for more information and to acquire your sitekey and secret.

```bash
HCAPTCHA_SITEKEY=
HCAPTCHA_SECRET=
```

#### Metrics

Enable serving of prometheus metrics under the `/metrics` path

!!! danger
    The view is not secured (as per the prometheus default way) so make sure to secure it
    through your web server.

```bash
ENABLE_METRICS=0
```text

#### Tree Sorting

> default `0` - options `0`, `1`

By default SORT_TREE_BY_NAME is disabled this will store all Keywords and Food in the order they are created.
Enabling this setting makes saving new keywords and foods very slow, which doesn't matter in most usecases.
However, when doing large imports of recipes that will create new objects, can increase total run time by 10-15x
Keywords and Food can be manually sorted by name in Admin
This value can also be temporarily changed in Admin, it will revert the next time the application is started

!!! info
    Disabling tree sorting is a temporary fix, in the future we might find a better implementation to allow tree sorting
    without the large performance impacts.

```bash
SORT_TREE_BY_NAME=0
```

#### PDF Export

> default `0` - options `0`, `1`

Exporting PDF's is a community contributed feature to export recipes as PDF files. This requires the server to download
a chromium binary and is generally implemented only rudimentary and somewhat slow depending on your server device.

See [Export feature docs](https://docs.tandoor.dev/features/import_export/#pdf) for additional information.

```bash
ENABLE_PDF_EXPORT=1
```text

#### Legal URLS

Depending on your jurisdiction you might need to provide any of the following URLs for your instance.

```bash
TERMS_URL=
PRIVACY_URL=
IMPRINT_URL=
```

#### Rate Limits

There are some rate limits that can be configured.

- RATELIMIT_URL_IMPORT_REQUESTS: limit the number of external URL import requests. Useful to prevent your server from being abused for malicious requests.

### Authentication

All configurable variables regarding authentication.
Please also visit the [dedicated docs page](https://docs.tandoor.dev/features/authentication/) for more information.

#### Default Permissions

Configures if a newly created user (from social auth or public signup) should automatically join into the given space and
default group.

This setting is targeted at private, single space instances that typically have a custom authentication system managing
access to the data.

!!! danger
    With public signup enabled this will give everyone access to the data in the given space

!!! warning
    This feature might be deprecated in favor of a space join and public viewing system in the future

> default `0` (disabled) - options `0`, `1-X` (space id)

When enabled will join user into space and apply group configured in `SOCIAL_DEFAULT_GROUP`.

```bash
SOCIAL_DEFAULT_ACCESS = 1
```text

> default `guest` - options `guest`, `user`, `admin`

```bash
SOCIAL_DEFAULT_GROUP=guest
```

#### Enable Signup

> default `0` - options `0`, `1`

Allow everyone to create local accounts on your application instance (without an invite link)
You might want to setup HCAPTCHA to prevent bots from creating accounts/spam.

!!! info
    Social accounts will always be able to sign up, if providers are configured

```bash
ENABLE_SIGNUP=0
```text

#### Social Auth

Allows you to set up external OAuth providers.

```bash
SOCIAL_PROVIDERS = allauth.socialaccount.providers.github, allauth.socialaccount.providers.nextcloud,
```

#### Remote User Auth
> default `0` - options `0`, `1`

Allow authentication via the REMOTE-USER header (can be used for e.g. authelia).

!!! danger
    Leave off if you don't know what you are doing! Enabling this without proper configuration will enable anybody
    to login with any username!

```bash
REMOTE_USER_AUTH=0
```text

#### LDAP

LDAP based authentication is disabled by default. You can enable it by setting `LDAP_AUTH` to `1` and configuring the
other
settings accordingly. Please remove/comment settings you do not need for your setup.

```bash
LDAP_AUTH=
AUTH_LDAP_SERVER_URI=
AUTH_LDAP_BIND_DN=
AUTH_LDAP_BIND_PASSWORD=
AUTH_LDAP_USER_SEARCH_BASE_DN=
AUTH_LDAP_TLS_CACERTFILE=
AUTH_LDAP_START_TLS=
```

Instead of passing the LDAP password directly through the environment variable `AUTH_LDAP_BIND_PASSWORD`,
you can set the password in a file and set the environment variable `AUTH_LDAP_BIND_PASSWORD_FILE`
to the path of the file containing the ldap secret.

```bash
AUTH_LDAP_BIND_PASSWORD_FILE=/run/secrets/ldap_password.txt
```text

### External Services

#### Email

Email Settings, see [Django docs](https://docs.djangoproject.com/en/3.2/ref/settings/#email-host) for additional
information.
Required for email confirmation and password reset (automatically activates if host is set).

```bash
EMAIL_HOST=
EMAIL_PORT=
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=
EMAIL_USE_TLS=0
EMAIL_USE_SSL=0
# email sender address (default 'webmaster@localhost')

> **Context**: This page describes all configuration options for the application server. All settings must be configured in the environment of the application server
DEFAULT_FROM_EMAIL=
```

Instead of passing the email password directly through the environment variable `EMAIL_HOST_PASSWORD`,
you can set the password in a file and set the environment variable `EMAIL_HOST_PASSWORD_FILE`
to the path of the file containing the ldap secret.

```bash
EMAIL_HOST_PASSWORD_FILE=/run/secrets/email_password.txt
```text

Optional settings (only copy the ones you need)

```bash
