---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-12
heading_path: ["Faq", "How can I add an admin user?"]
chunk_type: prose
tokens: 54
summary: "How can I add an admin user?"
---

## How can I add an admin user?
To create a superuser you need to

1. execute into the container using `docker-compose exec web_recipes sh`
2. activate the virtual environment `source venv/bin/activate`
3. run `python manage.py createsuperuser` and follow the steps shown.
