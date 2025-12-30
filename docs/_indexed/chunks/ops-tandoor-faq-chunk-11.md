---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-11
heading_path: ["Faq", "How can I reset passwords?"]
chunk_type: prose
tokens: 63
summary: "How can I reset passwords?"
---

## How can I reset passwords?
To reset a lost password if access to the container is lost you need to:

1. execute into the container using `docker-compose exec web_recipes sh`
2. activate the virtual environment `source venv/bin/activate`
3. run `python manage.py changepassword <username>` and follow the steps shown.
