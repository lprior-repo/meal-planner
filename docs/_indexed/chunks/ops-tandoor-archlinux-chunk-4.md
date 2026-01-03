---
doc_id: ops/tandoor/archlinux
chunk_id: ops/tandoor/archlinux#chunk-4
heading_path: ["Archlinux", "Upgrade"]
chunk_type: prose
tokens: 57
summary: "Upgrade"
---

## Upgrade
```shell
cd tandoor-recipes-git
git pull
makepkg -sif
```
Or use your favourite AUR helper.
You shouldn't need to do anything else. This package applies migration automatically. If PostgreSQL has been updated to a new major version, you may need to [run pg_upgrade](https://wiki.archlinux.org/title/PostgreSQL#pg_upgrade).
