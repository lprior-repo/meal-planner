---
doc_id: ops/install/manual
chunk_id: ops/install/manual#chunk-9
heading_path: ["Manual installation instructions", "Initialize the application"]
chunk_type: prose
tokens: 76
summary: "Initialize the application"
---

## Initialize the application

Execute `export $(cat /var/www/recipes/.env |grep "^[^#]" | xargs)` to load variables from `/var/www/recipes/.env`

Execute `bin/python3 manage.py migrate`

and revert superuser from postgres:

```
sudo -u postgres psql` and `ALTER USER djangouser WITH NOSUPERUSER;
exit
```

Generate static files: `bin/python3 manage.py collectstatic --no-input` and `bin/python3 manage.py collectstatic_js_reverse` and remember the folder where files have been copied.
