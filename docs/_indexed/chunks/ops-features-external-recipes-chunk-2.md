---
doc_id: ops/features/external-recipes
chunk_id: ops/features/external-recipes#chunk-2
heading_path: ["External Recipes", "Storage"]
chunk_type: prose
tokens: 601
summary: "Storage"
---

## Storage

<!-- prettier-ignore -->
!!! danger
    In order for this application to retrieve data from external providers it needs to store authentication information.
    Please use read only/separate accounts or app passwords wherever possible.
    There are better ways to do this but they are currently not implemented

A `Storage Backend` is a remote storage location where files are **read** from.
To add a new backend click on `username >> External Recipes >> Manage External Storage >> the + next to Storage Backend List`.
There click the plus button.

The basic configuration is the same for all providers.

| Field  | Value                                                                |
| ------ | -------------------------------------------------------------------- |
| Name   | Your identifier for this storage source, can be everything you want. |
| Method | The desired method.                                                  |

<!-- prettier-ignore -->
!!! success
    Only the providers listed below are currently implemented. If you need anything else feel free to open
    an issue or pull request.

### Local

<!-- prettier-ignore -->
!!! info
    There is currently no way to upload files through the webinterface. This is a feature that might be added later.

The local provider does not need any configuration (username, password, token or URL).
For the monitor you will need to define a valid path on your host system. (Path)
The Path depends on your setup and can be both relative and absolute.

<!-- prettier-ignore -->
!!! warning "Volume"
    By default no data other than the mediafiles and the database is persisted. If you use the local provider
    make sure to mount the path you choose to monitor to your host system in order to keep it persistent.

#### Docker

If you use docker the default directory is `/opt/recipes/`.
add

```
      - ./externalfiles:/opt/recipes/externalfiles
```

to your docker-compose.yml file under the `web_recipes >> volumes` section. This will create a folder in your docker directory named `externalfiles` under which you could choose to store external pdfs (you could of course store them anywhere, just change `./externalfiles` to your preferred location).
save the docker-compose.yml and restart your docker container.

### Dropbox

| Field    | Value                                                                                                             |
| -------- | ----------------------------------------------------------------------------------------------------------------- |
| Username | Dropbox username                                                                                                  |
| Token    | Dropbox API Token. Can be found [here](https://dropbox.github.io/dropbox-api-v2-explorer/#auth_token/from_oauth1) |

### Nextcloud

<!-- prettier-ignore -->
!!! warning "Path"
    It appears that the correct webdav path varies from installation to installation (for whatever reason).
    In the Nextcloud webinterface click the `Settings` button in the bottom left corner, there your WebDav Url will be displayed.

| Field    | Value                                                                                                                                              |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Username | Nextcloud username                                                                                                                                 |
| Password | Nextcloud app password                                                                                                                             |
| Url      | Nextcloud Server URL (e.g. `https://cloud.mydomain.com`)                                                                                           |
| Path     | (optional) webdav path (e.g. `/remote.php/dav/files/vabene1111`). If no path is supplied `/remote.php/dav/files/` plus your username will be used. |
