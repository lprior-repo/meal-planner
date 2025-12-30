---
doc_id: tutorial/extending/function-caching
chunk_id: tutorial/extending/function-caching#chunk-1
heading_path: ["function-caching"]
chunk_type: prose
tokens: 94
summary: "> **Context**: Dagger can persist the results of your module functions so repeated calls skip wor..."
---
# Function Caching

> **Context**: Dagger can persist the results of your module functions so repeated calls skip work when the inputs have not changed. This page explains how to tune t...


Dagger can persist the results of your module functions so repeated calls skip work when the inputs have not changed. This page explains how to tune that behavior, opt out when needed, and understand the trade-offs of each caching mode.
