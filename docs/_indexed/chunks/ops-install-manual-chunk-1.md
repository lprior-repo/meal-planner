---
doc_id: ops/install/manual
chunk_id: ops/install/manual#chunk-1
heading_path: ["Manual installation instructions"]
chunk_type: prose
tokens: 141
summary: "Manual installation instructions"
---

# Manual installation instructions

> **Context**: These instructions are inspired from a standard django/gunicorn/postgresql instructions ([for example](https://www.digitalocean.com/community/tutorial

These instructions are inspired from a standard django/gunicorn/postgresql instructions ([for example](https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04))

!!! warning
    Make sure to use at least Python 3.12 or higher, and ensure that `pip` is associated with Python 3. Depending on your system configuration, using `python` or `pip` might default to Python 2. Make sure your machine has at least 2048 MB of memory; otherwise, the `yarn build` process may fail with the error: `FATAL ERROR: Reached heap limit - Allocation failed: JavaScript heap out of memory`.

!!! warning
    These instructions are **not** regularly reviewed and might be outdated.
