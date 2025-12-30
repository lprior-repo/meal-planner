---
doc_id: ops/install/manual
chunk_id: ops/install/manual#chunk-14
heading_path: ["Manual installation instructions", "load envirtonment variables"]
chunk_type: prose
tokens: 23
summary: "load envirtonment variables"
---

## load envirtonment variables
export $(cat /var/www/recipes/.env |grep "^[^#]" | xargs)
#install project requirements
bin/pip3 install -r requirements.txt
