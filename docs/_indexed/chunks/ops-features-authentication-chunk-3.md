---
doc_id: ops/features/authentication
chunk_id: ops/features/authentication#chunk-3
heading_path: ["Authentication", "LDAP"]
chunk_type: code
tokens: 85
summary: "LDAP"
---

## LDAP

LDAP authentication can be enabled in the `.env` file by setting `LDAP_AUTH=1`.
If set, users listed in the LDAP instance will be able to sign in without signing up.
These variables must be set to configure the connection to the LDAP instance:

```
AUTH_LDAP_SERVER_URI=ldap://ldap.example.org:389
AUTH_LDAP_BIND_DN=uid=admin,ou=users,dc=example,dc=org
AUTH_LDAP_BIND_PASSWORD=adminpassword
AUTH_LDAP_USER_SEARCH_BASE_DN=ou=users,dc=example,dc=org
```text

Additional optional variables:

```
AUTH_LDAP_USER_SEARCH_FILTER_STR=(uid=%(user)s)
AUTH_LDAP_USER_ATTR_MAP={'first_name': 'givenName', 'last_name': 'sn', 'email': 'mail'}
AUTH_LDAP_ALWAYS_UPDATE_USER=1
AUTH_LDAP_CACHE_TIMEOUT=3600
AUTH_LDAP_START_TLS=1
AUTH_LDAP_TLS_CACERTFILE=/etc/ssl/certs/own-ca.pem
```text
