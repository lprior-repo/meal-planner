# Service Proxies Configuration

Dagger can be configured to use HTTP(S) proxies to connect to external HTTP services.

## Supported Environment Variables

Standard:
- `HTTP_PROXY`
- `HTTPS_PROXY`
- `NO_PROXY`
- `ALL_PROXY`
- `FTP_PROXY`

Custom:
- `_DAGGER_ENGINE_SYSTEMENV_GOPROXY` (propagated to `GOPROXY` for Go modules)

## Configuration

Configuring proxy settings requires [provisioning a custom engine](/reference/configuration/custom-runner).

Set the environment variables on the custom Dagger container.

## Applies to All Containers

These proxy environment variables set on Dagger will also be automatically set on all containers created by userspace Dagger Functions unless otherwise specified.

The values of these environment variables:
- Do not impact caching of containers
- Are not persisted in Dagger's cache
- Changing values won't invalidate cache

If `withEnvVariable` API is used to explicitly set proxy environment variables, those will override any settings inherited from Dagger's proxy configuration.
