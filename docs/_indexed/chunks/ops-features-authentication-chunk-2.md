---
doc_id: ops/features/authentication
chunk_id: ops/features/authentication#chunk-2
heading_path: ["Authentication", "Allauth"]
chunk_type: code
tokens: 1002
summary: "Allauth"
---

## Allauth
[Django Allauth](https://django-allauth.readthedocs.io/en/latest/index.html) is an awesome project that
allows you to use a [huge number](https://docs.allauth.org/en/latest/socialaccount/providers/index.html) of different
authentication providers.

They basically explain everything in their documentation, but the following is a short overview on how to get started.

<!-- prettier-ignore -->
!!! warning "Public Providers"
    If you choose Google, Github or any other publicly available service as your authentication provider anyone
    with an account on that site can create an account on your installation.
    A new account does not have any permission but it is still **not recommended** to give public access to
    your installation.

Choose a provider from the [list](https://docs.allauth.org/en/latest/socialaccount/providers/index.html) and install it using the environment variable `SOCIAL_PROVIDERS` as shown
in the example below.

When at least one social provider is set up, the social login sign in buttons should appear on the login page. The example below enables Nextcloud and the generic OpenID Connect providers.

```ini
SOCIAL_PROVIDERS=allauth.socialaccount.providers.openid_connect,allauth.socialaccount.providers.nextcloud
```

<!-- prettier-ignore -->
!!! warning "Formatting"
   The exact formatting is important so make sure to follow the steps explained here!

### Configuration, via environment

Depending on your authentication provider you **might need** to configure it.
This needs to be done through the settings system. To make the system flexible (allow multiple providers) and to
not require another file to be mounted into the container the configuration ins done through a single
environment variable. The downside of this approach is that the configuration needs to be put into a single line
as environment files loaded by docker compose don't support multiple lines for a single variable.

The line data needs to either be in json or as Python dictionary syntax.

Take the example configuration from the allauth docs, fill in your settings and then inline the whole object
(you can use a service like [www.freeformatter.com](https://www.freeformatter.com/json-formatter.html) for formatting).
Assign it to the additional `SOCIALACCOUNT_PROVIDERS` variable.

The example below is for a generic OIDC provider with PKCE enabled. Most values need to be customized for your specifics!

```ini
SOCIALACCOUNT_PROVIDERS = "{ 'openid_connect': { 'OAUTH_PKCE_ENABLED': True, 'APPS': [ { 'provider_id': 'oidc', 'name': 'My-IDM', 'client_id': 'my_client_id', 'secret': 'my_client_secret', 'settings': { 'server_url': 'https://idm.example.com/oidc/recipes' } } ] } }"
```

Because this JSON contains sensitive data (client id and secret), you may instead choose to save the JSON in a file
and set the environment variable `SOCIALACCOUNT_PROVIDERS_FILE` to the path of the file containing the JSON.

```
SOCIALACCOUNT_PROVIDERS_FILE=/run/secrets/socialaccount_providers.txt
```

!!! success "Improvements ?"
    There are most likely ways to achieve the same goal but with a cleaner or simpler system.
    If you know such a way feel free to let me know.

### Configuration, via Django Admin

Instead of defining `SOCIALACCOUNT_PROVIDERS` in your environment, most configuration options can be done via the Admin interface. PKCE for `openid_connect` cannot currently be enabled this way.
Use your superuser account to configure your authentication backend by opening the admin page and do the following

1. Select `Sites` and edit the default site with the URL of your installation (or create a new).
2. Create a new `Social Application` with the required information as stated in the provider documentation of allauth.
3. Make sure to add your site to the list of available sites

Now the provider is configured and you should be able to sign up and sign in using the provider.
Use the superuser account to grant permissions to the newly created users, or enable default access via `SOCIAL_DEFAULT_ACCESS` & `SOCIAL_DEFAULT_GROUP`.

<!-- prettier-ignore -->
!!! info "WIP"
    I do not have a ton of experience with using various single signon providers and also cannot test all of them.
    If you have any Feedback or issues let me know.

### Third-party authentication example

Keycloak is a popular IAM solution and integration is straight forward thanks to Django Allauth. This example can also be used as reference for other third-party authentication solutions, as documented by Allauth.

At Keycloak, create a new client and assign a `Client-ID`, this client comes with a `Secret-Key`. Both values are required later on. Make sure to define the correct Redirection-URL for the service, for example `https://tandoor.example.com/*`. Depending on your Keycloak setup, you need to assign roles and groups to grant access to the service.

To enable Keycloak as a sign in option, set those variables to define the social provider and specify its configuration:

```ini
SOCIAL_PROVIDERS=allauth.socialaccount.providers.openid_connect
SOCIALACCOUNT_PROVIDERS='{"openid_connect":{"APPS":[{"provider_id":"keycloak","name":"Keycloak","client_id":"KEYCLOAK_CLIENT_ID","secret":"KEYCLOAK_CLIENT_SECRET","settings":{"server_url":"https://auth.example.org/realms/KEYCLOAK_REALM/.well-known/openid-configuration"}}]}}
'
```

You are now able to sign in using Keycloak after a restart of the service.

### Linking accounts
To link an account to an already existing normal user go to the settings page of the user and link it.
Here you can also unlink your account if you no longer want to use a social login method.
