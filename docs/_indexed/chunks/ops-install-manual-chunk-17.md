---
doc_id: ops/install/manual
chunk_id: ops/install/manual#chunk-17
heading_path: ["Manual installation instructions", "if the output is not \"0 static files copied\" you might want to run the commands again to make sure everythig is collected"]
chunk_type: prose
tokens: 40
summary: "if the output is not \"0 static files copied\" you might want to run the commands again to make sure e"
---

## if the output is not "0 static files copied" you might want to run the commands again to make sure everythig is collected
bin/python3 manage.py collectstatic --no-input
bin/python3 manage.py collectstatic_js_reverse
